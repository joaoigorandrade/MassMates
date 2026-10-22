-- =============================================================================
-- A2 · account_deletion.sql · the two-tap account deletion
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
-- Impersonation pattern: see supabase/tests/README.md §6
--   set local role authenticated;
--   set local request.jwt.claims = '{"sub":"<uuid>","role":"authenticated"}';
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(21);

-- ---------------------------------------------------------------------------
-- A. The table exists, is protected, and owns its updated_at trigger
-- ---------------------------------------------------------------------------
select has_table ('public', 'account_deletion_requests', 'account_deletion_requests table exists');
select ok (public.pgtap_rls_enabled ('public.account_deletion_requests'::regclass), 'RLS is enabled on account_deletion_requests');
select ok (public.pgtap_rls_forced ('public.account_deletion_requests'::regclass), 'RLS is FORCED on account_deletion_requests');
select has_trigger ('public', 'account_deletion_requests', 'trg_account_deletion_requests_updated_at', 'the updated_at trigger is attached');
select is (public.pgtap_policy_count ('public.account_deletion_requests'::regclass, 'd'), 0, 'there is NO delete policy for clients');
select is (public.pgtap_policy_count ('public.account_deletion_requests'::regclass, 'r'), 1, 'exactly one SELECT policy');
select is (public.pgtap_policy_count ('public.account_deletion_requests'::regclass, 'a'), 1, 'exactly one INSERT policy');
select is (public.pgtap_policy_count ('public.account_deletion_requests'::regclass, 'w'), 1, 'exactly one UPDATE policy');

-- ---------------------------------------------------------------------------
-- B. Fixture: two signed-up users
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a2e00000-0000-4000-8000-000000000001', 'a2_del@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{"full_name":"Deletavel"}'::jsonb, now(), now()),
  ('a2e00000-0000-4000-8000-000000000002', 'a2_other@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{"full_name":"Outro"}'::jsonb, now(), now());

-- A confirmed request that belongs to the SECOND user (known token).
insert into public.account_deletion_requests (user_id, confirmation_token, status, confirmed_at, expires_at)
values (
  'a2e00000-0000-4000-8000-000000000002',
  '11111111-2222-3333-4444-555555555555',
  'confirmed', now(), now() + interval '10 minutes'
);

-- ---------------------------------------------------------------------------
-- C. Tap 1 — request_account_deletion()
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a2e00000-0000-4000-8000-000000000001","role":"authenticated"}';

select lives_ok ($$select public.request_account_deletion()$$, 'request_account_deletion runs');
select is ((select public.request_account_deletion() ->> 'status'), 'pending', 'the new request is pending');
select ok (
  (select (public.request_account_deletion() ->> 'confirmation_token') ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'),
  'the request returns a uuid confirmation token');
select is (
  (select count(*) from public.account_deletion_requests where user_id = 'a2e00000-0000-4000-8000-000000000001')::int,
  1, 'repeated calls create exactly one request row');
select is (
  (select public.request_account_deletion() ->> 'confirmation_token')::text,
  (select confirmation_token::text from public.account_deletion_requests
    where user_id = 'a2e00000-0000-4000-8000-000000000001' and status = 'pending'),
  'the returned token is the token of the stored row');
select is (
  (select r ->> 'id' from (select public.request_account_deletion() as r) a),
  (select r ->> 'id' from (select public.request_account_deletion() as r) b),
  'request_account_deletion is idempotent: a retry returns the same request');

-- ---------------------------------------------------------------------------
-- D. Tap 2 — confirm_account_deletion(token)
-- ---------------------------------------------------------------------------
select throws_ok (
  $$select public.confirm_account_deletion (gen_random_uuid())$$,
  '22023', 'invalid_deletion_token',
  'an unknown confirmation token is rejected');
select throws_ok (
  $$select public.confirm_account_deletion ('11111111-2222-3333-4444-555555555555')$$,
  '22023', 'invalid_deletion_token',
  'a confirmation token that belongs to another user is rejected');

select is (
  (select public.confirm_account_deletion (
      (select public.request_account_deletion() ->> 'confirmation_token')::uuid) ->> 'status'),
  'confirmed',
  'the right token confirms the request');
select is (
  (select status from public.account_deletion_requests
    where user_id = 'a2e00000-0000-4000-8000-000000000001'),
  'confirmed', 'the stored request row is confirmed');
select is (
  (select public.confirm_account_deletion (
      (select public.request_account_deletion() ->> 'confirmation_token')::uuid) ->> 'status'),
  'confirmed',
  'confirming twice is idempotent');

-- ---------------------------------------------------------------------------
-- E. RLS: the rows of another user are invisible
-- ---------------------------------------------------------------------------
set local request.jwt.claims = '{"sub":"a2e00000-0000-4000-8000-000000000002","role":"authenticated"}';

select is (
  (select count(*) from public.account_deletion_requests where user_id = 'a2e00000-0000-4000-8000-000000000001')::int,
  0, 'a user cannot read another user''s deletion request');

reset role;
set local role anon;
set local request.jwt.claims = '{}';

select is (
  (select count(*) from public.account_deletion_requests)::int,
  0, 'anon cannot read the deletion requests');

reset role;
set local request.jwt.claims = '{}';

select * from finish ();
select public.pgtap_summary () as result;

rollback;
