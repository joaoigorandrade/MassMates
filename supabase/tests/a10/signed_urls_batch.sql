-- =============================================================================
-- A10 · signed_urls_batch.sql · public.create_signed_witness_urls()
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
--   B. the batch authorises EVERY path with the SAME checks as the single-URL
--      RPC: a valid path, a path of a group the caller does not belong to, a
--      malformed path and a path blocked by the photo owner
--   C. one bad path NEVER fails the batch and NEVER leaks whether the object
--      exists
--   D. the clamps: p_expires_in -> 60..3600, at most 50 paths
--   E. A6's single-URL RPC is UNCHANGED
--
--   Fixture
--     u1 Ana    e4000000-0000-0000-0000-000000000001  admin of G1, BLOCKED by u4
--     u2 Bruno  e4000000-0000-0000-0000-000000000002  member of G1
--     u3 Carla  e4000000-0000-0000-0000-000000000003  outsider
--     u4 Daniel e4000000-0000-0000-0000-000000000004  admin of G2, blocks u1
--     G1       e4000000-0000-0000-0000-000000000101
--     G2       e4000000-0000-0000-0000-000000000102
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(37);

-- -----------------------------------------------------------------------------
-- A. Structure
-- -----------------------------------------------------------------------------

select has_function ('public', 'create_signed_witness_urls', array['text[]','integer']::name[],
                     'public.create_signed_witness_urls(text[],integer) exists');
select ok (to_regprocedure ('private.create_signed_witness_urls_impl (text[], integer)') is not null,
           'private.create_signed_witness_urls_impl(text[],integer) exists');
select ok ((select p.prosecdef from pg_catalog.pg_proc p
             join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'create_signed_witness_urls') is false,
           'public.create_signed_witness_urls() is SECURITY INVOKER (the body lives in private)');
select ok ((select p.prosecdef from pg_catalog.pg_proc p
             join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'private' and p.proname = 'create_signed_witness_urls_impl') is true,
           'private.create_signed_witness_urls_impl() is SECURITY DEFINER');
select ok (not has_function_privilege ('anon', 'public.create_signed_witness_urls (text[], integer)', 'execute'),
           'anon may not execute public.create_signed_witness_urls()');
select ok (has_function_privilege ('authenticated', 'public.create_signed_witness_urls (text[], integer)', 'execute'),
           'authenticated may execute public.create_signed_witness_urls()');
select ok (not has_function_privilege ('anon', 'private.create_signed_witness_urls_impl (text[], integer)', 'execute'),
           'anon may not execute the private batch implementation');

-- -----------------------------------------------------------------------------
-- Fixture
-- -----------------------------------------------------------------------------

insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('e4000000-0000-0000-0000-000000000001', 'su_ana@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e4000000-0000-0000-0000-000000000002', 'su_bruno@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e4000000-0000-0000-0000-000000000003', 'su_carla@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e4000000-0000-0000-0000-000000000004', 'su_daniel@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.groups (id, name, created_by)
values
  ('e4000000-0000-0000-0000-000000000101', 'Su One', 'e4000000-0000-0000-0000-000000000001'),
  ('e4000000-0000-0000-0000-000000000102', 'Su Two', 'e4000000-0000-0000-0000-000000000004');

insert into public.group_members (group_id, user_id, role)
values
  ('e4000000-0000-0000-0000-000000000101', 'e4000000-0000-0000-0000-000000000001', 'admin'),
  ('e4000000-0000-0000-0000-000000000101', 'e4000000-0000-0000-0000-000000000002', 'member'),
  ('e4000000-0000-0000-0000-000000000102', 'e4000000-0000-0000-0000-000000000004', 'admin');

-- u4 blocks u1
insert into public.user_blocks (blocker_id, blocked_id)
values ('e4000000-0000-0000-0000-000000000004', 'e4000000-0000-0000-0000-000000000001');

create function pg_temp.su_item (p_paths text[], p_expires integer, p_index integer)
  returns jsonb
  language sql
  stable
as $$
  select public.create_signed_witness_urls (p_paths, p_expires) -> 'items' -> p_index;
$$;

create function pg_temp.su_count (p_paths text[], p_expires integer)
  returns integer
  language sql
  stable
as $$
  select jsonb_array_length (public.create_signed_witness_urls (p_paths, p_expires) -> 'items');
$$;

-- -----------------------------------------------------------------------------
-- B. The batch
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"e4000000-0000-0000-0000-000000000001","role":"authenticated"}';

-- the four paths
select ok ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             300, 0) ->> 'authorized') = 'true',
           'a valid path is authorised');
select ok ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             300, 0) ->> 'signed_url') is null,
           'an authorised path has no signed_url: this deployment has NO SQL signer');
select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             300, 0) ->> 'source'), 'edge_function',
           'the source of an authorised path is the edge_function');
select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             300, 0) ->> 'object_path'),
           'e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg',
           'the authorised path returns the bucket-relative object_path');
select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             300, 0) ->> 'group_id'), 'e4000000-0000-0000-0000-000000000101',
           'the authorised path returns the group id');
select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             300, 0) ->> 'owner_id'), 'e4000000-0000-0000-0000-000000000002',
           'the authorised path returns the owner id');

-- a path of a group the caller does not belong to
select ok ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000102/e4000000-0000-0000-0000-000000000002/cccccccc-cccc-cccc-cccc-cccccccccccc.jpg'],
             300, 0) ->> 'authorized') = 'false',
           'a path of a group the caller does not belong to is NOT authorised');
select ok ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000102/e4000000-0000-0000-0000-000000000002/cccccccc-cccc-cccc-cccc-cccccccccccc.jpg'],
             300, 0) ->> 'signed_url') is null,
           'an unauthorised path has NO signed_url');
