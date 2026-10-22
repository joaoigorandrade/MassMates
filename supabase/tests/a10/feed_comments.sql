-- =============================================================================
-- A10 · feed_comments.sql · public.feed_post_comments + its four RPCs
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
--
-- WHAT IT PROVES
--   A. the table, its columns and its RLS skeleton
--   B. the RLS matrix for the FIVE personas
--      (anon / outsider / member / admin / blocked)
--   C. the write policies: own row only, admin may delete, no client may
--      forge the moderation columns
--   D. the four RPCs: create / list / delete / soft-delete
--   E. the body-length rules (blank and > 500 rejected, 500 accepted)
--   F. the append semantics (a member may comment twice)
--   G. the cursor pagination: no duplicate and no skipped row, even when two
--      comments share the same created_at
--   H. the moderation path: a hidden comment is invisible to a plain member,
--      visible to an admin, and writes EXACTLY ONE audit_log row
--
--   Fixture (10 comments, all in G1)
--     u1 Ana    e3000000-0000-0000-0000-000000000001  admin  of G1
--     u2 Bruno  e3000000-0000-0000-0000-000000000002  member of G1, BLOCKS u4
--     u3 Carla  e3000000-0000-0000-0000-000000000003  outsider
--     u4 Daniel e3000000-0000-0000-0000-000000000004  member of G1, blocked by u2
--     G1       e3000000-0000-0000-0000-000000000101
--     P1       e3000000-0000-0000-0000-000000000201  post by u2 (RLS fixture)
--     P2       e3000000-0000-0000-0000-000000000202  post by u1 (pagination fixture)
--     P3       e3000000-0000-0000-0000-000000000203  post by u1 (RPC fixture)
--     C1  301  P1  u2  2026-01-01 10:00
--     C2  302  P1  u1  2026-01-01 11:00
--     C3  303  P1  u4  2026-01-01 12:00
--     C4  304  P1  u2  2026-01-01 09:00
--     PA..PF    P2  u1  six rows, PA and PF share a created_at
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(83);

-- -----------------------------------------------------------------------------
-- A. Structure
-- -----------------------------------------------------------------------------

select has_table ('public', 'feed_post_comments', 'the feed_post_comments table exists');
select ok (public.pgtap_rls_enabled ('public.feed_post_comments'::regclass),
           'RLS is enabled on feed_post_comments');
select ok (public.pgtap_rls_forced ('public.feed_post_comments'::regclass),
           'RLS is FORCED on feed_post_comments');
select ok (public.pgtap_policy_count ('public.feed_post_comments'::regclass) > 0,
           'feed_post_comments has policies');
select is (public.pgtap_policy_count ('public.feed_post_comments'::regclass, 'r'), 1,
           'feed_post_comments has exactly 1 SELECT policy');
select is (public.pgtap_policy_count ('public.feed_post_comments'::regclass, 'a'), 1,
           'feed_post_comments has exactly 1 INSERT policy');
select is (public.pgtap_policy_count ('public.feed_post_comments'::regclass, 'w'), 1,
           'feed_post_comments has exactly 1 UPDATE policy');
select is (public.pgtap_policy_count ('public.feed_post_comments'::regclass, 'd'), 1,
           'feed_post_comments has exactly 1 DELETE policy');

select ok (to_regprocedure ('public.create_feed_post_comment (uuid, text)') is not null,
           'public.create_feed_post_comment(uuid,text) exists');
select ok (to_regprocedure ('public.get_feed_post_comments (uuid, text, integer)') is not null,
           'public.get_feed_post_comments(uuid,text,integer) exists');
select ok (to_regprocedure ('public.delete_feed_post_comment (uuid)') is not null,
           'public.delete_feed_post_comment(uuid) exists');
select ok (to_regprocedure ('public.soft_delete_feed_post_comment (uuid)') is not null,
           'public.soft_delete_feed_post_comment(uuid) exists');
select ok (not exists (
            select 1 from pg_catalog.pg_proc p
            join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public'
              and p.proname in ('create_feed_post_comment', 'get_feed_post_comments',
                                'delete_feed_post_comment', 'soft_delete_feed_post_comment')
              and has_function_privilege ('anon', p.oid, 'execute')),
           'anon may not execute any of the four comment RPCs');
