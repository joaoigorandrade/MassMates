-- =============================================================================
-- A6 · storage_moderation.sql · storage + moderation + safety test suite
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish();
--   select public.pgtap_summary() as result;   -- always the last result set
--   rollback;
-- `public.pgtap_summary()` is the verdict: {"verdict":"PASS"|"FAIL", ...}.
--
-- NOTE ON ROLE SWITCHING: every state assertion is made as the GROUP ADMIN
-- (u1), because A5's feed_posts policy hides `is_hidden` rows from plain
-- members and A6's moderation_actions is admin-only.
-- =============================================================================

begin;
set local search_path = extensions, public;

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------
-- u1 group admin · u2 member (post author + photo owner) · u3/u4 reporters
-- u5 outsider (not a member) · u6 member used for the block test
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a6000000-0000-0000-0000-000000000001', 'a6_admin@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{"display_name":"A6 Admin"}'::jsonb, now(), now()),
  ('a6000000-0000-0000-0000-000000000002', 'a6_member@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{"display_name":"A6 Member"}'::jsonb, now(), now()),
  ('a6000000-0000-0000-0000-000000000003', 'a6_reporter2@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{"display_name":"A6 Reporter 2"}'::jsonb, now(), now()),
  ('a6000000-0000-0000-0000-000000000004', 'a6_reporter3@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{"display_name":"A6 Reporter 3"}'::jsonb, now(), now()),
  ('a6000000-0000-0000-0000-000000000005', 'a6_outsider@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{"display_name":"A6 Outsider"}'::jsonb, now(), now()),
  ('a6000000-0000-0000-0000-000000000006', 'a6_blocker@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{"display_name":"A6 Blocker"}'::jsonb, now(), now());

insert into public.groups (id, name, created_by)
values ('a6000000-0000-0000-0000-0000000000aa', 'A6 Test Group', 'a6000000-0000-0000-0000-000000000001');

insert into public.group_members (group_id, user_id, role)
values
  ('a6000000-0000-0000-0000-0000000000aa', 'a6000000-0000-0000-0000-000000000001', 'admin'),
  ('a6000000-0000-0000-0000-0000000000aa', 'a6000000-0000-0000-0000-000000000002', 'member'),
  ('a6000000-0000-0000-0000-0000000000aa', 'a6000000-0000-0000-0000-000000000003', 'member'),
  ('a6000000-0000-0000-0000-0000000000aa', 'a6000000-0000-0000-0000-000000000004', 'member'),
  ('a6000000-0000-0000-0000-0000000000aa', 'a6000000-0000-0000-0000-000000000006', 'member');

insert into public.feed_posts (id, group_id, user_id, practice_kind, reflection_text, points)
values
  ('a6000000-0000-0000-0000-0000000000bb', 'a6000000-0000-0000-0000-0000000000aa', 'a6000000-0000-0000-0000-000000000002', 'rosary', 'A6 test post one', 1),
  ('a6000000-0000-0000-0000-0000000000cc', 'a6000000-0000-0000-0000-0000000000aa', 'a6000000-0000-0000-0000-000000000002', 'rosary', 'A6 test post two', 1);

-- SECURITY INVOKER helpers: they run with the CURRENT role, therefore with the
-- current RLS policies. They return true when the statement was ALLOWED.
create function pg_temp.anon_insert_report ()
  returns boolean
  language plpgsql
as $$
begin
  insert into public.content_reports (reporter_id, target_type, target_id, reason)
  values ('a6000000-0000-0000-0000-000000000005', 'post', 'a6000000-0000-0000-0000-0000000000bb', 'spam');
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.outsider_delete_post ()
  returns boolean
  language plpgsql
as $$
begin
  perform public.admin_delete_post ('a6000000-0000-0000-0000-0000000000cc');
  return true;
exception
  when others then
    return false;
end;
$$;

select plan(81);

-- ---------------------------------------------------------------------------
-- A. Buckets
-- ---------------------------------------------------------------------------
select ok ((select count(*) from storage.buckets where id in ('avatars','group-covers','witness-photos')) = 3,
            'A6: the three storage buckets exist');
select ok ((select public from storage.buckets where id = 'avatars') is true,
            'A6: avatars is a PUBLIC bucket');
