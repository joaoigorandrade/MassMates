-- =============================================================================
-- A8 · guardian_angel.sql · the Secret Guardian Angel mechanic
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
--
-- Fixture ids
--   u1 Ana     a8a80000-0000-0000-0000-000000000001
--   u2 Bruno   a8a80000-0000-0000-0000-000000000002
--   u3 Carla   a8a80000-0000-0000-0000-000000000003
--   u4 Daniel  a8a80000-0000-0000-0000-000000000004
--   u5 Eva     a8a80000-0000-0000-0000-000000000005   (never opts in)
--   u6 Felipe  a8a80000-0000-0000-0000-000000000006   (blocked by u1)
--   MAIN  a8a80000-0000-0000-0000-000000000501  fraternity
--   BLOCK a8a80000-0000-0000-0000-000000000502  fraternity (u1 <-> u6 blocked)
--   CHAL  a8a80000-0000-0000-0000-000000000503  challenge
--   SMALL a8a80000-0000-0000-0000-000000000504  fraternity (1 member, 0 opt-ins)
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(89);

create function pg_temp.can_read_sender_id ()
  returns boolean
  language plpgsql
as $$
begin
  execute 'select sender_id from public.guardian_nudges limit 1';
  return true;
exception
  when others then
    return false;
end;
$$;

-- A temp table is not writable by `authenticated` unless it is granted.
create temporary table a8_nudge_result (payload jsonb) on commit drop;
grant insert, select on pg_temp.a8_nudge_result to authenticated, anon;
grant usage, select on all sequences in schema pg_temp to authenticated, anon;

-- ===========================================================================
-- A. Structure
-- ===========================================================================
select has_table ('public', 'guardian_angel_opt_ins', 'guardian_angel_opt_ins table exists');
select has_table ('public', 'guardian_angel_pairings', 'guardian_angel_pairings table exists');
select has_table ('public', 'guardian_nudges', 'guardian_nudges table exists');
select ok (public.pgtap_rls_enabled ('public.guardian_angel_pairings'::regclass), 'RLS is enabled on guardian_angel_pairings');
select ok (public.pgtap_rls_forced ('public.guardian_angel_pairings'::regclass), 'RLS is FORCED on guardian_angel_pairings');
select ok (public.pgtap_rls_enabled ('public.guardian_nudges'::regclass), 'RLS is enabled on guardian_nudges');
select ok (public.pgtap_rls_forced ('public.guardian_nudges'::regclass), 'RLS is FORCED on guardian_nudges');
select ok (
  not exists (select 1 from pg_policies
               where schemaname = 'public'
                 and tablename = 'guardian_angel_pairings'
                 and 'authenticated' = any (roles::text[])),
  'guardian_angel_pairings has NO SELECT policy for authenticated (the identity stays secret)');
select ok (
  not has_table_privilege ('authenticated', 'public.guardian_angel_pairings', 'select'),
  'authenticated has no SELECT privilege on guardian_angel_pairings');
select ok (
  exists (select 1 from pg_constraint
           where conrelid = 'public.guardian_angel_pairings'::regclass
             and conname = 'guardian_angel_pairings_no_self'),
  'guardian_angel_pairings has the no-self-pair CHECK');
select ok (
  exists (select 1 from pg_indexes
           where schemaname = 'public' and tablename = 'guardian_angel_pairings'
             and indexdef like 'CREATE UNIQUE INDEX%'
             and indexdef like '%(cycle_key, guardian_id)%'),
  'guardian_angel_pairings has UNIQUE (cycle_key, guardian_id)');
select ok (
  exists (select 1 from pg_indexes
           where schemaname = 'public' and tablename = 'guardian_angel_pairings'
             and indexdef like 'CREATE UNIQUE INDEX%'
             and indexdef like '%(cycle_key, protected_id)%'),
  'guardian_angel_pairings has UNIQUE (cycle_key, protected_id)');
