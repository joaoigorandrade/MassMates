-- =============================================================================
-- A10 · my_groups.sql · public.my_groups()
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
--
-- WHAT IT PROVES
--   A. the function exists, in the private + INVOKER pattern, and `anon`
--      cannot execute it
--   B. the admin's view: the ACTIVE groups, the running challenge first, the
--      invite code PRESENT
--   C. the plain member's view: the invite code is NULL
--   D. an archived group, an expired challenge, a blocked member and an
--      outsider get NOTHING
--   E. the documented JSON shape
--
--   Fixture
--     u1 Ana    e2000000-0000-0000-0000-000000000001  admin  of G1/G2/G3/G4
--     u2 Bruno  e2000000-0000-0000-0000-000000000002  member of G1
--     u3 Carla  e2000000-0000-0000-0000-000000000003  outsider
--     u4 Daniel e2000000-0000-0000-0000-000000000004  member of G1, BLOCKED by u1
--     u5 Eva    e2000000-0000-0000-0000-000000000005  member of G2 (archived) / G3 (expired)
--     G1       e2000000-0000-0000-0000-000000000101  'Gap Frat'     fraternity
--     G2       e2000000-0000-0000-0000-000000000102  'Gap Archived' archived
--     G3       e2000000-0000-0000-0000-000000000103  'Gap Expired'  challenge, season over
--     G4       e2000000-0000-0000-0000-000000000104  'Gap Live'     challenge, running, FEATURED
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(26);

-- -----------------------------------------------------------------------------
-- A. Structure
-- -----------------------------------------------------------------------------

select ok (to_regprocedure ('public.my_groups ()') is not null,
           'public.my_groups() exists');
select ok (to_regprocedure ('private.my_groups_impl ()') is not null,
           'private.my_groups_impl() exists');
select ok (not has_function_privilege ('anon', 'public.my_groups ()', 'execute'),
           'anon may not execute public.my_groups()');
select ok (has_function_privilege ('authenticated', 'public.my_groups ()', 'execute'),
           'authenticated may execute public.my_groups()');
select ok ((select p.prosecdef from pg_catalog.pg_proc p
             join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'my_groups') is false,
           'public.my_groups() is SECURITY INVOKER (the body lives in private)');
select ok ((select p.prosecdef from pg_catalog.pg_proc p
             join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'private' and p.proname = 'my_groups_impl') is true,
           'private.my_groups_impl() is SECURITY DEFINER');
