-- =============================================================================
-- A7 · monetization.sql · sponsors, the reward ledger and the reward RPCs
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish();
--   select public.pgtap_summary() as result;   -- always the last result set
--   rollback;
-- =============================================================================

begin;
set local search_path = extensions, public;

-- Two users. The A2 trigger `on_auth_user_created` creates the profiles.
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('11111111-1111-1111-1111-111111111111', 'a7_one@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('22222222-2222-2222-2222-222222222222', 'a7_two@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

-- Helper: SECURITY INVOKER. true = the INSERT was ALLOWED.
create function pg_temp.try_insert_grant (p_txn text)
  returns boolean
  language plpgsql
as $$
begin
  insert into public.reward_grants (user_id, reward_type, source, transaction_id)
  values ('11111111-1111-1111-1111-111111111111', 'group_slot', 'admob_ssv', p_txn);
  return true;
exception
  when unique_violation then
    return false;
end;
$$;

-- Helper: SECURITY INVOKER. true = the INSERT was ALLOWED.
create function pg_temp.try_insert_ad_token ()
  returns boolean
  language plpgsql
as $$
begin
  insert into public.ad_view_tokens (user_id, transaction_id, reward_type, expires_at)
  values ('11111111-1111-1111-1111-111111111111', 'client-made-token', 'group_slot', now() + interval '30 minutes');
  return true;
exception
  when others then
    return false;
end;
$$;

select plan(68);

-- ---------------------------------------------------------------------------
-- A. Tables
-- ---------------------------------------------------------------------------
select has_table ('public', 'sponsors', 'sponsors table exists');
select has_table ('public', 'sponsored_challenges', 'sponsored_challenges table exists');
select has_table ('public', 'reward_grants', 'reward_grants table exists');
select has_table ('public', 'ad_view_tokens', 'ad_view_tokens table exists');
select has_table ('public', 'ssv_receipts', 'ssv_receipts table exists');

-- ---------------------------------------------------------------------------
-- B. RLS enabled AND forced
-- ---------------------------------------------------------------------------
select ok (public.pgtap_rls_enabled ('public.sponsors'::regclass), 'RLS is enabled on sponsors');
select ok (public.pgtap_rls_enabled ('public.sponsored_challenges'::regclass), 'RLS is enabled on sponsored_challenges');
select ok (public.pgtap_rls_enabled ('public.reward_grants'::regclass), 'RLS is enabled on reward_grants');
select ok (public.pgtap_rls_enabled ('public.ad_view_tokens'::regclass), 'RLS is enabled on ad_view_tokens');
select ok (public.pgtap_rls_enabled ('public.ssv_receipts'::regclass), 'RLS is enabled on ssv_receipts');
select ok (public.pgtap_rls_forced ('public.sponsors'::regclass), 'RLS is FORCED on sponsors');
select ok (public.pgtap_rls_forced ('public.sponsored_challenges'::regclass), 'RLS is FORCED on sponsored_challenges');
select ok (public.pgtap_rls_forced ('public.reward_grants'::regclass), 'RLS is FORCED on reward_grants');
select ok (public.pgtap_rls_forced ('public.ad_view_tokens'::regclass), 'RLS is FORCED on ad_view_tokens');
select ok (public.pgtap_rls_forced ('public.ssv_receipts'::regclass), 'RLS is FORCED on ssv_receipts');

-- ---------------------------------------------------------------------------
-- C. Policies: SELECT only, and the SSV receipts are service_role only
-- ---------------------------------------------------------------------------
select ok (public.pgtap_policy_count ('public.reward_grants') = public.pgtap_policy_count ('public.reward_grants', 'r'), 'reward_grants has SELECT policies only');
select ok (public.pgtap_policy_count ('public.ad_view_tokens') = public.pgtap_policy_count ('public.ad_view_tokens', 'r'), 'ad_view_tokens has SELECT policies only');
select ok (
  not exists (
    select 1 from pg_policies
     where schemaname = 'public' and tablename = 'ssv_receipts'
       and ('anon' = any (roles) or 'authenticated' = any (roles))
  ),
  'ssv_receipts has no policy for anon or authenticated');

-- ---------------------------------------------------------------------------
-- D. Table privileges
-- ---------------------------------------------------------------------------
select ok (has_table_privilege ('authenticated', 'public.reward_grants', 'SELECT'), 'authenticated may SELECT reward_grants');
select ok (not has_table_privilege ('authenticated', 'public.reward_grants', 'INSERT'), 'authenticated may not INSERT into reward_grants');
select ok (not has_table_privilege ('authenticated', 'public.reward_grants', 'UPDATE'), 'authenticated may not UPDATE reward_grants');
select ok (not has_table_privilege ('authenticated', 'public.reward_grants', 'DELETE'), 'authenticated may not DELETE from reward_grants');
select ok (not has_table_privilege ('authenticated', 'public.ad_view_tokens', 'INSERT'), 'authenticated may not INSERT into ad_view_tokens');
select ok (not has_table_privilege ('authenticated', 'public.ssv_receipts', 'SELECT'), 'authenticated may not read the SSV receipts');
select ok (has_table_privilege ('anon', 'public.sponsors', 'SELECT'), 'anon may SELECT sponsors');
select ok (has_table_privilege ('anon', 'public.sponsored_challenges', 'SELECT'), 'anon may SELECT sponsored_challenges');

-- ---------------------------------------------------------------------------
-- E. The AdMob SSV smoke test granted nothing
-- ---------------------------------------------------------------------------
select ok ((select count(*) from public.reward_grants) = 0, 'the ledger is empty: the failed SSV pings granted nothing');
select ok ((select count(*) from public.ssv_receipts) = 0, 'the failed SSV pings never reached the database');
select ok ((select count(*) from public.ad_view_tokens) = 0, 'the failed SSV pings created no ad-view token');

-- ---------------------------------------------------------------------------
-- F. The partial unique index: a replayed transaction is never granted twice
-- ---------------------------------------------------------------------------
select ok (
  exists (
    select 1 from pg_indexes
     where schemaname = 'public' and tablename = 'reward_grants'
       and indexname = 'reward_grants_txn_uk'
       and indexdef like '%UNIQUE%'
       and indexdef like '%(source, transaction_id)%'
       and indexdef like '%transaction_id IS NOT NULL%'
  ),
  'reward_grants has the partial unique index on (source, transaction_id)');
select ok (pg_temp.try_insert_grant ('txn-duplicate'), 'the first insert of a transaction id is accepted');
select ok (not pg_temp.try_insert_grant ('txn-duplicate'), 'a duplicate (source, transaction_id) is rejected');
select ok (
  (select count(*) from public.reward_grants where transaction_id is null) = 0,
  'no NULL transaction id was written by the helper');

-- NULL transaction ids are distinct in Postgres: several manual grants are fine.
insert into public.reward_grants (user_id, reward_type, source, transaction_id)
values ('11111111-1111-1111-1111-111111111111', 'group_slot', 'admin_grant', null);
insert into public.reward_grants (user_id, reward_type, source, transaction_id)
values ('11111111-1111-1111-1111-111111111111', 'group_slot', 'admin_grant', null);
insert into public.reward_grants (user_id, reward_type, source, transaction_id)
values ('11111111-1111-1111-1111-111111111111', 'group_slot', 'admin_grant', null);
select ok (
  (select count(*) from public.reward_grants where transaction_id is null) = 3,
  'several grants with a NULL transaction id are allowed');

-- ---------------------------------------------------------------------------
-- G. The function contract
-- ---------------------------------------------------------------------------
select ok (
  not has_function_privilege ('authenticated', 'public.grant_reward (uuid, text, text, text, integer, jsonb)', 'EXECUTE'),
  'authenticated may NOT execute grant_reward');
select ok (
  not has_function_privilege ('anon', 'public.grant_reward (uuid, text, text, text, integer, jsonb)', 'EXECUTE'),
  'anon may NOT execute grant_reward');
select ok (
  has_function_privilege ('service_role', 'public.grant_reward (uuid, text, text, text, integer, jsonb)', 'EXECUTE'),
  'service_role may execute grant_reward');
select ok (
  (select p.prosecdef from pg_proc p where p.oid = 'public.grant_reward (uuid, text, text, text, integer, jsonb)'::regprocedure),
  'grant_reward is SECURITY DEFINER');
select ok (
  (select p.proconfig from pg_proc p where p.oid = 'public.grant_reward (uuid, text, text, text, integer, jsonb)'::regprocedure)
    @> array['search_path=""'],
  'grant_reward pins an empty search_path');
select ok (
  has_function_privilege ('authenticated', 'public.my_rewards ()', 'EXECUTE')
  and not has_function_privilege ('anon', 'public.my_rewards ()', 'EXECUTE'),
  'my_rewards is executable by authenticated and not by anon');
select ok (
  has_function_privilege ('authenticated', 'public.consume_reward (uuid)', 'EXECUTE'),
  'authenticated may execute consume_reward (its own grants)');

-- ---------------------------------------------------------------------------
-- H. The grant flow, as service_role (the AdMob SSV path)
-- ---------------------------------------------------------------------------
set local role service_role;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"service_role"}';

