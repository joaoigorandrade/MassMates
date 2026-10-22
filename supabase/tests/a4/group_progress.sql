-- =============================================================================
-- A4 · group_progress.sql · scoring modes + the Group Progress tab
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
-- The file MUST end with:
--   select * from finish();
--   select public.pgtap_summary() as result;   -- always the last result set
--   rollback;
-- =============================================================================

begin;
set local search_path = extensions, public;

-- ---------------------------------------------------------------------------
-- Fixture: 3 users, 4 groups, 1 block
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a4111111-1111-1111-1111-111111111111', 'a4_alice@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a4222222-2222-2222-2222-222222222222', 'a4_bob@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a4333333-3333-3333-3333-333333333333', 'a4_carol@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.profiles (id, display_name, timezone, rule_of_life)
values
  ('a4111111-1111-1111-1111-111111111111', 'Alice', 'UTC', '[]'::jsonb),
  ('a4222222-2222-2222-2222-222222222222', 'Bob',   'UTC', '[]'::jsonb),
  ('a4333333-3333-3333-3333-333333333333', 'Carol', 'UTC', '[]'::jsonb)
on conflict (id) do update
  set display_name = excluded.display_name,
      timezone     = excluded.timezone;

insert into public.groups (id, name, created_by, scoring_mode, sharing_requirement, goal_target)
values
  ('a4555555-5555-5555-5555-555555555555', 'A4 Open Group',  'a4222222-2222-2222-2222-222222222222', 'faithful_days',       'open',          100),
  ('a4666666-6666-6666-6666-666666666666', 'A4 Fruit Group', 'a4111111-1111-1111-1111-111111111111', 'custom_points',      'written_fruit', 100),
  ('a4777777-7777-7777-7777-777777777777', 'A4 Photo Group', 'a4111111-1111-1111-1111-111111111111', 'collective_treasure','photo_witness',  50),
  ('a4888888-8888-8888-8888-888888888888', 'A4 Carol Group', 'a4333333-3333-3333-3333-333333333333', 'faithful_days',       'open',          100);

insert into public.group_members (group_id, user_id, role)
values
  ('a4555555-5555-5555-5555-555555555555', 'a4111111-1111-1111-1111-111111111111', 'admin'),
  ('a4555555-5555-5555-5555-555555555555', 'a4222222-2222-2222-2222-222222222222', 'member'),
  ('a4555555-5555-5555-5555-555555555555', 'a4333333-3333-3333-3333-333333333333', 'member'),
  ('a4666666-6666-6666-6666-666666666666', 'a4111111-1111-1111-1111-111111111111', 'admin'),
  ('a4777777-7777-7777-7777-777777777777', 'a4111111-1111-1111-1111-111111111111', 'admin'),
  ('a4888888-8888-8888-8888-888888888888', 'a4333333-3333-3333-3333-333333333333', 'admin');

-- Alice blocked Carol: Carol must disappear from Alice's Group Progress view.
insert into public.user_blocks (blocker_id, blocked_id)
values ('a4111111-1111-1111-1111-111111111111', 'a4333333-3333-3333-3333-333333333333');

select plan(21);

set local role authenticated;
set local request.jwt.claims = '{"sub":"a4111111-1111-1111-1111-111111111111","role":"authenticated","email":"alice@example.test"}';

-- ---------------------------------------------------------------------------
-- A. faithful_days — 1 point per active day
-- ---------------------------------------------------------------------------
select public.submit_check_in ('rosary', 'group', array['a4555555-5555-5555-5555-555555555555'::uuid], 'Amen', null, current_date - 5);
select public.submit_check_in ('rosary', 'group', array['a4555555-5555-5555-5555-555555555555'::uuid], 'Amen', null, current_date - 4);
select public.submit_check_in ('rosary', 'group', array['a4555555-5555-5555-5555-555555555555'::uuid], 'Amen', null, current_date - 3);

select is (
  (select points from public.check_ins
    where user_id = auth.uid() and practice_kind = 'rosary' and local_date = current_date - 5
      and sharing = 'group'),
  1,
  'scoring: faithful_days gives 1 point per check-in');

-- ---------------------------------------------------------------------------
-- B. custom_points — the group's practice_points row wins
-- ---------------------------------------------------------------------------
select ok (
  (public.set_practice_points ('a4666666-6666-6666-6666-666666666666', 'rosary', 30)) ->> 'points' = '30',
  'scoring: a group admin can set the points of a practice');

select public.submit_check_in ('rosary', 'group', array['a4666666-6666-6666-6666-666666666666'::uuid], 'Fruit', null, current_date - 2);
select public.submit_check_in ('holy_mass', 'group', array['a4666666-6666-6666-6666-666666666666'::uuid], 'Fruit', null, current_date - 4);

select is (
  (select points from public.check_ins
    where user_id = auth.uid() and practice_kind = 'rosary' and local_date = current_date - 2
      and sharing = 'group' and reflection_text = 'Fruit'),
  30,
  'scoring: custom_points uses the group practice_points row (30)');

