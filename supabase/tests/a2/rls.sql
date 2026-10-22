-- =============================================================================
-- A2 · rls.sql · the row level security of the profile surface
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
-- Impersonation pattern: see supabase/tests/README.md §6
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(8);

-- ---------------------------------------------------------------------------
-- Fixture: two signed-up users (the trigger creates their profiles)
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a2f00000-0000-4000-8000-000000000001', 'owner@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a2f00000-0000-4000-8000-000000000002', 'other@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

-- ---------------------------------------------------------------------------
-- A. public.profiles has no client INSERT / DELETE policy (A1, by design)
-- ---------------------------------------------------------------------------
select is (public.pgtap_policy_count ('public.profiles'::regclass, 'a'), 0, 'profiles has NO client INSERT policy');
select is (public.pgtap_policy_count ('public.profiles'::regclass, 'd'), 0, 'profiles has NO client DELETE policy');

-- ---------------------------------------------------------------------------
-- B. anon reads nothing
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{}';

select is ((select count(*) from public.profiles)::int, 0, 'anon cannot read any profile row');
select is ((select count(*) from public.profiles where id = 'a2f00000-0000-4000-8000-000000000001')::int, 0, 'anon cannot read a profile by id');

-- ---------------------------------------------------------------------------
-- C. an authenticated non-owner cannot update another profile
--    The helper is SECURITY INVOKER, so it runs with the current role and the
--    current policies. It returns the number of rows actually updated.
-- ---------------------------------------------------------------------------
reset role;

create function pg_temp.update_other_profile ()
  returns integer
  language plpgsql
as $$
declare
  n integer;
begin
  update public.profiles
     set display_name = 'Hacked'
   where id = 'a2f00000-0000-4000-8000-000000000002';
  get diagnostics n = row_count;
  return n;
end;
$$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"a2f00000-0000-4000-8000-000000000001","role":"authenticated"}';

select is (pg_temp.update_other_profile (), 0, 'a non-owner cannot update another user''s profile');
select lives_ok (
  $$update public.profiles set display_name = 'Owner Updated' where id = 'a2f00000-0000-4000-8000-000000000001'$$,
  'the owner can update their own profile');

reset role;
set local request.jwt.claims = '{}';

select is ((select display_name from public.profiles where id = 'a2f00000-0000-4000-8000-000000000002'), 'other', 'the other profile was not modified');
select is ((select display_name from public.profiles where id = 'a2f00000-0000-4000-8000-000000000001'), 'Owner Updated', 'the owner update was applied');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
