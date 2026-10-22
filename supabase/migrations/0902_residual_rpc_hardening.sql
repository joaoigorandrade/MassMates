-- =============================================================================
-- A10 · 0902 · residual hardening of the exposed RPC surface
-- =============================================================================
-- Owner: A10 (security & QA audit). Prefix range 0900-0999.
--
-- WHAT
--   After migration 0901 the only `public` functions a signed-in client can
--   still reach that it has no use for are the leftovers of the foundation:
--
--     public.current_user_id()   -- returns auth.uid(); anon gets NULL
--     public.probe_wrapper(text) -- a debug echo (already restricted to
--                                   service_role by migration 0900)
--
--   `public.current_user_id()` is called by the `private.*_impl` bodies, all
--   of which run as the table owner (postgres) -- except the thin public
--   wrappers, which run as the caller. `authenticated` and `service_role`
--   therefore keep EXECUTE; `anon` does not need it (every RPC that uses it
--   is already revoked from `anon`).
--
--   The result: the ONLY functions an unauthenticated client can execute over
--   PostgREST are the four documented public endpoints:
--
--     public.preview_group_by_code(text)   -- the massmates://join/:code deep link
--     public.list_featured_challenges()     -- the logged-out discovery list
--     public.get_today_liturgy()            -- today's liturgy
--     public.get_liturgical_calendar(int)   -- the liturgical calendar
--
-- PERFORMANCE NOTE (accepted baseline)
--   `get_advisors({type:"performance"})` reports `unused_index` as INFO for the
--   empty tables: the planner cannot prove an index unused when the table has
--   no rows. Every one of those indexes backs a foreign key, a unique
--   constraint or a documented lookup path, so they are KEPT. The list is
--   recorded in supabase/SCHEMA.md §21.
-- -----------------------------------------------------------------------------

revoke all on function public.current_user_id () from public, anon;
grant execute on function public.current_user_id () to authenticated, service_role;

comment on function public.current_user_id () is
  'auth.uid() of the caller. The helper is not reachable by `anon` (migration 0902): every RPC that uses it is already revoked from `anon`.';

do $$
declare
  v_bad int;
begin
  -- the four public endpoints are the ONLY anon-executable functions
  select count (*) into v_bad
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prorettype <> 'trigger'::regtype
    and p.proname not like 'pgtap\_%'
    and has_function_privilege ('anon', p.oid, 'execute')
    and p.proname not in ('preview_group_by_code', 'list_featured_challenges',
                          'get_today_liturgy', 'get_liturgical_calendar');
  if v_bad <> 0 then
    raise exception 'a10 0902: % public functions are still executable by anon', v_bad;
  end if;
end;
$$;
