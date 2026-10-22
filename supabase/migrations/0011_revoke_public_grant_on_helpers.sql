-- =============================================================================
-- A1 · 0011 · Revoke the default PUBLIC grant on the SECURITY DEFINER helpers
-- =============================================================================
-- Migration 0010 revoked EXECUTE from `anon` — but the functions were created
-- with the default ACL, which grants EXECUTE to PUBLIC. `anon` is a member of
-- PUBLIC, so it kept the privilege (verified: `has_function_privilege('anon',
-- 'public.is_group_member(uuid,uuid)', 'execute')` was still true).
--
-- The correct fix is to drop the PUBLIC grant and re-grant only the roles that
-- genuinely need it:
--   * `authenticated` — REQUIRED: PostgreSQL evaluates an RLS policy with the
--     privileges of the querying role, so the querying role needs EXECUTE on
--     every function the policy calls. Revoking it makes every policy that
--     uses a helper fail with `42501 permission denied for function ...`.
--   * `service_role` — direct calls from server-side tooling.
--   * `postgres` — the owner; always keeps EXECUTE implicitly.
--
-- `anon` is deliberately excluded: it is fully unauthenticated and no policy in
-- this schema targets it. This removes the unauthenticated RPC surface
-- (`/rest/v1/rpc/is_group_member` etc. no longer resolve for `anon`).
-- -----------------------------------------------------------------------------

revoke execute on function public.is_group_member       (uuid, uuid) from public;
revoke execute on function public.is_group_admin         (uuid, uuid) from public;
revoke execute on function public.is_group_member_of_any (uuid)       from public;
revoke execute on function public.is_any_group_admin     (uuid)        from public;
revoke execute on function public.is_blocked             (uuid, uuid) from public;

grant execute on function public.is_group_member       (uuid, uuid) to authenticated, service_role;
grant execute on function public.is_group_admin         (uuid, uuid) to authenticated, service_role;
grant execute on function public.is_group_member_of_any (uuid)       to authenticated, service_role;
grant execute on function public.is_any_group_admin     (uuid)        to authenticated, service_role;
grant execute on function public.is_blocked             (uuid, uuid) to authenticated, service_role;

-- If a future agent needs one of these inside an `anon` policy, re-grant it
-- explicitly for that agent only:
--   grant execute on function public.is_group_member (uuid, uuid) to anon;
