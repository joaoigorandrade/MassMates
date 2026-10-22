-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025633  ("create_moderation_rpcs")
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
-- A6 · 0504 · moderation RPCs, auto-hide trigger and helpers
-- =============================================================================
-- Owner: A6 (storage, moderation & safety).
--
-- Public RPCs (all `security definer set search_path = ''`):
--   public.block_user(p_blocked_id uuid)                          -> jsonb
--   public.unblock_user(p_blocked_id uuid)                        -> jsonb
--   public.list_blocked_users()                                   -> jsonb
--   public.report_content(p_target_type text, p_target_id uuid,
--                         p_reason text, p_details text default null,
--                         p_group_id uuid default null)           -> jsonb
--   public.admin_delete_post(p_post_id uuid)                      -> jsonb
--   public.hide_content(p_target_type text, p_target_id uuid,
--                        p_reason text)                            -> jsonb
--   public.get_moderation_queue(p_group_id uuid)                  -> jsonb
--   public.resolve_report(p_report_id uuid, p_status text,
--                         p_note text default null)                -> jsonb
--   public.get_moderation_actions(p_group_id uuid)                -> jsonb
--
-- AUTO-HIDE: when the number of unresolved reports for one target reaches
-- private.auto_hide_threshold() (3), an AFTER INSERT trigger on
-- public.content_reports hides the target and records a moderation_actions
-- row of type 'auto_hide'.
--
-- The target tables owned by A4/A5 (feed_posts, chat_messages,
-- prayer_intentions) are referenced through `to_regclass` guards and hardcoded
-- table names, so this migration never depends on their deployment order and
-- never runs dynamic SQL against a caller-supplied table name.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- The A6 spec lists ten action types. A report that a moderator *acteded* on
-- has no matching type, so 'action_report' is added: without it the
-- resolution of an actioned report could not be recorded in the trail.
-- -----------------------------------------------------------------------------
alter table public.moderation_actions
  drop constraint if exists moderation_actions_action_type_check;

alter table public.moderation_actions
  add constraint moderation_actions_action_type_check
  check (action_type in ('hide_post','restore_post','delete_post','hide_chat_message',
                          'hide_intention','remove_member','warn_user','suspend_user',
                          'dismiss_report','action_report','auto_hide'));

-- -----------------------------------------------------------------------------
-- private helpers (not exposed through PostgREST)
-- -----------------------------------------------------------------------------
create or replace function private.auto_hide_threshold ()
  returns integer
  language sql
  immutable
as $$
  select 3;
$$;

revoke all on function private.auto_hide_threshold () from public, anon;

create or replace function private.has_column (p_table regclass, p_column text)
  returns boolean
  language sql
  stable
as $$
  select exists (
    select 1
      from pg_catalog.pg_attribute a
     where a.attrelid = p_table
       and a.attname = p_column
       and a.attnum > 0
       and not a.attisdropped
  );
$$;

revoke all on function private.has_column (regclass, text) from public, anon;

-- Resolve the group that owns a reported target.
create or replace function private.resolve_report_group (
  p_target_type text,
  p_target_id   uuid,
  p_group_id    uuid
)
  returns uuid
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_group  uuid;
  v_caller uuid := auth.uid ();
