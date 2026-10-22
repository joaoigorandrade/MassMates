-- =============================================================================
-- A10 · 0901 · move the domain RPCs behind a non-exposed implementation
-- =============================================================================
-- Owner: A10 (security & QA audit). Prefix range 0900-0999.
--
-- WHY
--   28 public RPCs were `SECURITY DEFINER` inside the PostgREST-exposed
--   `public` schema and executable by `authenticated`. That is exactly what
--   the Supabase linter flags as
--   `authenticated_security_definer_function_executable` (33 findings = 28
--   domain RPCs + 5 A1 helpers; the 5 helpers are fixed by migration 0900).
--
--   The proven pattern (already used by A2, A3, A5, A7):
--
--     private.<name>_impl   SECURITY DEFINER, SET search_path = ''   <- privileged
--     public.<name>          SECURITY INVOKER,  SET search_path = ''   <- thin wrapper
--
--   The implementation lives in `private`, which PostgREST does NOT expose,
--   so it is unreachable through /rest/v1/rpc/... and the linter never sees
--   it. The public wrapper keeps the EXACT signature, the EXACT return type
--   and the EXACT error behaviour of the original function -- only the
--   security context changes.
--
--   The 28 functions converted here:
--     A4: get_consistency_heatmap, get_group_progress, get_rule_of_life_ring,
--          get_streak_summary, set_practice_points, submit_check_in,
--          use_streak_mercy
--     A5: clear_pinned_notice, create_chat_message, create_prayer_intention,
--          get_chat_messages, get_feed_posts, get_prayer_intentions,
--          set_pinned_notice, soft_delete_chat_message, soft_delete_feed_post,
--          toggle_amen, toggle_prayed_for
--     A6: admin_delete_post, block_user, create_signed_witness_url,
--          get_moderation_actions, get_moderation_queue, hide_content,
--          list_blocked_users, report_content, resolve_report, unblock_user
--
-- HOW
--   The privileged body is moved VERBATIM: it is read back from
--   `pg_get_functiondef()` and re-created as `private.<name>_impl`, so there
--   is no risk of a transcription error in a 500-line body. The public
--   function is then re-created in place with `CREATE OR REPLACE FUNCTION`,
--   which keeps its name, signature, defaults and ACL.
--
--   Cross-references are safe: a `SECURITY DEFINER` implementation that calls
--   `public.other(...)` now calls the thin INVOKER wrapper, which forwards to
--   `private.other_impl(...)`. The effective privilege is still the owner's
--   (postgres), so the behaviour is unchanged. The one dynamic-SQL reference
--   (`public.admin_delete_post` -> `public.soft_delete_feed_post`) resolves
--   the same way.
--
--   The public wrappers keep the ORIGINAL volatility so the planner behaves
--   exactly as before.
-- -----------------------------------------------------------------------------

do $$
declare
  r       record;
  v_def   text;
  v_args  text;
  v_ret   text;
  v_vol   text;
  v_call  text;
  v_names text;
begin
  for r in
    select p.oid, p.proname, p.proargnames, p.provolatile
    from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and p.proname = any (array[
        -- A4
        'get_consistency_heatmap', 'get_group_progress', 'get_rule_of_life_ring',
        'get_streak_summary', 'set_practice_points', 'submit_check_in',
        'use_streak_mercy',
        -- A5
        'clear_pinned_notice', 'create_chat_message', 'create_prayer_intention',
        'get_chat_messages', 'get_feed_posts', 'get_prayer_intentions',
        'set_pinned_notice', 'soft_delete_chat_message', 'soft_delete_feed_post',
        'toggle_amen', 'toggle_prayed_for',
        -- A6
        'admin_delete_post', 'block_user', 'create_signed_witness_url',
        'get_moderation_actions', 'get_moderation_queue', 'hide_content',
        'list_blocked_users', 'report_content', 'resolve_report', 'unblock_user'])
    order by p.proname
  loop
    -- 1. the privileged body moves into the non-exposed schema, VERBATIM
    v_def := pg_get_functiondef (r.oid);
    v_def := regexp_replace (v_def, '^CREATE OR REPLACE FUNCTION public\.', 'CREATE OR REPLACE FUNCTION private.', '');
    v_def := regexp_replace (v_def, '(private\.' || r.proname || ')\(', '\1' || '_impl(', '');
    execute v_def;

    -- 2. the public function becomes a thin SECURITY INVOKER wrapper
    v_args := pg_get_function_arguments (r.oid);
    v_ret  := pg_get_function_result (r.oid);
    v_vol  := case r.provolatile
                when 'i' then 'immutable'
                when 's' then 'stable'
                else 'volatile'
              end;

    select string_agg (quote_ident (nm), ', ' order by ord)
      into v_call
      from unnest (r.proargnames) with ordinality as t (nm, ord);

    execute format ($a10$
      create or replace function public.%1$I (%2$s)
      returns %3$s
      language plpgsql
      %4$s
      security invoker
      set search_path = ''
      as $a10fn$
      begin
        return private.%1$I_impl (%5$s);
      end;
      $a10fn$;
    $a10$, r.proname, v_args, v_ret, v_vol, v_call);
  end loop;
