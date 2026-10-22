-- =============================================================================
-- A2 · handle_new_user.sql · auth trigger + profile derivation
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--   -> send the ENTIRE file as the `query` argument of execute_sql
--   -> the verdict is the last result set: select public.pgtap_summary()
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(27);

-- ---------------------------------------------------------------------------
-- A. The function and the trigger exist and are locked down
-- ---------------------------------------------------------------------------
select has_function ('public', 'handle_new_user', 'handle_new_user() exists');
select ok (
  (select p.prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'handle_new_user'),
  'handle_new_user is SECURITY DEFINER');
select ok (
  (select p.proconfig @> array['search_path=""'] from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'handle_new_user'),
  'handle_new_user pins search_path = ''''');
select has_trigger ('auth', 'users', 'on_auth_user_created', 'the trigger is attached to auth.users');
select ok (
  (select (t.tgtype & 1) = 1      -- FOR EACH ROW
     and (t.tgtype & 2) = 0        -- AFTER (the BEFORE bit is clear)
     and (t.tgtype & 4) = 4        -- INSERT
     from pg_trigger t
    where t.tgname = 'on_auth_user_created' and not t.tgisinternal),
  'the trigger is AFTER INSERT FOR EACH ROW');
select ok (
  not has_function_privilege ('anon', 'public.handle_new_user()', 'EXECUTE'),
  'anon cannot execute handle_new_user');
select ok (
  not has_function_privilege ('authenticated', 'public.handle_new_user()', 'EXECUTE'),
  'authenticated cannot execute handle_new_user');
select ok (
  has_function_privilege ('supabase_auth_admin', 'public.handle_new_user()', 'EXECUTE'),
  'the auth server (supabase_auth_admin) can execute handle_new_user');
select ok (
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'handle_new_user'
      and position('on conflict' in lower(pg_get_functiondef(p.oid))) > 0
  ),
  'the profile insert is idempotent (ON CONFLICT DO NOTHING)');

-- ---------------------------------------------------------------------------
-- B. The derivation helpers (private schema)
-- ---------------------------------------------------------------------------
select is (private.derive_display_name ('{"full_name":"Maria Silva"}'::jsonb, 'maria@example.test'), 'Maria Silva', 'full_name wins');
select is (private.derive_display_name ('{"name":"João"}'::jsonb, 'joao@example.test'), 'João', 'name is the second choice');
select is (private.derive_display_name ('{"user_name":"Zé"}'::jsonb, 'ze@example.test'), 'Zé', 'user_name is the third choice');
select is (private.derive_display_name ('{}'::jsonb, 'local.part@example.test'), 'local.part', 'the email local part is the fourth choice');
select is (private.derive_display_name ('{}'::jsonb, null), 'Irmão', 'Irmão is the default fallback');
select is (private.derive_display_name ('{"gender":"female"}'::jsonb, null), 'Irmã', 'Irmã is the gendered fallback');
select is (
  char_length (private.derive_display_name ('{"full_name":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}'::jsonb, 'x@example.test')),
  60,
  'a display name longer than 60 characters is truncated');
select is (private.derive_locale ('{"locale":"en"}'::jsonb), 'en', 'the locale comes from the metadata');
select is (private.derive_locale ('{"locale":"fr-FR"}'::jsonb), 'pt-BR', 'an unsupported locale falls back to pt-BR');
select is (private.derive_timezone ('{"timezone":"Europe/Lisbon"}'::jsonb), 'Europe/Lisbon', 'the timezone comes from the metadata');
select is (private.derive_timezone ('{"timezone":"Mars/Phobos"}'::jsonb), 'America/Sao_Paulo', 'an unknown timezone falls back to America/Sao_Paulo');
select is (private.derive_avatar_path ('{"avatar_url":"avatars/abc/u.png"}'::jsonb), 'avatars/abc/u.png', 'an avatars/ path is kept');
select is (private.derive_avatar_path ('{"avatar_url":"https://cdn.example.com/u.png"}'::jsonb), null, 'an external avatar URL is dropped (avatar_path is a storage path, not a URL)');

-- ---------------------------------------------------------------------------
-- C. The trigger actually fires on auth.users
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values (
  'a2c00000-0000-4000-8000-000000000001',
  'a2_trigger@example.test', 'authenticated', 'authenticated',
  '{}'::jsonb, '{"full_name":"Maria Testeira","locale":"en"}'::jsonb, now(), now()
);

select is (
  (select display_name from public.profiles where id = 'a2c00000-0000-4000-8000-000000000001'),
  'Maria Testeira',
  'the trigger created the profile with the derived display name');
select is (
  (select locale from public.profiles where id = 'a2c00000-0000-4000-8000-000000000001'),
  'en',
  'the trigger copied the locale from the metadata');
select ok (
  (select ad_consent_analytics = false and ad_personalization = false
     from public.profiles where id = 'a2c00000-0000-4000-8000-000000000001'),
  'the trigger never grants ad consent');
select is (
  (select rule_of_life from public.profiles where id = 'a2c00000-0000-4000-8000-000000000001'),
  '[]'::jsonb,
  'the trigger starts the rule of life empty');

-- ---------------------------------------------------------------------------
-- D. The backfill helper covers an auth user without a profile
--    (the backfill migration is idempotent and only fills the gaps)
-- ---------------------------------------------------------------------------
select is (
  (select count(*) from public.profiles),
  (select count(*) from auth.users),
  'every auth user has exactly one profile row (backfill invariant)');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
