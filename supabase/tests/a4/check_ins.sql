-- =============================================================================
-- A4 · check_ins.sql · check-in engine: schema, privacy, RPC, fan-out, RLS
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
-- Fixture: 3 users, 4 groups, 4 memberships
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a4111111-1111-1111-1111-111111111111', 'a4_alice@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a4222222-2222-2222-2222-222222222222', 'a4_bob@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a4333333-3333-3333-3333-333333333333', 'a4_carol@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

-- A2's on_auth_user_created trigger already created the profiles; refine them.
insert into public.profiles (id, display_name, timezone, rule_of_life)
values
  ('a4111111-1111-1111-1111-111111111111', 'Alice', 'UTC', '[{"kind":"rosary","label":"Rosary"},{"kind":"holy_mass","label":"Mass"}]'::jsonb),
  ('a4222222-2222-2222-2222-222222222222', 'Bob',   'UTC', '[]'::jsonb),
  ('a4333333-3333-3333-3333-333333333333', 'Carol', 'UTC', '[]'::jsonb)
on conflict (id) do update
  set display_name = excluded.display_name,
      timezone     = excluded.timezone,
      rule_of_life = excluded.rule_of_life;

insert into public.groups (id, name, created_by, scoring_mode, sharing_requirement, goal_target)
values
  ('a4555555-5555-5555-5555-555555555555', 'A4 Open Group',   'a4111111-1111-1111-1111-111111111111', 'faithful_days',       'open',          100),
  ('a4666666-6666-6666-6666-666666666666', 'A4 Fruit Group',  'a4111111-1111-1111-1111-111111111111', 'custom_points',      'written_fruit', 100),
  ('a4777777-7777-7777-7777-777777777777', 'A4 Photo Group',  'a4111111-1111-1111-1111-111111111111', 'collective_treasure','photo_witness',  50),
  ('a4888888-8888-8888-8888-888888888888', 'A4 Carol Group',  'a4333333-3333-3333-3333-333333333333', 'faithful_days',       'open',          100);

insert into public.group_members (group_id, user_id, role)
values
  ('a4555555-5555-5555-5555-555555555555', 'a4111111-1111-1111-1111-111111111111', 'admin'),
  ('a4666666-6666-6666-6666-666666666666', 'a4111111-1111-1111-1111-111111111111', 'member'),
  ('a4777777-7777-7777-7777-777777777777', 'a4111111-1111-1111-1111-111111111111', 'member'),
  ('a4555555-5555-5555-5555-555555555555', 'a4222222-2222-2222-2222-222222222222', 'member'),
  ('a4888888-8888-8888-8888-888888888888', 'a4333333-3333-3333-3333-333333333333', 'admin');

-- SECURITY INVOKER helper: runs with the CURRENT role, therefore with the
-- current RLS policies. Returns true when the statement was ALLOWED.
create function pg_temp.try_insert_check_in () returns boolean language plpgsql as $$
begin
  insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone)
  values (auth.uid(), 'rosary', 'private', current_date, 'UTC');
  return true;
exception when others then
  return false;
end;
$$;

create function pg_temp.try_insert_destination () returns boolean language plpgsql as $$
begin
  insert into public.check_in_destinations (check_in_id, group_id)
  values (gen_random_uuid(), 'a4555555-5555-5555-5555-555555555555');
  return true;
exception when others then
  return false;
end;
$$;

create function pg_temp.try_update_alice_check_in () returns integer language plpgsql as $$
declare
  n integer;
begin
  update public.check_ins
     set reflection_text = 'hacked'
   where user_id = 'a4111111-1111-1111-1111-111111111111';
  get diagnostics n = row_count;
  return n;
exception when others then
  return -1;
end;
$$;

create function pg_temp.try_delete_alice_check_in () returns integer language plpgsql as $$
declare
  n integer;
begin
  delete from public.check_ins
   where user_id = 'a4111111-1111-1111-1111-111111111111';
  get diagnostics n = row_count;
  return n;
exception when others then
  return -1;
end;
$$;

select plan(72);

