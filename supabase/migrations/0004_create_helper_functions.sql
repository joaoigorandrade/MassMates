-- =============================================================================
-- A1 · 0004 · RLS helper functions + triggers
-- =============================================================================
-- Every helper is SECURITY DEFINER with `set search_path = ''` and fully
-- qualified object names, so:
--   * it can read tables the calling role cannot read (no RLS recursion), and
--   * it cannot be hijacked through a mutable search_path.
-- The definer is the table owner (`postgres`), which has BYPASSRLS on this
-- project, so the inner reads are not re-filtered by RLS.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- current_user_id()
-- -----------------------------------------------------------------------------
create or replace function public.current_user_id ()
  returns uuid
  language sql
  stable
  security invoker
  set search_path = ''
as $$
  select auth.uid();
$$;

comment on function public.current_user_id () is
  'The uid of the caller (auth.uid()), or NULL for anon / service-role calls without a JWT. Use instead of auth.uid() so policies stay uniform.';

-- -----------------------------------------------------------------------------
-- is_group_member(group_id, user_id)
-- -----------------------------------------------------------------------------
create or replace function public.is_group_member (p_group_id uuid, p_user_id uuid default auth.uid ())
  returns boolean
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select exists (
    select 1
    from public.group_members gm
    where gm.group_id = p_group_id
      and gm.user_id  = p_user_id
  );
$$;

comment on function public.is_group_member (uuid, uuid) is
  'True when p_user_id is a member of p_group_id. SECURITY DEFINER: reads public.group_members without RLS, so it is safe to call from an RLS policy on group_members itself (no infinite recursion). p_user_id defaults to the caller.';

-- -----------------------------------------------------------------------------
-- is_group_admin(group_id, user_id)
-- -----------------------------------------------------------------------------
create or replace function public.is_group_admin (p_group_id uuid, p_user_id uuid default auth.uid ())
  returns boolean
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select exists (
    select 1
    from public.group_members gm
    where gm.group_id = p_group_id
      and gm.user_id  = p_user_id
      and gm.role     = 'admin'::public.member_role
  );
$$;

comment on function public.is_group_admin (uuid, uuid) is
  'True when p_user_id is an ADMIN of p_group_id (public.member_role = ''admin''). SECURITY DEFINER, recursion-safe. p_user_id defaults to the caller.';

-- -----------------------------------------------------------------------------
-- is_group_member_of_any(user_id)
-- -----------------------------------------------------------------------------
create or replace function public.is_group_member_of_any (p_user_id uuid default auth.uid ())
  returns boolean
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select exists (
    select 1
    from public.group_members gm
    where gm.user_id = p_user_id
  );
$$;

comment on function public.is_group_member_of_any (uuid) is
  'True when p_user_id belongs to at least one group. Used by A5 feed/chat policies to require "not a lone user". p_user_id defaults to the caller.';

-- -----------------------------------------------------------------------------
-- is_any_group_admin(user_id)
-- -----------------------------------------------------------------------------
create or replace function public.is_any_group_admin (p_user_id uuid default auth.uid ())
  returns boolean
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select exists (
    select 1
    from public.group_members gm
    where gm.user_id = p_user_id
      and gm.role    = 'admin'::public.member_role
  );
$$;

comment on function public.is_any_group_admin (uuid) is
  'True when p_user_id is an admin of at least one group. Used to gate reads of public.audit_log. p_user_id defaults to the caller.';

-- -----------------------------------------------------------------------------
-- is_blocked(user_id, other_id)  — symmetric
-- -----------------------------------------------------------------------------
create or replace function public.is_blocked (p_user_id uuid, p_other_id uuid)
  returns boolean
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select exists (
    select 1
    from public.user_blocks b
    where (b.blocker_id = p_user_id and b.blocked_id = p_other_id)
       or (b.blocker_id = p_other_id and b.blocked_id = p_user_id)
  );
$$;

comment on function public.is_blocked (uuid, uuid) is
  'True when a block exists in EITHER direction between the two users. Symmetric on purpose: a block hides both the blocker''s content and the blocked user''s content from the other side. A6 owns the block_user/unblock_user RPCs that write the rows.';

-- -----------------------------------------------------------------------------
-- set_updated_at() — trigger
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at ()
  returns trigger
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function public.set_updated_at () is
  'BEFORE UPDATE trigger that keeps updated_at current. Attach to every table that has an updated_at column (see attach_updated_at).';

-- -----------------------------------------------------------------------------
-- attach_updated_at(table) — convenience DDL helper
-- -----------------------------------------------------------------------------
create or replace function public.attach_updated_at (p_table regclass)
  returns void
  language plpgsql
  security invoker
  set search_path = ''
as $$
declare
  v_table   text;
  v_trigger text;
begin
  select c.relname into v_table
  from pg_catalog.pg_class c
  where c.oid = p_table;

  if v_table is null then
    raise exception 'attach_updated_at: relation % does not exist', p_table;
  end if;

  v_trigger := 'trg_' || v_table || '_updated_at';

  execute format('drop trigger if exists %I on %s', v_trigger, p_table);
  execute format(
    'create trigger %I before update on %s for each row execute function public.set_updated_at()',
    v_trigger,
    p_table
  );
end;
$$;

comment on function public.attach_updated_at (regclass) is
  'Creates (or replaces) the BEFORE UPDATE trigger trg_<table>_updated_at on p_table, wired to public.set_updated_at(). SECURITY INVOKER: must be called by the table owner (a migration running as postgres).';

-- The DDL helper is owner-only: it must never be callable by an end user.
revoke execute on function public.attach_updated_at (regclass) from public, anon, authenticated, service_role;
