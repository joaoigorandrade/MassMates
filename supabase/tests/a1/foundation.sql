-- =============================================================================
-- A1 · foundation.sql · schema foundation test suite
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish();
--   select public.pgtap_summary() as result;   -- always the last result set
--   rollback;
-- `public.pgtap_summary()` is the verdict: {"verdict":"PASS"|"FAIL", ...}.
-- =============================================================================

begin;
set local search_path = extensions, public;

-- Helper: exact, ordered label list of an enum.
create function pg_temp.enum_labels (p_schema text, p_type text)
  returns text[]
  language sql
  stable
as $$
  select array_agg (e.enumlabel::text order by e.enumsortorder)
  from pg_catalog.pg_type t
  join pg_catalog.pg_namespace n on n.oid = t.typnamespace
  join pg_catalog.pg_enum e on e.enumtypid = t.oid
  where n.nspname = p_schema and t.typname = p_type;
$$;

-- Helper: SECURITY INVOKER, so it runs with the CURRENT role and therefore
-- with the current RLS policies. Returns true when the insert was ALLOWED.
create function pg_temp.insert_third_party ()
  returns boolean
  language plpgsql
as $$
begin
  insert into public.group_members (group_id, user_id)
  values ('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333');
  return true;
exception
  when others then
    return false;
end;
$$;

select plan(81);

-- ---------------------------------------------------------------------------
-- A. Extensions
-- ---------------------------------------------------------------------------
select has_extension ('extensions', 'pgcrypto', 'pgcrypto is installed in schema extensions');
select has_extension ('pg_catalog', 'pg_cron', 'pg_cron is installed (pg_catalog, own schema cron)');
select has_extension ('extensions', 'pg_net', 'pg_net is installed in schema extensions');
select has_extension ('extensions', 'pgtap', 'pgtap is installed in schema extensions');

-- ---------------------------------------------------------------------------
-- B. Enums — exact value sets
-- ---------------------------------------------------------------------------
select has_enum ('public', 'group_type', 'group_type enum exists');
select has_enum ('public', 'scoring_mode', 'scoring_mode enum exists');
select has_enum ('public', 'sharing_requirement', 'sharing_requirement enum exists');
select has_enum ('public', 'member_role', 'member_role enum exists');
select has_enum ('public', 'liturgical_season', 'liturgical_season enum exists');
select has_enum ('public', 'practice_kind', 'practice_kind enum exists');

select ok (pg_temp.enum_labels ('public', 'group_type') = array['fraternity', 'challenge'], 'group_type has exactly [fraternity, challenge]');
select ok (pg_temp.enum_labels ('public', 'scoring_mode') = array['faithful_days', 'collective_treasure', 'custom_points'], 'scoring_mode has exactly [faithful_days, collective_treasure, custom_points]');
select ok (pg_temp.enum_labels ('public', 'sharing_requirement') = array['open', 'written_fruit', 'photo_witness'], 'sharing_requirement has exactly [open, written_fruit, photo_witness]');
select ok (pg_temp.enum_labels ('public', 'member_role') = array['admin', 'member'], 'member_role has exactly [admin, member]');
select ok (pg_temp.enum_labels ('public', 'liturgical_season') = array['advent', 'christmas', 'lent', 'easter', 'ordinary_time'], 'liturgical_season has exactly [advent, christmas, lent, easter, ordinary_time]');
select ok (pg_temp.enum_labels ('public', 'practice_kind') = array['rosary', 'holy_mass', 'daily_gospel', 'adoration', 'mental_prayer', 'spiritual_reading', 'fasting', 'confession'], 'practice_kind has exactly [rosary, holy_mass, daily_gospel, adoration, mental_prayer, spiritual_reading, fasting, confession]');

-- ---------------------------------------------------------------------------
-- C. Foundation tables + exact column lists
-- ---------------------------------------------------------------------------
select has_table ('public', 'profiles', 'profiles table exists');
select has_table ('public', 'groups', 'groups table exists');
select has_table ('public', 'group_members', 'group_members table exists');
select has_table ('public', 'user_blocks', 'user_blocks table exists');

