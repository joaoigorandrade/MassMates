-- =============================================================================
-- 1002 · create_feed_comment_rpcs
-- =============================================================================
-- Gap closure (A9 report): `addComment` was a silent no-op because the
-- comments table did not exist (migration 1000). These are the four RPCs the
-- iOS client calls.
--
-- PATTERN (A10's private + INVOKER split, SCHEMA.md §21.4):
--   private.<name>_impl  -- SECURITY DEFINER, SET search_path = ''
--   public.<name>        -- thin SECURITY INVOKER wrapper
--
-- CURSOR (identical to A5's, SCHEMA.md §15.3):
--   next_cursor = "<created_at ISO-8601 UTC>|<row uuid>"
--   ordering    = created_at DESC, id DESC
--   p_before    = text (not timestamptz)
--   p_limit     = clamped to 1..50
--
-- AUDIT (identical to A5's soft_delete_feed_post, SCHEMA.md §15.7):
--   action       = 'feed.comment_removed'
--   target_type  = 'feed_post_comment'
--   metadata     = { group_id, comment_author_id, reason }
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. public.create_feed_post_comment(p_post_id uuid, p_body text) -> jsonb
-- -----------------------------------------------------------------------------

create or replace function private.create_feed_post_comment_impl (p_post_id uuid, p_body text)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid ();
  v_body      text;
  v_gid       uuid;
  v_id        uuid;
  v_created   timestamptz;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  v_body := btrim (coalesce (p_body, ''));

  if char_length (v_body) < 1 then
    raise exception 'comment body cannot be empty' using errcode = '22023';
  end if;

  if char_length (v_body) > 500 then
    raise exception 'comment body must be at most 500 characters' using errcode = '22023';
  end if;

  -- The post must be VISIBLE to the caller: the caller is a member of the
  -- post's group, is not blocked with the post author and the post is not
  -- hidden (a group admin may still comment on a hidden post).
  v_gid := private.a5_visible_post_group (p_post_id, v_uid);

  if v_gid is null then
    raise exception 'post not available' using errcode = '42501';
  end if;

  insert into public.feed_post_comments (post_id, group_id, user_id, body)
  values (p_post_id, v_gid, v_uid, v_body)
  returning id, created_at into v_id, v_created;

  return jsonb_build_object (
    'id',         v_id,
    'post_id',    p_post_id,
    'group_id',   v_gid,
    'user_id',    v_uid,
    'body',       v_body,
    'is_hidden',  false,
    'created_at', private.a5_iso (v_created)
  );
end;
$$;

create or replace function public.create_feed_post_comment (p_post_id uuid, p_body text)
  returns jsonb
  language plpgsql
  set search_path = ''
as $$
begin
  return private.create_feed_post_comment_impl (p_post_id, p_body);
end;
$$;

comment on function public.create_feed_post_comment (p_post_id uuid, p_body text) is
  'Adds an encouraging comment to a feed post. The body is trimmed; a blank body is rejected (22023) and a body longer than 500 characters is rejected (22023). The caller must be a member of the post''s group and the post must be visible. Returns { id, post_id, group_id, user_id, body, is_hidden, created_at }.';

-- -----------------------------------------------------------------------------
-- 2. public.get_feed_post_comments(p_post_id uuid, p_before text, p_limit int)
-- -----------------------------------------------------------------------------

create or replace function private.get_feed_post_comments_impl (p_post_id uuid, p_before text default null, p_limit integer default 20)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid ();
  v_gid    uuid;
  v_limit  integer;
  v_ts     timestamptz;
  v_id     uuid;
  v_items  jsonb;
  v_cursor text;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  v_gid := private.a5_visible_post_group (p_post_id, v_uid);

  if v_gid is null then
    raise exception 'post not available' using errcode = '42501';
  end if;

  v_limit := least (greatest (coalesce (p_limit, 20), 1), 50);
  v_ts    := private.a5_cursor_ts (p_before);
  v_id    := private.a5_cursor_id (p_before);

  with page as (
    select c.id,
           c.post_id,
           c.group_id,
           c.user_id,
           c.body,
           c.is_hidden,
           c.created_at
      from public.feed_post_comments c
     where c.post_id = p_post_id
       and not private.is_blocked_impl (v_uid, c.user_id)
       and (not c.is_hidden or private.is_group_admin_impl (v_gid, v_uid))
       and (
             v_ts is null
             or (v_id is null and c.created_at < v_ts)
             or (v_id is not null and (c.created_at, c.id) < (v_ts, v_id))
           )
     order by c.created_at desc, c.id desc
     limit v_limit
  )
  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'id',         pg.id,
               'post_id',    pg.post_id,
               'group_id',   pg.group_id,
               'user_id',    pg.user_id,
               'body',       pg.body,
               'is_hidden',  pg.is_hidden,
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

create or replace function public.get_feed_post_comments (p_post_id uuid, p_before text default null, p_limit integer default 20)
  returns jsonb
  language plpgsql
  stable
  set search_path = ''
as $$
begin
  return private.get_feed_post_comments_impl (p_post_id, p_before, p_limit);
end;
$$;

comment on function public.get_feed_post_comments (p_post_id uuid, p_before text, p_limit integer) is
  'The comments of a feed post, newest first. Cursor pagination: next_cursor = "<created_at ISO-8601 UTC>|<row uuid>", ordering created_at DESC, id DESC; pass it back unchanged as p_before. p_limit is clamped to 1..50. Returns { items: [ { id, post_id, group_id, user_id, body, is_hidden, created_at } ], next_cursor }.';

-- -----------------------------------------------------------------------------
-- 3. public.delete_feed_post_comment(p_comment_id uuid) -> jsonb
-- -----------------------------------------------------------------------------

create or replace function private.delete_feed_post_comment_impl (p_comment_id uuid)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid ();
  v_gid     uuid;
  v_author  uuid;
  v_deleted integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select c.group_id, c.user_id
    into v_gid, v_author
    from public.feed_post_comments c
   where c.id = p_comment_id;

  if v_gid is null then
    raise exception 'comment not found' using errcode = 'P0002';
  end if;

  if v_author <> v_uid and not private.is_group_admin_impl (v_gid, v_uid) then
    raise exception 'only the author or a group admin can delete a comment' using errcode = '42501';
  end if;

  delete from public.feed_post_comments where id = p_comment_id;
  get diagnostics v_deleted = row_count;

  return jsonb_build_object (
    'comment_id', p_comment_id,
    'group_id',   v_gid,
    'deleted',    v_deleted > 0
  );
end;
$$;

create or replace function public.delete_feed_post_comment (p_comment_id uuid)
  returns jsonb
  language plpgsql
  set search_path = ''
as $$
begin
  return private.delete_feed_post_comment_impl (p_comment_id);
end;
$$;

comment on function public.delete_feed_post_comment (p_comment_id uuid) is
  'Hard-deletes a comment. The author or a group admin of the comment''s group may do it. Returns { comment_id, group_id, deleted }.';

-- -----------------------------------------------------------------------------
-- 4. public.soft_delete_feed_post_comment(p_comment_id uuid) -> jsonb
--    (group admin; mirrors public.soft_delete_feed_post)
-- -----------------------------------------------------------------------------

create or replace function private.soft_delete_feed_post_comment_impl (p_comment_id uuid)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid ();
  v_gid       uuid;
  v_author    uuid;
  v_changed   integer;
  v_hidden_at timestamptz := now ();
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select c.group_id, c.user_id
    into v_gid, v_author
    from public.feed_post_comments c
   where c.id = p_comment_id;

  if v_gid is null then
    raise exception 'comment not found' using errcode = 'P0002';
  end if;

  if not private.is_group_admin_impl (v_gid, v_uid) then
    raise exception 'only a group admin can remove a comment' using errcode = '42501';
  end if;

  update public.feed_post_comments
     set is_hidden = true,
         hidden_reason = 'admin_removed',
         hidden_at = v_hidden_at
   where id = p_comment_id
     and not is_hidden;
  get diagnostics v_changed = row_count;

  if v_changed > 0 then
    insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
    values (
      v_uid,
      'feed.comment_removed',
      'feed_post_comment',
      p_comment_id,
      jsonb_build_object (
        'group_id', v_gid,
        'comment_author_id', v_author,
        'reason', 'admin_removed'
      )
    );
  end if;

  return jsonb_build_object (
    'comment_id',    p_comment_id,
    'group_id',      v_gid,
    'hidden',        true,
    'hidden_reason', 'admin_removed',
    'hidden_at',     private.a5_iso (v_hidden_at),
    'changed',       v_changed
  );
end;
$$;

create or replace function public.soft_delete_feed_post_comment (p_comment_id uuid)
  returns jsonb
  language plpgsql
  set search_path = ''
as $$
begin
  return private.soft_delete_feed_post_comment_impl (p_comment_id);
end;
$$;

comment on function public.soft_delete_feed_post_comment (p_comment_id uuid) is
  'Hides a comment (soft delete) -- group admin only. Sets is_hidden/hidden_reason/hidden_at and appends ONE public.audit_log row (action = feed.comment_removed, target_type = feed_post_comment). Idempotent: a second call returns changed = 0 and writes no second audit row. Returns { comment_id, group_id, hidden, hidden_reason, hidden_at, changed }.';

-- -----------------------------------------------------------------------------
-- Grants -- the explicit `anon` revoke is REQUIRED on this project: the
-- default ACL of the `public` schema grants EXECUTE on every new function to
-- `anon` (SCHEMA.md §18.8).
-- -----------------------------------------------------------------------------

revoke all on function private.create_feed_post_comment_impl (uuid, text) from public, anon;
grant execute on function private.create_feed_post_comment_impl (uuid, text) to authenticated, service_role;

revoke all on function private.get_feed_post_comments_impl (uuid, text, integer) from public, anon;
grant execute on function private.get_feed_post_comments_impl (uuid, text, integer) to authenticated, service_role;

revoke all on function private.delete_feed_post_comment_impl (uuid) from public, anon;
grant execute on function private.delete_feed_post_comment_impl (uuid) to authenticated, service_role;

revoke all on function private.soft_delete_feed_post_comment_impl (uuid) from public, anon;
grant execute on function private.soft_delete_feed_post_comment_impl (uuid) to authenticated, service_role;

revoke all on function public.create_feed_post_comment (uuid, text) from public, anon;
grant execute on function public.create_feed_post_comment (uuid, text) to authenticated, service_role;

revoke all on function public.get_feed_post_comments (uuid, text, integer) from public, anon;
grant execute on function public.get_feed_post_comments (uuid, text, integer) to authenticated, service_role;

revoke all on function public.delete_feed_post_comment (uuid) from public, anon;
grant execute on function public.delete_feed_post_comment (uuid) to authenticated, service_role;

revoke all on function public.soft_delete_feed_post_comment (uuid) from public, anon;
grant execute on function public.soft_delete_feed_post_comment (uuid) to authenticated, service_role;
