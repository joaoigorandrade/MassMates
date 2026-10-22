-- =============================================================================
-- A2 · 0103 · profile settings RPCs (get / update / ad consent)
-- =============================================================================
-- Owner: A2 (auth & account lifecycle).
--
-- PATTERN (see SCHEMA.md "A2 additions"):
--   private.<impl>  = SECURITY DEFINER, set search_path = '', fully qualified.
--                      Lives in the NON-EXPOSED `private` schema, so it cannot be
--                      called through /rest/v1/rpc and does not add a finding to
--                      the `authenticated_security_definer_function_executable`
--                      advisor lint.
--   public.<rpc>    = the only client-reachable surface. SECURITY INVOKER,
--                      REVOKE EXECUTE FROM PUBLIC, GRANT EXECUTE TO authenticated.
--                      It delegates to private.<impl>, which owns the real
--                      enforcement (SECURITY DEFINER) — the effective privilege
--                      is the same as a public SECURITY DEFINER RPC, but the
--                      advisory counter stays flat.
--
-- ERROR CONTRACT: every rejection raises with ERRCODE 22023
-- (invalid_parameter_value) and a stable, Portuguese-friendly message key:
--   invalid_display_name · invalid_avatar_path · invalid_locale ·
--   invalid_timezone · invalid_parish · invalid_city ·
--   invalid_rule_of_life · invalid_rule_of_life_kind ·
--   invalid_rule_of_life_label · rule_of_life_too_long · invalid_ad_consent
--   not_authenticated (42501) · profile_not_found (P0002)
-- A9 maps the keys to the pt-BR / en strings shown to the user.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- private.validate_profile_fields() — the single source of truth for the
-- profile invariants. Called by the RPCs AND by the BEFORE UPDATE trigger, so
-- a direct PostgREST PATCH on public.profiles cannot bypass the rules.
-- -----------------------------------------------------------------------------
create or replace function private.validate_profile_fields (
  p_display_name text,
  p_avatar_path  text,
  p_locale       text,
  p_timezone     text,
  p_rule_of_life jsonb
)
  returns void
  language plpgsql
  security invoker
  set search_path = ''
as $$
declare
  v_elem  jsonb;
  v_kind  text;
  v_label text;
begin
  if p_display_name is not null then
    if char_length(btrim(p_display_name)) not between 1 and 60 then
      raise exception 'invalid_display_name' using
        errcode = '22023',
        hint = 'display_name must have between 1 and 60 characters after trimming';
    end if;
  end if;

  if p_avatar_path is not null then
    if char_length(p_avatar_path) > 255
       or p_avatar_path !~ '^avatars/[A-Za-z0-9][A-Za-z0-9._/-]*$'
       or p_avatar_path like '%..%' then
      raise exception 'invalid_avatar_path' using
        errcode = '22023',
        hint = 'avatar_path must be a path inside the avatars/ bucket';
    end if;
  end if;

  if p_locale is not null and p_locale not in ('pt-BR', 'en') then
    raise exception 'invalid_locale' using
      errcode = '22023',
      hint = 'locale must be pt-BR or en';
  end if;

  if p_timezone is not null and not exists (
    select 1 from pg_catalog.pg_timezone_names z where z.name = p_timezone
  ) then
    raise exception 'invalid_timezone' using
      errcode = '22023',
      hint = 'timezone must be a valid IANA time zone name';
  end if;

  if p_rule_of_life is not null then
    if jsonb_typeof(p_rule_of_life) <> 'array' then
      raise exception 'invalid_rule_of_life' using
        errcode = '22023',
        hint = 'rule_of_life must be a JSON array';
    end if;

    if jsonb_array_length(p_rule_of_life) > 10 then
      raise exception 'rule_of_life_too_long' using
        errcode = '22023',
        hint = 'rule_of_life accepts at most 10 commitments';
    end if;

    for v_elem in select jsonb_array_elements(p_rule_of_life) loop
      if jsonb_typeof(v_elem) <> 'object' then
        raise exception 'invalid_rule_of_life' using
          errcode = '22023',
          hint = 'every rule_of_life entry must be an object';
      end if;

      if exists (
        select 1 from jsonb_object_keys(v_elem) k where k not in ('kind', 'label')
      ) then
        raise exception 'invalid_rule_of_life' using
          errcode = '22023',
          hint = 'a rule_of_life entry accepts only the keys kind and label';
      end if;

      if not (v_elem ? 'kind') or not (v_elem ? 'label') then
        raise exception 'invalid_rule_of_life' using
          errcode = '22023',
          hint = 'a rule_of_life entry needs both kind and label';
      end if;

      v_kind := v_elem ->> 'kind';

      if not exists (
        select 1
        from pg_catalog.pg_type t
        join pg_catalog.pg_namespace n on n.oid = t.typnamespace
        join pg_catalog.pg_enum e on e.enumtypid = t.oid
        where n.nspname = 'public'
          and t.typname = 'practice_kind'
          and e.enumlabel = v_kind
      ) then
        raise exception 'invalid_rule_of_life_kind' using
          errcode = '22023',
          hint = 'rule_of_life.kind must be a public.practice_kind value';
      end if;

      if jsonb_typeof(v_elem -> 'label') <> 'string' then
        raise exception 'invalid_rule_of_life_label' using
          errcode = '22023',
          hint = 'rule_of_life.label must be a string';
      end if;

      v_label := btrim(v_elem ->> 'label');

      if char_length(v_label) not between 1 and 60 then
        raise exception 'invalid_rule_of_life_label' using
          errcode = '22023',
          hint = 'rule_of_life.label must have between 1 and 60 characters';
      end if;
    end loop;
  end if;
