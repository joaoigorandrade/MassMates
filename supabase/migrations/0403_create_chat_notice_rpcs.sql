-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025704  ("create_chat_notice_rpcs")
-- The backend agents ran CONCURRENTLY, so the applied order does NOT follow
-- the prefix order (the prefix only records the author's ownership range).
-- The file is therefore NOT renamed -- it is already applied.
--
-- A clean replay in FILENAME order is safe: the only two forward references
-- in the whole chain are `to_regclass`-guarded on purpose
-- (0305 -> public.feed_posts, 0402 -> public.notification_outbox), so they
-- no-op until the table exists.
-- =============================================================================

-- =============================================================================
-- A5 · 0403 · Chat + Pinned Notices RPCs
-- =============================================================================
-- Owner: A5.
--
-- Public surface (all SECURITY DEFINER, SET search_path = '', EXECUTE granted
-- to authenticated only):
--   public.get_chat_messages(p_group_id, p_before, p_limit)              -> jsonb
--   public.create_chat_message(p_group_id, p_body, p_reply_to_id)       -> jsonb
--   public.set_pinned_notice(p_group_id, p_body)                        -> jsonb  (group admin)
--   public.clear_pinned_notice(p_group_id)                              -> jsonb  (group admin)
-- -----------------------------------------------------------------------------

-- =============================================================================
-- public.get_chat_messages
-- =============================================================================
create or replace function public.get_chat_messages (
  p_group_id uuid,
  p_before   text    default null,
  p_limit    integer default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid ();
  v_limit  integer := least (greatest (coalesce (p_limit, 30), 1), 100);
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
    select m.id,
           m.group_id,
           m.user_id,
           m.body,
           m.reply_to_id,
           m.created_at
      from public.chat_messages m
     where m.group_id = p_group_id
       and not public.is_blocked (v_uid, m.user_id)
       and (
             v_ts is null
             or (v_id is null and m.created_at < v_ts)
             or (v_id is not null and (m.created_at, m.id) < (v_ts, v_id))
           )
     order by m.created_at desc, m.id desc
     limit v_limit
  )
  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'id', pg.id,
               'group_id', pg.group_id,
               'user_id', pg.user_id,
               'body', pg.body,
               'reply_to_id', pg.reply_to_id,
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

comment on function public.get_chat_messages (uuid, text, integer) is
  'Cursor-paginated group chat. Returns {"items":[...],"next_cursor":"<iso>|<uuid>"|null}. NEWEST FIRST (a chat is read from the bottom up, so the client reverses the array when it renders). p_limit is clamped to 1..100. Messages from a blocked user are never returned. Pass next_cursor back as p_before for the next (older) page.';

-- =============================================================================
-- public.create_chat_message
-- =============================================================================
create or replace function public.create_chat_message (
  p_group_id    uuid,
  p_body        text,
  p_reply_to_id uuid default null
)
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
    raise exception 'message body cannot be empty' using errcode = '22023';
  end if;

  if char_length (v_body) > 2000 then
    raise exception 'message body must be at most 2000 characters' using errcode = '22023';
  end if;

  if not public.is_group_member (p_group_id, v_uid) then
    raise exception 'not a member of this group' using errcode = '42501';
  end if;

  if p_reply_to_id is not null then
    if not exists (
      select 1
        from public.chat_messages m
       where m.id = p_reply_to_id
         and m.group_id = p_group_id
    ) then
      raise exception 'the message being replied to does not exist in this group' using errcode = '22023';
    end if;
  end if;

  insert into public.chat_messages (group_id, user_id, body, reply_to_id)
  values (p_group_id, v_uid, v_body, p_reply_to_id)
  returning id, created_at into v_id, v_created_at;

  return jsonb_build_object (
    'id', v_id,
    'group_id', p_group_id,
    'user_id', v_uid,
    'body', v_body,
    'reply_to_id', p_reply_to_id,
    'created_at', private.a5_iso (v_created_at)
  );
end;
$$;

comment on function public.create_chat_message (uuid, text, uuid) is
  'Posts a message to the group chat. The caller must be a member of p_group_id. Body is trimmed and must be 1..2000 characters. p_reply_to_id must reference a message of the SAME group. Chat messages are immutable — there is no edit path.';

-- =============================================================================
-- public.set_pinned_notice
-- =============================================================================
create or replace function public.set_pinned_notice (p_group_id uuid, p_body text)
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
  v_deactivated integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_admin (p_group_id, v_uid) then
    raise exception 'only a group admin can pin a notice' using errcode = '42501';
  end if;

  v_body := btrim (coalesce (p_body, ''));

  if char_length (v_body) < 1 then
    raise exception 'notice body cannot be empty' using errcode = '22023';
  end if;

  if char_length (v_body) > 500 then
    raise exception 'notice body must be at most 500 characters' using errcode = '22023';
  end if;

  -- At most ONE active notice per group (partial unique index
  -- uq_pinned_notices_active_group): deactivate the previous one first.
  update public.pinned_notices
     set is_active = false
   where group_id = p_group_id
     and is_active;
  get diagnostics v_deactivated = row_count;

  insert into public.pinned_notices (group_id, author_id, body, is_active)
  values (p_group_id, v_uid, v_body, true)
  returning id, created_at into v_id, v_created_at;

  return jsonb_build_object (
    'id', v_id,
    'group_id', p_group_id,
    'author_id', v_uid,
    'body', v_body,
    'is_active', true,
    'replaced', v_deactivated,
    'created_at', private.a5_iso (v_created_at)
  );
end;
$$;

comment on function public.set_pinned_notice (uuid, text) is
  'Pins a notice at the top of a group (group admins only). The previous active notice is deactivated, so there is never more than one active notice per group. Returns the new notice plus the number of notices it replaced.';

-- =============================================================================
-- public.clear_pinned_notice
-- =============================================================================
create or replace function public.clear_pinned_notice (p_group_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid      uuid := auth.uid ();
  v_cleared  integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_admin (p_group_id, v_uid) then
    raise exception 'only a group admin can clear a notice' using errcode = '42501';
  end if;

  update public.pinned_notices
     set is_active = false
   where group_id = p_group_id
     and is_active;
  get diagnostics v_cleared = row_count;

  return jsonb_build_object (
    'group_id', p_group_id,
    'cleared', v_cleared
  );
end;
$$;

comment on function public.clear_pinned_notice (uuid) is
  'Removes the active pinned notice of a group (group admins only). Returns {"group_id":...,"cleared":n} where n is the number of notices deactivated. Idempotent: calling it with no active notice returns cleared = 0.';

-- =============================================================================
-- Privileges
-- =============================================================================
revoke execute on function public.get_chat_messages (uuid, text, integer)     from public, anon;
revoke execute on function public.create_chat_message (uuid, text, uuid)      from public, anon;
revoke execute on function public.set_pinned_notice (uuid, text)              from public, anon;
revoke execute on function public.clear_pinned_notice (uuid)                  from public, anon;

grant execute on function public.get_chat_messages (uuid, text, integer)     to authenticated;
grant execute on function public.create_chat_message (uuid, text, uuid)      to authenticated;
grant execute on function public.set_pinned_notice (uuid, text)              to authenticated;
grant execute on function public.clear_pinned_notice (uuid)                  to authenticated;