-- ---------------------------------------------------------------------------
-- A. Schema
-- ---------------------------------------------------------------------------
select has_table ('public', 'check_ins', 'check_ins table exists');
select has_table ('public', 'check_in_destinations', 'check_in_destinations table exists');
select has_table ('public', 'streaks', 'streaks table exists');
select has_table ('public', 'streak_mercy_uses', 'streak_mercy_uses table exists');
select has_table ('public', 'streak_mercy_grants', 'streak_mercy_grants table exists');
select has_table ('public', 'streak_events', 'streak_events table exists');

select ok (public.pgtap_rls_enabled ('public.check_ins'::regclass), 'RLS is enabled on check_ins');
select ok (public.pgtap_rls_forced  ('public.check_ins'::regclass), 'RLS is FORCED on check_ins');
select ok (public.pgtap_rls_enabled ('public.check_in_destinations'::regclass), 'RLS is enabled on check_in_destinations');
select ok (public.pgtap_rls_forced  ('public.check_in_destinations'::regclass), 'RLS is FORCED on check_in_destinations');
select ok (public.pgtap_rls_enabled ('public.streaks'::regclass), 'RLS is enabled on streaks');
select ok (public.pgtap_rls_enabled ('public.streak_mercy_uses'::regclass), 'RLS is enabled on streak_mercy_uses');
select ok (public.pgtap_rls_enabled ('public.streak_mercy_grants'::regclass), 'RLS is enabled on streak_mercy_grants');
select ok (public.pgtap_rls_enabled ('public.streak_events'::regclass), 'RLS is enabled on streak_events');

select has_trigger ('public', 'streaks', 'trg_streaks_updated_at', 'updated_at trigger is attached to streaks');
select has_trigger ('public', 'check_ins', 'trg_check_ins_after_delete', 'delete trigger is attached to check_ins');
select has_trigger ('public', 'check_in_destinations', 'trg_check_in_destinations_fanout', 'fan-out trigger is attached to check_in_destinations');

select has_function ('public', 'submit_check_in', array['practice_kind','text','uuid[]','text','text','date','text']::name[], 'submit_check_in() exists with the contracted signature');
select has_function ('public', 'get_rule_of_life_ring', array['date']::name[], 'get_rule_of_life_ring(date) exists');
select has_function ('public', 'get_streak_summary', 'get_streak_summary() exists');
select has_function ('public', 'get_consistency_heatmap', array['date','date']::name[], 'get_consistency_heatmap(date, date) exists');
select has_function ('public', 'get_group_progress', array['uuid']::name[], 'get_group_progress(uuid) exists');
select has_function ('public', 'use_streak_mercy', array['date']::name[], 'use_streak_mercy(date) exists');
select has_function ('public', 'on_check_in_destination_fanout', 'on_check_in_destination_fanout() exists');

-- ---------------------------------------------------------------------------
-- B. THE PRIVACY GATE — table CHECK constraints (direct inserts)
-- ---------------------------------------------------------------------------
insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone, reflection_text)
values ('a4111111-1111-1111-1111-111111111111', 'rosary', 'group', current_date, 'UTC', 'Amen');

select ok (
  (select count(*)::int from public.check_ins
    where user_id = 'a4111111-1111-1111-1111-111111111111'
      and practice_kind = 'rosary' and sharing = 'group'
      and reflection_text = 'Amen') = 1,
  'a group check-in MAY carry a reflection');

select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone, reflection_text)
    values ('a4111111-1111-1111-1111-111111111111', 'rosary', 'private', current_date, 'UTC', 'secret diary')$$,
  '23514',
  'new row for relation "check_ins" violates check constraint "check_ins_private_has_no_content_ck"',
  'a private check-in with a reflection is REJECTED');

select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone, photo_path)
    values ('a4111111-1111-1111-1111-111111111111', 'rosary', 'private', current_date, 'UTC', 'witness-photos/a.png')$$,
  '23514',
  'new row for relation "check_ins" violates check constraint "check_ins_private_has_no_content_ck"',
  'a private check-in with a photo is REJECTED');