begin
  if p_group_id is not null then
    if public.is_group_member (p_group_id, v_caller) then
      return p_group_id;
    end if;
    return null;
  end if;

  if p_target_type = 'post' and to_regclass ('public.feed_posts') is not null then
    execute format ('select group_id from public.feed_posts where id = %L', p_target_id::text)
      into v_group;

  elsif p_target_type = 'chat_message' and to_regclass ('public.chat_messages') is not null then
    execute format ('select group_id from public.chat_messages where id = %L', p_target_id::text)
      into v_group;

  elsif p_target_type = 'prayer_intention' and to_regclass ('public.prayer_intentions') is not null then
    execute format ('select group_id from public.prayer_intentions where id = %L', p_target_id::text)
      into v_group;

  elsif p_target_type = 'check_in' and to_regclass ('public.feed_posts') is not null
        and private.has_column (to_regclass ('public.feed_posts'), 'check_in_id') then
    execute format ('select min(group_id) from public.feed_posts where check_in_id = %L', p_target_id::text)
      into v_group;

  elsif p_target_type = 'group' then
    v_group := p_target_id;

  elsif p_target_type = 'profile' then
    execute format (
      'select min (gm.group_id)
         from public.group_members gm
         join public.group_members mine on mine.group_id = gm.group_id
        where gm.user_id = %L and mine.user_id = %L',
      p_target_id::text, v_caller::text)
      into v_group;
  end if;

  return v_group;
end;
$$;

revoke all on function private.resolve_report_group (text, uuid, uuid) from public, anon;

-- Does the reported target exist? When the owning table is not deployed yet
-- the answer is optimistically 'yes' so the flow keeps working during a
-- rolling deployment.
create or replace function private.report_target_exists (p_target_type text, p_target_id uuid)
  returns boolean
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_cnt   int := 1;
  v_table text;
begin
  -- hardcoded allow-list: the table name is never taken from the caller.
  v_table := case p_target_type
               when 'post'            then 'feed_posts'
               when 'chat_message'    then 'chat_messages'
               when 'prayer_intention' then 'prayer_intentions'
               when 'check_in'        then 'check_ins'
               when 'profile'         then 'profiles'
               when 'group'           then 'groups'
             end;

  if v_table is null or to_regclass (format ('public.%I', v_table)) is null then
    return true;
  end if;

  execute format ('select count(*) from public.%I where id = %L', v_table, p_target_id::text)
    into v_cnt;

  return v_cnt > 0;
end;
$$;

revoke all on function private.report_target_exists (text, uuid) from public, anon;

-- Short preview of the reported content for the moderation queue. The column
-- name is picked from a hardcoded allow-list — never from caller input.
create or replace function private.target_preview (p_target_type text, p_target_id uuid)
  returns text
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_table text;
  v_col   text;
  v_text  text;
begin
  v_table := case p_target_type
               when 'post'            then 'feed_posts'
               when 'chat_message'    then 'chat_messages'
               when 'prayer_intention' then 'prayer_intentions'
             end;

  if v_table is null or to_regclass (format ('public.%I', v_table)) is null then
    return null;
  end if;

  foreach v_col in array array ['body', 'reflection_text', 'content', 'text', 'message', 'title'] loop
    if private.has_column (to_regclass (format ('public.%I', v_table)), v_col) then
      execute format ('select left(%I, 200) from public.%I where id = %L', v_col, v_table, p_target_id::text)
        into v_text;
      return v_text;
    end if;
  end loop;

  return null;
end;
$$;

revoke all on function private.target_preview (text, uuid) from public, anon;

-- Hide a target. Returns true when a row was actually hidden.
-- The table and column names are hardcoded — the caller only supplies a uuid.
create or replace function private.auto_hide_content (
  p_target_type    text,
  p_target_id      uuid,
  p_hidden_reason  text
)
  returns boolean
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_tbl   regclass;
  v_rows  int := 0;
  v_write text;
