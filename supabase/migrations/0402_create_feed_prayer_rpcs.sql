-- =============================================================================
-- A5 · 0402 · Feed + Prayer Wall RPCs (and the private helpers they use)
-- =============================================================================
-- Owner: A5.
--
-- Public surface (all SECURITY DEFINER, SET search_path = '', EXECUTE granted
-- to authenticated only):
--   public.get_feed_posts(p_group_id, p_before, p_limit)          -> jsonb
--   public.get_prayer_intentions(p_group_id, p_before, p_limit)  -> jsonb
--   public.toggle_amen(p_post_id, p_reaction_type)               -> jsonb
--   public.toggle_prayed_for(p_intention_id)                      -> jsonb
--   public.create_prayer_intention(p_group_id, p_body)            -> jsonb
--   public.emit_prayer_notification(p_intention_id, p_prayer_id)  -> jsonb  (A8 seam)
--
-- The implementation helpers live in the non-exposed `private` schema so the
-- public schema only carries the documented RPC surface (A1's guidance).
-- -----------------------------------------------------------------------------

-- =============================================================================
-- private helpers
-- =============================================================================
create or replace function private.a5_iso (p_ts timestamptz)
  returns text
  language sql
  immutable
  set search_path = ''
as $$
  select to_char (p_ts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
$$;

comment on function private.a5_iso (timestamptz) is
  'UTC ISO-8601 with microseconds, e.g. 2026-10-21T23:39:12.345678Z. Used for every timestamp returned by the A5 RPCs and for the pagination cursor.';

create or replace function private.a5_cursor_text (p_ts timestamptz, p_id uuid)
  returns text
  language sql
  immutable
  set search_path = ''
as $$
  select private.a5_iso (p_ts) || '|' || p_id::text;
$$;

comment on function private.a5_cursor_text (timestamptz, uuid) is
  'Pagination cursor: "<created_at ISO-8601 UTC>|<post id>". Composite so keyset pagination is strict even when two rows share the same created_at.';

create or replace function private.a5_cursor_ts (p_cursor text)
  returns timestamptz
  language plpgsql
  immutable
  set search_path = ''
as $$
declare
  v_raw text;
begin
  if p_cursor is null or btrim (p_cursor) = '' then
    return null;
  end if;

  v_raw := split_part (btrim (p_cursor), '|', 1);

  begin
    return v_raw::timestamptz;
  exception
    when others then
      raise exception 'invalid cursor: %', p_cursor using errcode = '22007';
  end;
end;
$$;

create or replace function private.a5_cursor_id (p_cursor text)
  returns uuid
  language plpgsql
  immutable
  set search_path = ''
as $$
declare
  v_raw text;
begin
  if p_cursor is null or btrim (p_cursor) = '' then
    return null;
  end if;

  v_raw := split_part (btrim (p_cursor), '|', 2);

  if v_raw = '' then
    return null;
  end if;

  begin
    return v_raw::uuid;
  exception
    when others then
      raise exception 'invalid cursor: %', p_cursor using errcode = '22023';
  end;
end;
$$;

comment on function private.a5_cursor_ts (text) is
  'Parses the timestamp part of a pagination cursor. Accepts the composite "<iso>|<uuid>" and a bare ISO-8601 timestamp.';

comment on function private.a5_cursor_id (text) is
  'Parses the id part of a pagination cursor. Returns NULL for a bare timestamp cursor (strict created_at comparison, ties are skipped).';

create or replace function private.a5_visible_post_group (p_post_id uuid, p_user_id uuid)
  returns uuid
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_gid     uuid;
  v_author  uuid;
  v_hidden  boolean;
begin
  if p_post_id is null or p_user_id is null then
    return null;
  end if;

  select p.group_id, p.user_id, p.is_hidden
    into v_gid, v_author, v_hidden
    from public.feed_posts p
   where p.id = p_post_id;

  if v_gid is null then
    return null;
  end if;

  if not public.is_group_member (v_gid, p_user_id) then
    return null;
  end if;

  if public.is_blocked (p_user_id, v_author) then
    return null;
  end if;

  if v_hidden and not public.is_group_admin (v_gid, p_user_id) then
    return null;
  end if;

  return v_gid;
end;
$$;

comment on function private.a5_visible_post_group (uuid, uuid) is
  'Returns the group id of a feed post when p_user_id may see it (group member, no block in either direction, and either the post is not hidden or the user is a group admin). Returns NULL otherwise. SECURITY DEFINER so it can read feed_posts without RLS recursion.';

create or replace function private.a5_visible_intention_group (p_intention_id uuid, p_user_id uuid)
  returns uuid
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_gid     uuid;
  v_author  uuid;
  v_hidden  boolean;
begin
  if p_intention_id is null or p_user_id is null then
    return null;
  end if;

  select i.group_id, i.user_id, i.is_hidden
    into v_gid, v_author, v_hidden
    from public.prayer_intentions i
   where i.id = p_intention_id;

  if v_gid is null then
    return null;
  end if;

  if not public.is_group_member (v_gid, p_user_id) then
    return null;
  end if;

  if public.is_blocked (p_user_id, v_author) then
    return null;
  end if;

  if v_hidden and not public.is_group_admin (v_gid, p_user_id) then
    return null;
  end if;

  return v_gid;
end;
$$;

comment on function private.a5_visible_intention_group (uuid, uuid) is
  'Returns the group id of a prayer intention when p_user_id may see it (group member, no block in either direction, and either the intention is not hidden or the user is a group admin). Returns NULL otherwise.';

revoke execute on function private.a5_iso (timestamptz)                from public, anon, authenticated, service_role;
revoke execute on function private.a5_cursor_text (timestamptz, uuid)   from public, anon, authenticated, service_role;
revoke execute on function private.a5_cursor_ts (text)                 from public, anon, authenticated, service_role;
revoke execute on function private.a5_cursor_id (text)                 from public, anon, authenticated, service_role;
revoke execute on function private.a5_visible_post_group (uuid, uuid)   from public, anon, authenticated, service_role;
revoke execute on function private.a5_visible_intention_group (uuid, uuid) from public, anon, authenticated, service_role;

-- =============================================================================
-- public.get_feed_posts
-- =============================================================================
create or replace function public.get_feed_posts (
  p_group_id uuid,
  p_before   text    default null,
  p_limit    integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid ();
  v_limit  integer := least (greatest (coalesce (p_limit, 20), 1), 50);
  v_ts     timestamptz;
  v_id     uuid;
  v_items  jsonb;
  v_cursor text;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_member (p_group_id, v_uid) then
    raise exception 'not a member of this group' using errcode = '42501';
  end if;

  v_ts := private.a5_cursor_ts (p_before);
  v_id := private.a5_cursor_id (p_before);

  with page as (
    select p.id,
           p.check_in_id,
           p.group_id,
           p.user_id,
           p.practice_kind,
           p.reflection_text,
           p.photo_path,
           p.points,
           p.created_at,
           (select count (*)
              from public.amen_reactions r
             where r.post_id = p.id
               and r.reaction_type = 'amen') as amens,
           (select count (*)
              from public.amen_reactions r
             where r.post_id = p.id
               and r.reaction_type = 'united_in_prayer') as united_in_prayer,
           (select coalesce (array_agg (r.reaction_type order by r.reaction_type), '{}'::text [])
              from public.amen_reactions r
             where r.post_id = p.id
               and r.user_id = v_uid) as my_reactions
      from public.feed_posts p
     where p.group_id = p_group_id
       and not public.is_blocked (v_uid, p.user_id)
       and (not p.is_hidden or public.is_group_admin (p_group_id, v_uid))
       and (
             v_ts is null
             or (v_id is null and p.created_at < v_ts)
             or (v_id is not null and (p.created_at, p.id) < (v_ts, v_id))
           )
     order by p.created_at desc, p.id desc
     limit v_limit
  )
  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'id', pg.id,
               'check_in_id', pg.check_in_id,
               'group_id', pg.group_id,
               'user_id', pg.user_id,
               'practice_kind', pg.practice_kind,
               'reflection_text', pg.reflection_text,
               'photo_path', pg.photo_path,
               'points', pg.points,
               'created_at', private.a5_iso (pg.created_at),
               'amens', pg.amens,
               'united_in_prayer', pg.united_in_prayer,
               'my_reactions', to_jsonb (pg.my_reactions)
             )
             order by pg.created_at desc, pg.id desc
           ),
           '[]'::jsonb
         ),
         (select private.a5_cursor_text (pg.created_at, pg.id)
            from page pg
           order by pg.created_at asc, pg.id asc
           limit 1)
    into v_items, v_cursor
  from page pg;

  return jsonb_build_object (
    'items', v_items,
    'next_cursor', v_cursor
  );