select ok (
  (select array_agg (c.column_name::text order by c.ordinal_position)
   from information_schema.columns c
   where c.table_schema = 'public' and c.table_name = 'profiles')
  = array['id', 'display_name', 'avatar_path', 'parish', 'city', 'timezone', 'locale',
          'ad_consent_analytics', 'ad_personalization', 'rule_of_life', 'guardian_angel_opt_in',
          'created_at', 'updated_at', 'deleted_at'],
  'profiles has exactly the expected columns');

select ok (
  (select array_agg (c.column_name::text order by c.ordinal_position)
   from information_schema.columns c
   where c.table_schema = 'public' and c.table_name = 'groups')
  = array['id', 'name', 'description', 'group_type', 'scoring_mode', 'sharing_requirement',
          'cover_path', 'invite_code', 'starts_on', 'ends_on', 'goal_target', 'created_by',
          'created_at', 'updated_at', 'archived_at'],
  'groups has exactly the expected columns');

select ok (
  (select array_agg (c.column_name::text order by c.ordinal_position)
   from information_schema.columns c
   where c.table_schema = 'public' and c.table_name = 'group_members')
  = array['id', 'group_id', 'user_id', 'role', 'joined_at'],
  'group_members has exactly the expected columns');

select ok (
  (select array_agg (c.column_name::text order by c.ordinal_position)
   from information_schema.columns c
   where c.table_schema = 'public' and c.table_name = 'user_blocks')
  = array['id', 'blocker_id', 'blocked_id', 'created_at'],
  'user_blocks has exactly the expected columns');

-- ---------------------------------------------------------------------------
-- D. RLS enabled + forced on every foundation table
-- ---------------------------------------------------------------------------
select ok (public.pgtap_rls_enabled ('public.profiles'::regclass), 'RLS is enabled on profiles');
select ok (public.pgtap_rls_enabled ('public.groups'::regclass), 'RLS is enabled on groups');
select ok (public.pgtap_rls_enabled ('public.group_members'::regclass), 'RLS is enabled on group_members');
select ok (public.pgtap_rls_enabled ('public.user_blocks'::regclass), 'RLS is enabled on user_blocks');
select ok (public.pgtap_rls_forced ('public.profiles'::regclass), 'RLS is FORCED on profiles');
select ok (public.pgtap_rls_forced ('public.groups'::regclass), 'RLS is FORCED on groups');
select ok (public.pgtap_rls_forced ('public.group_members'::regclass), 'RLS is FORCED on group_members');
select ok (public.pgtap_rls_forced ('public.user_blocks'::regclass), 'RLS is FORCED on user_blocks');

-- ---------------------------------------------------------------------------
-- E. RLS helper functions exist with the contracted signature
-- ---------------------------------------------------------------------------
select has_function ('public', 'current_user_id', 'current_user_id() exists');
-- A10 / migration 0900: the RLS helpers are SELF-SCOPED. The two-argument
-- forms (which let a signed-in user enumerate arbitrary group membership and
-- the block graph) were removed; the privileged bodies live in `private`.
select has_function ('public', 'is_group_member', array['uuid']::name[], 'is_group_member(uuid) exists (self-scoped)');
select has_function ('public', 'is_group_admin', array['uuid']::name[], 'is_group_admin(uuid) exists (self-scoped)');
select has_function ('public', 'is_group_member_of_any', 'is_group_member_of_any() exists (self-scoped)');
select has_function ('public', 'is_any_group_admin', 'is_any_group_admin() exists (self-scoped)');
select has_function ('public', 'is_blocked', array['uuid']::name[], 'is_blocked(uuid) exists (self-scoped)');
select has_function ('public', 'set_updated_at', 'set_updated_at() exists');
select has_function ('public', 'attach_updated_at', array['regclass']::name[], 'attach_updated_at(regclass) exists');
select has_function ('public', 'pgtap_summary', 'pgtap_summary() exists');

