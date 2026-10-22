-- =============================================================================
-- A8 · push.sql · device tokens, notification outbox, emission triggers
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
--
-- Fixture ids
--   p1 Paulo  a8b80000-0000-0000-0000-000000000001   (blocked p4)
--   p2 Ana    a8b80000-0000-0000-0000-000000000002
--   p3 Bia    a8b80000-0000-0000-0000-000000000003
--   p4 Raul  a8b80000-0000-0000-0000-000000000004   (blocked by p1)
--   GRP a8b80000-0000-0000-0000-000000000501
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(55);

create function pg_temp.can_insert_outbox ()
  returns boolean
  language plpgsql
as $$
begin
  insert into public.notification_outbox (user_id, notification_type, title, body, dedupe_key)
  values ('a8b80000-0000-0000-0000-000000000001', 'amen', 't', 'b', 'pg_temp_probe');
  return true;
exception
  when others then
    return false;
end;
$$;

-- ===========================================================================
-- A. Structure
-- ===========================================================================
select has_table ('public', 'device_tokens', 'device_tokens table exists');
select has_table ('public', 'notification_outbox', 'notification_outbox table exists');
select ok (public.pgtap_rls_enabled ('public.device_tokens'::regclass), 'RLS is enabled on device_tokens');
select ok (public.pgtap_rls_forced ('public.device_tokens'::regclass), 'RLS is FORCED on device_tokens');
select ok (public.pgtap_rls_enabled ('public.notification_outbox'::regclass), 'RLS is enabled on notification_outbox');
select ok (public.pgtap_rls_forced ('public.notification_outbox'::regclass), 'RLS is FORCED on notification_outbox');
select ok (
  exists (select 1 from pg_indexes
           where schemaname = 'public' and tablename = 'device_tokens'
             and indexdef like 'CREATE UNIQUE INDEX%'
             and indexdef like '%(platform, apns_token)%'),
  'device_tokens has UNIQUE (platform, apns_token)');
select ok (
  exists (select 1 from pg_indexes
           where schemaname = 'public' and tablename = 'notification_outbox'
             and indexdef like 'CREATE UNIQUE INDEX%'
             and indexdef like '%(dedupe_key)%'),
  'notification_outbox has UNIQUE (dedupe_key)');
select ok (
  not exists (select 1 from pg_policies
               where schemaname = 'public' and tablename = 'notification_outbox'
                 and cmd in ('INSERT', 'UPDATE', 'DELETE')
                 and 'authenticated' = any (roles::text[])),
  'notification_outbox has NO client INSERT/UPDATE/DELETE policy');
select ok (
  not has_table_privilege ('authenticated', 'public.notification_outbox', 'insert'),
  'authenticated has no INSERT privilege on notification_outbox');
select has_function ('public', 'claim_notification_outbox', array['integer']::name[], 'claim_notification_outbox exists');
select has_function ('public', 'complete_notification_outbox', array['uuid','text','text','timestamptz']::name[], 'complete_notification_outbox exists');
select has_function ('public', 'register_device_token', array['text','text','text','text']::name[], 'register_device_token exists');
select has_function ('public', 'dispatch_push_notifications', array[]::name[], 'dispatch_push_notifications exists');
select ok (not has_function_privilege ('authenticated', 'public.claim_notification_outbox(integer)', 'execute'), 'authenticated may NOT claim the outbox');
select ok (has_function_privilege ('service_role', 'public.claim_notification_outbox(integer)', 'execute'), 'service_role may claim the outbox');
select ok (has_function_privilege ('authenticated', 'public.register_device_token(text,text,text,text)', 'execute'), 'authenticated may register a device token');
select ok (
  (select count(*) from pg_policies
    where schemaname = 'public' and tablename = 'notification_outbox' and cmd = 'SELECT'
      and 'authenticated' = any (roles::text[])) = 1,
  'notification_outbox has exactly one SELECT policy for authenticated (own rows)');

-- ===========================================================================
-- B. Fixture
-- ===========================================================================
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a8b80000-0000-0000-0000-000000000001', 'a8_paulo@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a8b80000-0000-0000-0000-000000000002', 'a8_ana2@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a8b80000-0000-0000-0000-000000000003', 'a8_bia@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a8b80000-0000-0000-0000-000000000004', 'a8_raul@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

