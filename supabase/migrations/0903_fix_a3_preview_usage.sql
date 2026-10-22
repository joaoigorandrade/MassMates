-- =============================================================================
-- A10 · 0903 · fix the A3 public preview seam for signed-in users
-- =============================================================================
-- Owner: A10 (security & QA audit). Prefix range 0900-0999.
--
-- THE BUG (found by A10's RPC matrix, pre-existing since A3's migration 0208)
--   `public.preview_group_by_code(text)` and `public.list_featured_challenges()`
--   are thin SECURITY INVOKER wrappers that forward to
--   `a3_preview.preview_group_by_code_impl(...)` /
--   `a3_preview.list_featured_challenges_impl(...)`.
--
--   The `a3_preview` schema was granted USAGE to `anon` ONLY:
--
--     a3_preview = {postgres=UC/postgres, anon=U/postgres}
--
--   Because the wrappers are SECURITY INVOKER they run with the CALLER's
--   privileges, so a SIGNED-IN user got:
--
--     ERROR: 42501: permission denied for schema a3_preview
--
--   The logged-out discovery list therefore worked, but the very same list
--   failed for every authenticated user -- and the `massmates://join/:code`
--   deep link preview failed for anyone who was signed in.
--
-- THE FIX
--   Grant USAGE on the `a3_preview` schema to `authenticated` and
--   `service_role` as well.
--
--   This is safe: `a3_preview` contains NOTHING but the two preview
--   implementations, and both of them are already EXECUTE-able by `anon`
--   (their whole purpose is to serve the logged-out preview). The schema is
--   NOT exposed by PostgREST, so nothing new becomes reachable over HTTP.
-- -----------------------------------------------------------------------------

grant usage on schema a3_preview to authenticated, service_role;

grant execute on function a3_preview.preview_group_by_code_impl (text) to authenticated, service_role;
grant execute on function a3_preview.list_featured_challenges_impl ()   to authenticated, service_role;

comment on schema a3_preview is
  'Holds ONLY the two public preview implementations behind public.preview_group_by_code / public.list_featured_challenges. Not exposed by PostgREST. USAGE is granted to anon, authenticated and service_role (migration 0903).';

do $$
declare
  v_bad int;
begin
  -- both preview implementations must be reachable by authenticated
  select count (*) into v_bad
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'a3_preview'
    and not has_function_privilege ('authenticated', p.oid, 'execute');
  if v_bad <> 0 then
    raise exception 'a10 0903: authenticated can still not execute % a3_preview functions', v_bad;
  end if;

  -- ... and anon must keep them
  select count (*) into v_bad
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'a3_preview'
    and not has_function_privilege ('anon', p.oid, 'execute');
  if v_bad <> 0 then
    raise exception 'a10 0903: anon lost EXECUTE on % a3_preview functions', v_bad;
  end if;
end;
$$;
