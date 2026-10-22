-- supabase/tests/a3/groups.sql
-- A3 · groups, invites, slots
-- Every assertion runs inside `begin; ... rollback;` — nothing is persisted.
begin;
set local search_path = extensions, public;

select plan(110);

-- -----------------------------------------------------------------------------
-- helpers (owned by postgres, executed with the CURRENT role => the RPC is
-- really called as authenticated / anon)
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
-- fixtures: 4 users
-- -----------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('11111111-1111-1111-1111-111111111111', 'a3_alice@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('22222222-2222-2222-2222-222222222222', 'a3_bob@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('33333333-3333-3333-3333-333333333333', 'a3_carol@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('44444444-4444-4444-4444-444444444444', 'a3_dave@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

-- A2's `on_auth_user_created` trigger already created the profile rows, so the
-- display names are set with an upsert.
insert into public.profiles (id, display_name)
values
  ('11111111-1111-1111-1111-111111111111', 'Alice'),
  ('22222222-2222-2222-2222-222222222222', 'Bob'),
  ('33333333-3333-3333-3333-333333333333', 'Carol'),
  ('44444444-4444-4444-4444-444444444444', 'Dave')
on conflict (id) do update set display_name = excluded.display_name;

-- ===========================================================================
-- A. schema
-- ===========================================================================
select has_table ('public', 'group_invites', 'group_invites table exists');
select has_table ('public', 'slot_unlocks', 'slot_unlocks table exists');
select has_table ('public', 'group_featured', 'group_featured table exists');

select has_column ('public', 'group_invites', 'code', 'group_invites.code exists');
select has_column ('public', 'group_invites', 'max_uses', 'group_invites.max_uses exists');
select has_column ('public', 'slot_unlocks', 'kind', 'slot_unlocks.kind exists');
select has_column ('public', 'slot_unlocks', 'expires_at', 'slot_unlocks.expires_at exists');
select has_column ('public', 'group_featured', 'display_order', 'group_featured.display_order exists');

select ok (public.pgtap_rls_enabled ('public.group_invites'::regclass), 'RLS is enabled on group_invites');
select ok (public.pgtap_rls_forced  ('public.group_invites'::regclass), 'RLS is FORCED on group_invites');
select ok (public.pgtap_rls_enabled ('public.slot_unlocks'::regclass), 'RLS is enabled on slot_unlocks');
select ok (public.pgtap_rls_forced  ('public.slot_unlocks'::regclass), 'RLS is FORCED on slot_unlocks');
select ok (public.pgtap_rls_enabled ('public.group_featured'::regclass), 'RLS is enabled on group_featured');
select ok (public.pgtap_rls_forced  ('public.group_featured'::regclass), 'RLS is FORCED on group_featured');

select has_trigger ('public', 'group_invites',  'trg_group_invites_updated_at',  'updated_at trigger on group_invites');
select has_trigger ('public', 'slot_unlocks',   'trg_slot_unlocks_updated_at',   'updated_at trigger on slot_unlocks');
select has_trigger ('public', 'group_featured', 'trg_group_featured_updated_at', 'updated_at trigger on group_featured');

select ok (
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'create_group'
      and pg_get_function_identity_arguments (p.oid) =
          'p_name text, p_description text, p_group_type group_type, p_scoring_mode scoring_mode, p_sharing_requirement sharing_requirement, p_starts_on date, p_ends_on date, p_goal_target integer'
  ),
  'public.create_group has the contracted signature');

select has_function ('public', 'join_group_by_code',      array['text']::name[],       'join_group_by_code(text) exists');
select has_function ('public', 'reset_invite_code',        array['uuid']::name[],       'reset_invite_code(uuid) exists');
select has_function ('public', 'leave_group',              array['uuid']::name[],       'leave_group(uuid) exists');
select has_function ('public', 'remove_member',            array['uuid','uuid']::name[], 'remove_member(uuid,uuid) exists');
select has_function ('public', 'transfer_admin',           array['uuid','uuid']::name[], 'transfer_admin(uuid,uuid) exists');
select has_function ('public', 'join_featured_challenge',  array['uuid']::name[],       'join_featured_challenge(uuid) exists');
select has_function ('public', 'preview_group_by_code',    array['text']::name[],       'preview_group_by_code(text) exists');
select has_function ('public', 'list_featured_challenges', 'list_featured_challenges() exists');
select has_function ('public', 'my_group_slots',           'my_group_slots() exists');
select has_function ('public', 'grant_slot_unlock',        array['uuid','text','text','integer','text']::name[], 'grant_slot_unlock(uuid,text,text,integer,text) exists');
select has_function ('public', 'set_featured_group',       array['uuid','boolean','date','date','integer']::name[], 'set_featured_group(uuid,boolean,date,date,integer) exists');

select ok (
  exists (select 1 from pg_constraint where conname = 'groups_challenge_dates_ck'),
  'public.groups has the groups_challenge_dates_ck CHECK');

-- the grant matrix of the exposed RPCs
select ok (has_function_privilege ('anon', 'public.preview_group_by_code(text)', 'execute'), 'anon may call preview_group_by_code');
select ok (has_function_privilege ('anon', 'public.list_featured_challenges()', 'execute'), 'anon may call list_featured_challenges');
select ok (not has_function_privilege ('anon', 'public.create_group(text,text,public.group_type,public.scoring_mode,public.sharing_requirement,date,date,integer)', 'execute'), 'anon may NOT call create_group');
select ok (not has_function_privilege ('anon', 'public.join_group_by_code(text)', 'execute'), 'anon may NOT call join_group_by_code');
select ok (has_function_privilege ('authenticated', 'public.join_group_by_code(text)', 'execute'), 'authenticated may call join_group_by_code');
select ok (not has_function_privilege ('public', 'public.join_group_by_code(text)', 'execute'), 'PUBLIC may NOT call join_group_by_code');
select ok (not has_function_privilege ('public', 'public.preview_group_by_code(text)', 'execute'), 'PUBLIC may NOT call preview_group_by_code');

-- ===========================================================================
-- B. create_group  (as Alice)
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated","email":"a3_alice@example.test"}';

insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'frat_one', (r->'group'->>'id')::uuid, r->>'invite_code'
from (select pg_temp.rpc_result ($q$select public.create_group('A3 Frat One')$q$) as r) s
where r is not null;

select ok (exists (select 1 from pg_temp.a3_ids where label = 'frat_one'), 'create_group returns a payload');
select ok (
  coalesce((select invite_code from pg_temp.a3_ids where label = 'frat_one') ~ '^[0-9]{6}$', false),
  'the invite code is 6 digits');
select ok (
  exists (select 1 from public.groups g where g.name = 'A3 Frat One' and g.created_by = '11111111-1111-1111-1111-111111111111'),
  'the group row is created with created_by = the caller');
select ok (
  exists (select 1 from public.group_members m where m.user_id = '11111111-1111-1111-1111-111111111111' and m.role = 'admin'),
  'the creator is a member with role = admin');
select ok (
  exists (select 1 from public.group_invites i where i.created_by = '11111111-1111-1111-1111-111111111111' and i.revoked_at is null),
  'a group_invites row is created for the code');
select ok (
  exists (select 1 from public.groups g where g.name = 'A3 Frat One' and g.group_type = 'fraternity' and g.scoring_mode = 'faithful_days' and g.sharing_requirement = 'open'),
  'the defaults are fraternity / faithful_days / open');

select ok (
  pg_temp.rpc_error ($q$select public.create_group('Bad challenge', null, 'challenge')$q$) like '%requires both starts_on and ends_on%',
  'a challenge without dates is rejected');
select ok (
  pg_temp.rpc_error ($q$select public.create_group('Bad challenge', null, 'challenge', 'faithful_days', 'open', '2026-05-10', '2026-05-01')$q$) like '%ends_on >= starts_on%',
  'a challenge with ends_on < starts_on is rejected');
select ok (
  pg_temp.rpc_error ($q$select public.create_group('Bad target', null, 'fraternity', 'collective_treasure')$q$) like '%requires a goal_target%',
  'collective_treasure without a goal_target is rejected');

set local request.jwt.claims = '{}';
select ok (
  pg_temp.rpc_error ($q$select public.create_group('No identity')$q$) like '%authentication required%',
  'create_group without a JWT is rejected');
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- the database CHECK is the second line of defence
reset role;
select ok (
  pg_temp.rpc_error ($q$insert into public.groups (name, group_type, created_by) values ('Raw challenge', 'challenge', '11111111-1111-1111-1111-111111111111')$q$) like '%groups_challenge_dates_ck%',
  'the groups CHECK rejects a challenge without dates');
set local role authenticated;

-- a second fraternity (2 personal slots)
insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'frat_two', (r->'group'->>'id')::uuid, r->>'invite_code'
from (select pg_temp.rpc_result ($q$select public.create_group('A3 Frat Two')$q$) as r) s
where r is not null;

select ok (exists (select 1 from pg_temp.a3_ids where label = 'frat_two'), 'a second fraternity can be created');

-- the seasonal slot: one challenge
insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'challenge_one', (r->'group'->>'id')::uuid, r->>'invite_code'
from (select pg_temp.rpc_result ($q$select public.create_group('A3 Challenge One', null, 'challenge', 'faithful_days', 'open', current_date, current_date + 20)$q$) as r) s
where r is not null;

select ok (exists (select 1 from pg_temp.a3_ids where label = 'challenge_one'), 'a challenge can be created (seasonal slot)');

-- ===========================================================================
-- C. join_group_by_code
-- ===========================================================================
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select ok (
  coalesce((pg_temp.rpc_result (format ('select public.join_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'frat_one'))) ->> 'already_member'), '') = 'false',
  'join_group_by_code adds the member');

select ok (
  exists (select 1 from public.group_members m where m.user_id = '22222222-2222-2222-2222-222222222222' and m.group_id = (select group_id from pg_temp.a3_ids where label = 'frat_one')),
  'the joiner is a member of the group');

select ok (
  coalesce((pg_temp.rpc_result (format ('select public.join_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'frat_one'))) ->> 'already_member'), '') = 'true',
  'joining twice is idempotent');

select ok (
  (select count(*) from public.group_members m where m.user_id = '22222222-2222-2222-2222-222222222222' and m.group_id = (select group_id from pg_temp.a3_ids where label = 'frat_one')) = 1,
  'no duplicate group_members row is created');

select ok (
  pg_temp.rpc_error ($q$select public.join_group_by_code('12345')$q$) like '%invalid invite code%',
  'a 5 digit code is rejected');

select ok (
  pg_temp.rpc_error ($q$select public.join_group_by_code('abcdef')$q$) like '%invalid invite code%',
  'a non numeric code is rejected');

select ok (
  pg_temp.rpc_error ($q$select public.join_group_by_code('000000')$q$) like '%invite code not found%',
  'an unknown code is rejected');

-- a spaced code is normalised
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';

select ok (
  pg_temp.rpc_error (format ('select public.join_group_by_code(%L)', ' ' || substr (c.invite_code, 1, 3) || ' ' || substr (c.invite_code, 4, 3) || ' '))
    is null,
  'a spaced invite code is normalised and accepted')
from pg_temp.a3_ids c
where c.label = 'frat_two';

select ok (
  exists (select 1 from public.group_members m where m.user_id = '33333333-3333-3333-3333-333333333333' and m.group_id = (select group_id from pg_temp.a3_ids where label = 'frat_two')),
  'the spaced code really joined the group');

-- ===========================================================================
-- D. slot rule
-- ===========================================================================
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select ok (
  pg_temp.rpc_error ($q$select public.create_group('A3 Third Frat')$q$) like '%slot limit%',
  'a 3rd personal fraternity is rejected');

select ok (
  pg_temp.rpc_error ($q$select public.create_group('A3 Second Challenge', null, 'challenge', 'faithful_days', 'open', current_date, current_date + 10)$q$) like '%slot limit%',
  'a 2nd seasonal challenge is rejected');

select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'personal_max'), '') = '2',
  'my_group_slots: personal_max = 2 without a bonus');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'seasonal_max'), '') = '1',
  'my_group_slots: seasonal_max = 1');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'personal_used'), '') = '2',
  'my_group_slots: personal_used = 2');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'seasonal_used'), '') = '1',
  'my_group_slots: seasonal_used = 1');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'personal_available'), '') = '0',
  'my_group_slots: personal_available = 0');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'seasonal_available'), '') = '0',
  'my_group_slots: seasonal_available = 0');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'bonus_active'), '') = 'false',
  'my_group_slots: bonus_active = false without an unlock');

