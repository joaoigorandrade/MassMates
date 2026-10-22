-- =============================================================================
-- A10 · 0904 · fix the `FOUND` bug in private.join_group_impl
-- =============================================================================
-- Owner: A10 (security & QA audit). Prefix range 0900-0999.
--
-- THE BUG (found by A10's RPC matrix)
--   `private.join_group_impl` used the PL/pgSQL pseudo-variable `FOUND` to
--   decide whether an invite row existed:
--
--     select i.* into v_invite
--     from public.group_invites i
--     where i.code = v_code and i.revoked_at is null
--     order by i.created_at desc
--     limit 1;
--
--     if found and v_invite.max_uses > 0 and ... then   -- (1) usage check
--       raise exception 'this invite code has reached its usage limit';
--     end if;
--
--     insert into public.group_members (group_id, user_id, role) values (...);
--
--     if found then                                     -- (2) usage counter
--       update public.group_invites set uses = uses + 1 where id = v_invite.id
--         returning uses into v_uses;
--       if v_uses is null then
--         raise exception 'this invite code has reached its usage limit';
--       end if;
--     end if;
--
--   The INSERT in between RESETS `FOUND` to true. So (2) always ran, even
--   when NO `group_invites` row existed -- and the UPDATE then matched zero
--   rows, leaving `v_uses` NULL, which raised the misleading
--   "this invite code has reached its usage limit".
--
--   The bug is REACHABLE: `public.groups.invite_code` is writable by a group
--   admin through the `groups_update_admin` policy (PostgREST PATCH
--   /rest/v1/groups). An admin who sets an invite code by hand produces a
--   group that NOBODY can join, and the error message blames the wrong thing.
--
-- THE FIX
--   Capture `FOUND` into a dedicated variable (`v_has_invite`) immediately
--   after the SELECT INTO, and use that variable for both branches. The
--   behaviour of the normal path (a code WITH a `group_invites` row) is
--   unchanged; a code WITHOUT one is now treated as the unlimited code it
--   really is.
--
--   The body is otherwise byte-for-byte the body of A3's implementation.
-- -----------------------------------------------------------------------------

create or replace function private.join_group_impl (p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid();
  v_code   text;
  v_group  public.groups%rowtype;
  v_invite public.group_invites%rowtype;
  v_role   public.member_role;
  v_uses   integer;
  v_has_invite boolean := false;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  -- normalise: strip every non digit (spaces, dashes, letters) and require
  -- exactly six digits.
  v_code := regexp_replace (coalesce (p_code, ''), '[^0-9]', '', 'g');
  if v_code !~ '^[0-9]{6}$' then
    raise exception 'invalid invite code: expected 6 digits' using errcode = '22023';
  end if;

  select g.* into v_group
  from public.groups g
  where g.invite_code = v_code
    and g.archived_at is null
    and not exists (
      select 1 from public.group_invites i
      where i.code = g.invite_code
        and i.revoked_at is not null
    );

  if not found then
    raise exception 'invite code not found' using errcode = 'P0002';
  end if;

  -- idempotent: an existing member gets the group back, no duplicate row and
  -- no extra use of the invite.
  select gm.role into v_role
  from public.group_members gm
  where gm.group_id = v_group.id
    and gm.user_id = v_uid;

  if v_role is not null then
    return jsonb_build_object (
      'group',          to_jsonb (v_group) - 'invite_code',
      'invite_code',    v_code,
      'member_role',    v_role,
      'already_member', true
    );
  end if;

  if v_group.created_by is not null and private.is_blocked_impl (v_uid, v_group.created_by) then
    raise exception 'you cannot join this group' using errcode = 'P0001';
  end if;

  -- slot rule
  perform private.assert_slot_available (v_uid, v_group.group_type);

  -- invite usage
  select i.* into v_invite
  from public.group_invites i
  where i.code = v_code
    and i.revoked_at is null
  order by i.created_at desc
  limit 1;

  -- A10 / 0904: `FOUND` must be captured HERE -- the INSERT below resets it.
  v_has_invite := found;

  if v_has_invite and v_invite.max_uses > 0 and v_invite.uses >= v_invite.max_uses then
    raise exception 'this invite code has reached its usage limit' using errcode = 'P0001';
  end if;

  insert into public.group_members (group_id, user_id, role)
  values (v_group.id, v_uid, 'member');

  if v_has_invite then
    update public.group_invites
       set uses = uses + 1
     where id = v_invite.id
       and (max_uses = 0 or uses < max_uses)
    returning uses into v_uses;

    if v_uses is null then
      raise exception 'this invite code has reached its usage limit' using errcode = 'P0001';
    end if;
  end if;

  return jsonb_build_object (
    'group',          to_jsonb (v_group) - 'invite_code',
    'invite_code',    v_code,
    'member_role',    'member',
    'already_member', false
  );
end;
$$;

comment on function private.join_group_impl (text) is
  'A10 / 0904: the invite-usage branch now uses a captured FOUND instead of the PL/pgSQL pseudo-variable, which the INSERT into group_members reset.';

-- The public wrapper keeps calling the implementation -- nothing changes for
-- the client. Only the implementation was corrected.
revoke all on function private.join_group_impl (text) from public, anon;
grant execute on function private.join_group_impl (text) to authenticated, service_role;

do $$
declare
  v_bad int;
begin
  select count (*) into v_bad
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'private' and p.proname = 'join_group_impl'
    and p.prosrc not like '%v_has_invite := found%';
  if v_bad <> 0 then
    raise exception 'a10 0904: join_group_impl was not patched';
  end if;
end;
$$;
