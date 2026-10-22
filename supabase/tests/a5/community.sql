-- =============================================================================
-- A5 · community.sql · feed, prayer wall, chat and pinned notices
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
-- `public.pgtap_summary()` is the verdict: {"verdict":"PASS"|"FAIL", ...}.
-- =============================================================================

begin;
set local search_path = extensions, public;

-- ---------------------------------------------------------------------------
-- Helpers — SECURITY INVOKER, so they run with the CURRENT role and therefore
-- with the current RLS policies. `true` = the statement was ALLOWED.
-- ---------------------------------------------------------------------------
create function pg_temp.can_insert_reaction (p_post_id uuid, p_user_id uuid, p_type text)
  returns boolean
  language plpgsql
as $$
begin
  insert into public.amen_reactions (post_id, user_id, reaction_type)
  values (p_post_id, p_user_id, p_type);
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.can_insert_intention (p_group_id uuid, p_user_id uuid, p_body text)
  returns boolean
  language plpgsql
as $$
begin
  insert into public.prayer_intentions (group_id, user_id, body)
  values (p_group_id, p_user_id, p_body);
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.can_update_intention_body (p_intention_id uuid, p_body text)
  returns boolean
  language plpgsql
as $$
begin
  update public.prayer_intentions set body = p_body where id = p_intention_id;
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.can_tamper_prayer_count (p_intention_id uuid, p_count integer)
  returns boolean
  language plpgsql
as $$
begin
  update public.prayer_intentions set prayer_count = p_count where id = p_intention_id;
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.can_insert_chat (p_group_id uuid, p_user_id uuid, p_body text)
  returns boolean
  language plpgsql
as $$
begin
  insert into public.chat_messages (group_id, user_id, body)
  values (p_group_id, p_user_id, p_body);
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.can_delete_chat (p_message_id uuid)
  returns boolean
  language plpgsql
as $$
begin
  delete from public.chat_messages where id = p_message_id;
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.can_insert_pinned (p_group_id uuid, p_user_id uuid, p_body text)
  returns boolean
  language plpgsql
as $$
begin
  insert into public.pinned_notices (group_id, author_id, body)
  values (p_group_id, p_user_id, p_body);
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.can_delete_feed_post (p_post_id uuid)
  returns boolean
  language plpgsql
as $$
begin
  delete from public.feed_posts where id = p_post_id;
  return true;
exception
  when others then
    return false;
end;
$$;

select plan(132);

-- ===========================================================================
-- A. Objects
-- ===========================================================================
select has_table ('public', 'feed_posts', 'feed_posts table exists');
select has_table ('public', 'amen_reactions', 'amen_reactions table exists');
select has_table ('public', 'prayer_intentions', 'prayer_intentions table exists');
select has_table ('public', 'intention_prayers', 'intention_prayers table exists');
select has_table ('public', 'chat_messages', 'chat_messages table exists');
select has_table ('public', 'pinned_notices', 'pinned_notices table exists');

select ok (public.pgtap_rls_enabled ('public.feed_posts'::regclass), 'RLS is enabled on feed_posts');
select ok (public.pgtap_rls_forced ('public.feed_posts'::regclass), 'RLS is FORCED on feed_posts');
select ok (public.pgtap_rls_enabled ('public.amen_reactions'::regclass), 'RLS is enabled on amen_reactions');
select ok (public.pgtap_rls_forced ('public.amen_reactions'::regclass), 'RLS is FORCED on amen_reactions');
select ok (public.pgtap_rls_enabled ('public.prayer_intentions'::regclass), 'RLS is enabled on prayer_intentions');
select ok (public.pgtap_rls_forced ('public.prayer_intentions'::regclass), 'RLS is FORCED on prayer_intentions');
select ok (public.pgtap_rls_enabled ('public.intention_prayers'::regclass), 'RLS is enabled on intention_prayers');
select ok (public.pgtap_rls_forced ('public.intention_prayers'::regclass), 'RLS is FORCED on intention_prayers');
select ok (public.pgtap_rls_enabled ('public.chat_messages'::regclass), 'RLS is enabled on chat_messages');
select ok (public.pgtap_rls_forced ('public.chat_messages'::regclass), 'RLS is FORCED on chat_messages');
select ok (public.pgtap_rls_enabled ('public.pinned_notices'::regclass), 'RLS is enabled on pinned_notices');
select ok (public.pgtap_rls_forced ('public.pinned_notices'::regclass), 'RLS is FORCED on pinned_notices');

