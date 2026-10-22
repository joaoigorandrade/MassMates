-- =============================================================================
-- A1 · 0009 · Fix public.pgtap_summary()
-- =============================================================================
-- extensions.num_failed() is a LANGUAGE sql function whose body is
-- `SELECT _get('failed')` — an UNQUALIFIED call. Called from a function with
-- `set search_path = ''` the lookup fails with
--   ERROR: function _get(unknown) does not exist
--
-- extensions._get(text) is LANGUAGE plpgsql with a dynamic EXECUTE, so the
-- unqualified reference to the temp table __tcache__ still resolves (pg_temp is
-- always searched first). Calling it qualified is therefore safe.
--
-- Same public contract, same return shape — only the internal call changes.
-- -----------------------------------------------------------------------------

create or replace function public.pgtap_summary ()
  returns jsonb
  language plpgsql
  stable
  set search_path = ''
as $$
declare
  v_plan integer;
  v_ran  integer;
  v_fail integer;
  v_msg  text;
  v_ok   boolean;
begin
  v_plan := extensions._get ('plan');
  v_ran  := extensions._get ('curr_test');
  v_fail := extensions._get ('failed');

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
