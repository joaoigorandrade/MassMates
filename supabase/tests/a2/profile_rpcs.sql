-- =============================================================================
-- A2 · profile_rpcs.sql · get_my_profile / update_my_profile / update_ad_consent
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- IMPERSONATION PATTERN (shared with every other agent — see §6 of the README):
--   set local role authenticated;
--   set local request.jwt.claims = '{"sub":"<uuid>","role":"authenticated"}';
--   ... assertions ...
--   reset role;
--   set local request.jwt.claims = '{}';
-- `auth.uid()` reads request.jwt.claims, so the RPCs see the impersonated user.
-- The public wrappers are SECURITY INVOKER, the implementations live in the
-- non-exposed `private` schema.
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(28);

-- ---------------------------------------------------------------------------
-- Fixture: one signed-up user (the trigger creates the profile)
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values (
  'a2d00000-0000-4000-8000-000000000001',
  'a2_rpc@example.test', 'authenticated', 'authenticated',
  '{}'::jsonb, '{"full_name":"Ana Tester"}'::jsonb, now(), now()
);

-- ---------------------------------------------------------------------------
-- A. get_my_profile
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a2d00000-0000-4000-8000-000000000001","role":"authenticated"}';

select lives_ok ($$select public.get_my_profile()$$, 'get_my_profile runs');
select is (
  (select public.get_my_profile() ->> 'id'),
  'a2d00000-0000-4000-8000-000000000001',
  'get_my_profile returns the caller row');
select is (
  (select public.get_my_profile() ->> 'display_name'),
  'Ana Tester',
  'get_my_profile returns the display name');

-- ---------------------------------------------------------------------------
-- B. update_my_profile — the rejections
-- ---------------------------------------------------------------------------
select throws_ok (
  $$select public.update_my_profile (p_display_name => repeat('x', 61))$$,
  '22023', 'invalid_display_name',
  'a display name longer than 60 characters is rejected');
select throws_ok (
  $$select public.update_my_profile (p_display_name => '   ')$$,
  '22023', 'invalid_display_name',
  'a blank display name is rejected');
select throws_ok (
  $$select public.update_my_profile (p_locale => 'fr-FR')$$,
  '22023', 'invalid_locale',
  'an unsupported locale is rejected');
select throws_ok (
  $$select public.update_my_profile (p_timezone => 'Mars/Phobos')$$,
  '22023', 'invalid_timezone',
  'an unknown timezone is rejected');
select throws_ok (
  $$select public.update_my_profile (p_avatar_path => 'other-bucket/x.png')$$,
  '22023', 'invalid_avatar_path',
  'an avatar path outside avatars/ is rejected');
select throws_ok (
  $$select public.update_my_profile (p_avatar_path => 'avatars/../secrets/x.png')$$,
  '22023', 'invalid_avatar_path',
  'an avatar path with a path traversal is rejected');
select throws_ok (
  $$select public.update_my_profile (p_rule_of_life => '{"kind":"rosary"}'::jsonb)$$,
  '22023', 'invalid_rule_of_life',
  'a rule of life that is not an array is rejected');
select throws_ok (
  $$select public.update_my_profile (p_rule_of_life => '[{"kind":"teleportation","label":"x"}]'::jsonb)$$,
  '22023', 'invalid_rule_of_life_kind',
  'an unknown practice kind is rejected');
select throws_ok (
  $$select public.update_my_profile (p_rule_of_life => '[{"kind":"rosary","label":""}]'::jsonb)$$,
  '22023', 'invalid_rule_of_life_label',
  'an empty rule of life label is rejected');
select throws_ok (
  $$select public.update_my_profile (p_rule_of_life => '[{"kind":"rosary","label":"x","note":"free text"}]'::jsonb)$$,
  '22023', 'invalid_rule_of_life',
  'a rule of life entry with an extra key is rejected');
select throws_ok (
  $$select public.update_my_profile (p_rule_of_life => (select jsonb_agg(jsonb_build_object('kind','rosary','label','x')) from generate_series(1,11)))$$,
  '22023', 'rule_of_life_too_long',
  'more than 10 commitments are rejected');

-- ---------------------------------------------------------------------------
-- C. update_my_profile — the happy path and the "NULL = unchanged" rule
-- ---------------------------------------------------------------------------
select lives_ok (
  $$select public.update_my_profile (
      p_display_name => 'Ana Validada',
      p_city        => 'Recife',
      p_parish      => 'Sagrada Familia',
      p_timezone    => 'America/Manaus',
      p_locale      => 'en',
      p_avatar_path => 'avatars/a2d00000/x.png',
      p_rule_of_life => '[{"kind":"rosary","label":"Rosario da manha"}]'::jsonb
  )$$,
  'a valid profile update is accepted');

select is (
  (select display_name from public.profiles where id = 'a2d00000-0000-4000-8000-000000000001'),
  'Ana Validada', 'the display name was updated');
select is (
  (select city from public.profiles where id = 'a2d00000-0000-4000-8000-000000000001'),
  'Recife', 'the city was updated');
select is (
  (select timezone from public.profiles where id = 'a2d00000-0000-4000-8000-000000000001'),
  'America/Manaus', 'the timezone was updated');
select is (
  (select rule_of_life -> 0 ->> 'label' from public.profiles where id = 'a2d00000-0000-4000-8000-000000000001'),
  'Rosario da manha', 'the rule of life was stored');

select lives_ok (
  $$select public.update_my_profile (p_city => 'Olinda')$$,
  'a partial update is accepted');
select is (
  (select display_name from public.profiles where id = 'a2d00000-0000-4000-8000-000000000001'),
  'Ana Validada', 'a NULL argument leaves the column unchanged');
select is (
  (select city from public.profiles where id = 'a2d00000-0000-4000-8000-000000000001'),
  'Olinda', 'the non-NULL argument was applied');

-- ---------------------------------------------------------------------------
-- D. The BEFORE UPDATE guard: a direct UPDATE cannot bypass the rules
-- ---------------------------------------------------------------------------
select throws_ok (
  $$update public.profiles set avatar_path = 'other/x.png' where id = 'a2d00000-0000-4000-8000-000000000001'$$,
  '22023', 'invalid_avatar_path',
  'a direct UPDATE on profiles cannot bypass the avatar_path rule');
select throws_ok (
  $$update public.profiles set rule_of_life = '[{"kind":"nope","label":"x"}]'::jsonb where id = 'a2d00000-0000-4000-8000-000000000001'$$,
  '22023', 'invalid_rule_of_life_kind',
  'a direct UPDATE on profiles cannot bypass the rule_of_life rule');

-- ---------------------------------------------------------------------------
-- E. update_ad_consent — the focused, auditable GDPR surface
-- ---------------------------------------------------------------------------
select lives_ok (
  $$select public.update_ad_consent (true, false)$$,
  'update_ad_consent runs');
select is (
  (select ad_consent_analytics from public.profiles where id = 'a2d00000-0000-4000-8000-000000000001'),
  true, 'the analytics consent was stored');
select is (
  (select ad_personalization from public.profiles where id = 'a2d00000-0000-4000-8000-000000000001'),
  false, 'the personalization consent was stored');

reset role;
set local request.jwt.claims = '{}';

select is (
  (select count(*) from public.audit_log
    where action = 'account.ad_consent_updated'
      and actor_id = 'a2d00000-0000-4000-8000-000000000001')::int,
  1, 'the consent change was written to the audit log');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