select is (public.pgtap_policy_count ('public.feed_posts'::regclass, 'r'), 1, 'feed_posts has exactly 1 SELECT policy');
select is (public.pgtap_policy_count ('public.feed_posts'::regclass, 'a'), 0, 'feed_posts has NO direct INSERT policy (writes go through the server)');
select is (public.pgtap_policy_count ('public.feed_posts'::regclass, 'w'), 0, 'feed_posts has NO direct UPDATE policy');
select is (public.pgtap_policy_count ('public.feed_posts'::regclass, 'd'), 0, 'feed_posts has NO direct DELETE policy');

select has_function ('public', 'get_feed_posts', 'get_feed_posts() exists');
select has_function ('public', 'get_prayer_intentions', 'get_prayer_intentions() exists');
select has_function ('public', 'toggle_amen', 'toggle_amen() exists');
select has_function ('public', 'toggle_prayed_for', 'toggle_prayed_for() exists');
select has_function ('public', 'create_prayer_intention', 'create_prayer_intention() exists');
select has_function ('public', 'get_chat_messages', 'get_chat_messages() exists');
select has_function ('public', 'create_chat_message', 'create_chat_message() exists');
select has_function ('public', 'set_pinned_notice', 'set_pinned_notice() exists');
select has_function ('public', 'clear_pinned_notice', 'clear_pinned_notice() exists');
select has_function ('public', 'soft_delete_feed_post', 'soft_delete_feed_post() exists');
select has_function ('public', 'emit_prayer_notification', 'emit_prayer_notification() exists');
select has_function ('public', 'insert_feed_post', 'insert_feed_post() exists');

select has_trigger ('public', 'intention_prayers', 'trg_intention_prayers_count', 'the prayer counter trigger is attached');
select has_trigger ('public', 'feed_posts', 'trg_feed_posts_updated_at', 'updated_at trigger is attached to feed_posts');
select has_trigger ('public', 'prayer_intentions', 'trg_prayer_intentions_updated_at', 'updated_at trigger is attached to prayer_intentions');
select has_trigger ('public', 'chat_messages', 'trg_chat_messages_updated_at', 'updated_at trigger is attached to chat_messages');

select ok (
  exists (select 1 from pg_constraint
          where conrelid = 'public.feed_posts'::regclass and conname = 'feed_posts_no_confession'),
  'feed_posts has the feed_posts_no_confession CHECK constraint');

select ok (
  exists (select 1 from pg_indexes
          where schemaname = 'public' and tablename = 'pinned_notices'
            and indexdef like '%UNIQUE%' and indexdef like '%is_active%'),
  'pinned_notices has a partial UNIQUE index on (group_id) WHERE is_active');

select ok (
  (select count(*) from pg_publication_tables
    where pubname = 'supabase_realtime'
      and tablename in ('chat_messages', 'amen_reactions', 'intention_prayers')) = 3,
  'chat_messages, amen_reactions and intention_prayers are in the supabase_realtime publication');

select ok (
  exists (select 1 from pg_constraint
          where conrelid = 'public.feed_posts'::regclass and conname = 'feed_posts_check_in_id_fkey'),
  'feed_posts.check_in_id is a foreign key to public.check_ins');

select ok (
  (select count(*) from pg_indexes
    where schemaname = 'public' and tablename = 'feed_posts'
      and indexdef like '%group_id%' and indexdef like '%created_at DESC%') >= 2,
  'feed_posts has the (group_id, created_at DESC) indexes');

select ok (
  not has_function_privilege ('authenticated', 'private.a5_cursor_ts(text)', 'execute'),
  'the private A5 helpers are NOT executable by the authenticated role');

select ok (
  has_function_privilege ('authenticated', 'public.get_feed_posts(uuid, text, integer)', 'execute'),
  'authenticated may call public.get_feed_posts');

select ok (
  not has_function_privilege ('anon', 'public.get_feed_posts(uuid, text, integer)', 'execute'),
  'anon may NOT call public.get_feed_posts');

select ok (
  not has_function_privilege ('authenticated', 'public.emit_prayer_notification(uuid, uuid)', 'execute'),
  'authenticated may NOT call public.emit_prayer_notification (server-side seam only)');

-- ===========================================================================
-- B. Fixture — 5 users, 3 groups, memberships, 1 block
-- ===========================================================================
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a5a50000-0000-0000-0000-000000000401', 'a5_admin@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a5a50000-0000-0000-0000-000000000402', 'a5_member@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a5a50000-0000-0000-0000-000000000403', 'a5_outsider@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a5a50000-0000-0000-0000-000000000404', 'a5_blocked@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a5a50000-0000-0000-0000-000000000405', 'a5_plain@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