select ok (
  (public.grant_reward ('11111111-1111-1111-1111-111111111111', 'group_slot', 'admob_ssv', 'txn-flow-1') ->> 'granted') = 'true',
  'the first grant succeeds');
select ok (
  (public.grant_reward ('11111111-1111-1111-1111-111111111111', 'group_slot', 'admob_ssv', 'txn-flow-1') ->> 'granted') = 'false',
  'a replayed transaction does not grant again');
select ok (
  (public.grant_reward ('11111111-1111-1111-1111-111111111111', 'group_slot', 'admob_ssv', 'txn-flow-1') ->> 'duplicate') = 'true',
  'a replayed transaction is reported as a duplicate');
select ok (
  (select count(*) from public.reward_grants where source = 'admob_ssv' and transaction_id = 'txn-flow-1') = 1,
  'the ledger holds exactly one row for the replayed transaction');
select ok (
  (select count(*) from public.slot_unlocks where user_id = '11111111-1111-1111-1111-111111111111' and kind = 'group_slot') = 1,
  'a group_slot reward unlocks exactly one group slot');
select ok (
  (select round(extract (epoch from (expires_at - starts_at)) / 86400)::int
     from public.slot_unlocks where user_id = '11111111-1111-1111-1111-111111111111' and kind = 'group_slot') = 30,
  'the unlocked group slot lasts 30 days');