begin
  if p_target_type = 'post' then
    v_tbl := to_regclass ('public.feed_posts');
    if v_tbl is not null and private.has_column (v_tbl, 'is_hidden') then
      if private.has_column (v_tbl, 'hidden_reason') then
        begin
          execute format (
            'update public.feed_posts set is_hidden = true, hidden_reason = %L where id = %L',
            p_hidden_reason, p_target_id::text);
          get diagnostics v_rows = row_count;
        exception
          when check_violation then
            execute format ('update public.feed_posts set is_hidden = true where id = %L', p_target_id::text);
            get diagnostics v_rows = row_count;
        end;
      else
        execute format ('update public.feed_posts set is_hidden = true where id = %L', p_target_id::text);
        get diagnostics v_rows = row_count;
      end if;
    end if;

  elsif p_target_type = 'chat_message' then
    v_tbl := to_regclass ('public.chat_messages');
    if v_tbl is not null and private.has_column (v_tbl, 'is_hidden') then
      execute format ('update public.chat_messages set is_hidden = true where id = %L', p_target_id::text);
      get diagnostics v_rows = row_count;
    end if;

  elsif p_target_type = 'prayer_intention' then
    v_tbl := to_regclass ('public.prayer_intentions');
    if v_tbl is not null and private.has_column (v_tbl, 'is_hidden') then
      execute format ('update public.prayer_intentions set is_hidden = true where id = %L', p_target_id::text);
      get diagnostics v_rows = row_count;
    end if;

  elsif p_target_type = 'check_in' then
    -- A check-in has no visibility flag of its own: it is hidden through the
    -- feed rows that carry it into the group timeline.
    v_tbl := to_regclass ('public.feed_posts');
    if v_tbl is not null
       and private.has_column (v_tbl, 'is_hidden')
       and private.has_column (v_tbl, 'check_in_id') then
      execute format ('update public.feed_posts set is_hidden = true where check_in_id = %L', p_target_id::text);
      get diagnostics v_rows = row_count;
    end if;
  end if;

  return v_rows > 0;
end;
$$;

revoke all on function private.auto_hide_content (text, uuid, text) from public, anon;

-- -----------------------------------------------------------------------------
-- Auto-hide trigger
-- -----------------------------------------------------------------------------
create or replace function private.auto_hide_after_report ()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_count    int;
  v_threshold int;
  v_hidden   boolean := false;
begin
  v_threshold := private.auto_hide_threshold ();

  select count(*)::int
    into v_count
    from public.content_reports
   where target_type = new.target_type
     and target_id   = new.target_id
     and status in ('open', 'reviewing');

  if v_count < v_threshold then
    return new;
  end if;

  -- never stack two auto-hide actions for the same target
  if exists (
       select 1 from public.moderation_actions
        where action_type = 'auto_hide'
          and target_type = new.target_type
          and target_id   = new.target_id) then
    return new;
  end if;

  v_hidden := private.auto_hide_content (new.target_type, new.target_id, 'auto_hidden');
  if not v_hidden then
    return new;
  end if;

  insert into public.moderation_actions
    (actor_id, action_type, target_type, target_id, group_id, report_id, reason, metadata)
  values
    (new.reporter_id, 'auto_hide', new.target_type, new.target_id, new.group_id, new.id,
     'hidden automatically after ' || v_count || ' reports',
     jsonb_build_object ('report_count', v_count, 'threshold', v_threshold, 'origin', 'auto_hide_threshold'));

  insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
  values
    (new.reporter_id, 'moderation.auto_hidden', new.target_type, new.target_id,
     jsonb_build_object ('report_count', v_count, 'threshold', v_threshold,
                         'report_id', new.id, 'group_id', new.group_id));

  return new;
end;
$$;

revoke all on function private.auto_hide_after_report () from public, anon;

create trigger trg_content_reports_auto_hide
  after insert on public.content_reports
  for each row execute function private.auto_hide_after_report ();

-- -----------------------------------------------------------------------------
-- 1. block_user / unblock_user / list_blocked_users
-- -----------------------------------------------------------------------------
create or replace function public.block_user (p_blocked_id uuid)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_caller  uuid := auth.uid ();
  v_written int  := 0;
begin
  if v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_blocked_id is null then
    raise exception 'blocked user is required' using errcode = '22023';
  end if;
  if p_blocked_id = v_caller then
    raise exception 'you cannot block yourself' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles where id = p_blocked_id) then
    raise exception 'user not found' using errcode = 'P0002';
  end if;

  insert into public.user_blocks (blocker_id, blocked_id)
  values (v_caller, p_blocked_id)
  on conflict (blocker_id, blocked_id) do nothing;

  get diagnostics v_written = row_count;

  if v_written > 0 then
    insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
    values (v_caller, 'moderation.user_blocked', 'profile', p_blocked_id,
            jsonb_build_object ('blocked_id', p_blocked_id));
  end if;

  return jsonb_build_object ('blocked', true, 'blocked_id', p_blocked_id, 'created', v_written > 0);