update public.profiles set display_name = 'A8 Paulo' where id = 'a8b80000-0000-0000-0000-000000000001';
update public.profiles set display_name = 'A8 Ana2'  where id = 'a8b80000-0000-0000-0000-000000000002';
update public.profiles set display_name = 'A8 Bia'   where id = 'a8b80000-0000-0000-0000-000000000003';
update public.profiles set display_name = 'A8 Raul' where id = 'a8b80000-0000-0000-0000-000000000004';

insert into public.groups (id, name, group_type, created_by)
values ('a8b80000-0000-0000-0000-000000000501', 'A8 Push Group', 'fraternity', 'a8b80000-0000-0000-0000-000000000001');

insert into public.group_members (group_id, user_id, role)
values
  ('a8b80000-0000-0000-0000-000000000501', 'a8b80000-0000-0000-0000-000000000001', 'admin'),
  ('a8b80000-0000-0000-0000-000000000501', 'a8b80000-0000-0000-0000-000000000002', 'member'),
  ('a8b80000-0000-0000-0000-000000000501', 'a8b80000-0000-0000-0000-000000000003', 'member'),
  ('a8b80000-0000-0000-0000-000000000501', 'a8b80000-0000-0000-0000-000000000004', 'member');

-- p1 blocks p4. The block is SYMMETRIC.
insert into public.user_blocks (blocker_id, blocked_id)
values ('a8b80000-0000-0000-0000-000000000001', 'a8b80000-0000-0000-0000-000000000004');

-- A feed post, a prayer intention.
insert into public.feed_posts (id, group_id, user_id, practice_kind, reflection_text, points)
values ('a8b80000-0000-0000-0000-000000000101', 'a8b80000-0000-0000-0000-000000000501',
        'a8b80000-0000-0000-0000-000000000001', 'rosary', 'A shared grace', 1);

insert into public.prayer_intentions (id, group_id, user_id, body)
values ('a8b80000-0000-0000-0000-000000000201', 'a8b80000-0000-0000-0000-000000000501',
        'a8b80000-0000-0000-0000-000000000001', 'Please pray for my family');

-- ===========================================================================
-- C. device_tokens — the same token moves to the new user
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a8b80000-0000-0000-0000-000000000001","role":"authenticated"}';