select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone)
    values ('a4111111-1111-1111-1111-111111111111', 'confession', 'group', current_date, 'UTC')$$,
  '23514',
  'new row for relation "check_ins" violates check constraint "check_ins_confession_is_private_ck"',
  'a confession check-in with sharing = group is REJECTED');

insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone)
values ('a4111111-1111-1111-1111-111111111111', 'confession', 'private', current_date, 'UTC');

select ok (
  (select count(*)::int from public.check_ins
    where user_id = 'a4111111-1111-1111-1111-111111111111'
      and practice_kind = 'confession' and sharing = 'private'
      and reflection_text is null and photo_path is null) = 1,
  'a confession check-in with sharing = private is accepted (and carries no content)');

select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone, photo_path)
    values ('a4111111-1111-1111-1111-111111111111', 'adoration', 'group', current_date, 'UTC', 'evil/path.png')$$,
  '23514',
  'new row for relation "check_ins" violates check constraint "check_ins_photo_path_check"',
  'a photo_path outside the witness-photos/ bucket is REJECTED');

select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone, reflection_text)
    values ('a4111111-1111-1111-1111-111111111111', 'adoration', 'group', current_date, 'UTC', repeat('x', 2001))$$,
  '23514',
  'new row for relation "check_ins" violates check constraint "check_ins_reflection_text_check"',
  'a reflection longer than 2000 characters is REJECTED');

select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone)
    values ('a4111111-1111-1111-1111-111111111111', 'rosary', 'group', current_date, 'UTC')$$,
  '23505',
  'duplicate key value violates unique constraint "check_ins_user_practice_day_uniq"',
  'a second check-in for the same (user, practice, local_date) is REJECTED');

-- clean the direct inserts so the RPC section starts from a known state
delete from public.check_ins
 where user_id = 'a4111111-1111-1111-1111-111111111111'
   and local_date = current_date;

-- ---------------------------------------------------------------------------
-- C. submit_check_in — the engine
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a4111111-1111-1111-1111-111111111111","role":"authenticated","email":"alice@example.test"}';

-- C.1 private ---------------------------------------------------------------
select ok (
  (select (public.submit_check_in ('rosary', 'private', null, null, null, current_date - 1)) ->> 'check_in_id') is not null,
  'submit_check_in: a private check-in returns a check_in_id');

select ok (
  (select count(*)::int from public.check_ins
    where user_id = auth.uid() and practice_kind = 'rosary' and local_date = current_date - 1
      and sharing = 'private'
      and reflection_text is null and photo_path is null) = 1,
  'submit_check_in: a private check-in is stored with NULL reflection and NULL photo');

select is (
  (select count(*)::int from public.check_in_destinations d
     join public.check_ins c on c.id = d.check_in_id
    where c.user_id = auth.uid() and c.local_date = current_date - 1),
  0,
  'submit_check_in: a private check-in creates ZERO destination rows (the privacy boundary)');

select is (
  (select points from public.check_ins
    where user_id = auth.uid() and practice_kind = 'rosary' and local_date = current_date - 1
      and sharing = 'private'),
  0,
  'submit_check_in: a private check-in scores 0 points');

select throws_ok (
  $$select public.submit_check_in ('adoration', 'private', null, 'my private fruit', null, current_date - 1)$$,
  '22023',
  'private_check_in_cannot_hold_content',
  'submit_check_in: a private check-in with a reflection is REJECTED');

select throws_ok (
  $$select public.submit_check_in ('adoration', 'private', null, null, 'witness-photos/a.png', current_date - 1)$$,
  '22023',
  'private_check_in_cannot_hold_content',
  'submit_check_in: a private check-in with a photo is REJECTED');

select throws_ok (
  $$select public.submit_check_in ('confession', 'group', array['a4555555-5555-5555-5555-555555555555'::uuid], null, null, current_date - 1)$$,
  '22023',
  'confession_is_private_only',
  'submit_check_in: a confession cannot be shared with a group (Confession Safeguard)');

select ok (
  (select (public.submit_check_in ('confession', 'private', null, null, null, current_date - 1)) ->> 'check_in_id') is not null,
  'submit_check_in: a confession can be recorded as a private check-in');

