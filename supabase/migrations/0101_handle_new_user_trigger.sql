-- =============================================================================
-- A2 · 0101 · handle_new_user trigger + private derivation helpers
-- =============================================================================
-- Owner: A2 (auth & account lifecycle). Prefix range 0100-0199.
--
-- `public.profiles` has NO client INSERT policy (A1, by design) and RLS is
-- enabled AND forced on it, so the profile row can only be created by a
-- SECURITY DEFINER function. This migration creates that function and the
-- AFTER INSERT trigger on `auth.users`.
--
-- The `private` schema is the non-exposed implementation schema used by every
-- A2 SECURITY DEFINER function (CONVENTIONS §5 + SCHEMA.md §3.2). It is NOT in
-- the PostgREST exposed-schema list, so its contents cannot be called through
-- /rest/v1/rpc — only the narrow public wrappers in `public` are reachable.
-- =============================================================================

create schema if not exists private;

revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;

comment on schema private is
  'Non-exposed internal implementations (A2). Not in the PostgREST exposed-schema list: clients reach these only through the narrow public wrappers in public. Every function here is SECURITY DEFINER with set search_path = '''' and fully-qualified object names.';

-- -----------------------------------------------------------------------------
-- Derivation helpers (pure functions, used by the trigger and by the backfill)
-- -----------------------------------------------------------------------------
create or replace function private.derive_display_name (p_meta jsonb, p_email text)
  returns text
  language sql
  immutable
  set search_path = ''
as $$
  select btrim(left(
    coalesce(
      nullif(btrim(p_meta ->> 'full_name'),  ''),
      nullif(btrim(p_meta ->> 'name'),      ''),
      nullif(btrim(p_meta ->> 'user_name'), ''),
      nullif(btrim(split_part(coalesce(p_email, ''), '@', 1)), ''),
      case
        when lower(coalesce(p_meta ->> 'gender', '')) in ('f', 'female', 'feminino', 'mulher')
          then 'Irmã'
        else 'Irmão'
      end
    ),
    60
  ));
$$;

comment on function private.derive_display_name (jsonb, text) is
  'display_name for a new profile: raw_user_meta_data.full_name -> name -> user_name -> email local part -> Irmão/Irmã. Always trimmed and truncated to 60 characters so public.profiles.display_name_check (1..60) holds.';

create or replace function private.derive_locale (p_meta jsonb)
  returns text
  language sql
  immutable
  set search_path = ''
as $$
  select case
    when p_meta ->> 'locale' in ('pt-BR', 'en') then p_meta ->> 'locale'
    else 'pt-BR'
  end;
$$;

comment on function private.derive_locale (jsonb) is
  'locale for a new profile: raw_user_meta_data.locale when it is pt-BR or en, otherwise pt-BR.';

create or replace function private.derive_timezone (p_meta jsonb)
  returns text
  language sql
  stable
  set search_path = ''
as $$
  select case
    when exists (
      select 1 from pg_catalog.pg_timezone_names z where z.name = p_meta ->> 'timezone'
    ) then p_meta ->> 'timezone'
    else 'America/Sao_Paulo'
  end;
$$;

comment on function private.derive_timezone (jsonb) is
  'timezone for a new profile: raw_user_meta_data.timezone when it is a real IANA zone name (checked against pg_catalog.pg_timezone_names), otherwise America/Sao_Paulo.';

create or replace function private.derive_avatar_path (p_meta jsonb)
  returns text
  language sql
  immutable
  set search_path = ''
as $$
  select case
    when p_meta ->> 'avatar_url' like 'avatars/%'
     and p_meta ->> 'avatar_url' not like '%..%'
     and char_length(p_meta ->> 'avatar_url') <= 255
      then p_meta ->> 'avatar_url'
    else null
  end;
$$;

comment on function private.derive_avatar_path (jsonb) is
  'avatar_path for a new profile. public.profiles.avatar_path is a STORAGE PATH in the avatars bucket (SCHEMA.md 2.1), not a URL, so only metadata values that already are an avatars/... path are stored; provider URLs (Google/Apple) are intentionally dropped (null) and the user re-uploads through A6.';

-- -----------------------------------------------------------------------------
-- public.handle_new_user() — AFTER INSERT trigger on auth.users
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user ()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  insert into public.profiles (
    id, display_name, avatar_path, locale, timezone,
    ad_consent_analytics, ad_personalization, rule_of_life
  )
  values (
    new.id,
    private.derive_display_name (v_meta, new.email),
    private.derive_avatar_path (v_meta),
    private.derive_locale (v_meta),
    private.derive_timezone (v_meta),
    false,
    false,
    '[]'::jsonb
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

comment on function public.handle_new_user () is
  'Creates the public.profiles row of a freshly signed-up user. SECURITY DEFINER (the table has FORCEd RLS and no client INSERT policy), SET search_path = ''''. Idempotent: ON CONFLICT (id) DO NOTHING. Ad consent is NEVER derived from metadata — it always starts as false.';

-- Only the auth server may execute the trigger body.
revoke execute on function public.handle_new_user () from public, anon, authenticated;
grant execute on function public.handle_new_user () to supabase_auth_admin, service_role;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user ();
