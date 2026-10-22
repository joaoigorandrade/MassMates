-- =============================================================================
-- A10 · 0900 · harden the RLS helper surface
-- =============================================================================
-- Owner: A10 (security & QA audit). Prefix range 0900-0999.
--
-- WHY
--   `public.is_group_member(uuid, uuid)` & friends were SECURITY DEFINER and
--   lived in the PostgREST-exposed `public` schema. `authenticated` MUST keep
--   EXECUTE on them (PostgreSQL evaluates an RLS policy expression with the
--   *querying role's* privileges), so any signed-in user could call
--     POST /rest/v1/rpc/is_group_member {"p_group_id":"…","p_user_id":"…"}
--   and learn whether an ARBITRARY user is a member of an ARBITRARY group --
--   and, through `is_blocked`, whether an ARBITRARY pair of users has blocked
--   each other. That is an enumeration oracle.
--
--   Every policy in this project evaluated those helpers with the CALLER'S OWN
--   id as the second argument, so the two-user form was never needed by a
--   policy. The fix is a pure signature simplification:
--
--     before                                          after
--     public.is_group_member(uuid, uuid DEFAULT auth.uid())
--                                                   public.is_group_member(uuid)
--     public.is_group_admin(uuid, uuid DEFAULT auth.uid())
--                                                   public.is_group_admin(uuid)
--     public.is_blocked(uuid, uuid)                  public.is_blocked(uuid)
--     public.is_group_member_of_any(uuid DEFAULT auth.uid())
--                                                   public.is_group_member_of_any()
--     public.is_any_group_admin(uuid DEFAULT auth.uid())
--                                                   public.is_any_group_admin()
--
--   The privileged bodies move to the NON-EXPOSED `private` schema, where the
--   Supabase linter never looks and PostgREST never routes:
--     private.is_group_member_impl(uuid, uuid)      -- SECURITY DEFINER
--     private.is_group_admin_impl(uuid, uuid)       -- SECURITY DEFINER
--     private.is_blocked_impl(uuid, uuid)           -- SECURITY DEFINER
--     private.is_group_member_of_any_impl(uuid)     -- SECURITY DEFINER
--     private.is_any_group_admin_impl(uuid)         -- SECURITY DEFINER
--
--   The public helper becomes a thin SECURITY INVOKER wrapper that supplies
--   auth.uid() itself. Server-side code (the private.*_impl bodies of
--   A3/A5/A8) keeps the two-user form by calling `private.*_impl` directly.
--
-- COMPATIBILITY
--   The public signatures of the 5 helpers CHANGE (documented in
--   supabase/SCHEMA.md §3 + §21 and docs/backend/API.md). No RPC, table or
--   column is renamed or dropped; the iOS client never calls the helpers.
--
--   `private.is_blocked_impl` keeps the block relation SYMMETRIC: a block in
--   either direction hides the content of both parties.
--
-- ORDER MATTERS (the whole migration runs in ONE transaction)
--   3. the DEFAULT of the old overloads is dropped, so a one-argument call
--      resolves unambiguously to the new helper;
--   4. the new one-argument helpers are created;
--   5. every policy that references a helper is re-issued, which re-points
--      its dependency from the old overload to the new helper and drops the
--      now-redundant second argument;
--   6. the old overloads are dropped (they have no dependency left).
--
--   The whole file is ONE transaction: `apply_migration` wraps it, so no
--   explicit BEGIN/COMMIT is used here.
-- -----------------------------------------------------------------------------

-- 1. the privileged implementations, in the non-exposed schema ---------------

create or replace function private.is_group_member_impl (p_group_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.group_members gm where gm.group_id = p_group_id and gm.user_id = p_user_id);
$$;

create or replace function private.is_group_admin_impl (p_group_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.group_members gm where gm.group_id = p_group_id and gm.user_id = p_user_id and gm.role = 'admin'::public.member_role);
$$;

create or replace function private.is_blocked_impl (p_user_id uuid, p_other_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = p_user_id and b.blocked_id = p_other_id)
       or (b.blocker_id = p_other_id and b.blocked_id = p_user_id)
  );
$$;

create or replace function private.is_group_member_of_any_impl (p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.group_members gm where gm.user_id = p_user_id);
$$;

create or replace function private.is_any_group_admin_impl (p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.group_members gm where gm.user_id = p_user_id and gm.role = 'admin'::public.member_role);
$$;