select ok (
  (select count(*)::int from public.check_ins
    where user_id = auth.uid() and practice_kind = 'confession' and local_date = current_date - 1
      and sharing = 'private' and reflection_text is null and photo_path is null) = 1,
  'submit_check_in: a confession is stored as private, with no content');

select throws_ok (
  $$select public.submit_check_in ('rosary', 'everyone', null, null, null, current_date - 1)$$,
  '22023',
  'invalid_sharing',
  'submit_check_in: an unknown sharing value is REJECTED');

-- C.2 group -----------------------------------------------------------------
select throws_ok (
  $$select public.submit_check_in ('rosary', 'group', '{}'::uuid[], 'fruit', null, current_date - 3)$$,
  '22023',
  'group_sharing_requires_destination',
  'submit_check_in: a group check-in without a destination is REJECTED');

select throws_ok (
  $$select public.submit_check_in ('rosary', 'group', array['a4888888-8888-8888-8888-888888888888'::uuid], 'fruit', null, current_date - 4)$$,
  '42501',
  'not_a_group_member',
  'submit_check_in: a group the caller does not belong to is REJECTED');

select throws_ok (
  $$select public.submit_check_in ('rosary', 'group', array['a4666666-6666-6666-6666-666666666666'::uuid], null, null, current_date - 5)$$,
  '22023',
  'group_sharing_requirement_not_met',
  'submit_check_in: a written_fruit group without a reflection is REJECTED');

select throws_ok (
  $$select public.submit_check_in ('rosary', 'group', array['a4777777-7777-7777-7777-777777777777'::uuid], 'fruit', null, current_date - 6)$$,
  '22023',
  'group_sharing_requirement_not_met',
  'submit_check_in: a photo_witness group without a photo is REJECTED');

select ok (
  (select (public.submit_check_in ('rosary', 'group', array['a4555555-5555-5555-5555-555555555555'::uuid], 'Amen', null, current_date - 2)) ->> 'check_in_id') is not null,
  'submit_check_in: an open group accepts a check-in with a reflection');

select ok (
  (select count(*)::int from public.check_in_destinations d
     join public.check_ins c on c.id = d.check_in_id
    where c.user_id = auth.uid() and c.practice_kind = 'rosary' and c.sharing = 'group'
      and d.group_id = 'a4555555-5555-5555-5555-555555555555') = 1,
  'submit_check_in: the destination row is created for the open group');

select ok (
  (select (public.submit_check_in ('holy_mass', 'group', array['a4666666-6666-6666-6666-666666666666'::uuid], 'Fruit of the Mass', null, current_date - 2)) ->> 'check_in_id') is not null,
  'submit_check_in: a written_fruit group accepts a check-in WITH a reflection');

select ok (
  (select (public.submit_check_in ('adoration', 'group', array['a4777777-7777-7777-7777-777777777777'::uuid], 'Witness', 'witness-photos/x.png', current_date - 2)) ->> 'check_in_id') is not null,
  'submit_check_in: a photo_witness group accepts a check-in WITH a reflection AND a photo');

select is (
  (select count(*)::int from public.check_in_destinations d
     join public.check_ins c on c.id = d.check_in_id
    where c.user_id = auth.uid() and c.sharing = 'group'),
  3,
  'submit_check_in: exactly 3 destination rows exist for the 3 group check-ins');

select throws_ok (
  $$select public.submit_check_in ('rosary', 'group', array['a4555555-5555-5555-5555-555555555555'::uuid], 'Amen', null, current_date - 2)$$,
  '23505',
  'already_checked_in_today',
  'submit_check_in: a duplicate (practice, local_date) is REJECTED');

select throws_ok (
  $$select public.submit_check_in ('fasting', 'private', null, null, null, current_date + 5)$$,
  '22023',
  'local_date_in_future',
  'submit_check_in: a local_date in the future is REJECTED');

select throws_ok (
  $$select public.submit_check_in ('fasting', 'private', null, null, null, current_date - 400)$$,
  '22023',
  'local_date_too_old',
  'submit_check_in: a local_date older than one year is REJECTED');