end;
$$;

comment on function public.get_feed_posts (uuid, text, integer) is
  'Cursor-paginated group feed. Returns {"items":[...],"next_cursor":"<iso>|<uuid>"|null}. Newest first. Only posts the caller may see (group member, no block in either direction, hidden posts only for group admins). p_limit is clamped to 1..50. Pass next_cursor back as p_before to fetch the next page; p_before also accepts a bare ISO-8601 timestamp (strict created_at comparison).';

-- =============================================================================
-- public.get_prayer_intentions
-- =============================================================================
create or replace function public.get_prayer_intentions (
  p_group_id uuid,
  p_before   text    default null,
  p_limit    integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid ();
  v_limit  integer := least (greatest (coalesce (p_limit, 20), 1), 50);
  v_ts     timestamptz;
  v_id     uuid;
  v_items  jsonb;
  v_cursor text;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_member (p_group_id, v_uid) then
    raise exception 'not a member of this group' using errcode = '42501';
  end if;

  v_ts := private.a5_cursor_ts (p_before);
  v_id := private.a5_cursor_id (p_before);

  with page as (
    select i.id,
           i.group_id,
           i.user_id,
           i.body,
           i.prayer_count,
           i.created_at,
           exists (
             select 1
               from public.intention_prayers ip
              where ip.intention_id = i.id
                and ip.prayer_id = v_uid
           ) as prayed
      from public.prayer_intentions i
     where i.group_id = p_group_id
       and not public.is_blocked (v_uid, i.user_id)
       and (not i.is_hidden or public.is_group_admin (p_group_id, v_uid))
       and (
             v_ts is null
             or (v_id is null and i.created_at < v_ts)
             or (v_id is not null and (i.created_at, i.id) < (v_ts, v_id))
           )
     order by i.created_at desc, i.id desc
     limit v_limit
  )
  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'id', pg.id,
               'group_id', pg.group_id,
               'user_id', pg.user_id,
               'body', pg.body,
               'prayer_count', pg.prayer_count,
               'prayed', pg.prayed,
               'created_at', private.a5_iso (pg.created_at)
             )
             order by pg.created_at desc, pg.id desc
           ),
           '[]'::jsonb
         ),
         (select private.a5_cursor_text (pg.created_at, pg.id)
            from page pg
           order by pg.created_at asc, pg.id asc
           limit 1)
    into v_items, v_cursor
  from page pg;

  return jsonb_build_object (
    'items', v_items,
    'next_cursor', v_cursor
  );
