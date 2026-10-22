-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022031118  ("harden_a6_rpc_privileges")
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
-- A6 · 0505 · harden the A6 RPC privileges + pin the private search_path
-- =============================================================================
-- Owner: A6 (storage, moderation & safety).
--
-- WHY THIS MIGRATION EXISTS
-- The project carries a DEFAULT PRIVILEGE that grants EXECUTE on every new
-- function of schema `public` to anon / authenticated / service_role:
--
--   select defaclacl from pg_default_acl d
--     join pg_namespace n on n.oid = d.defaclnamespace
--    where n.nspname = 'public' and d.defaclobjtype = 'f';
--   -- {postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,...}
--
-- `revoke execute ... from public` therefore does NOT remove `anon`: the
-- explicit anon grant survives and PostgREST would expose the function as an
-- unauthenticated RPC. Every A6 function must be revoked from `anon`
-- explicitly (same pattern as A1's migration 0010).
--
-- The second half pins `search_path = ''` on the three `private` helpers that
-- were created without it (the `function_search_path_mutable` advisor lint).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- public RPCs: no unauthenticated access, ever.
-- ---------------------------------------------------------------------------
revoke execute on function public.block_user (uuid) from public, anon;
revoke execute on function public.unblock_user (uuid) from public, anon;
revoke execute on function public.list_blocked_users () from public, anon;
revoke execute on function public.report_content (text, uuid, text, text, uuid) from public, anon;
revoke execute on function public.admin_delete_post (uuid) from public, anon;
revoke execute on function public.hide_content (text, uuid, text) from public, anon;
revoke execute on function public.get_moderation_queue (uuid) from public, anon;
revoke execute on function public.resolve_report (uuid, text, text) from public, anon;
revoke execute on function public.get_moderation_actions (uuid) from public, anon;
revoke execute on function public.create_signed_witness_url (text, integer) from public, anon;

grant execute on function public.block_user (uuid) to authenticated, service_role;
grant execute on function public.unblock_user (uuid) to authenticated, service_role;
grant execute on function public.list_blocked_users () to authenticated, service_role;
grant execute on function public.report_content (text, uuid, text, text, uuid) to authenticated, service_role;
grant execute on function public.admin_delete_post (uuid) to authenticated, service_role;
grant execute on function public.hide_content (text, uuid, text) to authenticated, service_role;
grant execute on function public.get_moderation_queue (uuid) to authenticated, service_role;
grant execute on function public.resolve_report (uuid, text, text) to authenticated, service_role;
grant execute on function public.get_moderation_actions (uuid) to authenticated, service_role;
grant execute on function public.create_signed_witness_url (text, integer) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- private helpers: not callable by any web role.
-- ---------------------------------------------------------------------------
revoke all on function private.auto_hide_threshold () from public, anon, authenticated;
revoke all on function private.has_column (regclass, text) from public, anon, authenticated;
revoke all on function private.resolve_report_group (text, uuid, uuid) from public, anon, authenticated;
revoke all on function private.report_target_exists (text, uuid) from public, anon, authenticated;
revoke all on function private.target_preview (text, uuid) from public, anon, authenticated;
revoke all on function private.auto_hide_content (text, uuid, text) from public, anon, authenticated;
revoke all on function private.auto_hide_after_report () from public, anon, authenticated;

-- `private.try_uuid` IS called from the storage policies, so `authenticated`
-- keeps EXECUTE on it (PostgreSQL evaluates a policy expression with the
-- querying role's privileges).
revoke all on function private.try_uuid (text) from public, anon;
grant execute on function private.try_uuid (text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Pin the search_path of the three helpers that were created without it.
-- ---------------------------------------------------------------------------
alter function private.try_uuid (text) set search_path = '';
alter function private.auto_hide_threshold () set search_path = '';
alter function private.has_column (regclass, text) set search_path = '';

-- ---------------------------------------------------------------------------
-- The `private` schema itself is never exposed through PostgREST.
-- ---------------------------------------------------------------------------
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;