-- ---------------------------------------------------------------------------
-- F. Fixture — 4 users, 1 group, 2 memberships, 1 block
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('11111111-1111-1111-1111-111111111111', 'a1_admin@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('22222222-2222-2222-2222-222222222222', 'a1_member@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('33333333-3333-3333-3333-333333333333', 'a1_outsider@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('44444444-4444-4444-4444-444444444444', 'a1_blocker@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

-- A2 (migration 0101) attaches `on_auth_user_created` to auth.users, so the
-- rows above already got a profile from the trigger. The fixture therefore
-- upserts instead of inserting.
insert into public.profiles (id, display_name)
values
  ('11111111-1111-1111-1111-111111111111', 'Admin'),
  ('22222222-2222-2222-2222-222222222222', 'Member'),
  ('33333333-3333-3333-3333-333333333333', 'Outsider'),
  ('44444444-4444-4444-4444-444444444444', 'Blocker')
on conflict (id) do update set display_name = excluded.display_name;

insert into public.groups (id, name, created_by)
values ('55555555-5555-5555-5555-555555555555', 'A1 Test Group', '11111111-1111-1111-1111-111111111111');

insert into public.group_members (group_id, user_id, role)
values
  ('55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111', 'admin'),
  ('55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222', 'member');

insert into public.user_blocks (blocker_id, blocked_id)
values ('44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111');

-- ---------------------------------------------------------------------------
-- G. Membership helpers (explicit user id)
--     A10 / migration 0900: the PUBLIC helpers are self-scoped (they always
--     use auth.uid()). The two-user logic now lives in the non-exposed
--     `private.is_*_impl` functions, which the server code calls directly.
--     These assertions exercise that logic.
-- ---------------------------------------------------------------------------
select ok (private.is_group_member_impl ('55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111'), 'is_group_member: admin is a member');
select ok (private.is_group_member_impl ('55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222'), 'is_group_member: member is a member');
select ok (not private.is_group_member_impl ('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333'), 'is_group_member: non-member is not a member');
select ok (not private.is_group_member_impl ('55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444'), 'is_group_member: blocker is not a member');
select ok (not private.is_group_member_impl ('55555555-5555-5555-5555-555555555555', null), 'is_group_member: null user (anon) is not a member');
select ok (private.is_group_admin_impl ('55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111'), 'is_group_admin: admin is an admin');
select ok (not private.is_group_admin_impl ('55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222'), 'is_group_admin: plain member is not an admin');
select ok (not private.is_group_admin_impl ('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333'), 'is_group_admin: outsider is not an admin');
select ok (not private.is_group_admin_impl ('55555555-5555-5555-5555-555555555555', null), 'is_group_admin: null user (anon) is not an admin');
select ok (private.is_group_member_of_any_impl ('22222222-2222-2222-2222-222222222222'), 'is_group_member_of_any: member belongs to a group');
select ok (not private.is_group_member_of_any_impl ('33333333-3333-3333-3333-333333333333'), 'is_group_member_of_any: outsider belongs to no group');
select ok (private.is_any_group_admin_impl ('11111111-1111-1111-1111-111111111111'), 'is_any_group_admin: admin of a group');
select ok (not private.is_any_group_admin_impl ('22222222-2222-2222-2222-222222222222'), 'is_any_group_admin: plain member is admin of no group');

-- ---------------------------------------------------------------------------
-- H. Blocking (symmetric)
-- ---------------------------------------------------------------------------
select ok (private.is_blocked_impl ('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444'), 'is_blocked: blocked user sees the block');
select ok (private.is_blocked_impl ('44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111'), 'is_blocked: blocker sees the block (symmetric)');
select ok (not private.is_blocked_impl ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333'), 'is_blocked: unrelated users are not blocked');
select ok (not private.is_blocked_impl ('11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'), 'is_blocked: a user is not blocked by themselves');

-- ---------------------------------------------------------------------------
-- I. Caller identity through the JWT GUC (default arguments)
-- ---------------------------------------------------------------------------
select ok (public.current_user_id () is null, 'current_user_id: null without a JWT (anon)');

set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select ok (public.current_user_id () = '22222222-2222-2222-2222-222222222222'::uuid, 'current_user_id: returns the JWT sub');
select ok (public.is_group_member ('55555555-5555-5555-5555-555555555555'), 'is_group_member default arg: member sees themselves as a member');
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
select ok (not public.is_group_member ('55555555-5555-5555-5555-555555555555'), 'is_group_member default arg: outsider is not a member');
set local request.jwt.claims = '{}';
select ok (not public.is_group_member ('55555555-5555-5555-5555-555555555555'), 'is_group_member default arg: anon (no sub) is not a member');
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
select ok (not public.is_group_admin ('55555555-5555-5555-5555-555555555555'), 'is_group_admin default arg: outsider is not an admin');
set local request.jwt.claims = '{}';
-- ---------------------------------------------------------------------------
-- J. RLS behaviour under the `authenticated` role
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select ok ((select count(*) from public.profiles where id = '22222222-2222-2222-2222-222222222222') = 1, 'RLS: a member can read their own profile');
select ok ((select count(*) from public.profiles where id = '11111111-1111-1111-1111-111111111111') = 1, 'RLS: a member can read a groupmate profile');
select ok ((select count(*) from public.profiles where id = '33333333-3333-3333-3333-333333333333') = 0, 'RLS: a member cannot read an unrelated profile');
select ok ((select count(*) from public.group_members where group_id = '55555555-5555-5555-5555-555555555555') = 2, 'RLS: a member can read the group roster');
select ok ((select count(*) from public.groups where id = '55555555-5555-5555-5555-555555555555') = 1, 'RLS: a member can read a non-archived group');

set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
select ok ((select count(*) from public.profiles where id = '22222222-2222-2222-2222-222222222222') = 0, 'RLS: an outsider cannot read another profile');
select ok ((select count(*) from public.group_members where group_id = '55555555-5555-5555-5555-555555555555') = 0, 'RLS: an outsider cannot read the group roster');
select ok ((select count(*) from public.user_blocks) = 0, 'RLS: a user cannot read somebody else block list');

set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select ok (not pg_temp.insert_third_party (), 'RLS: a member cannot add a third party to the roster');
select ok ((select count(*) from public.group_members where user_id = '33333333-3333-3333-3333-333333333333') = 0, 'RLS: the rejected third-party row was not written');

reset role;
set local request.jwt.claims = '{}';

-- ---------------------------------------------------------------------------
-- K. Trigger: set_updated_at
-- ---------------------------------------------------------------------------
select has_trigger ('public', 'profiles', 'trg_profiles_updated_at', 'updated_at trigger is attached to profiles');
select has_trigger ('public', 'groups', 'trg_groups_updated_at', 'updated_at trigger is attached to groups');
select has_trigger ('public', 'group_members', 'trg_group_members_updated_at', 'updated_at trigger is attached to group_members');

update public.profiles set updated_at = '2000-01-01 00:00:00+00' where id = '22222222-2222-2222-2222-222222222222';
update public.profiles set display_name = 'Member Renamed' where id = '22222222-2222-2222-2222-222222222222';
select ok ((select updated_at from public.profiles where id = '22222222-2222-2222-2222-222222222222') > '2000-01-01 00:00:00+00'::timestamptz, 'set_updated_at refreshes updated_at on UPDATE');

-- ---------------------------------------------------------------------------
-- L. CHECK constraints
-- ---------------------------------------------------------------------------
select throws_ok (
  $$insert into public.profiles (id, display_name) values (gen_random_uuid(), repeat('x', 61))$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_check"',
  'profiles.display_name longer than 60 characters is rejected');

select throws_ok (
  $$insert into public.groups (id, name, invite_code) values (gen_random_uuid(), 'Bad code', '12345')$$,
  '23514',
  'new row for relation "groups" violates check constraint "groups_invite_code_check"',
  'groups.invite_code that is not 6 digits is rejected');

select throws_ok (
  $$insert into public.user_blocks (blocker_id, blocked_id) values ('22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222')$$,
  '23514',
  'new row for relation "user_blocks" violates check constraint "user_blocks_check"',
  'user_blocks rejects a self block');

-- ---------------------------------------------------------------------------
-- Verdict
-- ---------------------------------------------------------------------------
select * from finish ();
select public.pgtap_summary () as result;

rollback;
