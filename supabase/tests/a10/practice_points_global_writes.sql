-- =============================================================================
-- A10 · practice_points_global_writes.sql
-- Regression test for the privilege hole found by A4 (and confirmed by the
-- orchestrator after the A10 audit closed without it).
--
-- THE HOLE
--   `practice_points` write policies used the predicate
--     (group_id IS NULL) OR is_group_admin(group_id)
--   The `group_id IS NULL` branch was satisfied by EVERY authenticated user,
--   so any signed-in member could INSERT / UPDATE / DELETE a GLOBAL point row.
--   A global row is the default applied to every `custom_points` group, so the
--   blast radius was the whole application, not just the caller's own groups.
--
-- THE FIX (migration 0905_harden_practice_points_global_writes.sql)
--   The three write policies now require a non-null group_id that the caller
--   administers. SELECT is deliberately unchanged: every authenticated user
--   must be able to READ the global defaults, otherwise a `custom_points`
--   group cannot resolve its point values.
--
--   The sanctioned write path is `public.set_practice_points(...)`, an
--   INVOKER wrapper over `private.set_practice_points_impl` (SECURITY
--   DEFINER, therefore RLS-exempt). That implementation already enforced
--   the correct rule, so tightening the policies does not break it.
--
-- NOTE ON RLS SEMANTICS (this drove the shape of the assertions)
--   An INSERT that violates a policy RAISES 42501.
--   An UPDATE or DELETE that violates a policy does NOT raise: the row is
--   filtered out by the `using` predicate and the statement affects 0 rows.
--   So the UPDATE/DELETE cases are asserted by their EFFECT (the global row
--   is untouched), not by an expected exception.
--
-- NOTE ON pgTAP
--   The 3-argument `throws_ok(sql, errcode, X)` treats X as the EXPECTED
--   ERROR MESSAGE, not as a free-form description. The 4-argument form
--   `throws_ok(sql, errcode, NULL, description)` is used here so the
--   assertions do not depend on PostgreSQL's error wording.
--
-- Remote invocation procedure: supabase/tests/README.md
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
-- =============================================================================

begin;

select plan(15);

-- -----------------------------------------------------------------------------
-- Fixtures
--   alice  : admin of Admin Group and Member Group (so: "any group admin")
--   bob    : plain member of Member Group, admin of Bob Group
--   carol  : belongs to nothing (so: "not any group admin")
-- -----------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, created_at, updated_at)
values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin@points.test',    'authenticated', 'authenticated', now(), now()),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'member@points.test',   'authenticated', 'authenticated', now(), now()),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'outsider@points.test', 'authenticated', 'authenticated', now(), now())
on conflict (id) do nothing;

insert into public.profiles (id, display_name)
values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Admin'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Member'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'Outsider')
on conflict (id) do update set display_name = excluded.display_name;

insert into public.groups (id, name, group_type, scoring_mode, created_by)
values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'Admin Group',  'fraternity', 'custom_points', 'aaaaaaaa-0000-0000-0000-000000000001'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'Member Group', 'fraternity', 'custom_points', 'aaaaaaaa-0000-0000-0000-000000000001'),
  ('bbbbbbbb-0000-0000-0000-000000000003', 'Bob Group',    'fraternity', 'custom_points', 'aaaaaaaa-0000-0000-0000-000000000002')
on conflict (id) do nothing;

insert into public.group_members (group_id, user_id, role)
values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'admin'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001', 'admin'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000002', 'member'),
  ('bbbbbbbb-0000-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0000-000000000002', 'admin')
on conflict (group_id, user_id) do nothing;

-- A pre-existing GLOBAL row, so the UPDATE/DELETE attempts have a target.
insert into public.practice_points (group_id, practice_kind, points)
values (null, 'rosary', 10)
on conflict on constraint practice_points_group_kind_unique do nothing;

-- -----------------------------------------------------------------------------
-- A. THE EXPLOIT IS CLOSED for a plain member.
-- -----------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000002","role":"authenticated","email":"member@points.test"}', true);

