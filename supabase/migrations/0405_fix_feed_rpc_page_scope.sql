-- =============================================================================
-- A5 · 0405 · Fix the page-CTE scope of the cursor-paginated RPCs
-- =============================================================================
-- Owner: A5.
--
-- Migrations 0402 and 0403 were applied to the shared project with a missing
-- `FROM page pg` in the outer SELECT of the `page` CTE, which made
-- public.get_feed_posts / public.get_prayer_intentions / public.get_chat_messages
-- fail with "missing FROM-clause entry for table pg". The definitions in
-- 0402/0403 have been corrected in place (so a fresh install is correct) and
-- this migration re-applies the corrected bodies to the live database.
--
-- No behaviour change beyond the alias scope: the cursor format, the ordering
-- and the visibility rules are identical.
-- -----------------------------------------------------------------------------

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