end;
$$;

revoke execute on function public.block_user (uuid) from public, anon;
grant  execute on function public.block_user (uuid) to authenticated, service_role;

create or replace function public.unblock_user (p_blocked_id uuid)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_caller  uuid := auth.uid ();
  v_deleted int  := 0;
begin
  if v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_blocked_id is null then
    raise exception 'blocked user is required' using errcode = '22023';
  end if;

  delete from public.user_blocks
   where blocker_id = v_caller
     and blocked_id = p_blocked_id;

  get diagnostics v_deleted = row_count;

  if v_deleted > 0 then
    insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
    values (v_caller, 'moderation.user_unblocked', 'profile', p_blocked_id,
            jsonb_build_object ('blocked_id', p_blocked_id));
  end if;

  return jsonb_build_object ('blocked', false, 'blocked_id', p_blocked_id, 'removed', v_deleted > 0);
end;
$$;

revoke execute on function public.unblock_user (uuid) from public, anon;
grant  execute on function public.unblock_user (uuid) to authenticated, service_role;

create or replace function public.list_blocked_users ()
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_caller uuid := auth.uid ();
  v_rows   jsonb;
begin
  if v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'user_id',      b.blocked_id,
               'display_name', p.display_name,
               'avatar_path',  p.avatar_path,
               'blocked_at',   b.created_at)
             order by b.created_at desc),
           '[]'::jsonb)
    into v_rows
    from public.user_blocks b
    left join public.profiles p on p.id = b.blocked_id
   where b.blocker_id = v_caller;

  return jsonb_build_object ('blocked_users', v_rows, 'count', jsonb_array_length (v_rows));
end;
$$;

revoke execute on function public.list_blocked_users () from public, anon;
grant  execute on function public.list_blocked_users () to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 2. report_content (+ auto-hide through the trigger)
-- -----------------------------------------------------------------------------
create or replace function public.report_content (
  p_target_type text,
  p_target_id   uuid,
  p_reason      text,
  p_details     text default null,
  p_group_id    uuid default null
)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_caller     uuid := auth.uid ();
  v_report_id  uuid;
  v_existing   uuid;
  v_group      uuid;
  v_count      int;
  v_auto_hidden boolean := false;
  v_sharing    text;