select ok ((select public from storage.buckets where id = 'group-covers') is true,
            'A6: group-covers is a PUBLIC bucket');
select ok ((select public from storage.buckets where id = 'witness-photos') is false,
            'A6: witness-photos is a PRIVATE bucket');
select ok ((select file_size_limit from storage.buckets where id = 'avatars') = 5242880,
            'A6: avatars file_size_limit is 5 MB');
select ok ((select file_size_limit from storage.buckets where id = 'group-covers') = 8388608,
            'A6: group-covers file_size_limit is 8 MB');
select ok ((select file_size_limit from storage.buckets where id = 'witness-photos') = 10485760,
            'A6: witness-photos file_size_limit is 10 MB');
select ok ((select allowed_mime_types from storage.buckets where id = 'avatars') = array['image/jpeg','image/png','image/heic','image/webp'],
            'A6: avatars accepts images only');
select ok ((select allowed_mime_types from storage.buckets where id = 'group-covers') = array['image/jpeg','image/png','image/heic','image/webp'],
            'A6: group-covers accepts images only');
select ok ((select allowed_mime_types from storage.buckets where id = 'witness-photos') = array['image/jpeg','image/png','image/heic','image/webp'],
            'A6: witness-photos accepts images only');

-- ---------------------------------------------------------------------------
-- B. storage.objects policies
-- ---------------------------------------------------------------------------
select ok ((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'avatars%') >= 4,
            'A6: storage.objects has the 4 avatars policies');
select ok ((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'group_covers%') >= 4,
            'A6: storage.objects has the 4 group-covers policies');
select ok ((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'witness_photos%') >= 4,
            'A6: storage.objects has the 4 witness-photos policies');
-- SACRED PRIVACY: no anon role may touch the witness-photos bucket at all.
select ok (not exists (
             select 1 from pg_policies
              where schemaname = 'storage' and tablename = 'objects'
                and policyname like 'witness_photos%' and 'anon' = any (roles)),
            'A6: witness-photos has NO policy for anon (sacred privacy)');
select ok (not exists (
             select 1 from pg_policies
              where schemaname = 'storage' and tablename = 'objects'
                and policyname like 'witness_photos%' and cmd in ('SELECT','INSERT') and 'anon' = any (roles)),
            'A6: witness-photos exposes no SELECT/INSERT policy to anon');
select ok (exists (
             select 1 from pg_policies
              where schemaname = 'storage' and tablename = 'objects'
                and policyname = 'witness_photos_select_members' and cmd = 'SELECT'
                and qual like '%is_group_member%'),
            'A6: witness-photos read policy is scoped to group members');
select ok (exists (
             select 1 from pg_policies
              where schemaname = 'storage' and tablename = 'objects'
                and policyname = 'witness_photos_insert_owner' and cmd = 'INSERT'
                and with_check like '%foldername%' and with_check like '%is_group_member%'),
            'A6: witness-photos write policy enforces the <group>/<user> path');
select ok (exists (
             select 1 from pg_policies
              where schemaname = 'storage' and tablename = 'objects'
                and policyname = 'avatars_select_public' and cmd = 'SELECT'
                and 'anon' = any (roles) and 'authenticated' = any (roles)),
            'A6: avatars read policy is open to anon and authenticated');