select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000102/e4000000-0000-0000-0000-000000000002/cccccccc-cccc-cccc-cccc-cccccccccccc.jpg'],
             300, 0) ->> 'reason'), 'not a member of the group that owns this photo',
           'the reason of a non-member path is the same message as the single-URL RPC');

-- a malformed path
select ok ((pg_temp.su_item (array['not-a-witness-photo.jpg'], 300, 0) ->> 'authorized') = 'false',
           'a malformed path is NOT authorised');
select is ((pg_temp.su_item (array['not-a-witness-photo.jpg'], 300, 0) ->> 'reason'),
           'invalid witness photo path',
           'the reason of a malformed path is the same message as the single-URL RPC');
select ok ((pg_temp.su_item (array['not-a-witness-photo.jpg'], 300, 0) ->> 'signed_url') is null,
           'a malformed path has NO signed_url');

-- a path blocked by the photo owner
select ok ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000004/dddddddd-dddd-dddd-dddd-dddddddddddd.jpg'],
             300, 0) ->> 'authorized') = 'false',
           'a path whose owner blocks the caller is NOT authorised');
select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000004/dddddddd-dddd-dddd-dddd-dddddddddddd.jpg'],
             300, 0) ->> 'reason'), 'blocked by the photo owner',
           'the reason of a blocked path is the same message as the single-URL RPC');

-- the whole batch
select is (pg_temp.su_count (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg',
             'witness-photos/e4000000-0000-0000-0000-000000000102/e4000000-0000-0000-0000-000000000002/cccccccc-cccc-cccc-cccc-cccccccccccc.jpg',
             'not-a-witness-photo.jpg',
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000004/dddddddd-dddd-dddd-dddd-dddddddddddd.jpg'],
             300), 4,
           'the batch returns one item per path and NEVER fails because of a bad path');
select is ((select count (*) from jsonb_array_elements (
              public.create_signed_witness_urls (array[
                'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg',
                'witness-photos/e4000000-0000-0000-0000-000000000102/e4000000-0000-0000-0000-000000000002/cccccccc-cccc-cccc-cccc-cccccccccccc.jpg',
                'not-a-witness-photo.jpg'],
              300) -> 'items') i
            where i ->> 'reason' in ('invalid witness photo path',
                                     'not a member of the group that owns this photo',
                                     'blocked by the photo owner')), 2::bigint,
           'the reasons are the AUTHORISATION messages: they never reveal whether the object exists');

-- -----------------------------------------------------------------------------
-- C. The clamps
-- -----------------------------------------------------------------------------

select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             5, 0) ->> 'expires_in'), '60',
           'p_expires_in = 5 is clamped to 60 seconds');
select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             99999, 0) ->> 'expires_in'), '3600',
           'p_expires_in = 99999 is clamped to 3600 seconds');
select is ((pg_temp.su_item (array[
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg'],
             null, 0) ->> 'expires_in'), '300',
           'p_expires_in = null falls back to 300 seconds');
select is (pg_temp.su_count (array[]::text[], 300), 0,
           'an empty array returns no item');
select is (pg_temp.su_count (null::text[], 300), 0,
           'a null array returns no item (no error)');
select is (pg_temp.su_count ((select array_agg ('witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/'
                                                 || lpad (i::text, 8, '0') || '-0000-0000-0000-000000000000.jpg')
                                from generate_series (1, 60) i), 300), 50,
           'the array size is clamped to 50 paths');
select ok ((public.create_signed_witness_urls ((select array_agg ('witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/'
                                                 || lpad (i::text, 8, '0') || '-0000-0000-0000-000000000000.jpg')
                                from generate_series (1, 60) i), 300) ->> 'truncated') = 'true',
           'a truncated batch is flagged truncated = true');
select ok ((public.create_signed_witness_urls ((select array_agg ('witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/'
                                                 || lpad (i::text, 8, '0') || '-0000-0000-0000-000000000000.jpg')
                                from generate_series (1, 50) i), 300) ->> 'truncated') = 'false',
           'a batch of exactly 50 paths is NOT truncated');

-- -----------------------------------------------------------------------------
-- D. A6's single-URL RPC is UNCHANGED
-- -----------------------------------------------------------------------------

select throws_ok ($$select public.create_signed_witness_url (
                    'witness-photos/e4000000-0000-0000-0000-000000000102/e4000000-0000-0000-0000-000000000002/cccccccc-cccc-cccc-cccc-cccccccccccc.jpg', 300)$$,
                  '42501', 'not a member of the group that owns this photo',
                  'the single-URL RPC still rejects a non-member');
select throws_ok ($$select public.create_signed_witness_url ('not-a-witness-photo.jpg', 300)$$,
                  '22023', 'invalid witness photo path',
                  'the single-URL RPC still rejects a malformed path');
select throws_ok ($$select public.create_signed_witness_url (
                    'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000004/dddddddd-dddd-dddd-dddd-dddddddddddd.jpg', 300)$$,
                  '42501', 'blocked by the photo owner',
                  'the single-URL RPC still rejects a blocked caller');
select is ((public.create_signed_witness_url (
             'witness-photos/e4000000-0000-0000-0000-000000000101/e4000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg', 300) ->> 'source'),
           'edge_function',
           'the single-URL RPC still returns the edge_function source');

reset role;

-- -----------------------------------------------------------------------------
-- E. The anonymous caller
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{}';

select throws_ok ($$select public.create_signed_witness_urls (array['not-a-witness-photo.jpg'], 300)$$,
                  '42501', 'authentication required',
                  'an anonymous caller is rejected');

reset role;

select ok (not has_function_privilege ('anon', 'public.create_signed_witness_url (text, integer)', 'execute'),
           'anon may not execute the single-URL RPC either');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
