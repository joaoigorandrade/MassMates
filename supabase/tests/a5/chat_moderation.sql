-- =============================================================================
-- A5 · chat_moderation.sql · chat message moderation + A6 cross-agent paths
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
-- Helper — SECURITY INVOKER, so it runs with the CURRENT role and therefore
-- with the current RLS policies. `true` = the statement was ALLOWED.
-- ---------------------------------------------------------------------------
create function pg_temp.try_hide_chat (p_message_id uuid)
  returns boolean
  language plpgsql
as $$
begin
  update public.chat_messages set is_hidden = true where id = p_message_id;
  return true;
exception
  when others then
    return false;
end;
$$;

select plan(41);

-- ===========================================================================
-- A. Objects
-- ===========================================================================
select has_column ('public', 'chat_messages', 'is_hidden', 'chat_messages.is_hidden exists');
select has_column ('public', 'chat_messages', 'hidden_reason', 'chat_messages.hidden_reason exists');
select has_column ('public', 'chat_messages', 'hidden_at', 'chat_messages.hidden_at exists');

select ok (
  (select c.is_nullable = 'NO' and c.column_default = 'false'
     from information_schema.columns c
    where c.table_schema = 'public' and c.table_name = 'chat_messages' and c.column_name = 'is_hidden'),
  'chat_messages.is_hidden is NOT NULL and defaults to false');

select ok (
  (select c.is_nullable = 'YES' and c.column_default is null
     from information_schema.columns c
    where c.table_schema = 'public' and c.table_name = 'chat_messages' and c.column_name = 'hidden_at'),
  'chat_messages.hidden_at has NO default (it is set only by the moderation RPC)');

select ok (
  exists (select 1 from pg_indexes
          where schemaname = 'public' and tablename = 'chat_messages'
            and indexname = 'chat_messages_hidden_idx'
            and indexdef like '%is_hidden%'),
  'chat_messages has the partial index chat_messages_hidden_idx WHERE is_hidden');

select ok (
  (select qual from pg_policies
    where schemaname = 'public' and tablename = 'chat_messages'
      and policyname = 'chat_messages_select_members') like '%is_hidden%',
  'the chat_messages SELECT policy takes is_hidden into account');

select has_function ('public', 'soft_delete_chat_message', 'soft_delete_chat_message() exists');

select ok (not has_function_privilege ('anon', 'public.soft_delete_chat_message (uuid)', 'execute'), 'anon may NOT execute public.soft_delete_chat_message');
select ok (has_function_privilege ('authenticated', 'public.soft_delete_chat_message (uuid)', 'execute'), 'authenticated may execute public.soft_delete_chat_message');
select ok (not has_function_privilege ('anon', 'public.soft_delete_feed_post (uuid)', 'execute'), 'anon may NOT execute public.soft_delete_feed_post (A6 finding, verified)');
select ok (not has_function_privilege ('anon', 'public.hide_content (text, uuid, text)', 'execute'), 'anon may NOT execute A6''s public.hide_content (A6 finding, verified)');

-- ===========================================================================
-- B. Fixture — 4 users, 1 group, 2 chat messages, 1 feed post
-- ===========================================================================
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a5a50000-0000-0000-0000-000000000401', 'a5m_admin@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a5a50000-0000-0000-0000-000000000402', 'a5m_member@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a5a50000-0000-0000-0000-000000000403', 'a5m_outsider@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a5a50000-0000-0000-0000-000000000405', 'a5m_plain@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.groups (id, name, created_by)
values ('a5a50000-0000-0000-0000-000000000501', 'A5 Moderation Group', 'a5a50000-0000-0000-0000-000000000401');

insert into public.group_members (group_id, user_id, role)
values
  ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000401', 'admin'),
  ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'member'),
  ('a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000405', 'member');

insert into public.chat_messages (id, group_id, user_id, body, created_at)
values
  ('a5a50000-0000-0000-0000-000000000201', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'Visible message',   '2026-02-01 18:00:00+00'),
  ('a5a50000-0000-0000-0000-000000000202', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000405', 'Another message',   '2026-02-01 18:05:00+00');

insert into public.feed_posts (id, group_id, user_id, practice_kind, points, created_at)
values ('a5a50000-0000-0000-0000-000000000001', 'a5a50000-0000-0000-0000-000000000501', 'a5a50000-0000-0000-0000-000000000402', 'rosary', 3, '2026-02-01 10:00:00+00');

-- ===========================================================================
-- C. RLS — before hiding
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 1, 'RLS chat_messages: an ordinary member sees a visible message');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 1, 'RLS chat_messages: a group admin sees a visible message');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 0, 'RLS chat_messages: a non-member sees no message');

-- ===========================================================================
-- D. public.soft_delete_chat_message
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select throws_ok (
  $$select public.soft_delete_chat_message ('a5a50000-0000-0000-0000-000000000201')$$,
  '42501',
  'only a group admin can remove a message',
  'soft_delete_chat_message: an ordinary member cannot remove a message');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select is ((public.soft_delete_chat_message ('a5a50000-0000-0000-0000-000000000201') ->> 'hidden'), 'true', 'soft_delete_chat_message: the group admin can remove a message');