-- ---------------------------------------------------------------------------
-- C. Tables, RLS, view, trigger and RPC signatures
-- ---------------------------------------------------------------------------
select has_table ('public', 'content_reports', 'A6: content_reports table exists');
select has_table ('public', 'moderation_actions', 'A6: moderation_actions table exists');
select has_view ('public', 'v_target_report_counts', 'A6: v_target_report_counts view exists');
select ok (public.pgtap_rls_enabled ('public.content_reports'::regclass), 'A6: RLS is enabled on content_reports');
select ok (public.pgtap_rls_forced ('public.content_reports'::regclass), 'A6: RLS is FORCED on content_reports');
select ok (public.pgtap_rls_enabled ('public.moderation_actions'::regclass), 'A6: RLS is enabled on moderation_actions');
select ok (public.pgtap_rls_forced ('public.moderation_actions'::regclass), 'A6: RLS is FORCED on moderation_actions');
select has_trigger ('public', 'content_reports', 'trg_content_reports_auto_hide', 'A6: the auto-hide trigger is attached');
select has_function ('public', 'block_user', array['uuid']::name[], 'A6: block_user(uuid) exists');
select has_function ('public', 'unblock_user', array['uuid']::name[], 'A6: unblock_user(uuid) exists');
select has_function ('public', 'list_blocked_users', 'A6: list_blocked_users() exists');
select has_function ('public', 'report_content', array['text','uuid','text','text','uuid']::name[], 'A6: report_content(text,uuid,text,text,uuid) exists');
select has_function ('public', 'admin_delete_post', array['uuid']::name[], 'A6: admin_delete_post(uuid) exists');
select has_function ('public', 'hide_content', array['text','uuid','text']::name[], 'A6: hide_content(text,uuid,text) exists');
select has_function ('public', 'get_moderation_queue', array['uuid']::name[], 'A6: get_moderation_queue(uuid) exists');
select has_function ('public', 'resolve_report', array['uuid','text','text']::name[], 'A6: resolve_report(uuid,text,text) exists');
select has_function ('public', 'get_moderation_actions', array['uuid']::name[], 'A6: get_moderation_actions(uuid) exists');
select has_function ('public', 'create_signed_witness_url', array['text','integer']::name[], 'A6: create_signed_witness_url(text,integer) exists');

-- ---------------------------------------------------------------------------
-- D. Blocking (u1 = admin blocks u5 = outsider)
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000001","role":"authenticated","email":"a6_admin@example.test"}';

select lives_ok ($$select public.block_user('a6000000-0000-0000-0000-000000000005'::uuid)$$,
                 'A6: block_user runs without error');
select ok ((select count(*) from public.user_blocks
             where blocker_id = 'a6000000-0000-0000-0000-000000000001'
               and blocked_id = 'a6000000-0000-0000-0000-000000000005') = 1,
            'A6: block_user inserts the user_blocks row');
select lives_ok ($$select public.block_user('a6000000-0000-0000-0000-000000000005'::uuid)$$,
                 'A6: block_user is idempotent (retry does not error)');
select ok ((select count(*) from public.user_blocks
             where blocker_id = 'a6000000-0000-0000-0000-000000000001'
               and blocked_id = 'a6000000-0000-0000-0000-000000000005') = 1,
            'A6: block_user is idempotent (no duplicate row)');
select throws_ok ($$select public.block_user('a6000000-0000-0000-0000-000000000001'::uuid)$$,
                  '22023', 'you cannot block yourself',
                  'A6: block_user rejects a self block');
select ok (public.is_blocked ('a6000000-0000-0000-0000-000000000001', 'a6000000-0000-0000-0000-000000000005'),
            'A6: is_blocked is true for the blocker');
select ok (public.is_blocked ('a6000000-0000-0000-0000-000000000005', 'a6000000-0000-0000-0000-000000000001'),
            'A6: is_blocked is true for the blocked user (symmetric)');
select lives_ok ($$select public.unblock_user('a6000000-0000-0000-0000-000000000005'::uuid)$$,
                 'A6: unblock_user runs without error');
select ok ((select count(*) from public.user_blocks
             where blocker_id = 'a6000000-0000-0000-0000-000000000001'
               and blocked_id = 'a6000000-0000-0000-0000-000000000005') = 0,
            'A6: unblock_user removes the user_blocks row');
select lives_ok ($$select public.unblock_user('a6000000-0000-0000-0000-000000000005'::uuid)$$,
                 'A6: unblock_user is idempotent (retry does not error)');
select ok ((select count(*) from public.user_blocks
             where blocker_id = 'a6000000-0000-0000-0000-000000000001') = 0,
            'A6: unblock_user leaves no row behind');
select ok ((public.list_blocked_users () ->> 'count')::int = 0,
            'A6: list_blocked_users reports an empty list after unblocking');

-- ---------------------------------------------------------------------------
-- E. Reporting + auto-hide (3 independent reporters)
-- ---------------------------------------------------------------------------
select lives_ok ($$select public.report_content('post', 'a6000000-0000-0000-0000-0000000000bb'::uuid, 'spam', 'first report'::text, null::uuid)$$,
                 'A6: report_content runs without error');