select throws_ok(
  $$ insert into public.practice_points (group_id, practice_kind, points)
     values (null, 'holy_mass', 999) $$,
  '42501', null,
  'A1: a plain member cannot insert a GLOBAL point row'
);

-- UPDATE / DELETE do not raise; they are filtered to 0 rows. Assert the effect.
select lives_ok(
  $$ update public.practice_points set points = 999 where group_id is null $$,
  'A2: an update aimed at the GLOBAL row is filtered by RLS, not raised'
);

select lives_ok(
  $$ delete from public.practice_points where group_id is null $$,
  'A3: a delete aimed at the GLOBAL row is filtered by RLS, not raised'
);

select is(
  (select points from public.practice_points where group_id is null and practice_kind = 'rosary'),
  10::int,
  'A4: the GLOBAL point row still holds its original value'
);

select is(
  (select count(*) from public.practice_points where points = 999),
  0::bigint,
  'A5: no row was overwritten with the tampered value'
);

select is(
  (select count(*) from public.practice_points where group_id is null),
  1::bigint,
  'A6: the GLOBAL row was not deleted'
);

-- A member must not be able to write into a group they do not administer.
select throws_ok(
  $$ insert into public.practice_points (group_id, practice_kind, points)
     values ('bbbbbbbb-0000-0000-0000-000000000001', 'rosary', 5) $$,
  '42501', null,
  'A7: a plain member cannot insert a point row for a group they do not administer'
);

-- A member CAN write a point row for a group they DO administer.
insert into public.practice_points (group_id, practice_kind, points)
values ('bbbbbbbb-0000-0000-0000-000000000003', 'rosary', 7);

select is(
  (select points from public.practice_points
    where group_id = 'bbbbbbbb-0000-0000-0000-000000000003' and practice_kind = 'rosary'),
  7::int,
  'A8: a member CAN write a point row for a group they administer'
);

-- A member CANNOT write a point row for a group they merely belong to.
select throws_ok(
  $$ insert into public.practice_points (group_id, practice_kind, points)
     values ('bbbbbbbb-0000-0000-0000-000000000002', 'adoration', 3) $$,
  '42501', null,
  'A9: a non-admin member cannot write a point row for their own group'
);

-- -----------------------------------------------------------------------------
-- B. READING the global defaults is still open to every signed-in user,
--    otherwise a `custom_points` group cannot resolve its point values.
-- -----------------------------------------------------------------------------
select is(
  (select count(*) from public.practice_points
    where group_id is null and practice_kind = 'rosary'),
  1::bigint,
  'B1: a plain member can still READ the global point row'
);

-- -----------------------------------------------------------------------------
-- C. THE SANCTIONED PATH still works.
--    `set_practice_points` is an INVOKER wrapper over a SECURITY DEFINER impl,
--    so it is RLS-exempt and enforces its own rule.
-- -----------------------------------------------------------------------------
-- C1: alice administers at least one group, so she may set a GLOBAL default.
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated","email":"admin@points.test"}', true);

select lives_ok(
  $$ select public.set_practice_points(null, 'adoration', 25) $$,
  'C1: a group admin can set a GLOBAL default through the sanctioned RPC'
);

select is(
  (select points from public.practice_points
    where group_id is null and practice_kind = 'adoration'),
  25::int,
  'C2: the sanctioned RPC actually wrote the global row'
);

-- C4: carol administers no group at all, so the impl itself rejects her.
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000003","role":"authenticated","email":"outsider@points.test"}', true);

select throws_ok(
  $$ select public.set_practice_points(null, 'fasting', 15) $$,
  '42501', null,
  'C3: a user who administers no group cannot set a global default'
);

reset role;

-- -----------------------------------------------------------------------------
-- D. anon can neither read nor write.
-- -----------------------------------------------------------------------------
set local role anon;

select is(
  (select count(*) from public.practice_points),
  0::bigint,
  'D1: anon cannot read practice_points'
);

select throws_ok(
  $$ insert into public.practice_points (group_id, practice_kind, points)
     values (null, 'rosary', 1) $$,
  '42501', null,
  'D2: anon cannot insert a point row'
);

reset role;

select * from finish ();
select public.pgtap_summary () as result;

rollback;
