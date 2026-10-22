-- =============================================================================
-- A10 · privacy.sql · the sacred-privacy audit (hard build gate)
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
--
-- WHAT IT PROVES
--   A. CATALOG SCAN (static)
--      A1 no table / column / bucket is named like a confession or Spiritual
--         Diary store -- the deliberate absence is documented here
--      A2 the `check_ins` privacy CHECKs exist AND are enforced
--      A3 `feed_posts` refuses a confession
--      A4 the `witness-photos` bucket is private and `anon` has NO policy on
--         `storage.objects`
--   B. BEHAVIOURAL PROOF (the end-to-end flow, in one transaction)
--      Alice creates a fraternity, Bob joins with the 6-digit code, Bob
--      submits a group check-in with a reflection, a private check-in WITH a
--      reflection (rejected), a private check-in WITHOUT content (accepted),
--      and a confession as a group check-in (rejected). The fan-out counts,
--      the streak, the Rule of Life Ring, the outbox and the audit log are
--      all asserted.
--   C. GUARDIAN ANGEL ANONYMITY
--      the nudge payload carries neither the sender's id nor the sender's
--      name, and `guardian_angel_pairings` is not client-readable.
--   D. THE MODERATION PATH
--      a post auto-hides after 3 independent reports; a group admin can hide
--      a chat message.
--
--   Fixture
--     d1 Alice   d1000000-0000-0000-0000-000000000001  admin of the fraternity
--     d2 Bob     d1000000-0000-0000-0000-000000000002  member (the subject)
--     d3 Carla   d1000000-0000-0000-0000-000000000003  member (reporter 2)
--     d4 Daniel  d1000000-0000-0000-0000-000000000004  member (reporter 3)
--     d5 Eve     d1000000-0000-0000-0000-000000000005  member (the guardian)
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(65);

-- -----------------------------------------------------------------------------
-- A. The catalog scan
-- -----------------------------------------------------------------------------

-- A1. The deliberate absence: there is NO confession store and NO Spiritual
--     Diary store anywhere in the backend. The word "confession" exists only
--     as a VALUE of public.practice_kind (a kind of practice that may be
--     RECORDED, never shared) and in the CHECK constraints that forbid
--     sharing it.
select ok (not exists (
         select 1 from pg_catalog.pg_class c
         join pg_catalog.pg_namespace n on n.oid = c.relnamespace
         where n.nspname = 'public' and c.relkind = 'r'
           and c.relname ~* '(confession|confisso|diary|diario|penance|sacrament)'),
       'A1: no public TABLE is named like a confession / Spiritual Diary store');

select ok (not exists (
         select 1 from pg_catalog.pg_attribute a
         join pg_catalog.pg_class c on c.oid = a.attrelid
         join pg_catalog.pg_namespace n on n.oid = c.relnamespace
         where n.nspname = 'public' and a.attnum > 0 and not a.attisdropped
           and a.attname ~* '(confession|confisso|diary|diario|penance|sacrament)'),
       'A1: no public COLUMN is named like a confession / Spiritual Diary store');

select ok (not exists (
         select 1 from storage.buckets
         where id ~* '(confession|confisso|diary|diario|penance|sacrament)'),
       'A1: no storage BUCKET is named like a confession / Spiritual Diary store');

select is ((select string_agg (id, ',' order by id) from storage.buckets),
           'avatars,group-covers,witness-photos',
           'A1: the storage buckets are exactly the three documented ones');

-- A2. The two privacy CHECKs of public.check_ins exist...
select ok (exists (select 1 from pg_catalog.pg_constraint
                   where conrelid = 'public.check_ins'::regclass
                     and conname = 'check_ins_private_has_no_content_ck' and contype = 'c'),
           'A2: check_ins has the private-has-no-content CHECK');
select ok (exists (select 1 from pg_catalog.pg_constraint
                   where conrelid = 'public.check_ins'::regclass
                     and conname = 'check_ins_confession_is_private_ck' and contype = 'c'),
           'A2: check_ins has the confession-is-private CHECK');