select ok (
  exists (select 1 from pg_indexes
           where schemaname = 'public' and tablename = 'guardian_nudges'
             and indexdef like 'CREATE UNIQUE INDEX%'
             and indexdef like '%(sender_id, local_date)%'),
  'guardian_nudges has UNIQUE (sender_id, local_date) — one nudge per day');
select has_function ('public', 'run_guardian_angel_pairing', array['uuid','text','date']::name[], 'run_guardian_angel_pairing exists');
select has_function ('public', 'my_guardian_assignment', array['uuid']::name[], 'my_guardian_assignment exists');
select has_function ('public', 'opt_in_to_guardian_angel', array['uuid','boolean']::name[], 'opt_in_to_guardian_angel exists');
select has_function ('public', 'send_guardian_nudge', array['uuid','date']::name[], 'send_guardian_nudge exists');
select has_function ('public', 'guardian_angel_state', array['uuid']::name[], 'guardian_angel_state exists');
select has_function ('public', 'reveal_guardian_identities', array['uuid']::name[], 'reveal_guardian_identities exists');
select ok (has_function_privilege ('authenticated', 'public.my_guardian_assignment(uuid)', 'execute'), 'authenticated may call my_guardian_assignment');
select ok (not has_function_privilege ('anon', 'public.my_guardian_assignment(uuid)', 'execute'), 'anon may NOT call my_guardian_assignment');
select ok (not has_function_privilege ('authenticated', 'public.run_guardian_angel_pairing(uuid,text,date)', 'execute'), 'authenticated may NOT run the pairing');
select ok (not has_function_privilege ('authenticated', 'public.reveal_guardian_identities(uuid)', 'execute'), 'authenticated may NOT reveal the identities');
select ok (has_function_privilege ('service_role', 'public.run_guardian_angel_pairing(uuid,text,date)', 'execute'), 'service_role may run the pairing');

-- ===========================================================================
-- B. Fixture
-- ===========================================================================
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a8a80000-0000-0000-0000-000000000001', 'a8_ana@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a8a80000-0000-0000-0000-000000000002', 'a8_bruno@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a8a80000-0000-0000-0000-000000000003', 'a8_carla@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a8a80000-0000-0000-0000-000000000004', 'a8_daniel@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a8a80000-0000-0000-0000-000000000005', 'a8_eva@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a8a80000-0000-0000-0000-000000000006', 'a8_felipe@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

update public.profiles set display_name = 'A8 Ana'    where id = 'a8a80000-0000-0000-0000-000000000001';
update public.profiles set display_name = 'A8 Bruno'  where id = 'a8a80000-0000-0000-0000-000000000002';
update public.profiles set display_name = 'A8 Carla'  where id = 'a8a80000-0000-0000-0000-000000000003';
update public.profiles set display_name = 'A8 Daniel' where id = 'a8a80000-0000-0000-0000-000000000004';
update public.profiles set display_name = 'A8 Eva'    where id = 'a8a80000-0000-0000-0000-000000000005';
update public.profiles set display_name = 'A8 Felipe' where id = 'a8a80000-0000-0000-0000-000000000006';

insert into public.groups (id, name, group_type, starts_on, ends_on, created_by)
values
  ('a8a80000-0000-0000-0000-000000000501', 'A8 Main',      'fraternity', null, null, 'a8a80000-0000-0000-0000-000000000001'),
  ('a8a80000-0000-0000-0000-000000000502', 'A8 Blocked',   'fraternity', null, null, 'a8a80000-0000-0000-0000-000000000001'),
  ('a8a80000-0000-0000-0000-000000000503', 'A8 Challenge', 'challenge',  current_date - 3, current_date + 10, 'a8a80000-0000-0000-0000-000000000001'),
  ('a8a80000-0000-0000-0000-000000000504', 'A8 Small',     'fraternity', null, null, 'a8a80000-0000-0000-0000-000000000001');