begin
  if v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_target_type is null
     or p_target_type not in ('post', 'chat_message', 'prayer_intention', 'check_in', 'profile', 'group') then
    raise exception 'invalid target type' using errcode = '22023';
  end if;

  if p_reason is null
     or p_reason not in ('inappropriate_photo', 'inappropriate_text', 'spam', 'harassment', 'hate', 'self_harm', 'other') then
    raise exception 'invalid reason' using errcode = '22023';
  end if;

  if p_target_id is null then
    raise exception 'target is required' using errcode = '22023';
  end if;

  if p_details is not null and char_length (p_details) > 500 then
    raise exception 'details must be 500 characters or fewer' using errcode = '22023';
  end if;

  if not private.report_target_exists (p_target_type, p_target_id) then
    raise exception 'reported content not found' using errcode = 'P0002';
  end if;

  -- Sacred privacy: a private check-in ("Only in My Private Diary") carries no
  -- content at all and is never shared, so it can never be reported.
  if p_target_type = 'check_in' and to_regclass ('public.check_ins') is not null then
    execute format ('select sharing from public.check_ins where id = %L', p_target_id::text) into v_sharing;
    if v_sharing = 'private' then
      raise exception 'this check-in is private and cannot be reported' using errcode = '22023';
    end if;
  end if;

  v_group := private.resolve_report_group (p_target_type, p_target_id, p_group_id);

  if v_group is not null and not public.is_group_member (v_group, v_caller) then
    raise exception 'you can only report content inside your own groups' using errcode = '42501';
  end if;

  -- Idempotent: a client retry must never create a second report for the same
  -- target, and a single user must not be able to trip the auto-hide threshold
  -- on their own.
  select r.id
    into v_existing
    from public.content_reports r
   where r.reporter_id  = v_caller
     and r.target_type  = p_target_type
     and r.target_id    = p_target_id
     and r.status in ('open', 'reviewing')
   order by r.created_at
   limit 1;

  if v_existing is not null then
    select count(*)::int
      into v_count
      from public.content_reports
     where target_type = p_target_type
       and target_id   = p_target_id
       and status in ('open', 'reviewing');

    select exists (
             select 1 from public.moderation_actions
              where action_type = 'auto_hide'
                and target_type = p_target_type
                and target_id   = p_target_id)
      into v_auto_hidden;

    return jsonb_build_object (
      'report_id',    v_existing,
      'auto_hidden',  v_auto_hidden,
      'report_count', v_count,
      'status',       'open',
      'group_id',     v_group,
      'duplicate',    true);
  end if;

  insert into public.content_reports
    (reporter_id, target_type, target_id, group_id, reason, details, status)
  values
    (v_caller, p_target_type, p_target_id, v_group, p_reason, p_details, 'open')
  returning id into v_report_id;

  select count(*)::int
    into v_count
    from public.content_reports
   where target_type = p_target_type
     and target_id   = p_target_id
     and status in ('open', 'reviewing');

  select exists (
           select 1 from public.moderation_actions
            where action_type = 'auto_hide'
              and target_type = p_target_type
              and target_id   = p_target_id)
    into v_auto_hidden;

  return jsonb_build_object (
    'report_id',    v_report_id,
    'auto_hidden',  v_auto_hidden,
    'report_count', v_count,
    'status',       'open',
    'group_id',     v_group,
    'duplicate',    false);
end;
$$;

revoke execute on function public.report_content (text, uuid, text, text, uuid) from public, anon;
grant  execute on function public.report_content (text, uuid, text, text, uuid) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 3. admin_delete_post — delegates to A5's soft_delete_feed_post when present
-- -----------------------------------------------------------------------------
create or replace function public.admin_delete_post (p_post_id uuid)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_caller uuid := auth.uid ();
  v_group  uuid;
  v_hidden boolean := false;
  v_detail jsonb := '{}'::jsonb;
begin
  if v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_post_id is null then
    raise exception 'post is required' using errcode = '22023';
  end if;

  v_group := private.resolve_report_group ('post', p_post_id, null);
  if v_group is null then
    raise exception 'post not found' using errcode = 'P0002';
  end if;
  if not public.is_group_admin (v_group, v_caller) then
    raise exception 'only a group administrator can delete a post' using errcode = '42501';
  end if;

  if to_regprocedure ('public.soft_delete_feed_post(uuid)') is not null then
    execute format ('select public.soft_delete_feed_post(%L)', p_post_id::text) into v_detail;
  else
    v_hidden := private.auto_hide_content ('post', p_post_id, 'admin_removed');
    v_detail := jsonb_build_object ('hidden', v_hidden, 'source', 'a6_fallback');
  end if;

  insert into public.moderation_actions
    (actor_id, action_type, target_type, target_id, group_id, reason, metadata)
  values
    (v_caller, 'delete_post', 'post', p_post_id, v_group, 'removed by group administrator',
     jsonb_build_object ('detail', v_detail));

  insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
  values
    (v_caller, 'moderation.post_deleted', 'post', p_post_id,
     jsonb_build_object ('group_id', v_group, 'detail', v_detail));

  return jsonb_build_object (
    'deleted',  true,
    'post_id',  p_post_id,
    'group_id', v_group,
    'detail',   v_detail);
