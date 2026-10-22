-- supabase/tests/a3/featured_challenge.sql
-- A3 · featured seasonal challenges (public.join_featured_challenge)
begin;
set local search_path = extensions, public;

select plan(17);

-- -----------------------------------------------------------------------------
-- helpers
-- -----------------------------------------------------------------------------
create function pg_temp.rpc_result (p_sql text)
  returns jsonb
  language plpgsql
  set search_path = ''
as $$
declare
  v jsonb;
begin
  execute p_sql into v;
  return v;
exception when others then
  return null;
end;
$$;

create function pg_temp.rpc_error (p_sql text)
  returns text
  language plpgsql
  set search_path = ''
as $$
begin
  execute p_sql;
  return null;
exception when others then
  return sqlerrm;
end;
$$;

create temporary table pg_temp.a3_ids (
  label       text primary key,
  group_id    uuid,
  invite_code text
) on commit drop;

grant select, insert, update, delete on pg_temp.a3_ids to authenticated, anon;

-- -----------------------------------------------------------------------------
-- fixtures
-- -----------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('11111111-1111-1111-1111-111111111111', 'a3f_alice@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('22222222-2222-2222-2222-222222222222', 'a3f_bob@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.profiles (id, display_name)
values
  ('11111111-1111-1111-1111-111111111111', 'Alice'),
  ('22222222-2222-2222-2222-222222222222', 'Bob')
on conflict (id) do update set display_name = excluded.display_name;

-- ===========================================================================
-- A. Alice creates a challenge and a fraternity
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'challenge_one', (r->'group'->>'id')::uuid, r->>'invite_code'
from (select pg_temp.rpc_result ($q$select public.create_group('A3F Challenge One', null, 'challenge', 'faithful_days', 'open', current_date, current_date + 20)$q$) as r) s
where r is not null;

insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'frat_one', (r->'group'->>'id')::uuid, r->>'invite_code'
from (select pg_temp.rpc_result ($q$select public.create_group('A3F Frat One')$q$) as r) s
where r is not null;

select ok (exists (select 1 from pg_temp.a3_ids where label = 'challenge_one'), 'a challenge is created');
select ok (exists (select 1 from pg_temp.a3_ids where label = 'frat_one'), 'a fraternity is created');

-- ===========================================================================
-- B. publishing a featured challenge (server side)
-- ===========================================================================
reset role;
select ok (
  public.set_featured_group ((select group_id from pg_temp.a3_ids where label = 'challenge_one'), true, current_date, current_date + 20, 1) ->> 'is_featured' = 'true',
  'set_featured_group publishes the challenge');

select ok (
  pg_temp.rpc_error (format ('select public.set_featured_group(%L, true)', (select group_id from pg_temp.a3_ids where label = 'frat_one'))) like '%only a challenge can be featured%',
  'a fraternity can never be featured');

select ok (
  (select count(*) from public.group_featured where group_id = (select group_id from pg_temp.a3_ids where label = 'challenge_one')) = 1,
  'the group_featured link row exists');

-- ===========================================================================
-- C. joining a featured challenge
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select ok (
  coalesce((pg_temp.rpc_result (format ('select public.join_featured_challenge(%L)', (select group_id from pg_temp.a3_ids where label = 'challenge_one'))) ->> 'already_member'), '') = 'false',
  'join_featured_challenge joins the featured challenge');

select ok (
  exists (select 1 from public.group_members m where m.user_id = '22222222-2222-2222-2222-222222222222' and m.group_id = (select group_id from pg_temp.a3_ids where label = 'challenge_one')),
  'the joiner is a member of the featured challenge');

select ok (
  coalesce((pg_temp.rpc_result (format ('select public.join_featured_challenge(%L)', (select group_id from pg_temp.a3_ids where label = 'challenge_one'))) ->> 'already_member'), '') = 'true',
  'joining a featured challenge twice is idempotent');

select ok (
  (select count(*) from public.group_members m where m.user_id = '22222222-2222-2222-2222-222222222222' and m.group_id = (select group_id from pg_temp.a3_ids where label = 'challenge_one')) = 1,
  'no duplicate membership row is created');

select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'seasonal_used'), '') = '1',
  'the featured challenge consumed the seasonal slot');

select ok (
  pg_temp.rpc_error ($q$select public.create_group('A3F Second Challenge', null, 'challenge', 'faithful_days', 'open', current_date, current_date + 10)$q$) like '%slot limit%',
  'a 2nd seasonal challenge is rejected');

select ok (
  pg_temp.rpc_error (format ('select public.join_featured_challenge(%L)', (select group_id from pg_temp.a3_ids where label = 'frat_one'))) like '%not available%',
  'a fraternity is not a featured challenge');

select ok (
  pg_temp.rpc_error (format ('select public.join_featured_challenge(%L)', '99999999-9999-9999-9999-999999999999')) like '%not available%',
  'an unknown group cannot be joined as a featured challenge');

-- ===========================================================================
-- D. the public preview of a featured challenge
-- ===========================================================================
reset role;
set local role anon;
set local request.jwt.claims = '{}';

select ok (
  coalesce((pg_temp.rpc_result (format ('select public.preview_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'challenge_one'))) ->> 'is_featured'), '') = 'true',
  'the preview reports is_featured = true for a featured challenge');

select ok (
  not (pg_temp.rpc_result (format ('select public.preview_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'challenge_one'))) ? 'invite_code'),
  'the preview of a featured challenge never contains invite_code');

select ok (
  exists (
    select 1 from jsonb_array_elements (pg_temp.rpc_result ($q$select public.list_featured_challenges()$q$)) e
    where e ->> 'id' = (select group_id from pg_temp.a3_ids where label = 'challenge_one')::text
      and e ->> 'group_type' = 'challenge'
  ),
  'list_featured_challenges lists the featured challenge');

reset role;

-- ===========================================================================
-- E. the featured list is empty for a plain group
-- ===========================================================================
set local role anon;
set local request.jwt.claims = '{}';

select ok (
  not exists (
    select 1 from jsonb_array_elements (pg_temp.rpc_result ($q$select public.list_featured_challenges()$q$)) e
    where e ->> 'id' = (select group_id from pg_temp.a3_ids where label = 'frat_one')::text
  ),
  'a fraternity is never listed as a featured challenge');

reset role;
set local request.jwt.claims = '{}';

select * from finish ();
select public.pgtap_summary () as result;

rollback;