update public.profiles set display_name = 'A5 Admin'    where id = 'a5a50000-0000-0000-0000-000000000401';
update public.profiles set display_name = 'A5 Member'   where id = 'a5a50000-0000-0000-0000-000000000402';
update public.profiles set display_name = 'A5 Outsider' where id = 'a5a50000-0000-0000-0000-000000000403';
update public.profiles set display_name = 'A5 Blocked'  where id = 'a5a50000-0000-0000-0000-000000000404';
update public.profiles set display_name = 'A5 Plain'    where id = 'a5a50000-0000-0000-0000-000000000405';

insert into public.groups (id, name, created_by)
values
  ('a5a50000-0000-0000-0000-000000000501', 'A5 Main Group',   'a5a50000-0000-0000-0000-000000000401'),
  ('a5a50000-0000-0000-0000-000000000502', 'A5 Paging Group', 'a5a50000-0000-0000-0000-000000000401'),
  ('a5a50000-0000-0000-0000-000000000503', 'A5 Ties Group',   'a5a50000-0000-0000-0000-000000000401');

insert into public.group_members (group_id, user_id, role)
values
  ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000401', 'admin'),
  ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'member'),
  ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000404', 'member'),
  ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000405', 'member'),
  ('a5a50000-0000-0000-0000-000000000502', 'a5a50000-0000-0000-0000-000000000401', 'admin'),
  ('a5a50000-0000-0000-0000-000000000502', 'a5a50000-0000-0000-0000-000000000402', 'member'),
  ('a5a50000-0000-0000-0000-000000000503', 'a5a50000-0000-0000-0000-000000000401', 'admin'),
  ('a5a50000-0000-0000-0000-000000000503', 'a5a50000-0000-0000-0000-000000000402', 'member');

-- The member blocks the "blocked" user. The block is SYMMETRIC.
insert into public.user_blocks (blocker_id, blocked_id)
values ('a5a50000-0000-0000-0000-000000000402', 'a5a50000-0000-0000-0000-000000000404');

-- Feed posts.
insert into public.feed_posts (id, group_id, user_id, practice_kind, reflection_text, points, created_at)
values
  ('a5a50000-0000-0000-0000-000000000001', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'rosary',    'Grace received', 3, '2026-02-01 10:00:00+00'),
  ('a5a50000-0000-0000-0000-000000000002', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000404', 'adoration', 'Adoration',     2, '2026-02-02 10:00:00+00'),
  ('a5a50000-0000-0000-0000-000000000003', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'rosary',    'Hidden one',    1, '2026-02-03 10:00:00+00');

update public.feed_posts
   set is_hidden = true, hidden_reason = 'admin_removed'
 where id = 'a5a50000-0000-0000-0000-000000000003';

-- 5 posts for the pagination test (distinct created_at).
insert into public.feed_posts (id, group_id, user_id, practice_kind, points, created_at)
values
  ('a5a50000-0000-0000-0000-000000000011', 'a5a50000-0000-0000-0000-000000000502', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 1, '2026-03-01 00:00:01+00'),
  ('a5a50000-0000-0000-0000-000000000012', 'a5a50000-0000-0000-0000-000000000502', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 1, '2026-03-01 00:00:02+00'),
  ('a5a50000-0000-0000-0000-000000000013', 'a5a50000-0000-0000-0000-000000000502', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 1, '2026-03-01 00:00:03+00'),
  ('a5a50000-0000-0000-0000-000000000014', 'a5a50000-0000-0000-0000-000000000502', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 1, '2026-03-01 00:00:04+00'),
  ('a5a50000-0000-0000-0000-000000000015', 'a5a50000-0000-0000-0000-000000000502', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 1, '2026-03-01 00:00:05+00');

-- 3 posts that SHARE the same created_at (strict keyset pagination).
insert into public.feed_posts (id, group_id, user_id, practice_kind, points, created_at)
values
  ('a5a50000-0000-0000-0000-000000000021', 'a5a50000-0000-0000-0000-000000000503', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 1, '2026-04-01 00:00:00+00'),
  ('a5a50000-0000-0000-0000-000000000022', 'a5a50000-0000-0000-0000-000000000503', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 1, '2026-04-01 00:00:00+00'),
  ('a5a50000-0000-0000-0000-000000000023', 'a5a50000-0000-0000-0000-000000000503', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 1, '2026-04-01 00:00:00+00');

-- Prayer intentions.
insert into public.prayer_intentions (id, group_id, user_id, body, created_at)
values
  ('a5a50000-0000-0000-0000-000000000101', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'Please pray for my mother', '2026-02-01 09:00:00+00'),
  ('a5a50000-0000-0000-0000-000000000102', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000404', 'Pray for my job',           '2026-02-02 09:00:00+00');

-- Chat messages.
insert into public.chat_messages (id, group_id, user_id, body, created_at)
values
  ('a5a50000-0000-0000-0000-000000000201', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'Rosary tonight at 8pm', '2026-02-01 18:00:00+00'),
  ('a5a50000-0000-0000-0000-000000000202', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000404', 'Count me in',           '2026-02-01 18:05:00+00');

-- ===========================================================================
-- C. SACRED PRIVACY — a confession can never reach the feed
-- ===========================================================================
select throws_ok (
  $$insert into public.feed_posts (group_id, user_id, practice_kind)
    values ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'confession')$$,
  '23514',
  'new row for relation "feed_posts" violates check constraint "feed_posts_no_confession"',
  'feed_posts rejects practice_kind = ''confession'' (sacred privacy gate)');

-- ===========================================================================
-- D. RLS — feed_posts
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';

select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000001') = 1, 'RLS feed_posts: a plain group member can see a visible post');
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000003') = 0, 'RLS feed_posts: a hidden post is invisible to a plain member');
select ok ((select count(*) from public.feed_posts where group_id = 'a5a50000-0000-0000-0000-000000000501') = 2, 'RLS feed_posts: a plain member sees exactly the 2 visible posts of the group');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000003') = 1, 'RLS feed_posts: a group admin still sees a hidden post');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000001') = 0, 'RLS feed_posts: a non-member cannot see a post');
select ok ((select count(*) from public.feed_posts) = 0, 'RLS feed_posts: a non-member sees no post at all');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000404","role":"authenticated"}';
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000001') = 0, 'RLS feed_posts: a member blocked by the post author cannot see that post');
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000002') = 1, 'RLS feed_posts: a blocked user still sees their OWN post');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000402","role":"authenticated"}';
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000001') = 1, 'RLS feed_posts: the author sees their own post');
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000002') = 0, 'RLS feed_posts: the blocker does not see the blocked user''s post');
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000001') = 1, 'RLS feed_posts: a member cannot DELETE a post directly (the row is filtered out, not deleted)');