end;
$$;

revoke execute on function public.admin_delete_post (uuid) from public, anon;
grant  execute on function public.admin_delete_post (uuid) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 4. hide_content — group admin moderation action
-- -----------------------------------------------------------------------------
create or replace function public.hide_content (
  p_target_type text,
  p_target_id   uuid,
  p_reason      text
)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_caller uuid := auth.uid ();
  v_group  uuid;
  v_action text;
  v_hidden boolean := false;
begin
  if v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_target_type is null
     or p_target_type not in ('post', 'chat_message', 'prayer_intention') then
    raise exception 'this content type cannot be hidden' using errcode = '22023';
  end if;
  if p_target_id is null then
    raise exception 'target is required' using errcode = '22023';
  end if;

  v_group := private.resolve_report_group (p_target_type, p_target_id, null);
  if v_group is null then
    raise exception 'content not found' using errcode = 'P0002';
  end if;
  if not public.is_group_admin (v_group, v_caller) then
    raise exception 'only a group administrator can hide content' using errcode = '42501';
  end if;

  v_action := case p_target_type
                when 'post'            then 'hide_post'
                when 'chat_message'    then 'hide_chat_message'
                else 'hide_intention'
              end;

  v_hidden := private.auto_hide_content (p_target_type, p_target_id, 'hidden_by_admin');

  insert into public.moderation_actions
    (actor_id, action_type, target_type, target_id, group_id, reason, metadata)
  values
    (v_caller, v_action, p_target_type, p_target_id, v_group,
     left (coalesce (p_reason, ''), 200),
     jsonb_build_object ('hidden', v_hidden));

  insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
  values
    (v_caller, 'moderation.content_hidden', p_target_type, p_target_id,
     jsonb_build_object ('group_id', v_group, 'reason', p_reason, 'hidden', v_hidden));

  return jsonb_build_object (
    'hidden',      v_hidden,
    'action_type', v_action,
    'target_id',   p_target_id,
    'group_id',    v_group);
end;
$$;

revoke execute on function public.hide_content (text, uuid, text) from public, anon;
grant  execute on function public.hide_content (text, uuid, text) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 5. get_moderation_queue
-- -----------------------------------------------------------------------------
create or replace function public.get_moderation_queue (p_group_id uuid)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_caller uuid := auth.uid ();
  v_service boolean := (coalesce (auth.role (), '') = 'service_role');
  v_reports jsonb;
begin
  if not v_service and v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_group_id is null then
    raise exception 'group is required' using errcode = '22023';
  end if;
  if not v_service and not public.is_group_admin (p_group_id, v_caller) then
    raise exception 'only a group administrator can read the moderation queue' using errcode = '42501';
  end if;

  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'report_id',      r.id,
               'reporter_id',    r.reporter_id,
               'reporter_name',  coalesce (pr.display_name, 'Member'),
               'target_type',    r.target_type,
               'target_id',      r.target_id,
               'target_preview', private.target_preview (r.target_type, r.target_id),
               'reason',         r.reason,
               'details',        r.details,
               'status',         r.status,
               'created_at',     r.created_at,
               'report_count',   (select count(*)::int
                                    from public.content_reports r2
                                   where r2.target_type = r.target_type
                                     and r2.target_id   = r.target_id
                                     and r2.status in ('open', 'reviewing')))
             order by r.created_at),
           '[]'::jsonb)
    into v_reports
    from public.content_reports r
    left join public.profiles pr on pr.id = r.reporter_id
   where r.group_id = p_group_id
     and r.status in ('open', 'reviewing');

  return jsonb_build_object (
    'group_id', p_group_id,
    'reports',  v_reports,
    'count',    jsonb_array_length (v_reports));
end;
$$;

