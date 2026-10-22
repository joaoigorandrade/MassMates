-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025039  ("join_group")
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
-- A3 · 0203 · public.join_group_by_code · public.join_featured_challenge
-- =============================================================================
-- Both entry points enforce the slot rule server side. The client is never
-- trusted: a user can only ever hold 2 personal groups (+1 while a rewarded
-- slot is active) and 1 seasonal challenge.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- private.join_group_impl(code)
-- -----------------------------------------------------------------------------
create or replace function private.join_group_impl (p_code text)
  returns jsonb
  language plpgsql
  volatile
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
      select 1
      from public.group_invites i
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

  if v_group.created_by is not null and public.is_blocked (v_uid, v_group.created_by) then
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

  if found and v_invite.max_uses > 0 and v_invite.uses >= v_invite.max_uses then
    raise exception 'this invite code has reached its usage limit' using errcode = 'P0001';
  end if;

  insert into public.group_members (group_id, user_id, role)
  values (v_group.id, v_uid, 'member');

  if found then
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
  'Joins the group behind a 6-digit invite code. Idempotent, block aware, slot enforcing.';

-- -----------------------------------------------------------------------------
-- public.join_group_by_code()
-- -----------------------------------------------------------------------------
create or replace function public.join_group_by_code (p_code text)
  returns jsonb
  language sql
  volatile
  security definer
  set search_path = ''
as $$
  select private.join_group_impl (p_code);
$$;

comment on function public.join_group_by_code (text) is
  'Joins a group with its 6-digit invite code. Returns {"group": {...}, "invite_code": "...", "member_role": "...", "already_member": bool}.';

revoke execute on function public.join_group_by_code (text) from public, anon;
grant  execute on function public.join_group_by_code (text) to authenticated, service_role;

revoke execute on function private.join_group_impl (text) from public;

-- -----------------------------------------------------------------------------
-- private.join_featured_impl(group_id)
-- -----------------------------------------------------------------------------
create or replace function private.join_featured_impl (p_group_id uuid)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_group public.groups%rowtype;
  v_role  public.member_role;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select g.* into v_group
  from public.group_featured gf
  join public.groups g on g.id = gf.group_id
  where gf.group_id = p_group_id
    and gf.is_featured
    and g.archived_at is null;

  if not found then
    raise exception 'this challenge is not available' using errcode = 'P0002';
  end if;

  select gm.role into v_role
  from public.group_members gm
  where gm.group_id = v_group.id
    and gm.user_id = v_uid;

  if v_role is not null then
    return jsonb_build_object (
      'group',          to_jsonb (v_group) - 'invite_code',
      'member_role',    v_role,
      'already_member', true
    );
  end if;

  if v_group.created_by is not null and public.is_blocked (v_uid, v_group.created_by) then
    raise exception 'you cannot join this group' using errcode = 'P0001';
  end if;

  -- a featured challenge is always a challenge, so it consumes the seasonal slot
  perform private.assert_slot_available (v_uid, 'challenge'::public.group_type);

  insert into public.group_members (group_id, user_id, role)
  values (v_group.id, v_uid, 'member');

  return jsonb_build_object (
    'group',          to_jsonb (v_group) - 'invite_code',
    'member_role',    'member',
    'already_member', false
  );
end;
$$;

comment on function private.join_featured_impl (uuid) is
  'Joins a group listed in public.group_featured. Consumes the seasonal slot.';

-- -----------------------------------------------------------------------------
-- public.join_featured_challenge()
-- -----------------------------------------------------------------------------
create or replace function public.join_featured_challenge (p_group_id uuid)
  returns jsonb
  language sql
  volatile
  security definer
  set search_path = ''
as $$
  select private.join_featured_impl (p_group_id);
$$;

comment on function public.join_featured_challenge (uuid) is
  'Joins a Featured Seasonal Challenge. Consumes the single seasonal slot.';

revoke execute on function public.join_featured_challenge (uuid) from public, anon;
grant  execute on function public.join_featured_challenge (uuid) to authenticated, service_role;

revoke execute on function private.join_featured_impl (uuid) from public;