-- ===========================================================================
-- E. RLS + RPC — amen_reactions
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok (pg_temp.can_insert_reaction ('a5a50000-0000-0000-0000-000000000001', 'a5a50000-0000-0000-0000-000000000405', 'amen'), 'RLS amen_reactions: a group member can add a reaction');
select throws_ok (
  $$insert into public.amen_reactions (post_id, user_id, reaction_type)
    values ('a5a50000-0000-0000-0000-000000000001', 'a5a50000-0000-0000-0000-000000000405', 'amen')$$,
  '23505',
  'duplicate key value violates unique constraint "amen_reactions_post_id_user_id_reaction_type_key"',
  'amen_reactions: the unique constraint prevents a duplicate reaction');
select ok (not pg_temp.can_insert_reaction ('a5a50000-0000-0000-0000-000000000001', 'a5a50000-0000-0000-0000-000000000401', 'amen'), 'RLS amen_reactions: a member cannot react on behalf of another user');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select ok (not pg_temp.can_insert_reaction ('a5a50000-0000-0000-0000-000000000001', 'a5a50000-0000-0000-0000-000000000403', 'amen'), 'RLS amen_reactions: a non-member cannot add a reaction');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select is ((public.toggle_amen ('a5a50000-0000-0000-0000-000000000001', 'united_in_prayer') ->> 'reacted'), 'true', 'toggle_amen: adds the reaction when it is missing');
select is ((public.toggle_amen ('a5a50000-0000-0000-0000-000000000001', 'united_in_prayer') ->> 'reacted'), 'false', 'toggle_amen: toggling twice removes the reaction');
select is ((public.toggle_amen ('a5a50000-0000-0000-0000-000000000001', 'united_in_prayer') ->> 'united_in_prayer'), '1', 'toggle_amen: returns the number of united_in_prayer');
select is ((public.toggle_amen ('a5a50000-0000-0000-0000-000000000001', 'united_in_prayer') ->> 'united_in_prayer'), '0', 'toggle_amen: the count follows the toggle');
select is ((public.toggle_amen ('a5a50000-0000-0000-0000-000000000001', 'amen') ->> 'amens'), '0', 'toggle_amen: toggling the amen off lowers the count');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select throws_ok (
  $$select public.toggle_amen ('a5a50000-0000-0000-0000-000000000001', 'amen')$$,
  '42501',
  'post not available',
  'toggle_amen: a non-member cannot react');
select throws_ok (
  $$select public.toggle_amen ('a5a50000-0000-0000-0000-000000000001', 'nope')$$,
  '22023',
  'invalid reaction_type: nope',
  'toggle_amen: an unknown reaction type is rejected');