select throws_ok (
  $$select public.submit_check_in ('fasting', 'private', null, null, null, current_date - 1, 'Mars/Olympus')$$,
  '22023',
  'invalid_timezone',
  'submit_check_in: an unknown timezone is REJECTED');

-- ---------------------------------------------------------------------------
-- D. RLS
-- ---------------------------------------------------------------------------
select ok (not pg_temp.try_insert_check_in (), 'RLS: an authenticated user cannot INSERT a check_in directly');
select ok (not pg_temp.try_insert_destination (), 'RLS: an authenticated user cannot INSERT a check_in_destinations row directly');
select is  (pg_temp.try_update_alice_check_in (), 0, 'RLS: there is no client UPDATE policy — a check_in is immutable');

select is (
  (select count(*)::int from public.check_ins where user_id = auth.uid()),
  5,
  'RLS: the owner reads their own 5 check-ins');

set local request.jwt.claims = '{"sub":"a4222222-2222-2222-2222-222222222222","role":"authenticated","email":"bob@example.test"}';

select is (
  (select count(*)::int from public.check_ins),
  0,
  'RLS: another authenticated user cannot read someone else check-ins');

select is (
  (select count(*)::int from public.check_in_destinations),
  1,
  'RLS: a group member reads the destination rows of their own group');

select is (
  (select count(*)::int from public.streaks),
  0,
  'RLS: another authenticated user cannot read someone else streak');

select is (
  (select count(*)::int from public.streak_events),
  0,
  'RLS: another authenticated user cannot read someone else streak events');

select is (
  pg_temp.try_delete_alice_check_in (),
  0,
  'RLS: another authenticated user cannot DELETE someone else check-ins');

reset role;
set local request.jwt.claims = '{}';
set local role anon;

select is (
  (select count(*)::int from public.check_ins),
  0,
  'RLS: anon cannot read any check-in');

select is (
  (select count(*)::int from public.check_in_destinations),
  0,
  'RLS: anon cannot read any destination row');

reset role;
set local request.jwt.claims = '{}';

-- ---------------------------------------------------------------------------
-- E. Feed fan-out (defensive: A5's public.feed_posts may not exist yet)
-- ---------------------------------------------------------------------------
select ok (
  case
    when to_regclass ('public.feed_posts') is null then true
    else (select count(*)::int from public.feed_posts fp
           join public.check_ins c on c.id = fp.check_in_id
          where c.user_id = 'a4111111-1111-1111-1111-111111111111') = 3
  end,
  'fan-out: the 3 group check-ins produced 3 feed_posts rows');

select ok (
  case
    when to_regclass ('public.feed_posts') is null then true
    else (select count(*)::int from public.feed_posts fp
           join public.check_ins c on c.id = fp.check_in_id
          where c.user_id = 'a4111111-1111-1111-1111-111111111111'
            and c.sharing = 'private') = 0
  end,
  'fan-out: a private check-in NEVER produces a feed_posts row');

select ok (
  case
    when to_regclass ('public.feed_posts') is null then true
    else (select count(*)::int from public.feed_posts where reflection_text is null and photo_path is null) = 0
  end,
  'fan-out: every feed_posts row carries the group check-in content');

-- ---------------------------------------------------------------------------
-- F. DELETE own check-ins (the delete trigger keeps the streak consistent)
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a4111111-1111-1111-1111-111111111111","role":"authenticated","email":"alice@example.test"}';

select is (
  pg_temp.try_delete_alice_check_in (),
  5,
  'DELETE: the owner may delete their own check-ins');

reset role;
set local request.jwt.claims = '{}';

select is (
  (select count(*)::int from public.check_ins where user_id = 'a4111111-1111-1111-1111-111111111111'),
  0,
  'DELETE: the check-ins are gone');

select is (
  (select current_streak from public.streaks where user_id = 'a4111111-1111-1111-1111-111111111111'),
  0,
  'DELETE: the delete trigger recomputed the streak to 0');

-- ---------------------------------------------------------------------------
-- Verdict
-- ---------------------------------------------------------------------------
select * from finish ();
select public.pgtap_summary () as result;

rollback;