select ok (
  (public.grant_reward ('22222222-2222-2222-2222-222222222222', 'streak_mercy', 'admob_ssv', 'txn-flow-2') ->> 'granted') = 'true',
  'a streak_mercy reward is granted');
select ok (
  (select count(*) from public.streak_mercy_grants where user_id = '22222222-2222-2222-2222-222222222222') = 1,
  'the streak mercy is written to the A4 mercy table');
select ok (
  (select round(extract (epoch from (expires_at - granted_at)) / 86400)::int
     from public.streak_mercy_grants where user_id = '22222222-2222-2222-2222-222222222222') = 30,
  'the streak mercy lasts 30 days');
select ok (
  (public.grant_reward ('22222222-2222-2222-2222-222222222222', 'streak_mercy', 'admob_ssv', 'txn-flow-3') ->> 'reason') = 'streak_mercy_limit_reached',
  'a second streak mercy while one is active is refused');
select ok (
  (select count(*) from public.streak_mercy_grants where user_id = '22222222-2222-2222-2222-222222222222') = 1,
  'the refused streak mercy created no extra row');

select ok (
  (public.grant_reward ('11111111-1111-1111-1111-111111111111', 'saint_theme', 'admob_ssv', 'txn-flow-4') ->> 'granted') = 'true',
  'a saint_theme reward is granted');