comment on function private.is_group_member_impl (uuid, uuid) is
  'Two-user membership check. Reachable only from server-side code; the public helper public.is_group_member(uuid) supplies auth.uid() itself.';
comment on function private.is_group_admin_impl (uuid, uuid) is
  'Two-user group-admin check. Reachable only from server-side code.';
comment on function private.is_blocked_impl (uuid, uuid) is
  'Symmetric block lookup between two users (a block in either direction counts).';

-- 2. every server-side body now calls the private implementation -------------
--    (a pure textual substitution: `public.is_x (` -> `private.is_x_impl (`).
--    The two-user semantics of every call site are preserved exactly.

do $$
declare
  r         record;
  v_def     text;
  v_new     text;
begin
  for r in
    select p.oid, n.nspname, p.proname
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private', 'a3_preview')
      and p.prokind = 'f'
      and p.proname not in ('is_group_member', 'is_group_admin', 'is_blocked',
                            'is_group_member_of_any', 'is_any_group_admin')
    order by n.nspname, p.proname
  loop
    v_def := pg_get_functiondef (r.oid);
    v_new := v_def;
    v_new := regexp_replace (v_new, 'public\.is_group_member_of_any *\(', 'private.is_group_member_of_any_impl (', 'g');
    v_new := regexp_replace (v_new, 'public\.is_any_group_admin *\(',    'private.is_any_group_admin_impl (',    'g');
    v_new := regexp_replace (v_new, 'public\.is_group_member *\(',       'private.is_group_member_impl (',       'g');
    v_new := regexp_replace (v_new, 'public\.is_group_admin *\(',        'private.is_group_admin_impl (',        'g');
    v_new := regexp_replace (v_new, 'public\.is_blocked *\(',            'private.is_blocked_impl (',            'g');
    if v_new <> v_def then
      execute v_new;
    end if;
  end loop;
end;
$$;

-- 3. retire the two-argument overloads ---------------------------------------
--    They are RENAMED first (not dropped) so that:
--      * the policies that still reference them keep working (a policy depends
--        on the function by OID, so a rename is invisible to it), and
--      * the new one-argument overloads below can be created WITHOUT an
--        ambiguity error: `f(uuid)` next to `f(uuid, uuid DEFAULT …)` makes
--        every one-argument call ambiguous ("function f(uuid) is not unique").
--    The `_legacy` names are dropped in step 6, inside the same transaction.

alter function public.is_group_member        (uuid, uuid) rename to is_group_member_legacy;
alter function public.is_group_admin         (uuid, uuid) rename to is_group_admin_legacy;
alter function public.is_blocked             (uuid, uuid) rename to is_blocked_legacy;
alter function public.is_group_member_of_any (uuid)     rename to is_group_member_of_any_legacy;
alter function public.is_any_group_admin     (uuid)     rename to is_any_group_admin_legacy;

-- 4. the new, self-scoped public helpers --------------------------------------
--    Thin SECURITY INVOKER wrappers: they supply `auth.uid()` themselves, so a
--    caller can only ever ask about ITSELF.

