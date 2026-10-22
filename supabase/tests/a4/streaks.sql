-- =============================================================================
-- A4 · streaks.sql · Daily Streak, Rule of Life Ring, heatmap, Streak Mercy
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
-- Fixture
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a4111111-1111-1111-1111-111111111111', 'a4_alice@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.profiles (id, display_name, timezone, rule_of_life)
values
  ('a4111111-1111-1111-1111-111111111111', 'Alice', 'UTC',
   '[{"kind":"rosary","label":"Rosary"},{"kind":"holy_mass","label":"Mass"}]'::jsonb)
on conflict (id) do update
  set display_name = excluded.display_name,
      timezone     = excluded.timezone,
      rule_of_life = excluded.rule_of_life;

select plan(42);

set local role authenticated;
set local request.jwt.claims = '{"sub":"a4111111-1111-1111-1111-111111111111","role":"authenticated","email":"alice@example.test"}';

-- ---------------------------------------------------------------------------
-- A. The Daily Streak
--   A = today-10, B = today-9, C = today-5 (gap), D = today-4, E = today-3
--   X = today-20 (a back-fill, far away)
-- ---------------------------------------------------------------------------
select is (
  (public.submit_check_in ('rosary', 'private', null, null, null, current_date - 10)) -> 'streak' ->> 'current',
  '1',
  'streak: the first check-in starts the streak at 1');

select is (
  (public.submit_check_in ('holy_mass', 'private', null, null, null, current_date - 10)) -> 'streak' ->> 'current',
  '1',
  'streak: a second practice on the SAME day does not increase the streak');

select is (
  (public.submit_check_in ('holy_mass', 'private', null, null, null, current_date - 9)) -> 'streak' ->> 'current',
  '2',
  'streak: a check-in on the next day increases the streak to 2');

select is (
  (public.submit_check_in ('adoration', 'private', null, null, null, current_date - 5)) -> 'streak' ->> 'current',
  '1',
  'streak: a gap RESETS the streak to 1');

select is (
  (select count(*)::int from public.streak_events e
    where e.user_id = auth.uid() and e.event_type = 'reset' and e.local_date = current_date - 5),
  1,
  'streak: the reset is audited in streak_events');

select is (
  (public.submit_check_in ('rosary', 'private', null, null, null, current_date - 4)) -> 'streak' ->> 'current',
  '2',
  'streak: the day after the reset rebuilds the streak to 2');

select is (
  (public.submit_check_in ('rosary', 'private', null, null, null, current_date - 3)) -> 'streak' ->> 'current',
  '3',
  'streak: the streak reaches 3');

select is (
  (public.submit_check_in ('rosary', 'private', null, null, null, current_date - 20)) -> 'streak' ->> 'current',
  '3',
  'streak: a back-filled older date does NOT decrease the streak');

select is (
  (select current_streak::text from public.streaks where user_id = auth.uid()),
  '3',
  'streak: the persisted streak row agrees with the engine');

select is (
  (select longest_streak::text from public.streaks where user_id = auth.uid()),
  '3',
  'streak: the longest streak is the longest run (3)');

select is (
  (select total_practices::text from public.streaks where user_id = auth.uid()),
  '7',
  'streak: total_practices counts every recorded practice (7)');

select is (
  (select count(*)::int from public.streak_events e
    where e.user_id = auth.uid() and e.event_type = 'practice'),
  7,
  'streak: one practice event per check-in');

-- ---------------------------------------------------------------------------
-- B. The Rule of Life Ring (independent from the Streak)
-- ---------------------------------------------------------------------------
select is (
  (public.get_rule_of_life_ring (current_date - 10)) ->> 'completed',
  '2',
  'ring: two committed kinds checked in on the same day = 2 completed');

select is (
  (public.get_rule_of_life_ring (current_date - 10)) ->> 'total',
  '2',
  'ring: total comes from profiles.rule_of_life (2)');

select is (
  ((public.get_rule_of_life_ring (current_date - 10)) ->> 'percentage')::numeric,
  100.00::numeric,
  'ring: 2 of 2 committed kinds = 100%');

select is (
  ((public.get_rule_of_life_ring (current_date - 9)) ->> 'percentage')::numeric,
  50.00::numeric,
  'ring: 1 of 2 committed kinds = 50%');

select is (
  ((public.get_rule_of_life_ring (current_date - 5)) ->> 'percentage')::numeric,
  0.00::numeric,
  'ring: a practice that is NOT committed does not move the ring');

select is (
  (public.get_rule_of_life_ring (current_date - 5)) ->> 'completed',
  '0',
  'ring: the ring is 0 while the STREAK is 1 on the same day — they are independent');

select is (
  (select jsonb_array_length((public.get_rule_of_life_ring (current_date - 5)) -> 'items')),
  2,
  'ring: the items array lists the 2 commitments');

