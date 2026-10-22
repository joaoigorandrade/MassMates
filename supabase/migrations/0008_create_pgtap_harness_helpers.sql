-- =============================================================================
-- A1 · 0008 · pgTAP harness helpers
-- =============================================================================
-- The MCP `execute_sql` tool returns only the LAST NON-EMPTY result set of a
-- multi-statement batch. A pgTAP file emits one result set per assertion and
-- `finish()` returns ZERO rows when everything passed — so a plain
-- `select * from finish();` is NOT a reliable pass/fail signal.
--
-- These helpers make the harness deterministic for A2..A10:
--   public.pgtap_summary()  -> exactly one row, always the last result set.
--   public.pgtap_rls_enabled() / _rls_forced() / _policy_count()
--                             -> pgTAP 1.3.3 has no RLS assertions, so these
--                                fill the gap.
--
-- They are development helpers: EXECUTE is revoked from anon/authenticated so
-- they are not reachable through PostgREST. Only the owner (postgres, i.e.
-- the MCP tool) can run them.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- pgtap_summary() -> jsonb (one row)
-- -----------------------------------------------------------------------------
create or replace function public.pgtap_summary ()
  returns jsonb
  language plpgsql
  stable
  set search_path = ''
as $$
declare
  v_plan  integer;
  v_ran   integer;
  v_fail  integer;
  v_msg   text;
  v_ok    boolean;
begin
  v_plan := extensions._get ('plan');
  v_ran  := extensions._get ('curr_test');
  v_fail := extensions.num_failed ();

  v_ok := v_ran is not null
          and coalesce (v_fail, 0) = 0
          and (v_plan is null or v_plan = 0 or v_plan = v_ran);

  if v_ran is null then
    v_msg := 'no tests run';
  elsif v_plan is null or v_plan = 0 then
    v_msg := format ('no plan: ran %s test(s)', v_ran);
  elsif v_ran <> v_plan then
    v_msg := format ('Looks like you planned %s test(s) but ran %s', v_plan, v_ran);
  elsif coalesce (v_fail, 0) > 0 then
    v_msg := format ('Looks like you failed %s test(s) of %s', v_fail, v_plan);
  else
    v_msg := format ('Looks like you passed %s test(s)', v_ran);
  end if;

  return jsonb_build_object (
    'verdict', case when v_ok then 'PASS' else 'FAIL' end,
    'plan',    v_plan,
    'ran',     v_ran,
    'failed',  coalesce (v_fail, 0),
    'summary', v_msg
  );
end;
$$;

comment on function public.pgtap_summary () is
  'pgTAP verdict for the current session. Returns exactly one jsonb row: {"verdict":"PASS"|"FAIL","plan":n,"ran":n,"failed":n,"summary":"..."}. MUST be the last statement of a test file so the MCP execute_sql result is the verdict.';

-- -----------------------------------------------------------------------------
-- RLS helpers (pgTAP 1.3.3 ships no RLS assertions)
-- -----------------------------------------------------------------------------
create or replace function public.pgtap_rls_enabled (p_table regclass)
  returns boolean
  language sql
  stable
  set search_path = ''
as $$
  select coalesce (
    (select c.relrowsecurity from pg_catalog.pg_class c where c.oid = p_table),
    false
  );
$$;

create or replace function public.pgtap_rls_forced (p_table regclass)
  returns boolean
  language sql
  stable
  set search_path = ''
as $$
  select coalesce (
    (select c.relforcerowsecurity from pg_catalog.pg_class c where c.oid = p_table),
    false
  );
$$;

create or replace function public.pgtap_policy_count (p_table regclass, p_cmd text default null)
  returns integer
  language sql
  stable
  set search_path = ''
as $$
  select count (*)::integer
  from pg_catalog.pg_policy p
  where p.polrelid = p_table
    and (p_cmd is null or p.polcmd = p_cmd::"char");
$$;

comment on function public.pgtap_rls_enabled (regclass) is
  'True when RLS is enabled on the given table. Use inside ok(...): ok(public.pgtap_rls_enabled(''public.profiles''::regclass), ''RLS enabled on profiles'').';

comment on function public.pgtap_rls_forced (regclass) is
  'True when FORCE ROW LEVEL SECURITY is set on the given table.';

comment on function public.pgtap_policy_count (regclass, text) is
  'Number of RLS policies on the given table; p_cmd filters by command (r=select, a=insert, w=update, d=delete). NULL = all policies.';

-- -----------------------------------------------------------------------------
-- Lock down: development helpers only, never callable through PostgREST.
-- -----------------------------------------------------------------------------
revoke execute on function public.pgtap_summary () from public, anon, authenticated, service_role;
revoke execute on function public.pgtap_rls_enabled (regclass) from public, anon, authenticated, service_role;
revoke execute on function public.pgtap_rls_forced (regclass) from public, anon, authenticated, service_role;
revoke execute on function public.pgtap_policy_count (regclass, text) from public, anon, authenticated, service_role;
