-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025038  ("create_group")
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
-- A3 · 0202 · invite codes, slot accounting, public.create_group
-- =============================================================================
-- Implementation lives in the `private` schema (not an exposed PostgREST
-- schema). The `public` RPCs are thin wrappers so that PostgREST can reach
-- them while the privileged statements stay unreachable.
--
-- Error convention
--   42501  authentication / authorisation failure
--   22023  invalid argument
--   P0001  business rule violated (slot limit, last admin, ...)
--   P0002  not found
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- private.generate_invite_code()
-- -----------------------------------------------------------------------------
-- Collision safe 6-digit code.
--   * the transaction-scoped advisory lock serialises the "is it free?" check
--     against the INSERT, so two concurrent creators cannot pick the same code;
--   * the loop is bounded (20 attempts) — it never spins forever;
--   * a code is "taken" while it is the invite_code of ANY group (archived
--     groups included) or the code of a live (not revoked) invite row.
create or replace function private.generate_invite_code (p_max_attempts integer default 20)
  returns text
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_code    text;
  v_attempt integer := 0;
begin
  perform pg_advisory_xact_lock (hashtext ('massmates.group_invite_code'));

  while v_attempt < coalesce (p_max_attempts, 20) loop
    v_attempt := v_attempt + 1;
    v_code := lpad (floor (random () * 1000000)::bigint::text, 6, '0');

    if not exists (select 1 from public.groups g where g.invite_code = v_code)
       and not exists (
         select 1
         from public.group_invites i
         where i.code = v_code
           and i.revoked_at is null
       ) then
      return v_code;
    end if;
  end loop;

  raise exception 'invite code generation failed after % attempts', p_max_attempts
    using errcode = 'P0001';
end;
$$;

comment on function private.generate_invite_code (integer) is
  'Returns a free 6-digit invite code. Bounded retry loop (default 20) under a transaction-scoped advisory lock; never loops forever.';

-- -----------------------------------------------------------------------------
-- private.slot_state(user_id)
-- -----------------------------------------------------------------------------
-- The single source of truth for the group-slot rules.
--
--   personal_max  = 2 (+1 while a `group_slot` unlock is active)
--   seasonal_max  = 1
--   personal_used = ACTIVE memberships in `fraternity` groups
--   seasonal_used = ACTIVE memberships in `challenge` groups
--
-- A membership counts as ACTIVE when the group is not archived and, for a
-- challenge, the season has not ended yet (ends_on is null or >= today).
create or replace function private.slot_state (p_user_id uuid)
  returns jsonb
  language sql
  stable
  security definer
  set search_path = ''
as $$
  with bonus as (
    select
      exists (
        select 1
        from public.slot_unlocks su
        where su.user_id = p_user_id
          and su.kind = 'group_slot'
          and (su.expires_at is null or su.expires_at > now())
      ) as active,
      (
        select max (su.expires_at)
        from public.slot_unlocks su
        where su.user_id = p_user_id
          and su.kind = 'group_slot'
          and (su.expires_at is null or su.expires_at > now())
      ) as expires_at
  ),
  personal as (
    select count(*)::int as used
    from public.group_members gm
    join public.groups g on g.id = gm.group_id
    where gm.user_id = p_user_id
      and g.group_type = 'fraternity'
      and g.archived_at is null
  ),
  seasonal as (
    select count(*)::int as used
    from public.group_members gm
    join public.groups g on g.id = gm.group_id
    where gm.user_id = p_user_id
      and g.group_type = 'challenge'
      and g.archived_at is null
      and (g.ends_on is null or g.ends_on >= current_date)
  )
  select jsonb_build_object (
    'personal_used',      personal.used,
    'personal_max',       2 + (case when bonus.active then 1 else 0 end),
    'seasonal_used',      seasonal.used,
    'seasonal_max',       1,
    'bonus_active',       bonus.active,
    'bonus_expires_at',   bonus.expires_at,
    'personal_available', greatest (0, 2 + (case when bonus.active then 1 else 0 end) - personal.used),
    'seasonal_available', greatest (0, 1 - seasonal.used)
  )
  from bonus, personal, seasonal;
$$;

comment on function private.slot_state (uuid) is
  'Slot accounting for one user: personal_used/max, seasonal_used/max, bonus_active, bonus_expires_at and the two `*_available` counters.';

-- -----------------------------------------------------------------------------
-- private.assert_slot_available(user_id, group_type)
-- -----------------------------------------------------------------------------
create or replace function private.assert_slot_available (
  p_user_id    uuid,
  p_group_type public.group_type
)
  returns void
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_state jsonb;
begin
  v_state := private.slot_state (p_user_id);

  if p_group_type = 'challenge' then
    if (v_state ->> 'seasonal_used')::int >= (v_state ->> 'seasonal_max')::int then
      raise exception
        'slot limit: you already hold the % seasonal challenge slot', (v_state ->> 'seasonal_max')
        using errcode = 'P0001';
    end if;
  else
    if (v_state ->> 'personal_used')::int >= (v_state ->> 'personal_max')::int then
      raise exception
        'slot limit: you already hold % personal groups (watch a rewarded video to unlock one more for 30 days)',
        (v_state ->> 'personal_max')
        using errcode = 'P0001';
    end if;
  end if;
end;
$$;

comment on function private.assert_slot_available (uuid, public.group_type) is
  'Raises when the caller has no free slot left. A challenge consumes the seasonal slot, a fraternity a personal slot.';