select ok ((select p.proconfig from pg_catalog.pg_proc p
             join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'private' and p.proname = 'my_groups_impl') @> array['search_path=""'],
           'private.my_groups_impl() pins search_path = ''''');

set local role authenticated;
set local request.jwt.claims = '{}';

select throws_ok ($$select public.my_groups ()$$,
                  '42501', 'authentication required',
                  'my_groups rejects a caller with no identity');

reset role;

-- -----------------------------------------------------------------------------
-- Fixture
-- -----------------------------------------------------------------------------

insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('e2000000-0000-0000-0000-000000000001', 'gap_ana@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e2000000-0000-0000-0000-000000000002', 'gap_bruno@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e2000000-0000-0000-0000-000000000003', 'gap_carla@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e2000000-0000-0000-0000-000000000004', 'gap_daniel@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e2000000-0000-0000-0000-000000000005', 'gap_eva@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.groups (id, name, description, created_by, invite_code, group_type, starts_on, ends_on, archived_at)
values
  ('e2000000-0000-0000-0000-000000000101', 'Gap Frat',     'a fraternity', 'e2000000-0000-0000-0000-000000000001', '345101', 'fraternity', null, null, null),
  ('e2000000-0000-0000-0000-000000000102', 'Gap Archived', 'archived',     'e2000000-0000-0000-0000-000000000001', '345102', 'fraternity', null, null, now()),
  ('e2000000-0000-0000-0000-000000000103', 'Gap Expired',  'season over', 'e2000000-0000-0000-0000-000000000001', '345103', 'challenge',  current_date - 10, current_date - 1, null),
  ('e2000000-0000-0000-0000-000000000104', 'Gap Live',     'running',      'e2000000-0000-0000-0000-000000000001', '345104', 'challenge',  current_date - 1,  current_date + 10, null);

insert into public.group_members (group_id, user_id, role)
values
  ('e2000000-0000-0000-0000-000000000101', 'e2000000-0000-0000-0000-000000000001', 'admin'),
  ('e2000000-0000-0000-0000-000000000101', 'e2000000-0000-0000-0000-000000000002', 'member'),
  ('e2000000-0000-0000-0000-000000000101', 'e2000000-0000-0000-0000-000000000004', 'member'),
  ('e2000000-0000-0000-0000-000000000102', 'e2000000-0000-0000-0000-000000000001', 'admin'),
  ('e2000000-0000-0000-0000-000000000102', 'e2000000-0000-0000-0000-000000000005', 'member'),
  ('e2000000-0000-0000-0000-000000000103', 'e2000000-0000-0000-0000-000000000001', 'admin'),
  ('e2000000-0000-0000-0000-000000000103', 'e2000000-0000-0000-0000-000000000005', 'member'),
  ('e2000000-0000-0000-0000-000000000104', 'e2000000-0000-0000-0000-000000000001', 'admin');

insert into public.group_featured (group_id) values ('e2000000-0000-0000-0000-000000000104');

-- u1 (the creator of G1) blocks u4
insert into public.user_blocks (blocker_id, blocked_id)
values ('e2000000-0000-0000-0000-000000000001', 'e2000000-0000-0000-0000-000000000004');

create function pg_temp.mg_keys (j jsonb)
  returns text
  language sql
  stable
as $$
  select coalesce (string_agg (k, ',' order by k), '') from jsonb_object_keys (j) k;
$$;

-- -----------------------------------------------------------------------------
-- B. The ADMIN's view (u1)
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"e2000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is ((select count (*) from jsonb_array_elements (public.my_groups () -> 'items')), 2::bigint,
           'the admin sees exactly the two ACTIVE groups (G1 + the running challenge)');
select is ((public.my_groups () -> 'items' -> 0 ->> 'id'), 'e2000000-0000-0000-0000-000000000104',
           'the running challenge comes first');
select is ((public.my_groups () -> 'items' -> 1 ->> 'id'), 'e2000000-0000-0000-0000-000000000101',
           'the fraternity comes second');
select is ((public.my_groups () -> 'items' -> 1 ->> 'role'), 'admin',
           'the role of the caller is reported');
select is ((public.my_groups () -> 'items' -> 1 ->> 'invite_code'), '345101',
           'the ADMIN receives the invite code');
select is ((public.my_groups () -> 'items' -> 0 ->> 'is_featured'), 'true',
           'the featured challenge is flagged is_featured');
select is ((public.my_groups () -> 'items' -> 1 ->> 'member_count'), '3',
           'member_count counts every member of the group');
select is ((select count (*) from jsonb_array_elements (public.my_groups () -> 'items') i
             where i ->> 'id' in ('e2000000-0000-0000-0000-000000000102',
                                  'e2000000-0000-0000-0000-000000000103')), 0::bigint,
           'the archived group and the expired challenge are EXCLUDED');

-- -----------------------------------------------------------------------------
-- C. The plain MEMBER's view (u2) -- the invite code must stay hidden
-- -----------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"e2000000-0000-0000-0000-000000000002","role":"authenticated"}';

select is ((select count (*) from jsonb_array_elements (public.my_groups () -> 'items')), 1::bigint,
           'the plain member sees only the group he belongs to');
select ok ((public.my_groups () -> 'items' -> 0 ->> 'invite_code') is null,
           'a plain member NEVER receives the invite code');
select is ((public.my_groups () -> 'items' -> 0 ->> 'role'), 'member',
           'the role of a plain member is reported');
select is ((public.my_groups () -> 'items' -> 0 ->> 'member_count'), '3',
           'the member sees the same member_count');

-- -----------------------------------------------------------------------------
-- D. The exclusions
-- -----------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"e2000000-0000-0000-0000-000000000004","role":"authenticated"}';

select is ((select count (*) from jsonb_array_elements (public.my_groups () -> 'items')), 0::bigint,
           'a member blocked by the group''s creator gets NOTHING');

set local request.jwt.claims = '{"sub":"e2000000-0000-0000-0000-000000000005","role":"authenticated"}';

select is ((select count (*) from jsonb_array_elements (public.my_groups () -> 'items')), 0::bigint,
           'a member of only the archived + expired groups gets NOTHING');

set local request.jwt.claims = '{"sub":"e2000000-0000-0000-0000-000000000003","role":"authenticated"}';

select is ((select count (*) from jsonb_array_elements (public.my_groups () -> 'items')), 0::bigint,
           'an outsider gets NOTHING');

-- -----------------------------------------------------------------------------
-- E. The documented JSON shape
-- -----------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"e2000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is (pg_temp.mg_keys (public.my_groups ()), 'items',
           'the answer is exactly { items }');
select is (pg_temp.mg_keys (public.my_groups () -> 'items' -> 0),
           'archived_at,cover_path,description,ends_on,goal_target,group_type,id,invite_code,is_featured,member_count,name,role,scoring_mode,sharing_requirement,starts_on',
           'the item carries exactly the documented keys');
select ok (jsonb_typeof (public.my_groups () -> 'items' -> 0 -> 'member_count') = 'number'
           and jsonb_typeof (public.my_groups () -> 'items' -> 0 -> 'is_featured') = 'boolean'
           and jsonb_typeof (public.my_groups () -> 'items' -> 0 -> 'invite_code') = 'string',
           'the numeric / boolean / nullable fields have the right JSON type');

reset role;

select * from finish ();
select public.pgtap_summary () as result;

rollback;
