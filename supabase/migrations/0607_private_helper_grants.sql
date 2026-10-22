-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022031253  ("0607_private_helper_grants")
-- The backend agents ran CONCURRENTLY, so the applied order does NOT follow
-- the prefix order (the prefix only records the author's ownership range).
-- The file is therefore NOT renamed -- it is already applied.
--
-- A clean replay in FILENAME order is safe: the only two forward references
-- in the whole chain are `to_regclass`-guarded on purpose
-- (0305 -> public.feed_posts, 0402 -> public.notification_outbox), so they
-- no-op until the table exists.
-- =============================================================================

-- =============================================================================
-- A7 · 0607 · Explicit grants on the private helpers
-- =============================================================================
-- Owner: A7 (liturgical content & monetization).
--
-- A function is EXECUTE-able by PUBLIC by default. A6 revoked the USAGE on the
-- `private` schema from `anon` (migration `revoke_anon_on_private`), so anon
-- cannot call anything there today — but the grant on the functions
-- themselves was still the default one. This migration makes A7's grants
-- explicit, so the exposure never comes back with the schema.
--
--   * private.easter_sunday / first_sunday_on_or_after / liturgical_calendar
--     -> calendar arithmetic, used by the seed and the migrations only.
--   * private.caller_role
--     -> reads the JWT role; used by the SECURITY DEFINER implementations.
--
-- The two SECURITY DEFINER implementations (`consume_reward_impl`,
-- `begin_ad_reward_impl`) already had their EXECUTE revoked from PUBLIC and
-- granted explicitly to `service_role` + `authenticated` (own rows only).
-- -----------------------------------------------------------------------------

revoke execute on function private.easter_sunday (integer) from public;
revoke execute on function private.first_sunday_on_or_after (date) from public;
revoke execute on function private.liturgical_calendar (integer) from public;
revoke execute on function private.caller_role () from public;

grant execute on function private.easter_sunday (integer) to service_role;
grant execute on function private.first_sunday_on_or_after (date) to service_role;
grant execute on function private.liturgical_calendar (integer) to service_role;
grant execute on function private.caller_role () to service_role;