-- a rewarded video unlocks one more personal slot for 30 days
-- (grant_slot_unlock is a service_role RPC; the owner runs it here)
reset role;
select ok (
  pg_temp.rpc_result ($q$select public.grant_slot_unlock('11111111-1111-1111-1111-111111111111', 'group_slot', 'rewarded_video', 30)$q$) ->> 'already_active' = 'false',
  'grant_slot_unlock grants a group_slot');
select ok (
  pg_temp.rpc_result ($q$select public.grant_slot_unlock('11111111-1111-1111-1111-111111111111', 'group_slot', 'rewarded_video', 30)$q$) ->> 'already_active' = 'true',
  'grant_slot_unlock never grants an active group_slot twice');
select ok (
  (select count(*) from public.slot_unlocks where user_id = '11111111-1111-1111-1111-111111111111' and kind = 'group_slot') = 1,
  'only one group_slot unlock row exists');
select ok (
  has_function_privilege ('service_role', 'public.grant_slot_unlock(uuid,text,text,integer,text)', 'execute'),
  'grant_slot_unlock is executable by service_role');
select ok (
  not has_function_privilege ('authenticated', 'public.grant_slot_unlock(uuid,text,text,integer,text)', 'execute'),
  'grant_slot_unlock is NOT executable by authenticated');
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'personal_max'), '') = '3',
  'my_group_slots: personal_max = 3 with an active bonus');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'bonus_active'), '') = 'true',
  'my_group_slots: bonus_active = true with an active unlock');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'personal_available'), '') = '1',
  'my_group_slots: personal_available = 1 with an active bonus');

insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'frat_three', (r->'group'->>'id')::uuid, r->>'invite_code'
from (select pg_temp.rpc_result ($q$select public.create_group('A3 Third Frat')$q$) as r) s
where r is not null;

select ok (exists (select 1 from pg_temp.a3_ids where label = 'frat_three'), 'the 3rd fraternity is allowed with an active bonus slot');

-- an EXPIRED unlock grants nothing
reset role;
insert into public.slot_unlocks (user_id, kind, source, starts_at, expires_at, notes)
values ('44444444-4444-4444-4444-444444444444', 'group_slot', 'rewarded_video', now() - interval '40 days', now() - interval '10 days', 'expired');
set local role authenticated;
set local request.jwt.claims = '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}';

insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'dave_one', (r->'group'->>'id')::uuid, r->>'invite_code'
from (select pg_temp.rpc_result ($q$select public.create_group('A3 Dave One')$q$) as r) s
where r is not null;

insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'dave_two', (r->'group'->>'id')::uuid, r->>'invite_code'
from (select pg_temp.rpc_result ($q$select public.create_group('A3 Dave Two')$q$) as r) s
where r is not null;

select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'bonus_active'), '') = 'false',
  'an expired unlock is not an active bonus');
select ok (
  coalesce((pg_temp.rpc_result ($q$select public.my_group_slots()$q$) ->> 'personal_max'), '') = '2',
  'an expired unlock does not raise personal_max');