end;
$$;

comment on function private.validate_profile_fields (text, text, text, text, jsonb) is
  'Validates the profile invariants A2 owns. Raises 22023 with a stable message key. Called by the profile RPCs and by trg_profiles_a2_validate, so the rules hold for every writer.';

-- -----------------------------------------------------------------------------
-- BEFORE UPDATE guard on public.profiles
-- -----------------------------------------------------------------------------
create or replace function private.validate_profile_update ()
  returns trigger
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  perform private.validate_profile_fields (
    new.display_name, new.avatar_path, new.locale, new.timezone, new.rule_of_life
  );
  return new;
end;
$$;

comment on function private.validate_profile_update () is
  'BEFORE UPDATE trigger on public.profiles: re-validates the A2-owned columns so a direct PostgREST PATCH cannot bypass private.validate_profile_fields.';

drop trigger if exists trg_profiles_a2_validate on public.profiles;

create trigger trg_profiles_a2_validate
  before update on public.profiles
  for each row execute function private.validate_profile_update ();

grant execute on function private.validate_profile_update () to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- private.get_my_profile_impl()
-- -----------------------------------------------------------------------------
create or replace function private.get_my_profile_impl ()
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := public.current_user_id ();
  v_row public.profiles;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using
      errcode = '42501',
      hint = 'a signed-in user is required';
  end if;

  select * into v_row from public.profiles where id = v_uid;

  if not found then
    raise exception 'profile_not_found' using
      errcode = 'P0002',
      hint = 'no profile row exists for the caller';
  end if;

  return to_jsonb(v_row);
end;
$$;

comment on function private.get_my_profile_impl () is
  'Implementation of public.get_my_profile(): the caller''s own profile row as jsonb.';

-- -----------------------------------------------------------------------------
-- private.update_my_profile_impl()
-- -----------------------------------------------------------------------------
create or replace function private.update_my_profile_impl (
  p_display_name         text    default null,
  p_avatar_path          text    default null,
  p_parish               text    default null,
  p_city                 text    default null,
  p_timezone             text    default null,
  p_locale               text    default null,
  p_ad_consent_analytics boolean default null,
  p_ad_personalization   boolean default null,
  p_rule_of_life         jsonb   default null
)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := public.current_user_id ();
  v_row public.profiles;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using
      errcode = '42501',
      hint = 'a signed-in user is required';
  end if;

  if p_parish is not null and char_length(p_parish) > 120 then
    raise exception 'invalid_parish' using
      errcode = '22023',
      hint = 'parish accepts at most 120 characters';
  end if;

  if p_city is not null and char_length(p_city) > 120 then
    raise exception 'invalid_city' using
      errcode = '22023',
      hint = 'city accepts at most 120 characters';
  end if;

  perform private.validate_profile_fields (
    p_display_name, p_avatar_path, p_locale, p_timezone, p_rule_of_life
  );

  update public.profiles
     set display_name         = coalesce(p_display_name, display_name),
         avatar_path          = coalesce(p_avatar_path, avatar_path),
         parish               = coalesce(p_parish, parish),
         city                 = coalesce(p_city, city),
         timezone             = coalesce(p_timezone, timezone),
         locale               = coalesce(p_locale, locale),
         ad_consent_analytics = coalesce(p_ad_consent_analytics, ad_consent_analytics),
         ad_personalization   = coalesce(p_ad_personalization, ad_personalization),
         rule_of_life         = coalesce(p_rule_of_life, rule_of_life)
   where id = v_uid
  returning * into v_row;

  if not found then
    raise exception 'profile_not_found' using
      errcode = 'P0002',
      hint = 'no profile row exists for the caller';
  end if;

  if (p_ad_consent_analytics is not null and p_ad_consent_analytics <> v_row.ad_consent_analytics)
     or (p_ad_personalization is not null and p_ad_personalization <> v_row.ad_personalization) then
    insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
    values (
      v_uid,
      'account.ad_consent_updated',
      'profile',
      v_uid,
      jsonb_build_object (
        'ad_consent_analytics', v_row.ad_consent_analytics,
        'ad_personalization',   v_row.ad_personalization
      )
    );
  end if;

  return to_jsonb(v_row);
