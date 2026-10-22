-- =============================================================================
-- A1 · 0010 · Restrict the RLS helpers: revoke EXECUTE from `anon`
-- =============================================================================
-- The Supabase security advisor flags every SECURITY DEFINER function that a
-- web role can EXECUTE, because PostgREST exposes such a function as an RPC
-- at /rest/v1/rpc/<name>.
--
-- `anon` is fully unauthenticated and NO policy in this schema targets it, so
-- `anon` never needs the helpers. Revoking removes 5 of the 10 findings and
-- closes the unauthenticated probe surface entirely.
--
-- `authenticated` MUST keep EXECUTE: PostgreSQL evaluates an RLS policy
-- expression with the privileges of the querying role, so revoking it makes
-- every policy that calls a helper fail with
--   ERROR: 42501 permission denied for function is_group_member
-- (verified empirically — see the A1 pgTAP suite and SCHEMA.md §3).
--
-- Residual finding: `authenticated` can still call the helpers as an RPC and
-- learn whether an arbitrary user is a member of an arbitrary group (or whether
-- an arbitrary pair of users is blocked). Mitigation recipe for A10 is in
-- supabase/SCHEMA.md §3.2.
-- -----------------------------------------------------------------------------

revoke execute on function public.is_group_member      (uuid, uuid) from anon;
revoke execute on function public.is_group_admin        (uuid, uuid) from anon;
revoke execute on function public.is_group_member_of_any (uuid)      from anon;
revoke execute on function public.is_any_group_admin    (uuid)       from anon;
revoke execute on function public.is_blocked            (uuid, uuid) from anon;

-- If a future agent needs one of these inside an `anon` policy, re-grant it
-- explicitly for that agent only:
--   grant execute on function public.is_group_member (uuid, uuid) to anon;