revoke execute on function public.get_moderation_queue (uuid) from public, anon;
grant  execute on function public.get_moderation_queue (uuid) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 6. resolve_report
-- -----------------------------------------------------------------------------
create or replace function public.resolve_report (
  p_report_id uuid,
  p_status    text,
  p_note      text default null
)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_caller  uuid := auth.uid ();
  v_service boolean := (coalesce (auth.role (), '') = 'service_role');
  v_report  public.content_reports%rowtype;
  v_action  text;
begin
  if not v_service and v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_report_id is null then
    raise exception 'report is required' using errcode = '22023';
  end if;
  if p_status is null
     or p_status not in ('open', 'reviewing', 'actioned', 'dismissed') then
    raise exception 'invalid status' using errcode = '22023';
  end if;

  select * into v_report from public.content_reports where id = p_report_id;
  if not found then
    raise exception 'report not found' using errcode = 'P0002';
  end if;

  if not v_service
     and (v_report.group_id is null
          or not public.is_group_admin (v_report.group_id, v_caller)) then
    raise exception 'only a group administrator can resolve this report' using errcode = '42501';
  end if;

  update public.content_reports
     set status      = p_status,
         resolved_at = case when p_status in ('actioned', 'dismissed') then now() else null end,
         resolved_by = case when p_status in ('actioned', 'dismissed') then v_caller else null end
   where id = p_report_id;

  v_action := case p_status
                when 'dismissed' then 'dismiss_report'
                when 'actioned'  then 'action_report'
              end;

  if v_action is not null
     and v_caller is not null
     and exists (select 1 from public.profiles where id = v_caller) then
    insert into public.moderation_actions
      (actor_id, action_type, target_type, target_id, group_id, report_id, reason, metadata)
    values
      (v_caller, v_action, v_report.target_type, v_report.target_id, v_report.group_id, p_report_id,
       left (coalesce (p_note, ''), 200),
       jsonb_build_object ('status', p_status));
  end if;

  insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
  values
    (v_caller, 'moderation.report_resolved', 'content_report', p_report_id,
     jsonb_build_object ('status', p_status, 'target_type', v_report.target_type,
                         'target_id', v_report.target_id, 'note', p_note,
                         'group_id', v_report.group_id));

  return jsonb_build_object (
    'report_id',   p_report_id,
    'status',      p_status,
    'action_type', v_action);
end;
$$;

revoke execute on function public.resolve_report (uuid, text, text) from public, anon;
grant  execute on function public.resolve_report (uuid, text, text) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 7. get_moderation_actions — the audit trail
-- -----------------------------------------------------------------------------
create or replace function public.get_moderation_actions (p_group_id uuid)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_caller  uuid := auth.uid ();
  v_service boolean := (coalesce (auth.role (), '') = 'service_role');
  v_rows    jsonb;
begin
  if not v_service and v_caller is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_group_id is null then
    raise exception 'group is required' using errcode = '22023';
  end if;
  if not v_service and not public.is_group_admin (p_group_id, v_caller) then
    raise exception 'only a group administrator can read the moderation trail' using errcode = '42501';
  end if;

  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'id',           m.id,
               'actor_id',     m.actor_id,
               'actor_name',   coalesce (pa.display_name, 'Member'),
               'action_type',  m.action_type,
               'target_type',  m.target_type,
               'target_id',    m.target_id,
               'group_id',     m.group_id,
               'report_id',    m.report_id,
               'reason',       m.reason,
               'metadata',     m.metadata,
               'created_at',   m.created_at)
             order by m.created_at desc),
           '[]'::jsonb)
    into v_rows
    from public.moderation_actions m
    left join public.profiles pa on pa.id = m.actor_id
   where m.group_id = p_group_id;

  return jsonb_build_object (
    'group_id', p_group_id,
    'actions',  v_rows,
    'count',    jsonb_array_length (v_rows));
end;
$$;

revoke execute on function public.get_moderation_actions (uuid) from public, anon;
grant  execute on function public.get_moderation_actions (uuid) to authenticated, service_role;