select ok (
  pg_temp.rpc_error ($q$select public.create_group('A3 Dave Three')$q$) like '%slot limit%',
  'an expired unlock does not allow a 3rd fraternity');

-- ===========================================================================
-- E. reset_invite_code
-- ===========================================================================
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';

select ok (
  pg_temp.rpc_error (format ('select public.reset_invite_code(%L)', (select group_id from pg_temp.a3_ids where label = 'frat_one'))) like '%only a group admin%',
  'a non admin cannot reset the invite code');

set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select ok (
  pg_temp.rpc_result (format ('select public.reset_invite_code(%L)', (select group_id from pg_temp.a3_ids where label = 'frat_one'))) ->> 'invite_code' ~ '^[0-9]{6}$',
  'an admin resets the invite code and gets a new 6 digit code');

reset role;
select ok (
  (select invite_code from pg_temp.a3_ids where label = 'frat_one')
    <> (select g.invite_code from public.groups g where g.id = (select group_id from pg_temp.a3_ids where label = 'frat_one')),
  'the new code differs from the old one');
select ok (
  exists (
    select 1 from public.group_invites i
    where i.group_id = (select group_id from pg_temp.a3_ids where label = 'frat_one')
      and i.revoked_at is not null
  ),
  'the previous invite row is revoked');