select ok ((select count(*) from public.content_reports
             where target_type = 'post' and target_id = 'a6000000-0000-0000-0000-0000000000bb') = 1,
            'A6: report_content inserts a content_reports row');
select ok ((select (public.report_content('post', 'a6000000-0000-0000-0000-0000000000bb'::uuid, 'spam', null, null)) ->> 'duplicate') = 'true',
            'A6: report_content is idempotent for the same reporter and target');
select ok ((select count(*) from public.content_reports
             where target_type = 'post' and target_id = 'a6000000-0000-0000-0000-0000000000bb') = 1,
            'A6: the idempotent retry did not create a second report');
select throws_ok ($$select public.report_content('post', 'a6000000-0000-0000-0000-0000000000bb'::uuid, 'not_a_reason', null, null)$$,
                  '22023', 'invalid reason',
                  'A6: report_content rejects an invalid reason');
select throws_ok ($$select public.report_content('not_a_type', 'a6000000-0000-0000-0000-0000000000bb'::uuid, 'spam', null, null)$$,
                  '22023', 'invalid target type',
                  'A6: report_content rejects an invalid target type');

-- second reporter
set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000003","role":"authenticated"}';
select lives_ok ($$select public.report_content('post', 'a6000000-0000-0000-0000-0000000000bb'::uuid, 'harassment', 'second report'::text, null::uuid)$$,
                 'A6: the second reporter can file a report');
select ok ((select is_hidden from public.feed_posts where id = 'a6000000-0000-0000-0000-0000000000bb') is false,
            'A6: two reports do NOT auto-hide the post (threshold is 3)');

-- third reporter crosses the threshold
set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000004","role":"authenticated"}';
select lives_ok ($$select public.report_content('post', 'a6000000-0000-0000-0000-0000000000bb'::uuid, 'hate', 'third report'::text, null::uuid)$$,
                 'A6: the third reporter can file a report');

-- the state is verified as the group admin (hidden posts are admin-only)
set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000001","role":"authenticated"}';
select ok ((select is_hidden from public.feed_posts where id = 'a6000000-0000-0000-0000-0000000000bb') is true,
            'A6: the third report auto-hides the post');
select ok ((select hidden_reason from public.feed_posts where id = 'a6000000-0000-0000-0000-0000000000bb') = 'auto_hidden',
            'A6: the auto-hidden post carries hidden_reason = auto_hidden');
select ok ((select count(*) from public.moderation_actions
             where action_type = 'auto_hide'
               and target_type = 'post'
               and target_id = 'a6000000-0000-0000-0000-0000000000bb') = 1,
            'A6: a moderation_actions row of type auto_hide was written');
select ok ((select (public.report_content('post', 'a6000000-0000-0000-0000-0000000000bb'::uuid, 'other', null, null)) ->> 'auto_hidden')::boolean is true,
            'A6: report_content reports auto_hidden = true once the threshold is crossed');
select ok ((select count(*) from public.v_target_report_counts
             where target_type = 'post' and target_id = 'a6000000-0000-0000-0000-0000000000bb') = 1,
            'A6: v_target_report_counts exposes the report counter of the target');

-- ---------------------------------------------------------------------------
-- F. admin_delete_post (group admin only)
-- ---------------------------------------------------------------------------
set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000005","role":"authenticated"}';
select ok (not pg_temp.outsider_delete_post (),
            'A6: a non-admin cannot call admin_delete_post');

set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000001","role":"authenticated"}';
select ok ((select is_hidden from public.feed_posts where id = 'a6000000-0000-0000-0000-0000000000cc') is false,
            'A6: the rejected admin_delete_post did not hide the post');
select lives_ok ($$select public.admin_delete_post('a6000000-0000-0000-0000-0000000000cc'::uuid)$$,
                 'A6: a group admin can call admin_delete_post');
select ok ((select is_hidden from public.feed_posts where id = 'a6000000-0000-0000-0000-0000000000cc') is true,
            'A6: the post is hidden after admin_delete_post');
