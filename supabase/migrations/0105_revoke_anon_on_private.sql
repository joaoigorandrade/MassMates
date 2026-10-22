-- =============================================================================
-- A2 · 0105 · tighten EXECUTE on the private schema
-- =============================================================================
-- Owner: A2 (auth & account lifecycle).
--
-- Supabase's platform default privileges grant EXECUTE on new functions to
-- `anon`, `authenticated` and `service_role`. That default also reached the
-- functions in the non-exposed `private` schema: `anon` must never be able to
-- execute a SECURITY DEFINER implementation, not even though it has no USAGE on
-- the schema (a privilege that can be granted later would open the door).
--
-- `authenticated` KEEPS the grant: the public wrappers delegate to these
-- implementations and the wrappers run with the caller's privileges.
-- =============================================================================

revoke execute on function private.derive_display_name (jsonb, text) from public, anon;
revoke execute on function private.derive_locale (jsonb) from public, anon;
revoke execute on function private.derive_timezone (jsonb) from public, anon;
revoke execute on function private.derive_avatar_path (jsonb) from public, anon;

revoke execute on function private.validate_profile_fields (text, text, text, text, jsonb) from public, anon;
revoke execute on function private.validate_profile_update () from public, anon;

revoke execute on function private.get_my_profile_impl () from public, anon;
revoke execute on function private.update_my_profile_impl (text, text, text, text, text, text, boolean, boolean, jsonb) from public, anon;
revoke execute on function private.update_ad_consent_impl (boolean, boolean) from public, anon;

revoke execute on function private.request_account_deletion_impl () from public, anon;
revoke execute on function private.confirm_account_deletion_impl (uuid) from public, anon;