end;
$$;

comment on function private.update_my_profile_impl (text, text, text, text, text, text, boolean, boolean, jsonb) is
  'Implementation of public.update_my_profile(): updates only the non-NULL arguments of the caller''s own profile row, after validating them. A change to the ad-consent flags is additionally written to public.audit_log.';

-- -----------------------------------------------------------------------------
-- private.update_ad_consent_impl()
-- -----------------------------------------------------------------------------
create or replace function private.update_ad_consent_impl (p_analytics boolean, p_personalization boolean)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := public.current_user_id ();
  v_row public.profiles;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using
      errcode = '42501',
      hint = 'a signed-in user is required';
  end if;

  if p_analytics is null or p_personalization is null then
    raise exception 'invalid_ad_consent' using
      errcode = '22023',
      hint = 'both ad_consent_analytics and ad_personalization are required';
  end if;

  update public.profiles
     set ad_consent_analytics = p_analytics,
         ad_personalization   = p_personalization
   where id = v_uid
  returning * into v_row;

  if not found then
    raise exception 'profile_not_found' using
      errcode = 'P0002',
      hint = 'no profile row exists for the caller';
  end if;

  insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
  values (
    v_uid,
    'account.ad_consent_updated',
    'profile',
    v_uid,
    jsonb_build_object (
      'ad_consent_analytics', v_row.ad_consent_analytics,
      'ad_personalization',   v_row.ad_personalization
    )
  );

  return jsonb_build_object (
    'id',                    v_row.id,
    'ad_consent_analytics', v_row.ad_consent_analytics,
    'ad_personalization',   v_row.ad_personalization,
    'updated_at',           v_row.updated_at
  );
end;
$$;

comment on function private.update_ad_consent_impl (boolean, boolean) is
  'Implementation of public.update_ad_consent(): the focused, auditable GDPR consent setter. Every call writes an account.ad_consent_updated row to public.audit_log.';

-- -----------------------------------------------------------------------------
-- Public wrappers — the only client-reachable surface
-- -----------------------------------------------------------------------------
create or replace function public.get_my_profile ()
  returns jsonb
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  return private.get_my_profile_impl ();
end;
$$;

comment on function public.get_my_profile () is
  'Returns the caller''s own public.profiles row as jsonb. No arguments.';

create or replace function public.update_my_profile (
  p_display_name         text    default null,
  p_avatar_path          text    default null,
  p_parish               text    default null,
  p_city                 text    default null,
  p_timezone             text    default null,
  p_locale               text    default null,
  p_ad_consent_analytics boolean default null,
  p_ad_personalization   boolean default null,
  p_rule_of_life         jsonb   default null
)
  returns jsonb
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  return private.update_my_profile_impl (
    p_display_name, p_avatar_path, p_parish, p_city, p_timezone,
    p_locale, p_ad_consent_analytics, p_ad_personalization, p_rule_of_life
  );
end;
$$;

comment on function public.update_my_profile (text, text, text, text, text, text, boolean, boolean, jsonb) is
  'Updates the caller''s own profile. Only the arguments that are NOT NULL are applied (NULL = leave unchanged). Returns the updated row as jsonb.';

create or replace function public.update_ad_consent (p_analytics boolean, p_personalization boolean)
  returns jsonb
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  return private.update_ad_consent_impl (p_analytics, p_personalization);
end;
$$;

comment on function public.update_ad_consent (boolean, boolean) is
  'Sets the caller''s ad consent flags (both required) and records the change in public.audit_log. Returns the consent state as jsonb.';

-- -----------------------------------------------------------------------------
-- Privileges: only `authenticated` (and the server) may call the RPCs.
-- -----------------------------------------------------------------------------
revoke execute on function public.get_my_profile () from public, anon;
grant execute on function public.get_my_profile () to authenticated, service_role;

revoke execute on function public.update_my_profile (text, text, text, text, text, text, boolean, boolean, jsonb) from public, anon;
grant execute on function public.update_my_profile (text, text, text, text, text, text, boolean, boolean, jsonb) to authenticated, service_role;

revoke execute on function public.update_ad_consent (boolean, boolean) from public, anon;
grant execute on function public.update_ad_consent (boolean, boolean) to authenticated, service_role;

grant execute on function private.get_my_profile_impl () to authenticated, service_role;
grant execute on function private.update_my_profile_impl (text, text, text, text, text, text, boolean, boolean, jsonb) to authenticated, service_role;
grant execute on function private.update_ad_consent_impl (boolean, boolean) to authenticated, service_role;
grant execute on function private.validate_profile_fields (text, text, text, text, jsonb) to authenticated, service_role;