select ok ((select count(*) from public.moderation_actions
             where action_type = 'delete_post'
               and target_id = 'a6000000-0000-0000-0000-0000000000cc') = 1,
            'A6: admin_delete_post wrote a delete_post moderation action');
select ok ((select count(*) from public.audit_log
             where action = 'moderation.post_deleted'
               and target_id = 'a6000000-0000-0000-0000-0000000000cc') = 1,
            'A6: admin_delete_post wrote an audit_log row');

-- ---------------------------------------------------------------------------
-- G. content_reports RLS
-- ---------------------------------------------------------------------------
set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000003","role":"authenticated"}';
select ok ((select count(*) from public.content_reports
             where reporter_id = 'a6000000-0000-0000-0000-000000000003') = 1,
            'A6: RLS: a user sees their own report');
select ok ((select count(*) from public.content_reports
             where reporter_id = 'a6000000-0000-0000-0000-000000000004') = 0,
            'A6: RLS: a user cannot see another user''s report');

set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000001","role":"authenticated"}';
select ok ((select count(*) from public.content_reports
             where group_id = 'a6000000-0000-0000-0000-0000000000aa') = 3,
            'A6: RLS: a group admin sees the reports of their group');

set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000005","role":"authenticated"}';
select ok ((select count(*) from public.content_reports) = 0,
            'A6: RLS: an outsider sees no report at all');

set local role anon;
set local request.jwt.claims = '{}';
select ok ((select count(*) from public.content_reports) = 0,
            'A6: RLS: anon sees no report');
select ok (not pg_temp.anon_insert_report (),
            'A6: RLS: anon cannot insert a report');

-- ---------------------------------------------------------------------------
-- H. create_signed_witness_url
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000001","role":"authenticated"}';

select throws_ok (
  $$select public.create_signed_witness_url(
       'witness-photos/99999999-9999-9999-9999-999999999999/a6000000-0000-0000-0000-000000000002/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg'::text,
       300::integer)$$,
  '42501', 'not a member of the group that owns this photo',
  'A6: create_signed_witness_url rejects a non-member of the group');
select throws_ok (
  $$select public.create_signed_witness_url('witness-photos/not-a-uuid/x/y.jpg'::text, 300::integer)$$,
  '22023', 'invalid witness photo path',
  'A6: create_signed_witness_url rejects a malformed path');
select ok ((public.create_signed_witness_url (
       'witness-photos/a6000000-0000-0000-0000-0000000000aa/a6000000-0000-0000-0000-000000000002/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg'::text,
       99999::integer) ->> 'object_path')
       = 'a6000000-0000-0000-0000-0000000000aa/a6000000-0000-0000-0000-000000000002/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg',
            'A6: create_signed_witness_url returns the bucket-relative object path');
select ok ((public.create_signed_witness_url (
       'witness-photos/a6000000-0000-0000-0000-0000000000aa/a6000000-0000-0000-0000-000000000002/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg'::text,
       99999::integer) ->> 'expires_in')::int = 3600,
            'A6: create_signed_witness_url clamps the TTL to 3600 seconds');
select ok ((public.create_signed_witness_url (
       'witness-photos/a6000000-0000-0000-0000-0000000000aa/a6000000-0000-0000-0000-000000000002/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg'::text,
       5::integer) ->> 'expires_in')::int = 60,
            'A6: create_signed_witness_url clamps the TTL to 60 seconds');

-- a block hides the photo from the blocked user
set local request.jwt.claims = '{"sub":"a6000000-0000-0000-0000-000000000006","role":"authenticated"}';
select lives_ok ($$select public.block_user('a6000000-0000-0000-0000-000000000002'::uuid)$$,
                 'A6: u6 blocks the photo owner');
select throws_ok (
  $$select public.create_signed_witness_url(
       'witness-photos/a6000000-0000-0000-0000-0000000000aa/a6000000-0000-0000-0000-000000000002/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg'::text,
       300::integer)$$,
  '42501', 'blocked by the photo owner',
  'A6: create_signed_witness_url refuses a user blocked by the photo owner');

-- ---------------------------------------------------------------------------
-- Verdict
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims = '{}';

select * from finish ();
select public.pgtap_summary () as result;

rollback;