select ok (not exists (
            select 1 from pg_catalog.pg_proc p
            join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public'
              and p.proname in ('create_feed_post_comment', 'get_feed_post_comments',
                                'delete_feed_post_comment', 'soft_delete_feed_post_comment')
              and p.prosecdef),
           'the four comment RPCs are SECURITY INVOKER (the body lives in private)');

-- -----------------------------------------------------------------------------
-- B. The columns
-- -----------------------------------------------------------------------------

select is ((select string_agg (column_name, ',' order by ordinal_position)
             from information_schema.columns
            where table_schema = 'public' and table_name = 'feed_post_comments'),
           'id,post_id,group_id,user_id,body,is_hidden,hidden_reason,hidden_at,created_at',
           'the table has exactly the documented columns');
select ok (not exists (
             select 1 from information_schema.columns
              where table_schema = 'public' and table_name = 'feed_post_comments'
                and column_name = 'updated_at'),
           'the table has NO updated_at column (the comments are append-only)');

-- -----------------------------------------------------------------------------
-- Fixture
-- -----------------------------------------------------------------------------

insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('e3000000-0000-0000-0000-000000000001', 'fc_ana@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e3000000-0000-0000-0000-000000000002', 'fc_bruno@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e3000000-0000-0000-0000-000000000003', 'fc_carla@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('e3000000-0000-0000-0000-000000000004', 'fc_daniel@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.groups (id, name, created_by)
values ('e3000000-0000-0000-0000-000000000101', 'Gap Comments', 'e3000000-0000-0000-0000-000000000001');

insert into public.group_members (group_id, user_id, role)
values
  ('e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'admin'),
  ('e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000002', 'member'),
  ('e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000004', 'member');

insert into public.feed_posts (id, group_id, user_id, practice_kind, reflection_text)
values
  ('e3000000-0000-0000-0000-000000000201', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000002', 'rosary', 'fc post 1'),
  ('e3000000-0000-0000-0000-000000000202', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'rosary', 'fc post 2'),
  ('e3000000-0000-0000-0000-000000000203', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'rosary', 'fc post 3');

-- u2 blocks u4 (the relation is symmetric)
insert into public.user_blocks (blocker_id, blocked_id)
values ('e3000000-0000-0000-0000-000000000002', 'e3000000-0000-0000-0000-000000000004');

-- Four comments on P1 (inserted as the owner, so the fixture is deterministic)
insert into public.feed_post_comments (id, post_id, group_id, user_id, body, created_at)
values
  ('e3000000-0000-0000-0000-000000000301', 'e3000000-0000-0000-0000-000000000201', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000002', 'first comment',   '2026-01-01 10:00:00+00'),
  ('e3000000-0000-0000-0000-000000000302', 'e3000000-0000-0000-0000-000000000201', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'admin comment',   '2026-01-01 11:00:00+00'),
  ('e3000000-0000-0000-0000-000000000303', 'e3000000-0000-0000-0000-000000000201', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000004', 'blocked comment', '2026-01-01 12:00:00+00'),
  ('e3000000-0000-0000-0000-000000000304', 'e3000000-0000-0000-0000-000000000201', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000002', 'own comment',     '2026-01-01 09:00:00+00');

-- Six comments on P2 for the pagination (two of them share a created_at)
insert into public.feed_post_comments (id, post_id, group_id, user_id, body, created_at)
values
  ('e3000000-0000-0000-0000-000000000401', 'e3000000-0000-0000-0000-000000000202', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'p5a', '2026-01-05 10:00:00+00'),
  ('e3000000-0000-0000-0000-000000000402', 'e3000000-0000-0000-0000-000000000202', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'p4',  '2026-01-04 10:00:00+00'),
  ('e3000000-0000-0000-0000-000000000403', 'e3000000-0000-0000-0000-000000000202', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'p3',  '2026-01-03 10:00:00+00'),
  ('e3000000-0000-0000-0000-000000000404', 'e3000000-0000-0000-0000-000000000202', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'p2',  '2026-01-02 10:00:00+00'),
  ('e3000000-0000-0000-0000-000000000405', 'e3000000-0000-0000-0000-000000000202', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'p1',  '2026-01-01 10:00:00+00'),
  ('e3000000-0000-0000-0000-000000000406', 'e3000000-0000-0000-0000-000000000202', 'e3000000-0000-0000-0000-000000000101', 'e3000000-0000-0000-0000-000000000001', 'p5b', '2026-01-05 10:00:00+00');

-- -----------------------------------------------------------------------------
-- Probe helpers (SECURITY INVOKER: the table's own RLS applies)
-- -----------------------------------------------------------------------------

create function pg_temp.fc_select ()
  returns bigint
  language plpgsql
as $$
declare
  n bigint;
begin
  begin
    execute 'select count(*) from public.feed_post_comments' into n;
  exception when others then
    n := 0;
  end;
  return coalesce (n, 0);
end;
$$;

create function pg_temp.fc_update ()
  returns bigint
  language plpgsql
as $$
declare
  n bigint;
begin
  begin
    execute 'update public.feed_post_comments set body = body';
    get diagnostics n = row_count;
    raise exception 'fc_rollback';
  exception when others then
    null;
  end;
  return coalesce (n, 0);
end;
$$;

create function pg_temp.fc_delete ()
  returns bigint
  language plpgsql
as $$
declare
  n bigint;
begin
  begin
    execute 'delete from public.feed_post_comments';
    get diagnostics n = row_count;
    raise exception 'fc_rollback';
  exception when others then
    null;
  end;
  return coalesce (n, 0);
end;
$$;

create function pg_temp.fc_insert ()
  returns bigint
  language plpgsql
as $$
declare
  n bigint;
begin
  begin
    insert into public.feed_post_comments (post_id, group_id, user_id, body)
    values ('e3000000-0000-0000-0000-000000000201',
            'e3000000-0000-0000-0000-000000000101',
            auth.uid(),
            'probe');
    get diagnostics n = row_count;
    raise exception 'fc_rollback';
  exception when others then
    null;
  end;
  return coalesce (n, 0);
end;
$$;

-- returns the number of rows the UPDATE touched; -1 when it raised
create function pg_temp.fc_try_update (p_id uuid, p_body text)
  returns integer
  language plpgsql
as $$
declare
  n integer;
begin
  update public.feed_post_comments set body = p_body where id = p_id;
  get diagnostics n = row_count;
  return n;
exception when others then
  return -1;
end;
$$;

-- returns true when the INSERT was ALLOWED
create function pg_temp.fc_try_insert (p_user uuid, p_group uuid)
  returns boolean
  language plpgsql
as $$
begin
  insert into public.feed_post_comments (post_id, group_id, user_id, body)
  values ('e3000000-0000-0000-0000-000000000201', p_group, p_user, 'forged');
  return true;
exception when others then
  return false;
end;
$$;

-- returns true when the UPDATE was ALLOWED
create function pg_temp.fc_try_hide (p_id uuid)
  returns boolean
  language plpgsql
as $$
begin
  update public.feed_post_comments set is_hidden = true where id = p_id;
  return true;
exception when others then
  return false;
end;
$$;

create function pg_temp.fc_ids (p_before text, p_limit integer)
  returns text[]
  language sql
  stable
as $$
  select coalesce (array_agg (t.x ->> 'id' order by t.ord), '{}'::text[])
    from jsonb_array_elements (
           public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000202', p_before, p_limit) -> 'items'
         ) with ordinality as t (x, ord);
$$;

-- -----------------------------------------------------------------------------
-- C. The RLS matrix -- five personas x (SELECT, INSERT, UPDATE, DELETE)
-- -----------------------------------------------------------------------------

set local role anon;
set local request.jwt.claims = '{}';

select is (pg_temp.fc_select (), 0::bigint, 'anon / SELECT reaches 0 comment(s)');
select is (pg_temp.fc_insert (), 0::bigint, 'anon / INSERT reaches 0 comment(s)');
select is (pg_temp.fc_update (), 0::bigint, 'anon / UPDATE reaches 0 comment(s)');
select is (pg_temp.fc_delete (), 0::bigint, 'anon / DELETE reaches 0 comment(s)');

reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000003","role":"authenticated"}';

select is (pg_temp.fc_select (), 0::bigint, 'outsider / SELECT reaches 0 comment(s)');
select is (pg_temp.fc_insert (), 0::bigint, 'outsider / INSERT reaches 0 comment(s)');
select is (pg_temp.fc_update (), 0::bigint, 'outsider / UPDATE reaches 0 comment(s)');
select is (pg_temp.fc_delete (), 0::bigint, 'outsider / DELETE reaches 0 comment(s)');

set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000002","role":"authenticated"}';

select is (pg_temp.fc_select (), 9::bigint,
           'member / SELECT reaches 9 comment(s) (the blocked one is hidden)');
select is (pg_temp.fc_insert (), 1::bigint, 'member / INSERT reaches 1 comment(s)');
select is (pg_temp.fc_update (), 2::bigint, 'member / UPDATE reaches 2 comment(s) (own rows only)');
select is (pg_temp.fc_delete (), 2::bigint, 'member / DELETE reaches 2 comment(s) (own rows only)');

set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is (pg_temp.fc_select (), 10::bigint,
           'admin / SELECT reaches 10 comment(s) (a hidden one stays visible to an admin)');
select is (pg_temp.fc_insert (), 1::bigint, 'admin / INSERT reaches 1 comment(s)');
select is (pg_temp.fc_update (), 7::bigint, 'admin / UPDATE reaches 7 comment(s) (own rows only)');
select is (pg_temp.fc_delete (), 10::bigint, 'admin / DELETE reaches 10 comment(s) (a group admin may delete any)');

set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000004","role":"authenticated"}';

select is (pg_temp.fc_select (), 8::bigint,
           'blocked / SELECT reaches 8 comment(s) (the blocker''s comments are hidden)');
select is (pg_temp.fc_insert (), 1::bigint, 'blocked / INSERT reaches 1 comment(s)');
select is (pg_temp.fc_update (), 1::bigint, 'blocked / UPDATE reaches 1 comment(s) (own rows only)');
select is (pg_temp.fc_delete (), 1::bigint, 'blocked / DELETE reaches 1 comment(s) (own rows only)');

reset role;

-- -----------------------------------------------------------------------------
-- D. The write policies in detail
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000002","role":"authenticated"}';

select ok (not pg_temp.fc_try_insert ('e3000000-0000-0000-0000-000000000001',
                                       'e3000000-0000-0000-0000-000000000101'),
           'RLS: a member cannot forge a comment in the name of another user');
select is (pg_temp.fc_try_update ('e3000000-0000-0000-0000-000000000301', 'edited by the author'), 1,
           'RLS: a member may edit the body of its OWN comment');
select is ((select body from public.feed_post_comments where id = 'e3000000-0000-0000-0000-000000000301'),
           'edited by the author',
           'the own edit was applied');
select is (pg_temp.fc_try_update ('e3000000-0000-0000-0000-000000000302', 'edited by a stranger'), 0,
           'RLS: a member may NOT edit the body of another member''s comment');
select ok (not pg_temp.fc_try_hide ('e3000000-0000-0000-0000-000000000301'),
           'RLS: a client may never set the moderation flag (no column privilege)');

reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000003","role":"authenticated"}';

select ok (not pg_temp.fc_try_insert ('e3000000-0000-0000-0000-000000000003',
                                       'e3000000-0000-0000-0000-000000000101'),
           'RLS: an outsider may not comment in a group it does not belong to');
select is (pg_temp.fc_try_update ('e3000000-0000-0000-0000-000000000301', 'edited by an outsider'), 0,
           'RLS: an outsider may not edit a comment');

reset role;

-- -----------------------------------------------------------------------------
-- E. The RPCs
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000002","role":"authenticated"}';

-- create
select is ((public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000203', '  amem  ') ->> 'body'),
           'amem',
           'create_feed_post_comment: the body is trimmed');
select is ((public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000203', 'amem') ->> 'user_id'),
           'e3000000-0000-0000-0000-000000000002',
           'create_feed_post_comment: the comment belongs to the caller');
select is ((public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000203', 'amem') ->> 'group_id'),
           'e3000000-0000-0000-0000-000000000101',
           'create_feed_post_comment: the group is the post''s group');
select is ((public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000203', 'amem') ->> 'is_hidden'),
           'false',
           'create_feed_post_comment: a new comment is not hidden');
select is ((public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000203', 'amem') ->> 'post_id'),
           'e3000000-0000-0000-0000-000000000203',
           'create_feed_post_comment: the comment is attached to the post');

select throws_ok ($$select public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000203', '   ')$$,
                  '22023', 'comment body cannot be empty',
                  'create_feed_post_comment: a blank body is rejected');
select throws_ok ($$select public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000203', repeat ('x', 501))$$,
                  '22023', 'comment body must be at most 500 characters',
                  'create_feed_post_comment: a body longer than 500 characters is rejected');
select ok ((public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000203', repeat ('x', 500)) ->> 'id') is not null,
           'create_feed_post_comment: a body of exactly 500 characters is accepted');

-- the DATABASE enforces the length too
select throws_ok (
  $$insert into public.feed_post_comments (post_id, group_id, user_id, body)
    values ('e3000000-0000-0000-0000-000000000201', 'e3000000-0000-0000-0000-000000000101',
            'e3000000-0000-0000-0000-000000000002', '')$$,
  '23514', 'new row for relation "feed_post_comments" violates check constraint "feed_post_comments_body_check"',
  'the database rejects a blank body');
select throws_ok (
  $$insert into public.feed_post_comments (post_id, group_id, user_id, body)
    values ('e3000000-0000-0000-0000-000000000201', 'e3000000-0000-0000-0000-000000000101',
            'e3000000-0000-0000-0000-000000000002', repeat ('x', 501))$$,
  '23514', 'new row for relation "feed_post_comments" violates check constraint "feed_post_comments_body_check"',
  'the database rejects a body longer than 500 characters');

-- append semantics: the same member may comment several times
select is ((select count (*) from public.feed_post_comments
             where post_id = 'e3000000-0000-0000-0000-000000000203'
               and user_id = 'e3000000-0000-0000-0000-000000000002'),
           6::bigint,
           'append semantics: the same member may comment several times (no uniqueness)');

-- the list
select is (jsonb_array_length (public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000201') -> 'items'),
           3,
           'get_feed_post_comments: the member sees 3 comments of P1 (the blocked one is hidden)');
select is ((public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000201') -> 'items' -> 0 ->> 'body'),
           'admin comment',
           'get_feed_post_comments: the newest comment comes first');
select is ((select count (*) from public.feed_post_comments
             where user_id = 'e3000000-0000-0000-0000-000000000004'), 0::bigint,
           'a blocked pair cannot see each other''s comments (the blocker sees none of them)');

reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000004","role":"authenticated"}';

select is ((select count (*) from public.feed_post_comments
             where user_id = 'e3000000-0000-0000-0000-000000000002'), 0::bigint,
           'a blocked pair cannot see each other''s comments (the blocked sees none of them)');
select throws_ok ($$select public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000201', 'hello')$$,
                  '42501', 'post not available',
                  'create_feed_post_comment: a blocked member cannot comment on the blocker''s post');
select throws_ok ($$select public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000201')$$,
                  '42501', 'post not available',
                  'get_feed_post_comments: a blocked member cannot read the comments of the blocker''s post');

reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000003","role":"authenticated"}';

select throws_ok ($$select public.create_feed_post_comment ('e3000000-0000-0000-0000-000000000201', 'hello')$$,
                  '42501', 'post not available',
                  'create_feed_post_comment: a non-member cannot comment');
select throws_ok ($$select public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000201')$$,
                  '42501', 'post not available',
                  'get_feed_post_comments: a non-member cannot read the comments');

reset role;

-- -----------------------------------------------------------------------------
-- F. The cursor pagination (P2: 6 comments, two of them share a created_at)
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is (pg_temp.fc_ids (null, 2),
           array['e3000000-0000-0000-0000-000000000406', 'e3000000-0000-0000-0000-000000000401'],
           'pagination: page 1 returns the two newest comments (identical created_at -> id DESC)');
select is ((public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000202', null, 2) ->> 'next_cursor'),
           '2026-01-05T10:00:00.000000Z|e3000000-0000-0000-0000-000000000401',
           'pagination: the cursor is the composite <created_at>|<id> of the oldest row of the page');
select is (pg_temp.fc_ids ('2026-01-05T10:00:00.000000Z|e3000000-0000-0000-0000-000000000401', 2),
           array['e3000000-0000-0000-0000-000000000402', 'e3000000-0000-0000-0000-000000000403'],
           'pagination: page 2 continues exactly where page 1 stopped');
select is (pg_temp.fc_ids ('2026-01-03T10:00:00.000000Z|e3000000-0000-0000-0000-000000000403', 2),
           array['e3000000-0000-0000-0000-000000000404', 'e3000000-0000-0000-0000-000000000405'],
           'pagination: page 3 returns the two oldest comments');
select is (pg_temp.fc_ids ('2026-01-01T10:00:00.000000Z|e3000000-0000-0000-0000-000000000405', 2),
           array[]::text[],
           'pagination: the last page is empty');
select ok ((public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000202',
                                            '2026-01-01T10:00:00.000000Z|e3000000-0000-0000-0000-000000000405', 2) ->> 'next_cursor') is null,
           'pagination: next_cursor is null on the last page');
select is (cardinality (pg_temp.fc_ids (null, 0)), 1,
           'pagination: p_limit = 0 is clamped to 1');
select is (cardinality (pg_temp.fc_ids (null, 999)), 6,
           'pagination: p_limit is clamped to 50 (the 6 comments fit)');

reset role;

-- -----------------------------------------------------------------------------
-- G. The moderation path
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000002","role":"authenticated"}';

select throws_ok ($$select public.soft_delete_feed_post_comment ('e3000000-0000-0000-0000-000000000301')$$,
                  '42501', 'only a group admin can remove a comment',
                  'soft_delete_feed_post_comment: a plain member cannot hide a comment');
select throws_ok ($$select public.delete_feed_post_comment ('e3000000-0000-0000-0000-000000000302')$$,
                  '42501', 'only the author or a group admin can delete a comment',
                  'delete_feed_post_comment: a plain member cannot delete another member''s comment');

reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is ((public.soft_delete_feed_post_comment ('e3000000-0000-0000-0000-000000000301') ->> 'hidden'), 'true',
           'soft_delete_feed_post_comment: the comment is hidden');
select is ((public.soft_delete_feed_post_comment ('e3000000-0000-0000-0000-000000000301') ->> 'changed'), '0',
           'soft_delete_feed_post_comment: the second call changes nothing (idempotent)');
select is ((public.soft_delete_feed_post_comment ('e3000000-0000-0000-0000-000000000301') ->> 'hidden_reason'), 'admin_removed',
           'soft_delete_feed_post_comment: the hidden reason is admin_removed');
select is (jsonb_array_length (public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000201') -> 'items'),
           4,
           'the ADMIN still sees the hidden comment');

reset role;

select is ((select count (*) from public.audit_log
             where action = 'feed.comment_removed'
               and target_type = 'feed_post_comment'
               and target_id = 'e3000000-0000-0000-0000-000000000301'),
           1::bigint,
           'exactly ONE audit_log row was written for the soft delete');
select is ((select metadata ->> 'group_id' from public.audit_log
             where action = 'feed.comment_removed'
               and target_id = 'e3000000-0000-0000-0000-000000000301'),
           'e3000000-0000-0000-0000-000000000101',
           'the audit_log metadata carries the group id');
select is ((select count (*) from public.feed_post_comments
             where id = 'e3000000-0000-0000-0000-000000000301' and is_hidden),
           1::bigint,
           'the soft-deleted comment is kept in the table (soft delete)');

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000002","role":"authenticated"}';

select is (jsonb_array_length (public.get_feed_post_comments ('e3000000-0000-0000-0000-000000000201') -> 'items'),
           2,
           'a hidden comment is INVISIBLE to a plain member');

reset role;

-- -----------------------------------------------------------------------------
-- H. The hard delete
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000002","role":"authenticated"}';

select is ((public.delete_feed_post_comment ('e3000000-0000-0000-0000-000000000304') ->> 'deleted'), 'true',
           'delete_feed_post_comment: the AUTHOR may delete his own comment');

reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"e3000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is ((public.delete_feed_post_comment ('e3000000-0000-0000-0000-000000000302') ->> 'deleted'), 'true',
           'delete_feed_post_comment: a group ADMIN may delete any comment of the group');

reset role;

select is ((select count (*) from public.feed_post_comments
             where id in ('e3000000-0000-0000-0000-000000000302', 'e3000000-0000-0000-0000-000000000304')),
           0::bigint,
           'the hard-deleted comments are gone');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