select is ((public.soft_delete_chat_message ('a5a50000-0000-0000-0000-000000000201') ->> 'hidden_reason'), 'admin_removed', 'soft_delete_chat_message: the hidden reason is admin_removed');
select is ((public.soft_delete_chat_message ('a5a50000-0000-0000-0000-000000000201') ->> 'changed'), '0', 'soft_delete_chat_message: calling it twice is idempotent (changed = 0)');

select ok ((select is_hidden from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201'), 'soft_delete_chat_message: the row is flagged is_hidden');
select ok ((select hidden_reason from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 'admin_removed', 'soft_delete_chat_message: the row keeps hidden_reason = admin_removed');
select ok ((select hidden_at from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') is not null, 'soft_delete_chat_message: hidden_at is stamped');

select is (
  (select count(*)::text from public.audit_log
    where action = 'chat.message_removed'
      and target_type = 'chat_message'
      and target_id = 'a5a50000-0000-0000-0000-000000000201'),
  '1',
  'soft_delete_chat_message: exactly ONE audit_log row was written');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 0, 'RLS chat_messages: a hidden message is INVISIBLE to an ordinary member');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 1, 'RLS chat_messages: a hidden message stays VISIBLE to the group admin');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000403","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000201') = 0, 'RLS chat_messages: a hidden message is still invisible to a non-member');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok (pg_temp.try_hide_chat ('a5a50000-0000-0000-0000-000000000202'), 'chat_messages: a member cannot write is_hidden directly (no UPDATE policy)');
select ok (not (select is_hidden from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000202'), 'chat_messages: the direct is_hidden write was filtered out by RLS');

-- ===========================================================================
-- E. public.get_chat_messages must not leak hidden messages
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select is (
  (select jsonb_array_length (public.get_chat_messages ('a5a50000-0000-0000-0000-000000000501', null, 30) -> 'items'))::text,
  '1',
  'get_chat_messages: a hidden message is not returned to an ordinary member');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select is (
  (select jsonb_array_length (public.get_chat_messages ('a5a50000-0000-0000-0000-000000000501', null, 30) -> 'items'))::text,
  '2',
  'get_chat_messages: a group admin still receives the hidden message');

-- ===========================================================================
-- F. CROSS-AGENT — A6's public.hide_content('chat_message', …) must ACTUALLY hide
-- ===========================================================================
select is (
  (public.hide_content ('chat_message', 'a5a50000-0000-0000-0000-000000000202', 'test') ->> 'hidden'),
  'true',
  'A6 cross-check: hide_content(''chat_message'', …) reports hidden = true');

select ok ((select is_hidden from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000202'), 'A6 cross-check: hide_content(''chat_message'', …) ACTUALLY sets chat_messages.is_hidden');
select ok ((select hidden_reason from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000202') is null, 'A6 cross-check: A6 sets only is_hidden (hidden_reason stays NULL — it is A5''s RPC that writes it)');
select ok ((select hidden_at from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000202') is null, 'A6 cross-check: A6 sets only is_hidden (hidden_at stays NULL)');

select is (
  (select count(*)::text from public.moderation_actions
    where action_type = 'hide_chat_message'
      and target_type = 'chat_message'
      and target_id = 'a5a50000-0000-0000-0000-000000000202'),
  '1',
  'A6 cross-check: hide_content wrote the moderation_actions trail');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok ((select count(*) from public.chat_messages where id = 'a5a50000-0000-0000-0000-000000000202') = 0, 'A6 cross-check: the message hidden by A6 is invisible to an ordinary member');

-- ===========================================================================
-- G. CROSS-AGENT — A6's public.admin_delete_post still delegates to
--    public.soft_delete_feed_post
-- ===========================================================================
set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000401","role":"authenticated"}';
select is (
  (public.admin_delete_post ('a5a50000-0000-0000-0000-000000000001') ->> 'deleted'),
  'true',
  'A6 cross-check: admin_delete_post still works after the A5 change');

select ok ((select is_hidden from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000001'), 'A6 cross-check: admin_delete_post delegated to soft_delete_feed_post and hid the post');
select ok ((select hidden_reason from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000001') = 'admin_removed', 'A6 cross-check: the feed post keeps hidden_reason = admin_removed');

select is (
  (select count(*)::text from public.moderation_actions
    where action_type = 'delete_post'
      and target_type = 'post'
      and target_id = 'a5a50000-0000-0000-0000-000000000001'),
  '1',
  'A6 cross-check: admin_delete_post wrote the moderation_actions trail');

set local request.jwt.claims = '{"sub":"a5a50000-0000-0000-0000-000000000405","role":"authenticated"}';
select ok ((select count(*) from public.feed_posts where id = 'a5a50000-0000-0000-0000-000000000001') = 0, 'A6 cross-check: the deleted feed post is invisible to an ordinary member');

-- ===========================================================================
-- Verdict
-- ===========================================================================
reset role;
set local request.jwt.claims = '{}';

select * from finish ();
select public.pgtap_summary () as result;

rollback;
