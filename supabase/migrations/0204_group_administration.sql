-- =============================================================================
-- A3 · 0204 · invite reset, leaving, member removal, admin transfer
-- =============================================================================
-- Group administration rules (documented in supabase/SCHEMA.md):
--   * a group has exactly one admin; the creator starts as that admin;
--   * the last admin cannot be removed and cannot leave — the role must be
--     transferred first;
--   * an admin MAY remove another admin (the group keeps at least one admin);
--   * when the last member leaves, the group is archived.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- private.reset_invite_code_impl(group_id)
-- -----------------------------------------------------------------------------
create or replace function private.reset_invite_code_impl (p_group_id uuid)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_group   public.groups%rowtype;
  v_code    text;
  v_created boolean := false;
  v_attempt integer := 0;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_admin (p_group_id, v_uid) then
    raise exception 'only a group admin can reset the invite code' using errcode = '42501';
  end if;

  select g.* into v_group
  from public.groups g
  where g.id = p_group_id
    and g.archived_at is null;

  if not found then
    raise exception 'group not found' using errcode = 'P0002';
  end if;

  while not v_created and v_attempt < 20 loop
    v_attempt := v_attempt + 1;
    v_code := private.generate_invite_code (20);

    begin
      update public.groups
         set invite_code = v_code
       where id = p_group_id;

      v_created := true;
    exception
      when unique_violation then
        v_code := null;
    end;
  end loop;

  if not v_created then
    raise exception 'could not allocate a unique invite code' using errcode = 'P0001';
  end if;

  -- retire the previous codes, then publish the new one
  update public.group_invites
     set revoked_at = now()
   where group_id = p_group_id
     and revoked_at is null;

  insert into public.group_invites (group_id, code, created_by, max_uses)
  values (p_group_id, v_code, v_uid, 0);

  return jsonb_build_object (
    'group_id',    p_group_id,
    'invite_code', v_code
  );
end;
$$;

comment on function private.reset_invite_code_impl (uuid) is
  'Admin only. Issues a new invite code and revokes the previous invite rows.';

-- -----------------------------------------------------------------------------
-- public.reset_invite_code()
-- -----------------------------------------------------------------------------
create or replace function public.reset_invite_code (p_group_id uuid)
  returns jsonb
  language sql
  volatile
  security definer
  set search_path = ''
as $$
  select private.reset_invite_code_impl (p_group_id);
$$;

comment on function public.reset_invite_code (uuid) is
  'Admin only. Returns {"group_id": "...", "invite_code": "123456"} and revokes the previous code.';

revoke execute on function public.reset_invite_code (uuid) from public, anon;
grant  execute on function public.reset_invite_code (uuid) to authenticated, service_role;

revoke execute on function private.reset_invite_code_impl (uuid) from public;

-- -----------------------------------------------------------------------------
-- private.leave_group_impl(group_id)
-- -----------------------------------------------------------------------------
create or replace function private.leave_group_impl (p_group_id uuid)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_uid         uuid := auth.uid();
  v_member      public.group_members%rowtype;
  v_member_count integer;
  v_admin_count  integer;
  v_archived     boolean := false;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select gm.* into v_member
  from public.group_members gm
  where gm.group_id = p_group_id
    and gm.user_id = v_uid;

  if not found then
    raise exception 'you are not a member of this group' using errcode = 'P0002';
  end if;

  select count(*) into v_member_count
  from public.group_members gm
  where gm.group_id = p_group_id;

  select count(*) into v_admin_count
  from public.group_members gm
  where gm.group_id = p_group_id
    and gm.role = 'admin';

  -- the last member leaving closes the group for good
  if v_member_count <= 1 then
    update public.groups
       set archived_at = now()
     where id = p_group_id
       and archived_at is null;

    delete from public.group_members
     where group_id = p_group_id
       and user_id = v_uid;

    v_archived := true;
  else
    if v_member.role = 'admin' and v_admin_count <= 1 then
      raise exception
        'you are the last admin of this group: transfer the admin role before leaving'
        using errcode = 'P0001';
    end if;

    delete from public.group_members
     where group_id = p_group_id
       and user_id = v_uid;
  end if;

  return jsonb_build_object (
    'group_id', p_group_id,
    'left',     true,
    'archived', v_archived
  );
end;
$$;

comment on function private.leave_group_impl (uuid) is
  'Removes the caller from a group. The last admin must transfer the role first; the last member leaving archives the group.';

-- -----------------------------------------------------------------------------
-- public.leave_group()
-- -----------------------------------------------------------------------------
create or replace function public.leave_group (p_group_id uuid)
  returns jsonb
  language sql
  volatile
  security definer
  set search_path = ''