select is (
  ((public.get_rule_of_life_ring (current_date - 5)) -> 'items' -> 0) ->> 'kind',
  'rosary',
  'ring: the first item keeps the committed kind');

select is (
  ((public.get_rule_of_life_ring (current_date - 5)) -> 'items' -> 0) ->> 'done',
  'false',
  'ring: an uncommitted practice leaves the item undone');

-- ---------------------------------------------------------------------------
-- C. The consistency heatmap
-- ---------------------------------------------------------------------------
select is (
  (public.get_consistency_heatmap (current_date - 30, current_date)) -> (current_date - 10)::text,
  '2',
  'heatmap: the day with 2 practices counts 2');

select is (
  (public.get_consistency_heatmap (current_date - 30, current_date)) -> (current_date - 5)::text,
  '1',
  'heatmap: a day with 1 practice counts 1');

select is (
  (select count(*)::int from jsonb_object_keys(public.get_consistency_heatmap (current_date - 30, current_date)) k),
  6,
  'heatmap: only the days with a practice appear in the map');

select throws_ok (
  $$select public.get_consistency_heatmap (current_date, current_date - 1)$$,
  '22023',
  'invalid_range',
  'heatmap: an inverted range is REJECTED');

select throws_ok (
  $$select public.get_consistency_heatmap (current_date - 400, current_date)$$,
  '22023',
  'range_too_large',
  'heatmap: a range longer than 366 days is REJECTED');

-- ---------------------------------------------------------------------------
-- D. The streak summary
-- ---------------------------------------------------------------------------
select is (
  (public.get_streak_summary ()) ->> 'current_streak',
  '3',
  'summary: current_streak');

select is (
  (public.get_streak_summary ()) ->> 'longest_streak',
  '3',
  'summary: longest_streak');

select is (
  (public.get_streak_summary ()) ->> 'total_practices',
  '7',
  'summary: total_practices');

select is (
  (public.get_streak_summary ()) ->> 'mercy_available',
  'false',
  'summary: no mercy is available without a grant');

select is (
  (public.get_streak_summary ()) ->> 'mercy_used_this_month',
  '0',
  'summary: no mercy was used this month');

-- ---------------------------------------------------------------------------
-- E. Streak Mercy
-- ---------------------------------------------------------------------------
select throws_ok (
  $$select public.use_streak_mercy (current_date - 2)$$,
  '22023',
  'no_streak_mercy_grant',
  'mercy: using mercy without a grant is REJECTED');

reset role;
set local request.jwt.claims = '{}';

insert into public.streak_mercy_grants (user_id) values ('a4111111-1111-1111-1111-111111111111');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a4111111-1111-1111-1111-111111111111","role":"authenticated","email":"alice@example.test"}';

select is (
  (public.get_streak_summary ()) ->> 'mercy_available',
  'true',
  'mercy: a grant makes the mercy available');

select throws_ok (
  $$select public.use_streak_mercy (current_date - 15)$$,
  '22023',
  'repairs_date_not_adjacent_to_streak',
  'mercy: a day that is not adjacent to the streak is REJECTED');

select throws_ok (
  $$select public.use_streak_mercy (current_date - 3)$$,
  '22023',
  'repairs_date_not_missed',
  'mercy: a day that already has a practice is REJECTED');

select is (
  (public.use_streak_mercy (current_date - 2)) ->> 'current_streak',
  '4',
  'mercy: a successful use extends the streak by EXACTLY 1 (3 -> 4)');

select is (
  (select count(*)::int from public.streak_events e
    where e.user_id = auth.uid() and e.event_type = 'mercy' and e.local_date = current_date - 2),
  1,
  'mercy: the usage is audited in streak_events');

select is (
  (select count(*)::int from public.streak_mercy_uses u
    where u.user_id = auth.uid() and u.repairs_date = current_date - 2),
  1,
  'mercy: a streak_mercy_uses row records the repaired day');

select is (
  (select count(*)::int from public.streak_mercy_grants g
    where g.user_id = auth.uid() and g.used_at is null),
  0,
  'mercy: the grant is consumed');

select is (
  (public.get_streak_summary ()) ->> 'mercy_used_this_month',
  '1',
  'mercy: the summary counts the mercy used this month');

select is (
  (public.get_streak_summary ()) ->> 'mercy_available',
  'false',
  'mercy: no second mercy is available in the same month');

reset role;
set local request.jwt.claims = '{}';

insert into public.streak_mercy_grants (user_id) values ('a4111111-1111-1111-1111-111111111111');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a4111111-1111-1111-1111-111111111111","role":"authenticated","email":"alice@example.test"}';

select throws_ok (
  $$select public.use_streak_mercy (current_date - 6)$$,
  '23505',
  'streak_mercy_already_used_this_month',
  'mercy: a SECOND mercy in the same calendar month is REJECTED');

-- ---------------------------------------------------------------------------
-- Verdict
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims = '{}';

select * from finish ();
select public.pgtap_summary () as result;

rollback;