insert into public.group_members (group_id, user_id, role)
values
  ('a8a80000-0000-0000-0000-000000000501', 'a8a80000-0000-0000-0000-000000000001', 'admin'),
  ('a8a80000-0000-0000-0000-000000000501', 'a8a80000-0000-0000-0000-000000000002', 'member'),
  ('a8a80000-0000-0000-0000-000000000501', 'a8a80000-0000-0000-0000-000000000003', 'member'),
  ('a8a80000-0000-0000-0000-000000000501', 'a8a80000-0000-0000-0000-000000000004', 'member'),
  ('a8a80000-0000-0000-0000-000000000501', 'a8a80000-0000-0000-0000-000000000005', 'member'),
  ('a8a80000-0000-0000-0000-000000000502', 'a8a80000-0000-0000-0000-000000000001', 'admin'),
  ('a8a80000-0000-0000-0000-000000000502', 'a8a80000-0000-0000-0000-000000000002', 'member'),
  ('a8a80000-0000-0000-0000-000000000502', 'a8a80000-0000-0000-0000-000000000003', 'member'),
  ('a8a80000-0000-0000-0000-000000000502', 'a8a80000-0000-0000-0000-000000000004', 'member'),
  ('a8a80000-0000-0000-0000-000000000502', 'a8a80000-0000-0000-0000-000000000006', 'member'),
  ('a8a80000-0000-0000-0000-000000000503', 'a8a80000-0000-0000-0000-000000000001', 'admin'),
  ('a8a80000-0000-0000-0000-000000000503', 'a8a80000-0000-0000-0000-000000000002', 'member'),
  ('a8a80000-0000-0000-0000-000000000503', 'a8a80000-0000-0000-0000-000000000003', 'member'),
  ('a8a80000-0000-0000-0000-000000000503', 'a8a80000-0000-0000-0000-000000000005', 'member'),
  ('a8a80000-0000-0000-0000-000000000504', 'a8a80000-0000-0000-0000-000000000001', 'admin');

-- The block is SYMMETRIC (public.is_blocked checks both directions).
insert into public.user_blocks (blocker_id, blocked_id)
values ('a8a80000-0000-0000-0000-000000000001', 'a8a80000-0000-0000-0000-000000000006');

-- The master switch.
update public.profiles set guardian_angel_opt_in = true where id in (
  'a8a80000-0000-0000-0000-000000000001',
  'a8a80000-0000-0000-0000-000000000002',
  'a8a80000-0000-0000-0000-000000000003',
  'a8a80000-0000-0000-0000-000000000004',
  'a8a80000-0000-0000-0000-000000000006');

-- Per-group opt-ins. u5 (Eva) never opts in.
insert into public.guardian_angel_opt_ins (user_id, group_id)
values
  ('a8a80000-0000-0000-0000-000000000001', 'a8a80000-0000-0000-0000-000000000501'),
  ('a8a80000-0000-0000-0000-000000000002', 'a8a80000-0000-0000-0000-000000000501'),
  ('a8a80000-0000-0000-0000-000000000003', 'a8a80000-0000-0000-0000-000000000501'),
  ('a8a80000-0000-0000-0000-000000000004', 'a8a80000-0000-0000-0000-000000000501'),
  ('a8a80000-0000-0000-0000-000000000001', 'a8a80000-0000-0000-0000-000000000502'),
  ('a8a80000-0000-0000-0000-000000000002', 'a8a80000-0000-0000-0000-000000000502'),
  ('a8a80000-0000-0000-0000-000000000003', 'a8a80000-0000-0000-0000-000000000502'),
  ('a8a80000-0000-0000-0000-000000000004', 'a8a80000-0000-0000-0000-000000000502'),
  ('a8a80000-0000-0000-0000-000000000006', 'a8a80000-0000-0000-0000-000000000502'),
  ('a8a80000-0000-0000-0000-000000000001', 'a8a80000-0000-0000-0000-000000000503'),
  ('a8a80000-0000-0000-0000-000000000002', 'a8a80000-0000-0000-0000-000000000503'),
  ('a8a80000-0000-0000-0000-000000000003', 'a8a80000-0000-0000-0000-000000000503');