as $$
  select private.leave_group_impl (p_group_id);
$$;

comment on function public.leave_group (uuid) is
  'Leaves a group. Returns {"group_id": "...", "left": true, "archived": bool}.';

revoke execute on function public.leave_group (uuid) from public, anon;
grant  execute on function public.leave_group (uuid) to authenticated, service_role;

revoke execute on function private.leave_group_impl (uuid) from public;

-- -----------------------------------------------------------------------------
-- private.remove_member_impl(group_id, member_id)
-- -----------------------------------------------------------------------------
create or replace function private.remove_member_impl (p_group_id uuid, p_member_id uuid)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid();
  v_target     public.group_members%rowtype;
  v_admin_count integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_admin (p_group_id, v_uid) then
    raise exception 'only a group admin can remove a member' using errcode = '42501';
  end if;

  select gm.* into v_target
  from public.group_members gm
  where gm.group_id = p_group_id
    and gm.user_id = p_member_id;

  if not found then
    raise exception 'that user is not a member of this group' using errcode = 'P0002';
  end if;

  -- an admin may be removed as long as the group keeps an admin
  if v_target.role = 'admin' then
    select count(*) into v_admin_count
    from public.group_members gm
    where gm.group_id = p_group_id
      and gm.role = 'admin';

    if v_admin_count <= 1 then
      raise exception
        'cannot remove the last admin: transfer the admin role first'
        using errcode = 'P0001';
    end if;
  end if;

  delete from public.group_members
   where group_id = p_group_id
     and user_id = p_member_id;

  return jsonb_build_object (
    'group_id',      p_group_id,
    'removed_user',  p_member_id,
    'removed_self',  p_member_id = v_uid
  );
end;
$$;

comment on function private.remove_member_impl (uuid, uuid) is
  'Admin only. Removes a member. The last admin cannot be removed (transfer first).';

-- -----------------------------------------------------------------------------
-- public.remove_member()
-- -----------------------------------------------------------------------------
create or replace function public.remove_member (p_group_id uuid, p_member_id uuid)
  returns jsonb
  language sql
  volatile
  security definer
  set search_path = ''
as $$
  select private.remove_member_impl (p_group_id, p_member_id);
$$;

comment on function public.remove_member (uuid, uuid) is
  'Admin only. Removes a member from the group. The last admin must transfer the role first.';

revoke execute on function public.remove_member (uuid, uuid) from public, anon;
grant  execute on function public.remove_member (uuid, uuid) to authenticated, service_role;

revoke execute on function private.remove_member_impl (uuid, uuid) from public;

-- -----------------------------------------------------------------------------
-- private.transfer_admin_impl(group_id, new_admin_id)
-- -----------------------------------------------------------------------------
create or replace function private.transfer_admin_impl (p_group_id uuid, p_new_admin_id uuid)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_admin (p_group_id, v_uid) then
    raise exception 'only a group admin can transfer the admin role' using errcode = '42501';
  end if;

  if p_new_admin_id is null then
    raise exception 'a new admin is required' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.group_members gm
    where gm.group_id = p_group_id
      and gm.user_id = p_new_admin_id
  ) then
    raise exception 'the new admin must already be a member of this group' using errcode = 'P0002';
  end if;

  -- a group keeps exactly one admin
  update public.group_members
     set role = 'member'
   where group_id = p_group_id
     and role = 'admin'
     and user_id <> p_new_admin_id;

  update public.group_members
     set role = 'admin'
   where group_id = p_group_id
     and user_id = p_new_admin_id;

  return jsonb_build_object (
    'group_id',    p_group_id,
    'new_admin',   p_new_admin_id,
    'previous_admin', v_uid
  );
end;
$$;

comment on function private.transfer_admin_impl (uuid, uuid) is
  'Admin only. Promotes a member to admin and demotes the previous admin(s) to member.';

-- -----------------------------------------------------------------------------
-- public.transfer_admin()
-- -----------------------------------------------------------------------------
create or replace function public.transfer_admin (p_group_id uuid, p_new_admin_id uuid)
  returns jsonb
  language sql
  volatile
  security definer
  set search_path = ''
as $$
  select private.transfer_admin_impl (p_group_id, p_new_admin_id);
$$;

comment on function public.transfer_admin (uuid, uuid) is
  'Admin only. Transfers the admin role to another member. The previous admin becomes a member.';

revoke execute on function public.transfer_admin (uuid, uuid) from public, anon;
grant  execute on function public.transfer_admin (uuid, uuid) to authenticated, service_role;

revoke execute on function private.transfer_admin_impl (uuid, uuid) from public;