end;
$$;

comment on function public.get_prayer_intentions (uuid, text, integer) is
  'Cursor-paginated Prayer Wall. Returns {"items":[...],"next_cursor":"<iso>|<uuid>"|null}. Newest first. Only intentions the caller may see (group member, no block, hidden intentions only for group admins). p_limit is clamped to 1..50.';

-- =============================================================================
-- public.toggle_amen
-- =============================================================================
create or replace function public.toggle_amen (
  p_post_id       uuid,
  p_reaction_type text default 'amen'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid ();
  v_gid     uuid;
  v_reacted boolean;
  v_amens   integer;
  v_united  integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_reaction_type is null or p_reaction_type not in ('amen', 'united_in_prayer') then
    raise exception 'invalid reaction_type: %', p_reaction_type using errcode = '22023';
  end if;

  v_gid := private.a5_visible_post_group (p_post_id, v_uid);

  if v_gid is null then
    raise exception 'post not available' using errcode = '42501';
  end if;

  delete from public.amen_reactions r
   where r.post_id = p_post_id
     and r.user_id = v_uid
     and r.reaction_type = p_reaction_type;

  if found then
    v_reacted := false;
  else
    insert into public.amen_reactions (post_id, user_id, reaction_type)
    values (p_post_id, v_uid, p_reaction_type);
    v_reacted := true;
  end if;

  select count (*) filter (where reaction_type = 'amen'),
         count (*) filter (where reaction_type = 'united_in_prayer')
    into v_amens, v_united
    from public.amen_reactions r
   where r.post_id = p_post_id;

  return jsonb_build_object (
    'amens', v_amens,
    'united_in_prayer', v_united,
    'reacted', v_reacted
  );
end;
$$;

comment on function public.toggle_amen (uuid, text) is
  'Toggles the caller''s reaction on a feed post. Returns {"amens":n,"united_in_prayer":n,"reacted":bool} where reacted tells whether the caller now holds the toggled reaction type. Idempotent-safe: calling it twice restores the original state.';

-- =============================================================================
-- public.toggle_prayed_for
-- =============================================================================
create or replace function public.toggle_prayed_for (p_intention_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid ();
  v_gid    uuid;
  v_prayed boolean;
  v_count  integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  v_gid := private.a5_visible_intention_group (p_intention_id, v_uid);

  if v_gid is null then
    raise exception 'intention not available' using errcode = '42501';
  end if;

  delete from public.intention_prayers ip
   where ip.intention_id = p_intention_id
     and ip.prayer_id = v_uid;

  if found then
    v_prayed := false;
  else
    insert into public.intention_prayers (intention_id, prayer_id)
    values (p_intention_id, v_uid);
    v_prayed := true;
    perform public.emit_prayer_notification (p_intention_id, v_uid);
  end if;

  select i.prayer_count into v_count
    from public.prayer_intentions i
   where i.id = p_intention_id;

  return jsonb_build_object (
    'prayer_count', v_count,
    'prayed', v_prayed
  );
end;
$$;

comment on function public.toggle_prayed_for (uuid) is
  'Toggles "I Prayed for You" on a prayer intention. Returns {"prayer_count":n,"prayed":bool}. On insert it calls public.emit_prayer_notification (the A8 seam) so the author is notified.';

-- =============================================================================
-- public.create_prayer_intention
-- =============================================================================
create or replace function public.create_prayer_intention (p_group_id uuid, p_body text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid ();
  v_body       text;
  v_id         uuid;
  v_created_at timestamptz;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  v_body := btrim (coalesce (p_body, ''));

  if char_length (v_body) < 1 then
    raise exception 'intention body cannot be empty' using errcode = '22023';
  end if;

  if char_length (v_body) > 1000 then
    raise exception 'intention body must be at most 1000 characters' using errcode = '22023';
  end if;

  if not public.is_group_member (p_group_id, v_uid) then
    raise exception 'not a member of this group' using errcode = '42501';
  end if;

  insert into public.prayer_intentions (group_id, user_id, body)
  values (p_group_id, v_uid, v_body)
  returning id, created_at into v_id, v_created_at;

  return jsonb_build_object (
    'id', v_id,
    'group_id', p_group_id,
    'user_id', v_uid,
    'body', v_body,
    'prayer_count', 0,
    'created_at', private.a5_iso (v_created_at)
  );
end;
$$;

comment on function public.create_prayer_intention (uuid, text) is
  'Posts a public prayer request on the Prayer Wall. The caller must be a member of p_group_id. Body is trimmed and must be 1..1000 characters.';

-- =============================================================================
-- public.emit_prayer_notification  (A8 seam)
-- =============================================================================
-- A8 owns public.notification_outbox. Until that table exists this function is
-- a safe no-op: it never raises, it just reports that nothing was emitted.
-- A8 replaces the body (or keeps it) and creates the trigger documented in
-- supabase/SCHEMA.md -> "A5 additions".
create or replace function public.emit_prayer_notification (p_intention_id uuid, p_prayer_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_emitted boolean := false;
  v_reason  text;
begin
  if to_regclass ('public.notification_outbox') is null then
    return jsonb_build_object (
      'emitted', false,
      'reason', 'notification_outbox_not_available'
    );
  end if;

  begin
    execute $q$
      insert into public.notification_outbox (recipient_id, actor_id, kind, payload, created_at)
      values (
        (select i.user_id from public.prayer_intentions i where i.id = $1),
        $2,
        'intention.prayed_for',
        jsonb_build_object ('intention_id', $1, 'prayer_id', $2),
        now ()
      )
    $q$
    using p_intention_id, p_prayer_id;

    v_emitted := true;
    v_reason  := null;
  exception
    when others then
      v_emitted := false;
      v_reason  := sqlerrm;
  end;

  return jsonb_build_object (
    'emitted', v_emitted,
    'reason', v_reason
  );
end;
$$;

comment on function public.emit_prayer_notification (uuid, uuid) is
  'A8 seam. Writes the "someone prayed for you" notification into public.notification_outbox (A8 owns the table). SAFE TO CALL BEFORE THAT TABLE EXISTS: it detects the table with to_regclass and returns {"emitted":false,"reason":"notification_outbox_not_available"} instead of raising. A8 must create the AFTER INSERT trigger trg_intention_prayers_notify on public.intention_prayers (see supabase/SCHEMA.md -> A5 additions). Not callable by clients.';

-- =============================================================================
-- Privileges
-- =============================================================================
revoke execute on function public.get_feed_posts (uuid, text, integer)          from public, anon;
revoke execute on function public.get_prayer_intentions (uuid, text, integer)  from public, anon;
revoke execute on function public.toggle_amen (uuid, text)                     from public, anon;
revoke execute on function public.toggle_prayed_for (uuid)                     from public, anon;
revoke execute on function public.create_prayer_intention (uuid, text)          from public, anon;

grant execute on function public.get_feed_posts (uuid, text, integer)          to authenticated;
grant execute on function public.get_prayer_intentions (uuid, text, integer)  to authenticated;
grant execute on function public.toggle_amen (uuid, text)                     to authenticated;
grant execute on function public.toggle_prayed_for (uuid)                     to authenticated;
grant execute on function public.create_prayer_intention (uuid, text)          to authenticated;

-- The notification seam is server-side only: A8's trigger and service_role.
revoke execute on function public.emit_prayer_notification (uuid, uuid) from public, anon, authenticated;
grant  execute on function public.emit_prayer_notification (uuid, uuid) to service_role;