select ok (
  (select count(*) from public.user_saint_unlocks where user_id = '11111111-1111-1111-1111-111111111111') = 1,
  'the saint theme is written to the unlock table');
select ok (
  (select round(extract (epoch from (expires_at - granted_at)) / 86400)::int
     from public.user_saint_unlocks where user_id = '11111111-1111-1111-1111-111111111111') = 7,
  'the saint theme lasts 7 days');

select throws_ok (
  $$select public.grant_reward ('11111111-1111-1111-1111-111111111111', 'free_coins', 'admob_ssv', 'txn-flow-5')$$,
  '22023',
  'unsupported reward_type: free_coins',
  'an unsupported reward type is rejected');

reset role;
set local request.jwt.claims = '{}';

-- The id of the OTHER user's grant, captured while we are still postgres:
-- under the caller's RLS the row is invisible, which is the point.
create temporary table pg_temp.a7_other_grant (id uuid) on commit drop;
insert into pg_temp.a7_other_grant (id)
select id from public.reward_grants where user_id = '22222222-2222-2222-2222-222222222222' limit 1;
grant select on pg_temp.a7_other_grant to authenticated;

-- ---------------------------------------------------------------------------
-- I. As a signed-in user
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select ok (
  (select jsonb_array_length (public.my_rewards () -> 'grants'))
    = (select count(*) from public.reward_grants where user_id = '11111111-1111-1111-1111-111111111111'),
  'my_rewards returns every grant of the caller');
select ok (
  (select jsonb_array_length (public.my_rewards () -> 'grants')) > 0,
  'the caller has at least one grant');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.my_rewards () -> 'grants') g
     where g ->> 'user_id' <> '11111111-1111-1111-1111-111111111111'
  ),
  'my_rewards never returns another user''s grant');
select ok (
  (select count(*) from public.reward_grants where user_id = '22222222-2222-2222-2222-222222222222') = 0,
  'RLS: the caller cannot read another user''s reward row');
select ok (not pg_temp.try_insert_ad_token (), 'a client cannot insert an ad-view token directly');

-- the caller consumes its own grant
select ok (
  (public.consume_reward ((public.my_rewards () -> 'grants' -> 0 ->> 'id')::uuid) ->> 'status') = 'consumed',
  'the caller can consume its own grant');
-- the caller cannot consume the other user's grant
select ok (
  (public.consume_reward ((select id from pg_temp.a7_other_grant)) ->> 'ok') = 'false',
  'the caller cannot consume another user''s grant');

-- the ad-view token flow
select ok (
  public.begin_ad_reward ('group_slot') ->> 'ok' = 'true',
  'begin_ad_reward opens a pending ad view');
select ok (
  (public.begin_ad_reward ('group_slot') ->> 'transaction_id') is not null,
  'begin_ad_reward returns a transaction id');
select ok (
  (select count(*) from public.ad_view_tokens where user_id = '11111111-1111-1111-1111-111111111111' and consumed_at is null) = 1,
  'exactly one open ad view is pending for the caller');
select ok (
  (select count(*) from public.ad_view_tokens where user_id = '11111111-1111-1111-1111-111111111111' and consumed_at is not null) = 1,
  'the previous pending ad view was closed');
select throws_ok (
  $$select public.begin_ad_reward ('free_coins')$$,
  '22023',
  'unsupported reward_type: free_coins',
  'begin_ad_reward rejects an unsupported reward type');

reset role;
set local request.jwt.claims = '{}';

-- ---------------------------------------------------------------------------
-- Verdict
-- ---------------------------------------------------------------------------
select * from finish ();
select public.pgtap_summary () as result;

rollback;