-- ... and they are ENFORCED (a direct INSERT is rejected).
select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone, reflection_text)
    values ('d1000000-0000-0000-0000-000000000002', 'rosary', 'private', current_date, 'UTC', 'secret diary')$$,
  '23514', 'new row for relation "check_ins" violates check constraint "check_ins_private_has_no_content_ck"',
  'A2: a private check-in with a reflection is rejected by the database');

select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone, photo_path)
    values ('d1000000-0000-0000-0000-000000000002', 'rosary', 'private', current_date, 'UTC', 'witness-photos/g/u/x.jpg')$$,
  '23514', 'new row for relation "check_ins" violates check constraint "check_ins_private_has_no_content_ck"',
  'A2: a private check-in with a photo is rejected by the database');

select throws_ok (
  $$insert into public.check_ins (user_id, practice_kind, sharing, local_date, timezone)
    values ('d1000000-0000-0000-0000-000000000002', 'confession', 'group', current_date, 'UTC')$$,
  '23514', 'new row for relation "check_ins" violates check constraint "check_ins_confession_is_private_ck"',
  'A2: a confession shared with the group is rejected by the database');

-- A3. The feed can never carry a confession.
select ok (exists (select 1 from pg_catalog.pg_constraint
                   where conrelid = 'public.feed_posts'::regclass
                     and conname = 'feed_posts_no_confession' and contype = 'c'),
           'A3: feed_posts has the no-confession CHECK');
select throws_ok (
  $$insert into public.feed_posts (group_id, user_id, practice_kind)
    values ('d1000000-0000-0000-0000-000000000101', 'd1000000-0000-0000-0000-000000000002', 'confession')$$,
  '23514', 'new row for relation "feed_posts" violates check constraint "feed_posts_no_confession"',
  'A3: a confession can never reach the feed');

-- A4. The only private bucket is private, and `anon` has no storage policy.
select ok ((select b.public from storage.buckets b where b.id = 'witness-photos') = false,
           'A4: the witness-photos bucket is NOT public');
select ok (not exists (
         select 1 from pg_catalog.pg_policies
         where schemaname = 'storage' and 'anon'::name = any (roles)
           and (coalesce (qual, '') like '%witness-photos%'
                or coalesce (with_check, '') like '%witness-photos%')),
       'A4: anon has NO policy on the private witness-photos bucket');
select is ((select string_agg (policyname, ',' order by policyname)
            from pg_catalog.pg_policies
            where schemaname = 'storage' and 'anon'::name = any (roles)),
           'avatars_select_public,group_covers_select_public',
           'A4: anon may only READ the two PUBLIC buckets');
select ok (not exists (
         select 1 from pg_catalog.pg_policies
         where schemaname = 'storage' and cmd in ('INSERT', 'UPDATE', 'DELETE')
           and 'anon'::name = any (roles)),
       'A4: anon may never write to storage.objects');

-- A5. The only columns that can hold free text written by a user are the
--     ones the moderation flow can act on; the `private` flag is the gate.
select ok (exists (
         select 1 from pg_catalog.pg_constraint
         where conrelid = 'public.check_ins'::regclass
           and pg_get_constraintdef (oid) like '%reflection_text IS NULL%'
           and pg_get_constraintdef (oid) like '%photo_path IS NULL%'),
       'A5: the private check-in gate is expressed by the CHECK constraint itself');

-- -----------------------------------------------------------------------------
-- B. The behavioural proof
-- -----------------------------------------------------------------------------

insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('d1000000-0000-0000-0000-000000000001', 'a10_priv_ana@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000002', 'a10_priv_bruno@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000003', 'a10_priv_carla@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000004', 'a10_priv_daniel@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('d1000000-0000-0000-0000-000000000005', 'a10_priv_eve@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

-- Bob commits to the Rosary AND to Adoration: the Rule of Life Ring tracks
-- the two FACTS, never the content.
update public.profiles
   set rule_of_life = '[{"kind":"rosary","label":"Rosary"},{"kind":"adoration","label":"Adoracao"}]'::jsonb
 where id = 'd1000000-0000-0000-0000-000000000002';

-- B1. Alice creates the fraternity.
set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000001","role":"authenticated"}';

create temporary table a10_created (invite_code text, group_id uuid);
grant insert, select on a10_created to authenticated;
grant usage, select on all sequences in schema pg_temp to authenticated;

insert into a10_created
select (r ->> 'invite_code'), (r -> 'group' ->> 'id')::uuid
from (select public.create_group ('A10 Privacy Fraternity') as r) s;

select ok ((select invite_code ~ '^[0-9]{6}$' from a10_created),
           'B1: Alice creates a fraternity and gets a 6-digit invite code');

-- B2. Bob joins with that code.
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';

select is ((public.join_group_by_code ((select invite_code from a10_created)) ->> 'member_role'), 'member',
           'B2: Bob joins the fraternity with the 6-digit code');

-- Carla and Daniel join too: they are the INDEPENDENT reporters of section D.
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000003","role":"authenticated"}';
select is ((public.join_group_by_code ((select invite_code from a10_created)) ->> 'member_role'), 'member',
           'B2: Carla joins the fraternity with the 6-digit code');
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000004","role":"authenticated"}';
select is ((public.join_group_by_code ((select invite_code from a10_created)) ->> 'member_role'), 'member',
           'B2: Daniel joins the fraternity with the 6-digit code');
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';
select is ((select count(*) from public.group_members
             where group_id = (select group_id from a10_created)), 4::bigint,
           'B2: the fraternity has exactly 4 members (Alice, Bob, Carla, Daniel)');

-- B3. Bob submits a GROUP check-in WITH a reflection.
select ok ((public.submit_check_in ('rosary', 'group', array[(select group_id from a10_created)]::uuid[],
                                     'a10 shared reflection', null, current_date, 'America/Sao_Paulo')
               ->> 'check_in_id') is not null,
           'B3: Bob submits a group check-in with a reflection');

select is ((select count(*) from public.check_ins
             where user_id = 'd1000000-0000-0000-0000-000000000002'), 1::bigint,
           'B3: exactly 1 check_ins row');
select is ((select count(*) from public.check_in_destinations), 1::bigint,
           'B3: exactly 1 check_in_destinations row (the group fan-out)');
select is ((select count(*) from public.feed_posts), 1::bigint,
           'B3: exactly 1 feed_posts row');
select is ((select count(*) from public.feed_posts
             where reflection_text = 'a10 shared reflection'), 1::bigint,
           'B3: the feed post carries the reflection');
select is ((select count(*) from public.check_ins
             where reflection_text = 'a10 shared reflection'), 1::bigint,
           'B3: the check-in carries the reflection');

-- B4. A PRIVATE check-in WITH a reflection is REJECTED.
select throws_ok ($$select public.submit_check_in('adoration', 'private', '{}'::uuid[],
                                                    'a10 SECRET diary', null, current_date, 'America/Sao_Paulo')$$,
                  '22023', 'private_check_in_cannot_hold_content',
                  'B4: a private check-in WITH a reflection is rejected');
select throws_ok ($$select public.submit_check_in('adoration', 'private', '{}'::uuid[],
                                                    null, 'witness-photos/g/u/x.jpg', current_date, 'America/Sao_Paulo')$$,
                  '22023', 'private_check_in_cannot_hold_content',
                  'B4: a private check-in WITH a photo is rejected');

-- B5. A CONFESSION shared with the group is REJECTED.
select throws_ok ($$select public.submit_check_in('confession', 'group', array[(select group_id from a10_created)]::uuid[],
                                                    null, null, current_date, 'America/Sao_Paulo')$$,
                  '22023', 'confession_is_private_only',
                  'B5: a confession cannot be shared with the group');

-- B6. A PRIVATE check-in WITHOUT content is ACCEPTED and stores NO content.
select ok ((public.submit_check_in ('adoration', 'private', '{}'::uuid[], null, null, current_date, 'America/Sao_Paulo')
               ->> 'check_in_id') is not null,
           'B6: a private check-in without content is accepted');
select is ((select count(*) from public.check_ins
             where user_id = 'd1000000-0000-0000-0000-000000000002' and sharing = 'private'), 1::bigint,
           'B6: exactly 1 private check-in');
select ok ((select reflection_text is null and photo_path is null
              from public.check_ins
             where user_id = 'd1000000-0000-0000-0000-000000000002' and sharing = 'private'),
           'B6: the private check-in stores NO reflection and NO photo');

-- B7. A private practice that is NOT a Rule of Life item is still recorded.
select ok ((public.submit_check_in ('fasting', 'private', '{}'::uuid[], null, null, current_date, 'America/Sao_Paulo')
               ->> 'check_in_id') is not null,
           'B7: a private check-in of a non-Rule-of-Life kind is accepted');

-- B8. THE FAN-OUT COUNTS -- nothing private ever fans out.
select is ((select count(*) from public.check_ins), 3::bigint,
           'B8: 3 check-ins in total (1 group + 2 private)');
select is ((select count(*) from public.check_in_destinations), 1::bigint,
           'B8: still exactly 1 check_in_destinations row -- the private check-ins fan out to NOBODY');
select is ((select count(*) from public.feed_posts), 1::bigint,
           'B8: still exactly 1 feed_posts row -- the private check-ins reach NO feed');
select is ((select count(*) from public.check_ins
             where sharing = 'private' and (reflection_text is not null or photo_path is not null)), 0::bigint,
           'B8: zero private check-ins carry content');
select is ((select count(*) from public.feed_posts
             where reflection_text like '%SECRET%' or reflection_text like '%diary%'), 0::bigint,
           'B8: zero feed rows carry the private text');
select is ((select count(*) from public.check_ins
             where practice_kind = 'confession' and sharing <> 'private'), 0::bigint,
           'B8: zero confession check-ins are shared');
select is ((select count(*) from public.feed_posts where practice_kind = 'confession'), 0::bigint,
           'B8: zero confession rows in feed_posts');
select is ((select count(*) from public.check_in_destinations
             where check_in_id in (select id from public.check_ins where sharing = 'private')), 0::bigint,
           'B8: zero destinations belong to a private check-in');

-- B9. The FACT is stored (streak), the CONTENT is not.
select is ((public.get_streak_summary () ->> 'total_practices')::int, 3,
           'B9: the streak counts all 3 practices, private ones included');
select is ((public.get_streak_summary () ->> 'current_streak')::int, 1,
           'B9: the current streak is 1 (one active day)');
select is ((public.get_rule_of_life_ring (current_date) ->> 'completed')::int, 2,
           'B9: the Rule of Life Ring counts the rosary AND the private adoration (facts, not content)');
select is ((public.get_rule_of_life_ring (current_date) ->> 'total')::int, 2,
           'B9: the Rule of Life Ring has 2 commitments');

-- B10. A private check-in never reaches the outbox or the audit log.
select is ((select count(*) from public.notification_outbox
             where title like '%SECRET%' or body like '%SECRET%'
                or payload::text like '%SECRET%' or payload::text like '%diary%'), 0::bigint,
           'B10: no notification carries the private text');
select is ((select count(*) from public.audit_log
             where metadata::text like '%SECRET%' or metadata::text like '%diary%'
                or metadata::text like '%adoration%'), 0::bigint,
           'B10: no audit-log entry carries the private text');
select is ((select count(*) from public.audit_log
             where target_type = 'check_in'), 0::bigint,
           'B10: a check-in is never written to the audit log at all');

reset role;

-- -----------------------------------------------------------------------------
-- C. The Guardian Angel anonymity
-- -----------------------------------------------------------------------------

-- The pairing is created server-side (the pairing RPC is service_role only).
insert into public.guardian_angel_opt_ins (user_id, group_id)
values ('d1000000-0000-0000-0000-000000000005', (select group_id from a10_created)),
       ('d1000000-0000-0000-0000-000000000002', (select group_id from a10_created));

insert into public.guardian_angel_pairings (group_id, cycle_key, guardian_id, protected_id, cycle_starts_on, cycle_ends_on)
values ((select group_id from a10_created), 'a10-cycle',
        'd1000000-0000-0000-0000-000000000005', 'd1000000-0000-0000-0000-000000000002',
        current_date, current_date + 6);

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000005","role":"authenticated"}';

select ok ((public.send_guardian_nudge ((select group_id from a10_created), current_date) ->> 'sent') = 'true',
           'C1: the guardian can send the anonymous nudge');

select ok (not exists (
         select 1 from pg_catalog.pg_policies
         where schemaname = 'public' and tablename = 'guardian_angel_pairings'
           and 'authenticated'::name = any (roles)),
       'C2: guardian_angel_pairings has NO client-readable policy');

select throws_ok ($$select count(*) from public.guardian_angel_pairings$$,
                  '42501', 'permission denied for table guardian_angel_pairings',
                  'C2: the protected member CANNOT read the pairings table at all');

reset role;

select is ((select count(*) from public.notification_outbox
             where notification_type = 'guardian_nudge'
               and user_id = 'd1000000-0000-0000-0000-000000000002'), 1::bigint,
           'C1: the protected member receives exactly one nudge');

select ok (not exists (
         select 1 from public.notification_outbox
         where notification_type = 'guardian_nudge'
           and (payload::text like '%d1000000-0000-0000-0000-000000000005%'
                or title like '%Eve%' or body like '%Eve%')),
       'C1: the nudge payload carries NEITHER the sender id NOR the sender name');

select is ((select count(*) from public.guardian_angel_pairings), 1::bigint,
           'C2: the pairing row exists (server side)');

-- -----------------------------------------------------------------------------
-- D. The moderation path
-- -----------------------------------------------------------------------------

set local role authenticated;

-- D1. Three INDEPENDENT reports auto-hide the post.
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';
select ok ((public.report_content ('post', (select id from public.feed_posts limit 1), 'spam', null, null) ->> 'auto_hidden') = 'false',
           'D1: the first report does not hide the post');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000003","role":"authenticated"}';
select ok ((public.report_content ('post', (select id from public.feed_posts limit 1), 'spam', null, null) ->> 'auto_hidden') = 'false',
           'D1: the second report does not hide the post');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000004","role":"authenticated"}';
select ok ((public.report_content ('post', (select id from public.feed_posts limit 1), 'spam', null, null) ->> 'auto_hidden') = 'true',
           'D1: the THIRD independent report auto-hides the post');
reset role;

select ok ((select is_hidden from public.feed_posts limit 1) = true,
           'D1: the post is hidden');
select is ((select hidden_reason from public.feed_posts limit 1), 'auto_hidden',
           'D1: the hidden reason is auto_hidden');
select is ((select count(*) from public.moderation_actions
             where action_type = 'auto_hide'), 1::bigint,
           'D1: exactly ONE auto_hide moderation action is written');

-- D2. A group admin can hide a chat message.
insert into public.chat_messages (id, group_id, user_id, body)
values ('d1000000-0000-0000-0000-000000000204', (select group_id from a10_created),
        'd1000000-0000-0000-0000-000000000002', 'a10 chat to moderate');

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000001","role":"authenticated"}';
select ok ((public.hide_content ('chat_message', 'd1000000-0000-0000-0000-000000000204', 'a10 reason') ->> 'hidden') = 'true',
           'D2: the group admin can hide a chat message');
reset role;

select ok ((select is_hidden from public.chat_messages where id = 'd1000000-0000-0000-0000-000000000204') = true,
           'D2: the chat message is hidden');
select is ((select count(*) from public.moderation_actions
             where action_type = 'hide_chat_message'), 1::bigint,
           'D2: the moderation action is recorded');

-- D3. A plain member may NOT hide content.
set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';
select throws_ok ($$select public.hide_content('chat_message', 'd1000000-0000-0000-0000-000000000204', 'nope')$$,
                  '42501', 'only a group administrator can hide content',
                  'D3: a plain member may not hide content');
reset role;

select * from finish ();
select public.pgtap_summary () as result;

rollback;