-- -----------------------------------------------------------------------------
-- private.create_group_impl()
-- -----------------------------------------------------------------------------
create or replace function private.create_group_impl (
  p_name                text,
  p_description         text,
  p_group_type          public.group_type,
  p_scoring_mode        public.scoring_mode,
  p_sharing_requirement public.sharing_requirement,
  p_starts_on           date,
  p_ends_on             date,
  p_goal_target         integer
)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_uid      uuid := auth.uid();
  v_group    public.groups%rowtype;
  v_code     text;
  v_created  boolean := false;
  v_attempt  integer := 0;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not exists (select 1 from public.profiles p where p.id = v_uid) then
    raise exception 'your profile is not available yet' using errcode = '23503';
  end if;

  -- --- validation -----------------------------------------------------------
  if p_name is null or char_length (btrim (p_name)) < 1 or char_length (p_name) > 80 then
    raise exception 'invalid group name: expected 1 to 80 characters' using errcode = '22023';
  end if;

  if p_description is not null and char_length (p_description) > 500 then
    raise exception 'invalid group description: expected at most 500 characters' using errcode = '22023';
  end if;

  if p_goal_target is not null and p_goal_target <= 0 then
    raise exception 'invalid goal_target: expected a positive integer' using errcode = '22023';
  end if;

  if p_group_type = 'challenge' then
    if p_starts_on is null or p_ends_on is null then
      raise exception 'a challenge requires both starts_on and ends_on' using errcode = '22023';
    end if;
    if p_ends_on < p_starts_on then
      raise exception 'a challenge requires ends_on >= starts_on' using errcode = '22023';
    end if;
    if p_ends_on < current_date then
      raise exception 'a challenge cannot end in the past' using errcode = '22023';
    end if;
  else
    if p_ends_on is not null and p_ends_on < current_date then
      raise exception 'a fraternity cannot have an ends_on in the past' using errcode = '22023';
    end if;
  end if;

  if p_scoring_mode = 'collective_treasure' and p_goal_target is null then
    raise exception 'the collective_treasure scoring mode requires a goal_target' using errcode = '22023';
  end if;

  -- --- slot rule, BEFORE anything is written --------------------------------
  perform private.assert_slot_available (v_uid, p_group_type);

  -- --- group + invite code --------------------------------------------------
  while not v_created and v_attempt < 20 loop
    v_attempt := v_attempt + 1;
    v_code := private.generate_invite_code (20);

    begin
      insert into public.groups (
        name, description, group_type, scoring_mode, sharing_requirement,
        invite_code, starts_on, ends_on, goal_target, created_by
      ) values (
        btrim (p_name), p_description, p_group_type, p_scoring_mode, p_sharing_requirement,
        v_code, p_starts_on, p_ends_on, p_goal_target, v_uid
      )
      returning * into v_group;

      v_created := true;
    exception
      when unique_violation then
        v_code := null;   -- the code was taken between the check and the insert
    end;
  end loop;

  if not v_created then
    raise exception 'could not allocate a unique invite code' using errcode = 'P0001';
  end if;

  -- the creator is the first admin
  insert into public.group_members (group_id, user_id, role)
  values (v_group.id, v_uid, 'admin');

  insert into public.group_invites (group_id, code, created_by, max_uses)
  values (v_group.id, v_code, v_uid, 0);

  return jsonb_build_object (
    'group',       to_jsonb (v_group) - 'invite_code',
    'invite_code', v_code
  );
end;
$$;

comment on function private.create_group_impl (text, text, public.group_type, public.scoring_mode, public.sharing_requirement, date, date, integer) is
  'Creates a group, its admin membership and its first invite row. Enforces the slot rule before writing anything.';

-- -----------------------------------------------------------------------------
-- public.create_group() — the thin, exposed wrapper
-- -----------------------------------------------------------------------------
create or replace function public.create_group (
  p_name                text,
  p_description         text                            default null,
  p_group_type          public.group_type               default 'fraternity'::public.group_type,
  p_scoring_mode        public.scoring_mode             default 'faithful_days'::public.scoring_mode,
  p_sharing_requirement public.sharing_requirement      default 'open'::public.sharing_requirement,
  p_starts_on           date                            default null,
  p_ends_on             date                            default null,
  p_goal_target         integer                         default null
)
  returns jsonb
  language sql
  volatile
  security definer
  set search_path = ''
as $$
  select private.create_group_impl (
    p_name,
    p_description,
    p_group_type,
    p_scoring_mode,
    p_sharing_requirement,
    p_starts_on,
    p_ends_on,
    p_goal_target
  );
$$;

comment on function public.create_group (text, text, public.group_type, public.scoring_mode, public.sharing_requirement, date, date, integer) is
  'Creates a group. Returns {"group": {...}, "invite_code": "123456"}. The creator becomes the admin and holds one slot (personal for a fraternity, seasonal for a challenge).';

revoke execute on function public.create_group (text, text, public.group_type, public.scoring_mode, public.sharing_requirement, date, date, integer) from public, anon;
grant  execute on function public.create_group (text, text, public.group_type, public.scoring_mode, public.sharing_requirement, date, date, integer) to authenticated, service_role;

-- the private implementations are owner-only
revoke execute on function private.generate_invite_code (integer) from public;
revoke execute on function private.slot_state (uuid) from public;
revoke execute on function private.assert_slot_available (uuid, public.group_type) from public;
revoke execute on function private.create_group_impl (text, text, public.group_type, public.scoring_mode, public.sharing_requirement, date, date, integer) from public;