-- A prayer intention of u2 (Bruno): the guardian of u2 may see it.
insert into public.prayer_intentions (id, group_id, user_id, body)
values ('a8a80000-0000-0000-0000-000000000601', 'a8a80000-0000-0000-0000-000000000501',
        'a8a80000-0000-0000-0000-000000000002', 'Please pray for my mother');

-- ===========================================================================
-- C. The pairing engine
-- ===========================================================================

-- C1 · fewer than 2 eligible members -> no pair at all
select is (
  (public.run_guardian_angel_pairing ('a8a80000-0000-0000-0000-000000000504')) ->> 'reason',
  'insufficient_opt_ins',
  'pairing: 0 opt-in members -> reason insufficient_opt_ins');
select is (
  (public.run_guardian_angel_pairing ('a8a80000-0000-0000-0000-000000000504')) ->> 'paired',
  '0',
  'pairing: 0 opt-in members -> 0 pairs');
select is (
  (select count(*) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000504')::int,
  0,
  'pairing: 0 opt-in members -> NO row was created');

-- C2 · the main group: 4 opt-ins -> 4 pairs
select is (
  (public.run_guardian_angel_pairing ('a8a80000-0000-0000-0000-000000000501')) ->> 'paired',
  '4',
  'pairing: 4 opt-in members -> 4 pairs');
select is (
  (select count(*) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501')::int,
  4,
  'pairing: 4 rows in guardian_angel_pairings');
select is (
  (select count(*) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501'
      and guardian_id = protected_id)::int,
  0,
  'pairing: NO self-pair (guardian_id <> protected_id for every row)');
select is (
  (select count(distinct guardian_id) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501')::int,
  4,
  'pairing: every member guards exactly one person');
select is (
  (select count(distinct protected_id) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501')::int,
  4,
  'pairing: every member is protected exactly once');
select is (
  (select count(*) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501'
      and (guardian_id = 'a8a80000-0000-0000-0000-000000000005'
        or protected_id = 'a8a80000-0000-0000-0000-000000000005'))::int,
  0,
  'pairing: the member who did NOT opt in is excluded from the draw');
select is (
  (select count(*) from (select cycle_key, guardian_id from public.guardian_angel_pairings
                          where group_id = 'a8a80000-0000-0000-0000-000000000501'
                          group by 1, 2) s)::int,
  (select count(*) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501')::int,
  'pairing: UNIQUE (cycle_key, guardian_id) holds — no duplicates');

-- C3 · idempotency: re-running does not duplicate and does not reshuffle
create temporary table a8_snapshot_before (
  guardian_id uuid, protected_id uuid,
  primary key (guardian_id, protected_id)
) on commit drop;

insert into pg_temp.a8_snapshot_before (guardian_id, protected_id)
select guardian_id, protected_id from public.guardian_angel_pairings
 where group_id = 'a8a80000-0000-0000-0000-000000000501';

select is (
  (public.run_guardian_angel_pairing ('a8a80000-0000-0000-0000-000000000501')) ->> 'paired',
  '4',
  'pairing: re-running the same cycle still reports 4 pairs');
select is (
  (select count(*) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501')::int,
  4,
  'pairing: re-running the same cycle does NOT duplicate the rows');
select is (
  (select count(*) from public.guardian_angel_pairings p
     join pg_temp.a8_snapshot_before b
       on b.guardian_id = p.guardian_id and b.protected_id = p.protected_id
    where p.group_id = 'a8a80000-0000-0000-0000-000000000501')::int,
  4,
  'pairing: re-running the same cycle does NOT reshuffle the draw');

-- C4 · a blocked member is excluded (u1 <-> u6 blocked -> both drop out)
select is (
  (public.run_guardian_angel_pairing ('a8a80000-0000-0000-0000-000000000502')) ->> 'paired',
  '3',
  'pairing: the blocked group keeps only the 3 unblocked members');
select is (
  (select count(*) from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000502'
      and (guardian_id = 'a8a80000-0000-0000-0000-000000000006'
        or protected_id = 'a8a80000-0000-0000-0000-000000000006'
        or guardian_id = 'a8a80000-0000-0000-0000-000000000001'
        or protected_id = 'a8a80000-0000-0000-0000-000000000001'))::int,
  0,
  'pairing: the blocked member (and its block partner) is excluded from the draw');

-- C5 · the cycle window
select is (
  (public.run_guardian_angel_pairing ('a8a80000-0000-0000-0000-000000000503')) ->> 'paired',
  '3',
  'pairing: the challenge group is drawn too (3 opted-in members)');
select is (
  (select cycle_starts_on from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000503' limit 1),
  (current_date - 3),
  'pairing: a challenge cycle spans starts_on .. ends_on (start)');
select is (
  (select cycle_ends_on from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000503' limit 1),
  (current_date + 10),
  'pairing: a challenge cycle spans starts_on .. ends_on (end)');
select is (
  (select cycle_starts_on from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501' limit 1),
  (current_date - ((extract (isodow from current_date)::int - 1))::int),
  'pairing: a fraternity cycle is the current ISO week (Monday)');
select is (
  (select cycle_ends_on from public.guardian_angel_pairings
    where group_id = 'a8a80000-0000-0000-0000-000000000501' limit 1),
  (current_date - ((extract (isodow from current_date)::int - 1))::int) + 6,
  'pairing: a fraternity cycle ends on Sunday');

-- C6 · the audit trail
select ok (
  exists (select 1 from public.audit_log
           where action = 'guardian.pairing_created'
             and target_type = 'guardian_angel_pairings'
             and metadata ->> 'group_id' = 'a8a80000-0000-0000-0000-000000000501'),
  'pairing: an audit_log row (guardian.pairing_created) was written');
select ok (
  exists (select 1 from public.audit_log
           where action = 'guardian.pairing_created'
             and metadata ->> 'member_count' = '4'
             and metadata ? 'rotation_offset'),
  'pairing: the audit metadata records member_count and the rotation offset');

-- ===========================================================================
-- D. opt_in_to_guardian_angel
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a8a80000-0000-0000-0000-000000000005","role":"authenticated"}';

select is (
  (public.opt_in_to_guardian_angel ('a8a80000-0000-0000-0000-000000000501', true)) ->> 'group_opt_in',
  'true',
  'opt-in: the RPC reports the per-group opt-in');
select is (
  (select count(*) from public.guardian_angel_opt_ins
    where user_id = 'a8a80000-0000-0000-0000-000000000005'
      and group_id = 'a8a80000-0000-0000-0000-000000000501')::int,
  1,
  'opt-in: the per-group opt-in row was created');
select is (
  (select guardian_angel_opt_in from public.profiles
    where id = 'a8a80000-0000-0000-0000-000000000005')::text,
  'true',
  'opt-in: the master switch profiles.guardian_angel_opt_in flipped to true');

select public.opt_in_to_guardian_angel ('a8a80000-0000-0000-0000-000000000501', true);
select is (
  (select count(*) from public.guardian_angel_opt_ins
    where user_id = 'a8a80000-0000-0000-0000-000000000005'
      and group_id = 'a8a80000-0000-0000-0000-000000000501')::int,
  1,
  'opt-in: calling it twice is idempotent (still one row)');

select public.opt_in_to_guardian_angel ('a8a80000-0000-0000-0000-000000000501', false);
select is (
  (select count(*) from public.guardian_angel_opt_ins
    where user_id = 'a8a80000-0000-0000-0000-000000000005')::int,
  0,
  'opt-out: the per-group opt-in row was removed');
select is (
  (select guardian_angel_opt_in from public.profiles
    where id = 'a8a80000-0000-0000-0000-000000000005')::text,
  'false',
  'opt-out: the master switch flipped back to false (no other group opted in)');

select public.opt_in_to_guardian_angel ('a8a80000-0000-0000-0000-000000000503', true);
select is (
  (select guardian_angel_opt_in from public.profiles
    where id = 'a8a80000-0000-0000-0000-000000000005')::text,
  'true',
  'opt-in: the master switch is true again after opting into ANOTHER group');
select public.opt_in_to_guardian_angel ('a8a80000-0000-0000-0000-000000000503', false);

reset role;

-- ===========================================================================
-- E. The assignment and the ANONYMITY guarantee
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a8a80000-0000-0000-0000-000000000001","role":"authenticated"}';

-- u1 guards u2 (rotation over the sorted list u1,u2,u3,u4) and is guarded by u4.
select is (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501')) ->> 'is_guardian',
  'true',
  'assignment: u1 is a guardian');
select is (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501')) ->> 'is_protected',
  'true',
  'assignment: u1 is also protected by somebody');
select is (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501')) ->> 'protected_display_name',
  'A8 Bruno',
  'assignment: the guardian sees the display name of the soul it guards');
select ok (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501')) -> 'protected_intentions' @> '[{"body":"Please pray for my mother"}]'::jsonb,
  'assignment: the guardian sees the prayer intentions of the soul it guards');
select is (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501')) ->> 'guardian_display_name',
  null,
  'ANONYMITY: the guardian identity is NOT revealed before the cycle ends');
select ok (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501'))::text
    not like '%A8 Daniel%',
  'ANONYMITY: the assignment never contains the guardian''s display name');
select ok (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501'))::text
    not like '%a8a80000-0000-0000-0000-000000000004%',
  'ANONYMITY: the assignment never contains the guardian''s id');

select is (
  (public.guardian_angel_state ('a8a80000-0000-0000-0000-000000000501')) ->> 'opted_in',
  'true',
  'state: u1 is opted in');
select is (
  (public.guardian_angel_state ('a8a80000-0000-0000-0000-000000000501')) ->> 'can_nudge',
  'true',
  'state: u1 may nudge (no nudge sent yet today)');
select is (
  (public.guardian_angel_state ('a8a80000-0000-0000-0000-000000000501')) ->> 'nudges_today',
  '0',
  'state: nudges_today starts at 0');

reset role;

-- ===========================================================================
-- F. The anonymous nudge
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a8a80000-0000-0000-0000-000000000001","role":"authenticated"}';

insert into pg_temp.a8_nudge_result
select public.send_guardian_nudge ('a8a80000-0000-0000-0000-000000000501', current_date);

select is (
  (select payload ->> 'sent' from pg_temp.a8_nudge_result),
  'true',
  'nudge: the guardian can send the nudge');
select is (
  (select payload ->> 'nudges_today' from pg_temp.a8_nudge_result),
  '1',
  'nudge: nudges_today is 1 after the nudge');

select is (
  (select count(*) from public.guardian_nudges
    where protected_id = 'a8a80000-0000-0000-0000-000000000002'
      and local_date = current_date)::int,
  1,
  'nudge: exactly one guardian_nudges row was created');
select is (
  (select count(*) from public.guardian_nudges)::int,
  1,
  'nudge: the SENDER sees their own nudge row');

-- a second nudge on the same day is rejected
select throws_ok (
  $$select public.send_guardian_nudge ('a8a80000-0000-0000-0000-000000000501', current_date)$$,
  'P0001',
  'nudge_already_sent_today',
  'nudge: a second nudge on the same day is rejected');

-- a nudge from somebody who is not a guardian is rejected
set local request.jwt.claims = '{"sub":"a8a80000-0000-0000-0000-000000000005","role":"authenticated"}';
select throws_ok (
  $$select public.send_guardian_nudge ('a8a80000-0000-0000-0000-000000000501', current_date)$$,
  '42501',
  'not_a_guardian',
  'nudge: a non-guardian cannot nudge');

-- the recipient cannot learn who sent it
set local request.jwt.claims = '{"sub":"a8a80000-0000-0000-0000-000000000002","role":"authenticated"}';
select is (
  (select count(*) from public.guardian_nudges)::int,
  0,
  'ANONYMITY: the recipient sees NO guardian_nudges row');
select ok (
  not pg_temp.can_read_sender_id (),
  'ANONYMITY: the recipient cannot even read the sender_id column');
select is (
  (select count(*) from public.notification_outbox where notification_type = 'guardian_nudge')::int,
  1,
  'nudge: the recipient reads their own outbox row');
select ok (
  (select body from public.notification_outbox where notification_type = 'guardian_nudge')
    not like '%A8 Ana%',
  'ANONYMITY: the outbox row the recipient reads is anonymous');

-- the state after the nudge
set local request.jwt.claims = '{"sub":"a8a80000-0000-0000-0000-000000000001","role":"authenticated"}';
select is (
  (public.guardian_angel_state ('a8a80000-0000-0000-0000-000000000501')) ->> 'nudges_today',
  '1',
  'state: nudges_today is 1 after the nudge');
select is (
  (public.guardian_angel_state ('a8a80000-0000-0000-0000-000000000501')) ->> 'can_nudge',
  'false',
  'state: can_nudge is false after the nudge of the day');

reset role;

-- ===========================================================================
-- G. The reveal (service_role only, end of the cycle)
-- ===========================================================================
-- The outbox is read as `postgres` here: the SENDER cannot read the row of
-- the recipient (RLS: only your own rows), which is the point.
select is (
  (select count(*) from public.notification_outbox
    where notification_type = 'guardian_nudge'
      and user_id = 'a8a80000-0000-0000-0000-000000000002')::int,
  1,
  'nudge: exactly one notification_outbox row was created for the protected member');
select ok (
  (select body from public.notification_outbox where notification_type = 'guardian_nudge')
    not like '%A8 Ana%',
  'ANONYMITY: the pushed body does not contain the sender''s display name');
select ok (
  (select payload::text from public.notification_outbox where notification_type = 'guardian_nudge')
    not like '%a8a80000-0000-0000-0000-000000000001%',
  'ANONYMITY: the pushed payload does not contain the sender''s id');
select ok (
  (select body from public.notification_outbox where notification_type = 'guardian_nudge')
    not like '%a8a80000-0000-0000-0000-000000000001%',
  'ANONYMITY: the pushed body does not contain the sender''s id');
select ok (
  (select dedupe_key from public.notification_outbox where notification_type = 'guardian_nudge')
    like 'nudge:%',
  'nudge: the dedupe key is nudge:<nudge_id> (server side only — the client cannot read it)');

select is (
  (public.reveal_guardian_identities ('a8a80000-0000-0000-0000-000000000501')) ->> 'revealed',
  '4',
  'reveal: the four pairs of the cycle are revealed');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a8a80000-0000-0000-0000-000000000001","role":"authenticated"}';
select is (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501')) ->> 'guardian_display_name',
  'A8 Daniel',
  'reveal: AFTER the cycle ends the protected member learns the guardian identity');
select is (
  (public.my_guardian_assignment ('a8a80000-0000-0000-0000-000000000501')) ->> 'revealed',
  'true',
  'reveal: the assignment reports revealed = true');
reset role;

-- ===========================================================================
-- H. pg_cron
-- ===========================================================================
select ok (
  exists (select 1 from cron.job
           where jobname = 'a8_pairing_weekly_fraternities' and schedule = '0 5 * * 1'),
  'cron: a8_pairing_weekly_fraternities runs on 0 5 * * 1 (Mondays 05:00 UTC)');
select ok (
  exists (select 1 from cron.job
           where jobname = 'a8_pairing_daily_challenges' and schedule = '0 6 * * *'),
  'cron: a8_pairing_daily_challenges runs on 0 6 * * *');
select ok (
  exists (select 1 from cron.job
           where jobname = 'a8_reveal_ended_cycles' and schedule = '15 6 * * *'),
  'cron: a8_reveal_ended_cycles runs on 15 6 * * *');
select ok (
  exists (select 1 from cron.job
           where jobname = 'a8_push_dispatch' and schedule = '*/5 * * * *'),
  'cron: a8_push_dispatch runs every 5 minutes');
select is (
  (select count(*) from cron.job where jobname like 'a8_%')::int,
  4,
  'cron: exactly one row per A8 job name (the schedule is idempotent)');
select ok (
  (select count(*) from cron.job
    where jobname like 'a8_%' and active) = 4,
  'cron: all four A8 jobs are active');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