select ok (
  (select count(*) from public.group_invites i where i.group_id = (select group_id from pg_temp.a3_ids where label = 'frat_one') and i.revoked_at is null) = 1,
  'exactly one live invite row remains');
-- the preview tests run as `anon`, which cannot read public.groups: keep the
-- new code in the temp table
insert into pg_temp.a3_ids (label, group_id, invite_code)
select 'frat_one_old', a.group_id, a.invite_code from pg_temp.a3_ids a where a.label = 'frat_one';

update pg_temp.a3_ids a
   set invite_code = g.invite_code
  from public.groups g
 where g.id = a.group_id
   and a.label = 'frat_one';
set local role authenticated;

select ok (
  pg_temp.rpc_error (format ('select public.join_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'frat_one_old'))) like '%invite code not found%',
  'the retired code can no longer be used');

-- ===========================================================================
-- F. membership administration (on A3 Frat Two)
-- ===========================================================================
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select ok (
  pg_temp.rpc_error (format ('select public.leave_group(%L)', (select group_id from pg_temp.a3_ids where label = 'frat_two'))) like '%last admin%',
  'the last admin cannot leave the group');

set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select ok (
  pg_temp.rpc_error (format ('select public.remove_member(%L, %L)', (select group_id from pg_temp.a3_ids where label = 'frat_two'), '11111111-1111-1111-1111-111111111111')) like '%only a group admin%',
  'a non admin cannot remove a member');

set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select ok (
  pg_temp.rpc_result (format ('select public.transfer_admin(%L, %L)', (select group_id from pg_temp.a3_ids where label = 'frat_two'), '33333333-3333-3333-3333-333333333333')) ->> 'new_admin' = '33333333-3333-3333-3333-333333333333',
  'transfer_admin promotes the new admin');

select ok (
  exists (select 1 from public.group_members m where m.group_id = (select group_id from pg_temp.a3_ids where label = 'frat_two') and m.user_id = '33333333-3333-3333-3333-333333333333' and m.role = 'admin'),
  'the new admin has role = admin');

select ok (
  exists (select 1 from public.group_members m where m.group_id = (select group_id from pg_temp.a3_ids where label = 'frat_two') and m.user_id = '11111111-1111-1111-1111-111111111111' and m.role = 'member'),
  'the old admin is demoted to member');

set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';

select ok (
  pg_temp.rpc_result (format ('select public.remove_member(%L, %L)', (select group_id from pg_temp.a3_ids where label = 'frat_two'), '11111111-1111-1111-1111-111111111111')) ->> 'removed_user' = '11111111-1111-1111-1111-111111111111',
  'an admin can remove a member');

select ok (
  not exists (select 1 from public.group_members m where m.group_id = (select group_id from pg_temp.a3_ids where label = 'frat_two') and m.user_id = '11111111-1111-1111-1111-111111111111'),
  'the removed member is really gone');

select ok (
  pg_temp.rpc_error (format ('select public.remove_member(%L, %L)', (select group_id from pg_temp.a3_ids where label = 'frat_two'), '33333333-3333-3333-3333-333333333333')) like '%last admin%',
  'the last admin cannot be removed');

select ok (
  coalesce((pg_temp.rpc_result (format ('select public.leave_group(%L)', (select group_id from pg_temp.a3_ids where label = 'frat_two'))) ->> 'archived'), '') = 'true',
  'the last member leaving archives the group');

-- ===========================================================================
-- G. public preview (anon)
-- ===========================================================================
reset role;
select ok (
  public.set_featured_group ((select group_id from pg_temp.a3_ids where label = 'challenge_one'), true, current_date, current_date + 20, 1) ->> 'group_id' = (select group_id from pg_temp.a3_ids where label = 'challenge_one')::text,
  'set_featured_group publishes the challenge');

set local role anon;
set local request.jwt.claims = '{}';

select ok (
  pg_temp.rpc_result (format ('select public.preview_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'frat_one'))) is not null,
  'preview_group_by_code works for anon');

select ok (
  not (pg_temp.rpc_result (format ('select public.preview_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'frat_one'))) ? 'invite_code'),
  'the preview never contains invite_code');

select ok (
  not (pg_temp.rpc_result (format ('select public.preview_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'frat_one'))) ? 'created_by'),
  'the preview never contains created_by');

select ok (
  coalesce((pg_temp.rpc_result (format ('select public.preview_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'frat_one'))) ->> 'name'), '') = 'A3 Frat One',
  'the preview exposes the group name');

select ok (
  coalesce((pg_temp.rpc_result (format ('select public.preview_group_by_code(%L)', (select invite_code from pg_temp.a3_ids where label = 'frat_one'))) ->> 'member_count'), '') = '2',
  'the preview exposes the member count');

select ok (
  pg_temp.rpc_error ($q$select public.preview_group_by_code('12')$q$) like '%invalid invite code%',
  'preview_group_by_code rejects a malformed code');

select ok (
  jsonb_typeof (pg_temp.rpc_result ($q$select public.list_featured_challenges()$q$)) = 'array',
  'list_featured_challenges returns an array for anon');

select ok (
  exists (
    select 1 from jsonb_array_elements (pg_temp.rpc_result ($q$select public.list_featured_challenges()$q$)) e
    where e ->> 'id' = (select group_id from pg_temp.a3_ids where label = 'challenge_one')::text
  ),
  'the featured challenge is listed');

reset role;
set local request.jwt.claims = '{}';

-- ===========================================================================
-- H. RLS on the A3 tables
-- ===========================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select ok (
  (select count(*) from public.group_members where group_id = (select group_id from pg_temp.a3_ids where label = 'frat_one')) >= 1,
  'RLS: a member can read the roster');

set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';

select ok (
  (select count(*) from public.group_members where group_id = (select group_id from pg_temp.a3_ids where label = 'frat_one')) = 0,
  'RLS: an outsider cannot read the roster of a group they do not belong to');

select ok (
  (select count(*) from public.slot_unlocks where user_id = '11111111-1111-1111-1111-111111111111') = 0,
  'RLS: a user cannot read somebody else slot unlock');

set local request.jwt.claims = '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}';

select ok (
  (select count(*) from public.slot_unlocks where user_id = '44444444-4444-4444-4444-444444444444') = 1,
  'RLS: a user can read their own slot unlock');

set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select ok (
  (select count(*) from public.group_invites where group_id = (select group_id from pg_temp.a3_ids where label = 'frat_one')) >= 1,
  'RLS: an admin can read the invite audit trail of their group');

set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';

select ok (
  (select count(*) from public.group_invites where group_id = (select group_id from pg_temp.a3_ids where label = 'frat_one')) = 0,
  'RLS: a non admin cannot read the invite audit trail');

reset role;

select * from finish ();
select public.pgtap_summary () as result;

rollback;