end;
$$;

-- 3. privileges ----------------------------------------------------------------
--    `REVOKE … FROM PUBLIC` alone is NOT enough on this project: the platform's
--    default ACL grants `anon` EXECUTE on new public functions directly
--    (pg_default_acl for schema public, objtype f). `anon` is revoked
--    explicitly and re-verified below.

do $$
declare
  r record;
begin
  for r in
    select p.proname, pg_get_function_identity_arguments (p.oid) as idargs
    from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and p.proname = any (array[
        'get_consistency_heatmap', 'get_group_progress', 'get_rule_of_life_ring',
        'get_streak_summary', 'set_practice_points', 'submit_check_in',
        'use_streak_mercy',
        'clear_pinned_notice', 'create_chat_message', 'create_prayer_intention',
        'get_chat_messages', 'get_feed_posts', 'get_prayer_intentions',
        'set_pinned_notice', 'soft_delete_chat_message', 'soft_delete_feed_post',
        'toggle_amen', 'toggle_prayed_for',
        'admin_delete_post', 'block_user', 'create_signed_witness_url',
        'get_moderation_actions', 'get_moderation_queue', 'hide_content',
        'list_blocked_users', 'report_content', 'resolve_report', 'unblock_user'])
  loop
    execute format ('revoke all on function public.%1$I (%2$s) from public, anon', r.proname, r.idargs);
    execute format ('grant execute on function public.%1$I (%2$s) to authenticated, service_role', r.proname, r.idargs);
    execute format ('revoke all on function private.%1$I (%2$s) from public, anon', r.proname || '_impl', r.idargs);
    execute format ('grant execute on function private.%1$I (%2$s) to authenticated, service_role', r.proname || '_impl', r.idargs);
  end loop;
end;
$$;

-- 4. verification ---------------------------------------------------------------

do $$
declare
  v_bad  int;
  v_list text[];
begin
  v_list := array[
    'get_consistency_heatmap', 'get_group_progress', 'get_rule_of_life_ring',
    'get_streak_summary', 'set_practice_points', 'submit_check_in',
    'use_streak_mercy',
    'clear_pinned_notice', 'create_chat_message', 'create_prayer_intention',
    'get_chat_messages', 'get_feed_posts', 'get_prayer_intentions',
    'set_pinned_notice', 'soft_delete_chat_message', 'soft_delete_feed_post',
    'toggle_amen', 'toggle_prayed_for',
    'admin_delete_post', 'block_user', 'create_signed_witness_url',
    'get_moderation_actions', 'get_moderation_queue', 'hide_content',
    'list_blocked_users', 'report_content', 'resolve_report', 'unblock_user']::text[];

  -- (a) every public wrapper is SECURITY INVOKER
  select count (*) into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname = any (v_list)
    and p.prosecdef;
  if v_bad <> 0 then
    raise exception 'a10 0901: % public RPCs are still SECURITY DEFINER', v_bad;
  end if;

  -- (b) every private implementation exists and is SECURITY DEFINER
  select count (*) into v_bad
  from pg_proc p
  where p.pronamespace = 'private'::regnamespace
    and p.proname = any (array(select x || '_impl' from unnest (v_list) x))
    and p.prosecdef
    and p.proconfig @> array['search_path=""'];
  if v_bad <> cardinality (v_list) then
    raise exception 'a10 0901: % private implementations are missing or not SECURITY DEFINER', v_bad;
  end if;

  -- (c) `anon` may not execute any of them
  select count (*) into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname = any (v_list)
    and has_function_privilege ('anon', p.oid, 'execute');
  if v_bad <> 0 then
    raise exception 'a10 0901: anon can still execute % public RPCs', v_bad;
  end if;

  -- (d) `authenticated` may still execute them (the client contract)
  select count (*) into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.proname = any (v_list)
    and not has_function_privilege ('authenticated', p.oid, 'execute');
  if v_bad <> 0 then
    raise exception 'a10 0901: authenticated lost EXECUTE on % public RPCs', v_bad;
  end if;

  -- (e) NO SECURITY DEFINER function callable by `authenticated` is left in the
  --     exposed `public` schema -- this is the lint the migration targets.
  select count (*) into v_bad
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and p.prosecdef
    and has_function_privilege ('authenticated', p.oid, 'execute');
  if v_bad <> 0 then
    raise exception 'a10 0901: % SECURITY DEFINER functions are still callable by authenticated', v_bad;
  end if;
end;
$$;