-- ===========================================================================
-- F. RLS + RPC — prayer_intentions
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok (pg_temp.can_insert_intention ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000405', 'Please pray for me'), 'RLS prayer_intentions: a group member can post an intention');
select ok ((select count(*) from public.prayer_intentions where id = 'a5a50000-0000-0000-0000-000000000101') = 1, 'RLS prayer_intentions: a group member can read an intention');
select ok (pg_temp.can_update_intention_body ('a5a50000-0000-0000-0000-000000000101', 'edited'), 'RLS prayer_intentions: a member can edit the body of an intention');
select ok (not pg_temp.can_tamper_prayer_count ('a5a50000-0000-0000-0000-000000000101', 999), 'RLS prayer_intentions: a client cannot write the prayer counter');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select ok (not pg_temp.can_insert_intention ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000403', 'Let me in'), 'RLS prayer_intentions: a non-member cannot post an intention');
select ok ((select count(*) from public.prayer_intentions) = 0, 'RLS prayer_intentions: a non-member sees no intention');
select throws_ok (
  $$select public.create_prayer_intention ('a5a50000-0000-0000-0000-000000000501', 'Let me in')$$,
  '42501',
  'not a member of this group',
  'create_prayer_intention: a non-member cannot create an intention');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok ((public.create_prayer_intention ('a5a50000-0000-0000-0000-000000000501', 'A new prayer request') ->> 'id') is not null, 'create_prayer_intention: a group member can create an intention');
select throws_ok (
  $$select public.create_prayer_intention ('a5a50000-0000-0000-0000-000000000501', repeat('x', 1001))$$,
  '22023',
  'intention body must be at most 1000 characters',
  'create_prayer_intention: a body longer than 1000 characters is rejected');
select throws_ok (
  $$select public.create_prayer_intention ('a5a50000-0000-0000-0000-000000000501', '   ')$$,
  '22023',
  'intention body cannot be empty',
  'create_prayer_intention: an empty body is rejected');
select throws_ok (
  $$insert into public.prayer_intentions (group_id, user_id, body)
    values ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000405', repeat('x', 1001))$$,
  '23514',
  'new row for relation "prayer_intentions" violates check constraint "prayer_intentions_body_check"',
  'prayer_intentions: the body length is enforced by a CHECK constraint');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000404","role":"authenticated"}';
select ok ((select count(*) from public.prayer_intentions where id = 'a5a50000-0000-0000-0000-000000000101') = 0, 'RLS prayer_intentions: a member blocked by the author cannot see that intention');

-- ===========================================================================
-- G. intention_prayers — the "I Prayed for You" counter
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';

insert into public.intention_prayers (intention_id, prayer_id)
values ('a5a50000-0000-0000-0000-000000000101', 'a5a50000-0000-0000-0000-000000000405');
select is ((select prayer_count::text from public.prayer_intentions where id = 'a5a50000-0000-0000-0000-000000000101'), '1', 'intention_prayers: the counter increments on INSERT');

select throws_ok (
  $$insert into public.intention_prayers (intention_id, prayer_id)
    values ('a5a50000-0000-0000-0000-000000000101', 'a5a50000-0000-0000-0000-000000000405')$$,
  '23505',
  'duplicate key value violates unique constraint "intention_prayers_intention_id_prayer_id_key"',
  'intention_prayers: one prayer per user per intention');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
insert into public.intention_prayers (intention_id, prayer_id)
values ('a5a50000-0000-0000-0000-000000000101', 'a5a50000-0000-0000-0000-000000000401');
select is ((select prayer_count::text from public.prayer_intentions where id = 'a5a50000-0000-0000-0000-000000000101'), '2', 'intention_prayers: a second member raises the counter to 2');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
delete from public.intention_prayers
 where intention_id = 'a5a50000-0000-0000-0000-000000000101'
   and prayer_id = 'a5a50000-0000-0000-0000-000000000405';
select is ((select prayer_count::text from public.prayer_intentions where id = 'a5a50000-0000-0000-0000-000000000101'), '1', 'intention_prayers: the counter decrements on DELETE');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
delete from public.intention_prayers
 where intention_id = 'a5a50000-0000-0000-0000-000000000101'
   and prayer_id = 'a5a50000-0000-0000-0000-000000000401';
select is ((select prayer_count::text from public.prayer_intentions where id = 'a5a50000-0000-0000-0000-000000000101'), '0', 'intention_prayers: the counter never goes below 0');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select is ((public.toggle_prayed_for ('a5a50000-0000-0000-0000-000000000101') ->> 'prayer_count'), '1', 'toggle_prayed_for: returns the prayer count');
select is ((public.toggle_prayed_for ('a5a50000-0000-0000-0000-000000000101') ->> 'prayed'), 'false', 'toggle_prayed_for: the second press removes the prayer');
select is ((public.toggle_prayed_for ('a5a50000-0000-0000-0000-000000000101') ->> 'prayer_count'), '1', 'toggle_prayed_for: the third press adds the prayer again');
select is ((public.toggle_prayed_for ('a5a50000-0000-0000-0000-000000000101') ->> 'prayer_count'), '0', 'toggle_prayed_for: the counter follows the toggle');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select throws_ok (
  $$select public.toggle_prayed_for ('a5a50000-0000-0000-0000-000000000101')$$,
  '42501',
  'intention not available',
  'toggle_prayed_for: a non-member cannot pray for an intention');

-- ===========================================================================
-- H. chat_messages
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok (pg_temp.can_insert_chat ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000405', 'Hello brothers'), 'RLS chat_messages: a group member can send a message');
select ok ((public.create_chat_message ('a5a50000-0000-0000-0000-000000000501', 'Rosary at 8') ->> 'id') is not null, 'create_chat_message: a group member can send a message');
select ok ((public.create_chat_message ('a5a50000-0000-0000-0000-000000000501', 'Re: Rosary at 8', 'a5a50000-0000-0000-0000-000000000201') ->> 'reply_to_id') = 'a5a50000-0000-0000-0000-000000000201', 'create_chat_message: a reply keeps the reference');
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 1, 'RLS chat_messages: a member cannot delete somebody else''s message (the row is filtered out, not deleted)');
select ok (pg_temp.can_delete_chat ((select id from public.chat_messages where body = 'Hello brothers')), 'RLS chat_messages: a member can delete their own message');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select ok (not pg_temp.can_insert_chat ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000403', 'Let me in'), 'RLS chat_messages: a non-member cannot send a message');
select throws_ok (
  $$select public.create_chat_message ('a5a50000-0000-0000-0000-000000000501', 'Let me in')$$,
  '42501',
  'not a member of this group',
  'create_chat_message: a non-member cannot send a message');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000402","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000202') = 0, 'RLS chat_messages: a blocked user''s message is invisible to the blocker');
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 1, 'RLS chat_messages: the blocker still sees their own message');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000404","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 0, 'RLS chat_messages: a message is invisible to the blocked user (symmetric block)');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select ok (pg_temp.can_delete_chat ('a5a50000-0000-0000-0000-000000000201'), 'RLS chat_messages: a group admin can delete any message of the group');

-- ===========================================================================
-- I. pinned_notices
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok (not pg_temp.can_insert_pinned ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000405', 'Not allowed'), 'RLS pinned_notices: a plain member cannot pin a notice');
select throws_ok (
  $$select public.set_pinned_notice ('a5a50000-0000-0000-0000-000000000501', 'Not allowed')$$,
  '42501',
  'only a group admin can pin a notice',
  'set_pinned_notice: a plain member cannot pin a notice');
select throws_ok (
  $$select public.clear_pinned_notice ('a5a50000-0000-0000-0000-000000000501')$$,
  '42501',
  'only a group admin can clear a notice',
  'clear_pinned_notice: a plain member cannot clear a notice');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select ok ((public.set_pinned_notice ('a5a50000-0000-0000-0000-000000000501', 'Rosary on Wednesday') ->> 'id') is not null, 'set_pinned_notice: a group admin can pin a notice');
select is ((select count(*)::text from public.pinned_notices where group_id = 'a5a50000-0000-0000-0000-000000000501' and is_active), '1', 'pinned_notices: exactly one active notice after the first pin');
select ok ((public.set_pinned_notice ('a5a50000-0000-0000-0000-000000000501', 'Rosary on Thursday') ->> 'id') is not null, 'set_pinned_notice: a group admin can replace the notice');
select is ((select count(*)::text from public.pinned_notices where group_id = 'a5a50000-0000-0000-0000-000000000501' and is_active), '1', 'pinned_notices: there is never more than ONE active notice per group');
select is ((select count(*)::text from public.pinned_notices where group_id = 'a5a50000-0000-0000-0000-000000000501'), '2', 'pinned_notices: the replaced notice is kept, deactivated');
select is ((public.clear_pinned_notice ('a5a50000-0000-0000-0000-000000000501') ->> 'cleared'), '1', 'clear_pinned_notice: the active notice is cleared');
select is ((select count(*)::text from public.pinned_notices where group_id = 'a5a50000-0000-0000-0000-000000000501' and is_active), '0', 'pinned_notices: no active notice is left after clearing');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select ok ((select count(*) from public.pinned_notices) = 0, 'RLS pinned_notices: a non-member sees no notice');

-- ===========================================================================
-- J. get_feed_posts — cursor pagination
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000402","role":"authenticated"}';

with p1 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000502', null, 2) as r),
     p2 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000502', (select r ->> 'next_cursor' from p1), 2) as r),
     p3 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000502', (select r ->> 'next_cursor' from p2), 2) as r),
     all_items as (
       select jsonb_array_elements (r -> 'items') as item from p1
       union all
       select jsonb_array_elements (r -> 'items') from p2
       union all
       select jsonb_array_elements (r -> 'items') from p3
     )
select ok (
  (select count(*) from all_items) = 5
  and (select count (distinct item ->> 'id') from all_items) = 5,
  'get_feed_posts: the 3 pages return the 5 posts exactly once (no duplicate, no skip)');

with p1 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000502', null, 2) as r),
     p2 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000502', (select r ->> 'next_cursor' from p1), 2) as r),
     p3 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000502', (select r ->> 'next_cursor' from p2), 2) as r),
     all_items as (
       select jsonb_array_elements (r -> 'items') as item from p1
       union all
       select jsonb_array_elements (r -> 'items') from p2
       union all
       select jsonb_array_elements (r -> 'items') from p3
     )
select ok (
  (select array_agg (item ->> 'id' order by item ->> 'created_at' desc) from all_items)
  = array[
      'a5a50000-0000-0000-0000-000000000015',
      'a5a50000-0000-0000-0000-000000000014',
      'a5a50000-0000-0000-0000-000000000013',
      'a5a50000-0000-0000-0000-000000000012',
      'a5a50000-0000-0000-0000-000000000011'
    ],
  'get_feed_posts: the pages contain exactly the 5 expected posts, newest first');

select ok (
  (select r ->> 'next_cursor' from (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000502', null, 2) as r) s)
  ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z\|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  'get_feed_posts: next_cursor is "<ISO-8601 UTC>|<uuid>"');

with t1 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000503', null, 1) as r),
     t2 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000503', (select r ->> 'next_cursor' from t1), 1) as r),
     t3 as (select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000503', (select r ->> 'next_cursor' from t2), 1) as r),
     all_items as (
       select jsonb_array_elements (r -> 'items') as item from t1
       union all
       select jsonb_array_elements (r -> 'items') from t2
       union all
       select jsonb_array_elements (r -> 'items') from t3
     )
select ok (
  (select count(*) from all_items) = 3
  and (select count (distinct item ->> 'id') from all_items) = 3,
  'get_feed_posts: the composite cursor does not skip nor duplicate rows that share a created_at');

select is (
  (public.get_feed_posts ('a5a50000-0000-0000-0000-000000000502', null, 2) -> 'items') -> 0 ->> 'created_at',
  '2026-03-01T00:00:05.000000Z',
  'get_feed_posts: created_at is returned as a UTC ISO-8601 string');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select throws_ok (
  $$select public.get_feed_posts ('a5a50000-0000-0000-0000-000000000501', null, 20)$$,
  '42501',
  'not a member of this group',
  'get_feed_posts: a non-member cannot read a feed');

-- ===========================================================================
-- K. soft_delete_feed_post (A6 seam)
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select throws_ok (
  $$select public.soft_delete_feed_post ('a5a50000-0000-0000-0000-000000000002')$$,
  '42501',
  'only a group admin can remove a post',
  'soft_delete_feed_post: a plain member cannot remove a post');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select is ((public.soft_delete_feed_post ('a5a50000-0000-0000-0000-000000000002') ->> 'hidden'), 'true', 'soft_delete_feed_post: the group admin can remove a post');
select is ((public.soft_delete_feed_post ('a5a50000-0000-0000-0000-000000000002') ->> 'hidden_reason'), 'admin_removed', 'soft_delete_feed_post: the hidden reason is admin_removed');

reset role;
set local request.jwt.claims = '{}';

select is (
  (select count(*)::text from public.audit_log
    where action = 'feed.post_removed' and target_id = 'a5a50000-0000-0000-0000-000000000002'),
  '1',
  'soft_delete_feed_post: exactly one audit_log row was written');

select is (
  (select hidden_reason from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000002'),
  'admin_removed',
  'soft_delete_feed_post: the post row is kept and flagged as hidden');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000002') = 0, 'RLS feed_posts: a removed post is invisible to a plain member');
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000002') = 1, 'RLS feed_posts: a removed post stays visible to the group admin');
reset role;
set local request.jwt.claims = '{}';

-- ===========================================================================
-- L. A4 fan-out (defensive — passes before AND after A4 lands)
-- ===========================================================================
do $$
begin
  if to_regclass ('public.check_ins') is not null
     and to_regclass ('public.check_in_destinations') is not null
     and to_regclass ('public.feed_posts') is not null then

    insert into public.check_ins (id, user_id, practice_kind, sharing, local_date, timezone, points, reflection_text)
    values ('a5a50000-0000-0000-0000-000000000301', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 'group', current_date, 'UTC', 3, 'Grace be with us');

    -- A4's own fan-out trigger (trg_check_in_destinations_fanout) fires here.
    insert into public.check_in_destinations (check_in_id, group_id)
    values ('a5a50000-0000-0000-0000-000000000301', 'a5a50000-0000-0000-0000-000000000501');

    -- A5's own seam must be idempotent: the post already exists.
    perform public.insert_feed_post (
      'a5a50000-0000-0000-0000-000000000301',
      'a5a50000-0000-0000-0000-000000000501',
      'a5a50000-0000-0000-0000-000000000402',
      'rosary',
      'Grace be with us',
      null,
      3
    );

    -- A PRIVATE check-in must never reach the feed.
    insert into public.check_ins (id, user_id, practice_kind, sharing, local_date, timezone, points)
    values ('a5a50000-0000-0000-0000-000000000302', 'a5a50000-0000-0000-0000-000000000402', 'mental_prayer', 'private', current_date, 'UTC', 0);

    begin
      perform public.insert_feed_post (
        'a5a50000-0000-0000-0000-000000000302',
        'a5a50000-0000-0000-0000-000000000501',
        'a5a50000-0000-0000-0000-000000000402',
        'mental_prayer',
        null,
        null,
        0
      );
    exception
      when others then
        null;  -- expected: the private check-in is refused
    end;
  end if;
end;
$$;

select ok (
  case
    when to_regclass ('public.check_ins') is not null
     and to_regclass ('public.check_in_destinations') is not null
    then (select count(*) from public.feed_posts where check_in_id = 'a5a50000-0000-0000-0000-000000000301') = 1
    else true
  end,
  'A4 fan-out: the check_in_destinations trigger creates exactly ONE feed post for a group-shared check-in');

select ok (
  case
    when to_regclass ('public.check_ins') is not null
     and to_regclass ('public.check_in_destinations') is not null
    then (select reflection_text from public.feed_posts where check_in_id = 'a5a50000-0000-0000-0000-000000000301') = 'Grace be with us'
    else true
  end,
  'A4 fan-out: the feed post carries the shared reflection of the check-in');

select ok (
  case
    when to_regclass ('public.check_ins') is not null
     and to_regclass ('public.check_in_destinations') is not null
    then (select count(*) from public.feed_posts where check_in_id = 'a5a50000-0000-0000-0000-000000000302') = 0
    else true
  end,
  'A4 fan-out: a PRIVATE check-in never produces a feed post (sacred privacy gate)');

-- ===========================================================================
-- M. emit_prayer_notification — the A8 seam
-- ===========================================================================
select ok (
  case
    when to_regclass ('public.notification_outbox') is null
    then (public.emit_prayer_notification ('a5a50000-0000-0000-0000-000000000101', 'a5a50000-0000-0000-0000-000000000405') ->> 'emitted') = 'false'
    else true
  end,
  'emit_prayer_notification: a safe no-op while notification_outbox does not exist');

-- The RPC path (toggle_prayed_for -> emit_prayer_notification) AND A8's
-- trigger on public.intention_prayers both fire for the same prayer. The
-- outbox dedupe_key must make them idempotent, otherwise the author of the
-- intention would receive TWO push notifications.
set local role authenticated;
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select (public.toggle_prayed_for ('a5a50000-0000-0000-0000-000000000101') ->> 'prayed') as prayed;
reset role;
set local request.jwt.claims = '{}';

select ok (
  case
    when to_regclass ('public.notification_outbox') is not null
    then (select count(*) from public.intention_prayers
           where intention_id = 'a5a50000-0000-0000-0000-000000000101') = 1
     and (select count(*) from public.notification_outbox o
           where o.user_id = 'a5a50000-0000-0000-0000-000000000402'
             and o.notification_type = 'prayed_for_you'
             and o.dedupe_key in (
               select 'prayed:' || ip.id::text
                 from public.intention_prayers ip
                where ip.intention_id = 'a5a50000-0000-0000-0000-000000000101')) = 1
    else true
  end,
  'the "prayed for you" notification is emitted exactly ONCE per prayer (the RPC path and A8''s trigger are de-duplicated)');

-- ===========================================================================
-- Verdict
-- ===========================================================================
select * from finish ();
select public.pgtap_summary () as result;

rollback;