select is (
  (public.register_device_token ('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 'ios', 'production', '1.0.0')) ->> 'registered',
  'true',
  'device token: the RPC registers a token');
select is (
  (select count(*) from public.device_tokens
    where user_id = 'a8b80000-0000-0000-0000-000000000001')::int,
  1,
  'device token: one row for p1');

select public.register_device_token ('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 'ios', 'production', '1.0.0');
select is (
  (select count(*) from public.device_tokens
    where apns_token = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')::int,
  1,
  'device token: re-registering the SAME token never duplicates the row');
select is (
  (select user_id::text from public.device_tokens
    where apns_token = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
  'a8b80000-0000-0000-0000-000000000001',
  'device token: the token still belongs to p1');

-- the same token re-registered by another user MOVES the row
set local request.jwt.claims = '{"sub":"a8b80000-0000-0000-0000-000000000002","role":"authenticated"}';
select public.register_device_token ('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 'ios', 'production', '1.0.0');
select is (
  (select count(*) from public.device_tokens
    where apns_token = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')::int,
  1,
  'device token: the token is stored ONCE even when another user registers it');
select is (
  (select user_id::text from public.device_tokens
    where apns_token = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
  'a8b80000-0000-0000-0000-000000000002',
  'device token: the token MOVED to the new user');

select is (
  (select count(*) from public.device_tokens)::int,
  1,
  'RLS device_tokens: the new owner reads their own token');
set local request.jwt.claims = '{"sub":"a8b80000-0000-0000-0000-000000000003","role":"authenticated"}';
select is (
  (select count(*) from public.device_tokens)::int,
  0,
  'RLS device_tokens: another member reads NO token');
reset role;

-- ===========================================================================
-- D. notification_outbox — idempotency and the liturgical gate
-- ===========================================================================
select throws_ok (
  $$insert into public.notification_outbox (user_id, notification_type, title, body, dedupe_key)
    values ('a8b80000-0000-0000-0000-000000000001', 'unknown_type', 't', 'b', 'probe_unknown')$$,
  '23514',
  'new row for relation "notification_outbox" violates check constraint "notification_outbox_notification_type_check"',
  'outbox: an unknown notification_type is rejected');
select throws_ok (
  $$insert into public.notification_outbox (user_id, notification_type, title, body, dedupe_key)
    values ('a8b80000-0000-0000-0000-000000000001', 'liturgical_reminder', 't', 'b', 'lit_probe')$$,
  '23514',
  'new row for relation "notification_outbox" violates check constraint "notification_outbox_notification_type_check"',
  'outbox: a LITURGICAL reminder can never be queued (liturgical reminders are local-only)');

insert into public.notification_outbox (user_id, notification_type, title, body, dedupe_key)
values ('a8b80000-0000-0000-0000-000000000001', 'streak_milestone', 't', 'b', 'dup_probe');

select throws_ok (
  $$insert into public.notification_outbox (user_id, notification_type, title, body, dedupe_key)
    values ('a8b80000-0000-0000-0000-000000000001', 'streak_milestone', 't2', 'b2', 'dup_probe')$$,
  '23505',
  'duplicate key value violates unique constraint "notification_outbox_dedupe_key_key"',
  'outbox: the UNIQUE dedupe_key rejects a duplicate');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a8b80000-0000-0000-0000-000000000001","role":"authenticated"}';
select ok (not pg_temp.can_insert_outbox (), 'RLS outbox: a client can NOT insert an outbox row');
reset role;

-- ===========================================================================
-- E. The emission triggers
-- ===========================================================================

-- E1 · prayed for you
insert into public.intention_prayers (intention_id, prayer_id)
values ('a8b80000-0000-0000-0000-000000000201', 'a8b80000-0000-0000-0000-000000000002');

select is (
  (select count(*) from public.notification_outbox
    where notification_type = 'prayed_for_you'
      and user_id = 'a8b80000-0000-0000-0000-000000000001')::int,
  1,
  'trigger: inserting into intention_prayers notifies the intention author');
select ok (
  (select dedupe_key from public.notification_outbox
    where notification_type = 'prayed_for_you'
      and user_id = 'a8b80000-0000-0000-0000-000000000001') like 'prayed:%',
  'trigger: the prayed-for-you dedupe key is prayed:<intention_prayer_id>');
select ok (
  (select body from public.notification_outbox
    where notification_type = 'prayed_for_you'
      and user_id = 'a8b80000-0000-0000-0000-000000000001') not like '%my family%',
  'trigger: the prayer body never reaches the push');

-- A5's own toggle path fires the SAME trigger: the dedupe key makes the two
-- paths idempotent, so EXACTLY ONE row is created.
insert into public.prayer_intentions (id, group_id, user_id, body)
values ('a8b80000-0000-0000-0000-000000000202', 'a8b80000-0000-0000-0000-000000000501',
        'a8b80000-0000-0000-0000-000000000002', 'Please pray for my brother');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a8b80000-0000-0000-0000-000000000003","role":"authenticated"}';
select public.toggle_prayed_for ('a8b80000-0000-0000-0000-000000000202');
reset role;

select is (
  (select count(*) from public.notification_outbox
    where notification_type = 'prayed_for_you'
      and user_id = 'a8b80000-0000-0000-0000-000000000002')::int,
  1,
  'trigger: A5''s toggle_prayed_for + the trigger produce exactly ONE row (idempotent dedupe)');

-- E2 · amen
insert into public.amen_reactions (post_id, user_id, reaction_type)
values ('a8b80000-0000-0000-0000-000000000101', 'a8b80000-0000-0000-0000-000000000002', 'amen');

select is (
  (select count(*) from public.notification_outbox
    where notification_type = 'amen'
      and user_id = 'a8b80000-0000-0000-0000-000000000001')::int,
  1,
  'trigger: an amen reaction notifies the post author');
select ok (
  (select dedupe_key from public.notification_outbox
    where notification_type = 'amen' and user_id = 'a8b80000-0000-0000-0000-000000000001') like 'amen:%',
  'trigger: the amen dedupe key is amen:<amen_reaction_id>');
select ok (
  (select body from public.notification_outbox
    where notification_type = 'amen' and user_id = 'a8b80000-0000-0000-0000-000000000001') like '%A8 Ana2%',
  'trigger: the amen push carries the reactor''s display name');

-- the author reacting to their own post notifies nobody
insert into public.amen_reactions (post_id, user_id, reaction_type)
values ('a8b80000-0000-0000-0000-000000000101', 'a8b80000-0000-0000-0000-000000000001', 'amen');

select is (
  (select count(*) from public.notification_outbox
    where notification_type = 'amen'
      and user_id = 'a8b80000-0000-0000-0000-000000000001')::int,
  1,
  'trigger: an author reacting to their OWN post notifies nobody');

-- E3 · pinned notice
insert into public.pinned_notices (group_id, author_id, body)
values ('a8b80000-0000-0000-0000-000000000501', 'a8b80000-0000-0000-0000-000000000001',
        'Rosary on Saturday at 8pm');

select is (
  (select count(*) from public.notification_outbox
    where notification_type = 'pinned_notice')::int,
  2,
  'trigger: a pinned notice notifies every member EXCEPT the author and the blocked one');
select ok (
  not exists (select 1 from public.notification_outbox
               where notification_type = 'pinned_notice'
                 and user_id = 'a8b80000-0000-0000-0000-000000000001'),
  'trigger: the author of the notice is NOT notified');
select ok (
  not exists (select 1 from public.notification_outbox
               where notification_type = 'pinned_notice'
                 and user_id = 'a8b80000-0000-0000-0000-000000000004'),
  'BLOCKED: the blocked member receives NO outbox row');

-- E4 · a blocked pair NEVER produces a notification
insert into public.amen_reactions (post_id, user_id, reaction_type)
values ('a8b80000-0000-0000-0000-000000000101', 'a8b80000-0000-0000-0000-000000000004', 'amen');

select is (
  (select count(*) from public.notification_outbox
    where notification_type = 'amen'
      and user_id = 'a8b80000-0000-0000-0000-000000000001')::int,
  1,
  'BLOCKED: an amen reaction from a blocked user produces NO outbox row for the author');

insert into public.intention_prayers (intention_id, prayer_id)
values ('a8b80000-0000-0000-0000-000000000201', 'a8b80000-0000-0000-0000-000000000004');

select is (
  (select count(*) from public.notification_outbox
    where notification_type = 'prayed_for_you'
      and user_id = 'a8b80000-0000-0000-0000-000000000001')::int,
  1,
  'BLOCKED: a prayer from a blocked user produces NO outbox row for the author');

-- ===========================================================================
-- F. The dispatch RPCs
-- ===========================================================================
select is (
  (select count(*) from public.claim_notification_outbox (50))::int,
  6,
  'dispatch: the claim RPC returns every pending row');
select is (
  (select count(*) from public.notification_outbox where status = 'processing')::int,
  6,
  'dispatch: the claimed rows are marked processing');
select is (
  (select count(*) from public.claim_notification_outbox (50))::int,
  0,
  'dispatch: a second claim finds nothing (the rows are locked)');

select is (
  (public.complete_notification_outbox (
     (select id from public.notification_outbox
       where notification_type = 'amen' and user_id = 'a8b80000-0000-0000-0000-000000000001' limit 1),
     'sent')) ->> 'status',
  'sent',
  'dispatch: completing a row with sent marks it sent');
select ok (
  (select sent_at is not null from public.notification_outbox
    where notification_type = 'amen' and user_id = 'a8b80000-0000-0000-0000-000000000001'),
  'dispatch: a sent row carries sent_at');

create temporary table a8_pinned_id (id uuid) on commit drop;
insert into pg_temp.a8_pinned_id
select id from public.notification_outbox
 where notification_type = 'pinned_notice'
 order by created_at, id
 limit 1;

select is (
  (public.complete_notification_outbox (
     (select id from pg_temp.a8_pinned_id),
     'failed', 'apns_0:transport_error')) ->> 'status',
  'pending',
  'dispatch: a failed row is rescheduled for a retry');
select ok (
  (select scheduled_at > now () from public.notification_outbox
    where id = (select id from pg_temp.a8_pinned_id)),
  'dispatch: the retry uses an exponential backoff (scheduled_at in the future)');

update public.notification_outbox
   set attempts = 5
 where id = (select id from pg_temp.a8_pinned_id);

select is (
  (public.complete_notification_outbox (
     (select id from pg_temp.a8_pinned_id),
     'failed', 'apns_400:BadDeviceToken')) ->> 'status',
  'failed',
  'dispatch: after 5 attempts the failure becomes permanent');
select ok (
  (select last_error is not null from public.notification_outbox
    where id = (select id from pg_temp.a8_pinned_id)),
  'dispatch: the permanent failure keeps the real error');

select is (
  (public.dispatch_push_notifications ()) ->> 'reason',
  'not_configured',
  'dispatch: the cron entry point is a NO-OP while push_dispatch_url is not configured');

-- ===========================================================================
-- G. pg_cron
-- ===========================================================================
select ok (
  exists (select 1 from cron.job
           where jobname = 'a8_push_dispatch' and schedule = '*/5 * * * *' and active),
  'cron: the outbox dispatcher runs every 5 minutes');
select is (
  (select count(*) from cron.job where jobname like 'a8_%')::int,
  4,
  'cron: exactly one row per A8 job name');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
