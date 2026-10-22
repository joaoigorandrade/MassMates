-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025705  ("create_moderation_and_realtime_rpcs")
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
-- A5 · 0404 · Moderation RPC (A6 seam) + A4 fan-out seam + Realtime
-- =============================================================================
-- Owner: A5.
--
-- Public surface:
--   public.soft_delete_feed_post(p_post_id)  -> jsonb   (group admin)  [A6 calls this]
--   public.insert_feed_post(...)             -> jsonb   (server side)  [A4 calls this]
--
-- Realtime: chat_messages, amen_reactions and intention_prayers are added to
-- the `supabase_realtime` publication so the iOS client can subscribe to
-- `postgres_changes` on the three channels.
-- -----------------------------------------------------------------------------

-- =============================================================================
-- public.soft_delete_feed_post   (A6 seam)
-- =============================================================================
create or replace function public.soft_delete_feed_post (p_post_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid      uuid := auth.uid ();
  v_gid      uuid;
  v_author   uuid;
  v_already  boolean;
  v_changed  integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select p.group_id, p.user_id, p.is_hidden
    into v_gid, v_author, v_already
    from public.feed_posts p
   where p.id = p_post_id;

  if v_gid is null then
    raise exception 'post not found' using errcode = 'P0002';
  end if;

  if not public.is_group_admin (v_gid, v_uid) then
    raise exception 'only a group admin can remove a post' using errcode = '42501';
  end if;

  update public.feed_posts
     set is_hidden = true,
         hidden_reason = 'admin_removed'
   where id = p_post_id
     and not is_hidden;
  get diagnostics v_changed = row_count;

  if v_changed > 0 then
    insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
    values (
      v_uid,
      'feed.post_removed',
      'feed_post',
      p_post_id,
      jsonb_build_object (
        'group_id', v_gid,
        'post_author_id', v_author,
        'reason', 'admin_removed'
      )
    );
  end if;

  return jsonb_build_object (
    'post_id', p_post_id,
    'group_id', v_gid,
    'hidden', true,
    'hidden_reason', 'admin_removed',
    'changed', v_changed
  );
end;
$$;

comment on function public.soft_delete_feed_post (uuid) is
  'GROUP-ADMIN removal of a feed post (A6 seam). Sets is_hidden = true and hidden_reason = ''admin_removed'' and appends one row to public.audit_log (action ''feed.post_removed'', target_type ''feed_post''). The post stays in the table (soft delete) and remains visible to group admins. The caller MUST be an admin of the post''s group — a platform-moderator path must be implemented by A6 as its own SECURITY DEFINER RPC.';

-- =============================================================================
-- public.insert_feed_post   (A4 seam)
-- =============================================================================
-- A4 fans a GROUP-SHARED check-in out to public.feed_posts with a trigger on
-- public.check_in_destinations. This RPC is the safe entry point for that
-- trigger: it re-validates the check-in against A4's own tables, so a feed post
-- can only ever exist for a real, group-shared check-in — never for a private
-- one and never for a confession.
create or replace function public.insert_feed_post (
  p_check_in_id     uuid,
  p_group_id        uuid,
  p_user_id         uuid,
  p_practice_kind   public.practice_kind,
  p_reflection_text text    default null,
  p_photo_path      text    default null,
  p_points          integer default 0
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ci_user    uuid;
  v_ci_kind    public.practice_kind;
  v_ci_sharing text;
  v_id         uuid;
begin
  if p_practice_kind = 'confession'::public.practice_kind then
    raise exception 'a confession check-in can never be published to a feed' using errcode = '22023';
  end if;

  select ci.user_id, ci.practice_kind, ci.sharing
    into v_ci_user, v_ci_kind, v_ci_sharing
    from public.check_ins ci
   where ci.id = p_check_in_id;

  if v_ci_user is null then
    raise exception 'check-in % does not exist', p_check_in_id using errcode = 'P0002';
  end if;

  if v_ci_sharing <> 'group' then
    raise exception 'only a group-shared check-in can be published to a feed' using errcode = '22023';
  end if;

  if v_ci_user <> p_user_id or v_ci_kind <> p_practice_kind then
    raise exception 'check-in metadata does not match' using errcode = '22023';
  end if;

  if not exists (
    select 1
      from public.check_in_destinations d
     where d.check_in_id = p_check_in_id
       and d.group_id = p_group_id
  ) then
    raise exception 'the check-in was not shared with this group' using errcode = '22023';
  end if;

  -- Idempotent: one feed post per (check-in, group).
  select f.id into v_id
    from public.feed_posts f
   where f.check_in_id = p_check_in_id
     and f.group_id = p_group_id;

  if v_id is null then
    insert into public.feed_posts (
      check_in_id, group_id, user_id, practice_kind, reflection_text, photo_path, points
    )
    values (
      p_check_in_id, p_group_id, p_user_id, p_practice_kind, p_reflection_text, p_photo_path,
      greatest (coalesce (p_points, 0), 0)
    )
    returning id into v_id;
  end if;

  return jsonb_build_object (
    'id', v_id,
    'check_in_id', p_check_in_id,
    'group_id', p_group_id,
    'user_id', p_user_id,
    'practice_kind', p_practice_kind
  );
end;
$$;

comment on function public.insert_feed_post (uuid, uuid, uuid, public.practice_kind, text, text, integer) is
  'A4 seam. Creates (or returns the existing) feed post for a GROUP-SHARED check-in. Re-validates the check-in against public.check_ins and public.check_in_destinations, so a private check-in or a confession can never be published. Idempotent per (check_in_id, group_id). Not callable by clients.';

-- =============================================================================
-- Privileges
-- =============================================================================
revoke execute on function public.soft_delete_feed_post (uuid) from public, anon;
grant  execute on function public.soft_delete_feed_post (uuid) to authenticated;

revoke execute on function public.insert_feed_post (uuid, uuid, uuid, public.practice_kind, text, text, integer)
  from public, anon, authenticated;
grant execute on function public.insert_feed_post (uuid, uuid, uuid, public.practice_kind, text, text, integer)
  to service_role;

-- =============================================================================
-- Realtime
-- =============================================================================
-- The publication must exist. Supabase creates it on the project; create it
-- defensively with the default publish = 'insert, update, delete'.
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    execute 'create publication supabase_realtime';
  end if;
end;
$$;

-- Add the three live tables. Adding a table that is already a member raises
-- duplicate_object — that is caught and ignored.
do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'public.chat_messages',
    'public.amen_reactions',
    'public.intention_prayers'
  ] loop
    begin
      execute format ('alter publication supabase_realtime add table %s', v_table);
    exception
      when duplicate_object then
        null;  -- already a member of the publication
    end;
  end loop;
end;
$$;

-- REPLICA IDENTITY FULL so an UPDATE/DELETE realtime event carries the whole
-- row (Supabase recommendation for tables in the realtime publication).
alter table public.chat_messages    replica identity full;
alter table public.amen_reactions    replica identity full;
alter table public.intention_prayers replica identity full;

-- Defence in depth: the proof photo always lives in the witness-photos bucket.
alter table public.feed_posts
  add constraint feed_posts_photo_path_check
  check (photo_path is null or photo_path like 'witness-photos/%');