create or replace function public.is_group_member (p_group_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select private.is_group_member_impl (p_group_id, auth.uid ());
$$;

create or replace function public.is_group_admin (p_group_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select private.is_group_admin_impl (p_group_id, auth.uid ());
$$;

create or replace function public.is_blocked (p_other_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select private.is_blocked_impl (auth.uid (), p_other_id);
$$;

create or replace function public.is_group_member_of_any ()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select private.is_group_member_of_any_impl (auth.uid ());
$$;

create or replace function public.is_any_group_admin ()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select private.is_any_group_admin_impl (auth.uid ());
$$;

comment on function public.is_group_member (uuid) is
  'True when the CALLER is a member of p_group_id. The two-argument form was removed in migration 0900: it let any signed-in user enumerate arbitrary group membership.';
comment on function public.is_group_admin (uuid) is
  'True when the CALLER is an admin of p_group_id. Self-scoped since migration 0900.';
comment on function public.is_blocked (uuid) is
  'True when p_other_id and the CALLER are blocked in either direction. Self-scoped since migration 0900.';

-- 5. every policy that references a helper is re-issued ----------------------
--    (a) the second argument (always the caller's own id) is dropped, and
--    (b) the dependency is re-pointed from the old overload to the new helper.
--    The replacement patterns match ONLY the exact two-argument shape used in
--    this project, so a policy can no longer express "is somebody else a
--    member?".

do $$
declare
  r record;
  v_qual  text;
  v_check text;
  v_arg1  text := '([a-z_][a-z0-9_.]*|private\.try_uuid\(\(storage\.foldername\(name\)\)\[1\]\))';
  v_arg2  text := '([a-z_][a-z0-9_.]*|private\.try_uuid\(\(storage\.foldername\(name\)\)\[2\]\))';
  v_pat_a text := 'is_(group_member|group_admin)(?:_legacy)?\(' || v_arg1 || ', \( SELECT auth\.uid\(\) AS uid\)\)';
  v_pat_b text := 'is_(group_member|group_admin)(?:_legacy)?\(' || v_arg1 || '\)';
  v_pat_c text := 'is_blocked(?:_legacy)?\(\( SELECT auth\.uid\(\) AS uid\), ' || v_arg2 || '\)';
  v_pat_d text := 'is_blocked(?:_legacy)?\(' || v_arg2 || '\)';
  v_pat_e text := 'is_(group_member_of_any|any_group_admin)(?:_legacy)?\(\)';
  v_pat_any text := 'is_(group_member|group_admin|blocked|group_member_of_any|any_group_admin)(?:_legacy)? *\(';
begin
  for r in
    select schemaname, tablename, policyname, cmd, qual, with_check
    from pg_policies
    where schemaname in ('public', 'storage')
    order by schemaname, tablename, policyname
  loop
    v_qual := r.qual;
    v_qual := regexp_replace (v_qual, v_pat_a, 'is_\1(\2)', 'g');
    v_qual := regexp_replace (v_qual, v_pat_b, 'is_\1(\2)', 'g');
    v_qual := regexp_replace (v_qual, v_pat_c, 'is_blocked(\1)', 'g');
    v_qual := regexp_replace (v_qual, v_pat_d, 'is_blocked(\1)', 'g');
    v_qual := regexp_replace (v_qual, v_pat_e, 'is_\1()', 'g');

    v_check := r.with_check;
    v_check := regexp_replace (v_check, v_pat_a, 'is_\1(\2)', 'g');
    v_check := regexp_replace (v_check, v_pat_b, 'is_\1(\2)', 'g');
    v_check := regexp_replace (v_check, v_pat_c, 'is_blocked(\1)', 'g');
    v_check := regexp_replace (v_check, v_pat_d, 'is_blocked(\1)', 'g');
    v_check := regexp_replace (v_check, v_pat_e, 'is_\1()', 'g');

    if r.qual ~ v_pat_any and lower (r.cmd) in ('all', 'select', 'update', 'delete') then
      execute format ('alter policy %I on %I.%I using (%s)', r.policyname, r.schemaname, r.tablename, v_qual);
    end if;
    if r.with_check ~ v_pat_any and lower (r.cmd) in ('all', 'insert', 'update') then
      execute format ('alter policy %I on %I.%I with check (%s)', r.policyname, r.schemaname, r.tablename, v_check);
    end if;
  end loop;
end;
$$;

-- 6. drop the retired two-argument overloads (the enumeration oracle) --------

drop function if exists public.is_group_member_legacy        (uuid, uuid);
drop function if exists public.is_group_admin_legacy         (uuid, uuid);
drop function if exists public.is_blocked_legacy             (uuid, uuid);
drop function if exists public.is_group_member_of_any_legacy (uuid);
drop function if exists public.is_any_group_admin_legacy     (uuid);

-- 7. privileges ---------------------------------------------------------------
--    `REVOKE … FROM PUBLIC` alone is NOT enough on this project: the platform's
--    default ACL grants `anon` EXECUTE on new public functions directly
--    (pg_default_acl for schema public, objtype f). `anon` is therefore
--    revoked explicitly and re-verified below.

revoke all on function private.is_group_member_impl (uuid, uuid)        from public, anon;
revoke all on function private.is_group_admin_impl (uuid, uuid)         from public, anon;
revoke all on function private.is_blocked_impl (uuid, uuid)             from public, anon;
revoke all on function private.is_group_member_of_any_impl (uuid)       from public, anon;
revoke all on function private.is_any_group_admin_impl (uuid)           from public, anon;

grant execute on function private.is_group_member_impl (uuid, uuid)      to authenticated, service_role;
grant execute on function private.is_group_admin_impl (uuid, uuid)       to authenticated, service_role;
grant execute on function private.is_blocked_impl (uuid, uuid)           to authenticated, service_role;
grant execute on function private.is_group_member_of_any_impl (uuid)     to authenticated, service_role;
grant execute on function private.is_any_group_admin_impl (uuid)         to authenticated, service_role;

revoke all on function public.is_group_member (uuid)        from public, anon;
revoke all on function public.is_group_admin (uuid)         from public, anon;
revoke all on function public.is_blocked (uuid)             from public, anon;
revoke all on function public.is_group_member_of_any ()     from public, anon;
revoke all on function public.is_any_group_admin ()         from public, anon;

grant execute on function public.is_group_member (uuid)      to authenticated, service_role;
grant execute on function public.is_group_admin (uuid)       to authenticated, service_role;
grant execute on function public.is_blocked (uuid)           to authenticated, service_role;
grant execute on function public.is_group_member_of_any ()   to authenticated, service_role;
grant execute on function public.is_any_group_admin ()       to authenticated, service_role;

-- 8. the legacy debug probe is no longer part of the client-facing API ------
--    `public.probe_wrapper` only echoes its argument, but it was callable by
--    `anon` and by PUBLIC. It is kept (it is a public object and may not be
--    dropped) but restricted to the server role.

revoke all on function public.probe_wrapper (text) from public, anon, authenticated;
grant execute on function public.probe_wrapper (text) to service_role;
revoke all on function private.probe_impl (text) from public, anon;
grant execute on function private.probe_impl (text) to service_role;

-- 9. verification ------------------------------------------------------------
--    Every check below MUST hold, otherwise the migration is rolled back.

do $$
declare
  v_bad int;
begin
  -- (a) the old overloads are gone: exactly 5 public helpers survive
  select count (*) into v_bad
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('is_group_member', 'is_group_admin', 'is_blocked',
                      'is_group_member_of_any', 'is_any_group_admin');
  if v_bad <> 5 then
    raise exception 'a10 0900: expected 5 public helpers, found %', v_bad;
  end if;

  select count (*) into v_bad
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('is_group_member', 'is_group_admin', 'is_blocked')
    and pg_get_function_identity_arguments (p.oid) not in ('p_group_id uuid', 'p_other_id uuid');
  if v_bad <> 0 then
    raise exception 'a10 0900: % public helpers still take a user id', v_bad;
  end if;

  -- (b) no policy still uses the two-argument shape
  select count (*) into v_bad
  from pg_policies
  where schemaname in ('public', 'storage')
    and (qual ~ 'is_(group_member|group_admin) *\([^()]*,' or with_check ~ 'is_(group_member|group_admin) *\([^()]*,')
    or (qual ~ 'is_blocked *\(\( *SELECT auth\.uid' or with_check ~ 'is_blocked *\(\( *SELECT auth\.uid');
  if v_bad <> 0 then
    raise exception 'a10 0900: % policies still call a two-argument helper', v_bad;
  end if;

  -- (c) no function body still calls a public helper
  select count (*) into v_bad
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname in ('public', 'private', 'a3_preview')
    and p.prosrc ~ 'public\.is_(group_member|group_admin|blocked|group_member_of_any|any_group_admin) *\(';
  if v_bad <> 0 then
    raise exception 'a10 0900: % function bodies still call a public helper', v_bad;
  end if;

  -- (d) `anon` may not execute any helper
  select count (*) into v_bad
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('is_group_member', 'is_group_admin', 'is_blocked',
                      'is_group_member_of_any', 'is_any_group_admin')
    and has_function_privilege ('anon', p.oid, 'execute');
  if v_bad <> 0 then
    raise exception 'a10 0900: anon can still execute % helpers', v_bad;
  end if;

  -- (e) `anon` may not reach the private implementations either
  select count (*) into v_bad
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'private'
    and p.proname in ('is_group_member_impl', 'is_group_admin_impl', 'is_blocked_impl',
                      'is_group_member_of_any_impl', 'is_any_group_admin_impl')
    and (has_function_privilege ('anon', p.oid, 'execute')
         or has_schema_privilege ('anon', 'private', 'usage'));
  if v_bad <> 0 then
    raise exception 'a10 0900: anon can still reach % private helper implementations', v_bad;
  end if;
end;
$$;