select is (
  (select points from public.check_ins
    where user_id = auth.uid() and practice_kind = 'holy_mass' and sharing = 'group'),
  0,
  'scoring: custom_points falls back to 0 when the practice has no point value');

-- the GLOBAL row is the fallback of a custom_points group
select ok (
  (public.set_practice_points (null, 'fasting', 7)) ->> 'points' = '7',
  'scoring: a group admin can set a GLOBAL default point value');

select public.submit_check_in ('fasting', 'group', array['a4666666-6666-6666-6666-666666666666'::uuid], 'Fruit', null, current_date - 3);

select is (
  (select points from public.check_ins
    where user_id = auth.uid() and practice_kind = 'fasting' and sharing = 'group'),
  7,
  'scoring: custom_points falls back to the GLOBAL practice_points row (7)');

-- ---------------------------------------------------------------------------
-- C. collective_treasure — 1 unit per check-in by default
-- ---------------------------------------------------------------------------
select public.submit_check_in ('adoration', 'group', array['a4777777-7777-7777-7777-777777777777'::uuid], 'Witness', 'witness-photos/p.png', current_date - 2);

select is (
  (select points from public.check_ins
    where user_id = auth.uid() and practice_kind = 'adoration' and sharing = 'group'),
  1,
  'scoring: collective_treasure pours 1 unit per check-in by default');

-- ---------------------------------------------------------------------------
-- D. Bob and Carol check in
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims = '{}';

set local role authenticated;
set local request.jwt.claims = '{"sub":"a4222222-2222-2222-2222-222222222222","role":"authenticated","email":"bob@example.test"}';
select public.submit_check_in ('rosary', 'group', array['a4555555-5555-5555-5555-555555555555'::uuid], 'Amen', null, current_date);

reset role;
set local request.jwt.claims = '{}';

set local role authenticated;
set local request.jwt.claims = '{"sub":"a4333333-3333-3333-3333-333333333333","role":"authenticated","email":"carol@example.test"}';
select public.submit_check_in ('rosary', 'group', array['a4555555-5555-5555-5555-555555555555'::uuid], 'Amen', null, current_date - 2);

select throws_ok (
  $$select public.get_group_progress ('a4666666-6666-6666-6666-666666666666')$$,
  '42501',
  'not_a_group_member',
  'group progress: a non-member cannot read the progress of a group');

-- ---------------------------------------------------------------------------
-- E. The Group Progress tab (as Alice)
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims = '{}';

set local role authenticated;
set local request.jwt.claims = '{"sub":"a4111111-1111-1111-1111-111111111111","role":"authenticated","email":"alice@example.test"}';

select is (
  (public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) ->> 'goal_current',
  '4',
  'group progress: faithful_days counts DISTINCT member-days (3 Alice + 1 Bob; Carol is blocked)');

select is (
  (public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) ->> 'goal_target',
  '100',
  'group progress: goal_target comes from the group');

select is (
  ((public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) ->> 'percentage')::numeric,
  4.00::numeric,
  'group progress: percentage = goal_current / goal_target');

select is (
  (public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) ->> 'scoring_mode',
  'faithful_days',
  'group progress: scoring_mode is reported');

select is (
  (public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) ->> 'member_count',
  '3',
  'group progress: member_count is the roster size');

select is (
  (public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) ->> 'active_today_count',
  '1',
  'group progress: active_today_count counts the members active today');

select is (
  (select jsonb_array_length((public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) -> 'per_member')),
  2,
  'group progress: the blocked member is EXCLUDED from per_member');

select is (
  (select p ->> 'points' from jsonb_array_elements((public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) -> 'per_member') p
    where p ->> 'user_id' = 'a4111111-1111-1111-1111-111111111111'),
  '3',
  'group progress: faithful_days gives each member 1 point per active day');

select is (
  (select p ->> 'days_active' from jsonb_array_elements((public.get_group_progress ('a4555555-5555-5555-5555-555555555555')) -> 'per_member') p
    where p ->> 'user_id' = 'a4111111-1111-1111-1111-111111111111'),
  '3',
  'group progress: days_active counts the distinct active days of the member');

select is (
  (public.get_group_progress ('a4666666-6666-6666-6666-666666666666')) ->> 'goal_current',
  '37',
  'group progress: custom_points sums the point values (30 + 7)');

select is (
  (public.get_group_progress ('a4666666-6666-6666-6666-666666666666')) ->> 'scoring_mode',
  'custom_points',
  'group progress: the custom_points mode is reported');

select is (
  (public.get_group_progress ('a4777777-7777-7777-7777-777777777777')) ->> 'goal_current',
  '1',
  'group progress: collective_treasure sums the poured units');

select is (
  ((public.get_group_progress ('a4777777-7777-7777-7777-777777777777')) ->> 'percentage')::numeric,
  2.00::numeric,
  'group progress: the collective goal bar percentage');

-- ---------------------------------------------------------------------------
-- Verdict
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims = '{}';

select * from finish ();
select public.pgtap_summary () as result;

rollback;
