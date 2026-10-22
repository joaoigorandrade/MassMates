-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025258  ("featured_and_slots")
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
-- A3 · 0206 · preview, featured challenges, slot state, server-only grants
-- =============================================================================
-- `public.preview_group_by_code` and `public.list_featured_challenges` are the
-- LOGGED-OUT entry points. They are deliberately the only A3 RPCs that `anon`
-- may execute, and they return public-safe fields only:
--   * never `invite_code`
--   * never `created_by`
--   * `description` only as a truncated preview (160 characters)
--
-- There is NO `anon` SELECT policy on `public.groups`: RLS is row level, so any
-- anon row policy would also expose the `invite_code` and `created_by` columns
-- of every visible row. The preview therefore goes through these RPCs.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- private.preview_group_by_code_impl(code)
-- -----------------------------------------------------------------------------
create or replace function private.preview_group_by_code_impl (p_code text)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_code        text;
  v_group       public.groups%rowtype;
  v_member_count integer;
  v_is_featured boolean;
begin
  v_code := regexp_replace (coalesce (p_code, ''), '[^0-9]', '', 'g');
  if v_code !~ '^[0-9]{6}$' then
    raise exception 'invalid invite code: expected 6 digits' using errcode = '22023';
  end if;

  select g.* into v_group
  from public.groups g
  where g.invite_code = v_code
    and g.archived_at is null;

  if not found then
    raise exception 'invite code not found' using errcode = 'P0002';
  end if;

  select count(*) into v_member_count
  from public.group_members gm
  where gm.group_id = v_group.id;

  select coalesce(bool_or (gf.is_featured), false) into v_is_featured
  from public.group_featured gf
  where gf.group_id = v_group.id;

  return jsonb_build_object (
    'id',                 v_group.id,
    'name',               v_group.name,
    'group_type',         v_group.group_type,
    'scoring_mode',       v_group.scoring_mode,
    'sharing_requirement', v_group.sharing_requirement,
    'cover_path',         v_group.cover_path,
    'member_count',       v_member_count,
    'is_featured',        v_is_featured,
    'starts_on',          v_group.starts_on,
    'ends_on',            v_group.ends_on,
    'goal_target',        v_group.goal_target,
    'description_preview', left (coalesce (v_group.description, ''), 160)
  );
end;
$$;

comment on function private.preview_group_by_code_impl (text) is
  'Public, safe preview of a group behind a 6-digit code. Never returns invite_code, created_by or the full description.';

-- -----------------------------------------------------------------------------
-- public.preview_group_by_code()  — callable by anon
-- -----------------------------------------------------------------------------
create or replace function public.preview_group_by_code (p_code text)
  returns jsonb
  language sql
  stable
  security invoker
  set search_path = ''
as $$
  select private.preview_group_by_code_impl (p_code);
$$;

comment on function public.preview_group_by_code (text) is
  'Public preview of a group for the massmates://join/:code deep link. Returns {id, name, group_type, scoring_mode, sharing_requirement, cover_path, member_count, is_featured, starts_on, ends_on, goal_target, description_preview}. Never returns invite_code or created_by.';

revoke execute on function public.preview_group_by_code (text) from public;
grant  execute on function public.preview_group_by_code (text) to anon, authenticated, service_role;

grant usage on schema private to anon;
grant execute on function private.preview_group_by_code_impl (text) to anon;

-- -----------------------------------------------------------------------------
-- private.list_featured_challenges_impl()
-- -----------------------------------------------------------------------------
create or replace function private.list_featured_challenges_impl ()
  returns jsonb
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select coalesce (
    jsonb_agg (
      to_jsonb (x)
      order by x.display_order, x.created_at
    ),
    '[]'::jsonb
  )
  from (
    select
      g.id,
      g.name,
      g.group_type,
      g.scoring_mode,
      g.sharing_requirement,
      g.cover_path,
      g.starts_on,
      g.ends_on,
      g.goal_target,
      gf.display_order,
      gf.created_at,
      left (coalesce (g.description, ''), 160) as description_preview,
      (
        select count(*)::int
        from public.group_members gm
        where gm.group_id = g.id
      ) as member_count
    from public.group_featured gf
    join public.groups g on g.id = gf.group_id
    where gf.is_featured
      and g.archived_at is null
      and g.group_type = 'challenge'
  ) x;
$$;

comment on function private.list_featured_challenges_impl () is
  'The public discovery showcase: the featured seasonal challenges with safe fields only.';

-- -----------------------------------------------------------------------------
-- public.list_featured_challenges()  — callable by anon
-- -----------------------------------------------------------------------------
create or replace function public.list_featured_challenges ()
  returns jsonb
  language sql
  stable
  security invoker
  set search_path = ''
as $$
  select private.list_featured_challenges_impl ();
$$;

comment on function public.list_featured_challenges () is
  'Returns the featured seasonal challenges as a jsonb array (safe fields only). Callable by anon.';

revoke execute on function public.list_featured_challenges () from public;
grant  execute on function public.list_featured_challenges () to anon, authenticated, service_role;

grant execute on function private.list_featured_challenges_impl () to anon;

-- -----------------------------------------------------------------------------
-- private.my_group_slots_impl()
-- -----------------------------------------------------------------------------
create or replace function private.my_group_slots_impl ()
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  return private.slot_state (v_uid);
end;
$$;

comment on function private.my_group_slots_impl () is
  'The slot state of the caller: personal_used/max, seasonal_used/max, bonus_active, bonus_expires_at, personal_available, seasonal_available.';

-- -----------------------------------------------------------------------------
-- public.my_group_slots()
-- -----------------------------------------------------------------------------
create or replace function public.my_group_slots ()
  returns jsonb
  language sql
  stable
  security invoker
  set search_path = ''
as $$
  select private.my_group_slots_impl ();
$$;

comment on function public.my_group_slots () is
  'Slot state of the caller. Returns {personal_used, personal_max, seasonal_used, seasonal_max, bonus_active, bonus_expires_at, personal_available, seasonal_available}.';

revoke execute on function public.my_group_slots () from public, anon;
grant  execute on function public.my_group_slots () to authenticated, service_role;

grant execute on function private.my_group_slots_impl () to authenticated;

-- -----------------------------------------------------------------------------
-- private.grant_slot_unlock_impl()
-- -----------------------------------------------------------------------------
-- Server side only (service_role). This is the entry point A7 uses after a
-- rewarded video / an admin grant / a sponsor gift.
create or replace function private.grant_slot_unlock_impl (
  p_user_id uuid,
  p_kind    text,
  p_source  text,
  p_days    integer default 30,
  p_notes   text default null
)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_row    public.slot_unlocks%rowtype;
  v_expiry timestamptz;
begin
  if p_user_id is null then
    raise exception 'a user is required' using errcode = '22023';
  end if;

  if p_kind is null or p_kind not in ('group_slot', 'streak_mercy', 'saint_theme') then
    raise exception 'invalid slot kind: %', p_kind using errcode = '22023';
  end if;

  if p_source is null or p_source not in ('rewarded_video', 'admin_grant', 'sponsored') then
    raise exception 'invalid slot source: %', p_source using errcode = '22023';
  end if;

  if p_notes is not null and char_length (p_notes) > 500 then
    raise exception 'invalid notes: expected at most 500 characters' using errcode = '22023';
  end if;

  -- a partial unique index on (user_id, kind) WHERE expires_at IS NULL OR
  -- expires_at > now() is impossible (now() is not immutable), so the
  -- "one active group_slot per user" rule is enforced here.
  if p_kind = 'group_slot' then
    select su.* into v_row
    from public.slot_unlocks su
    where su.user_id = p_user_id
      and su.kind = 'group_slot'
      and (su.expires_at is null or su.expires_at > now())
    order by su.created_at desc
    limit 1;

    if found then
      return jsonb_build_object (
        'slot_unlock',  to_jsonb (v_row),
        'already_active', true
      );
    end if;
  end if;

  if p_days is null or p_days <= 0 then
    v_expiry := null;
  else
    v_expiry := now() + make_interval (days => p_days);
  end if;

  insert into public.slot_unlocks (user_id, kind, source, starts_at, expires_at, notes)
  values (p_user_id, p_kind, p_source, now(), v_expiry, p_notes)
  returning * into v_row;

  return jsonb_build_object (
    'slot_unlock',   to_jsonb (v_row),
    'already_active', false
  );
end;
$$;

comment on function private.grant_slot_unlock_impl (uuid, text, text, integer, text) is
  'Grants a slot unlock. A second active group_slot for the same user is never created: the existing one is returned instead.';

-- -----------------------------------------------------------------------------
-- public.grant_slot_unlock()  — service_role only
-- -----------------------------------------------------------------------------
create or replace function public.grant_slot_unlock (
  p_user_id uuid,
  p_kind    text,
  p_source  text,
  p_days    integer default 30,
  p_notes   text default null
)
  returns jsonb
  language sql
  volatile
  security invoker
  set search_path = ''
as $$
  select private.grant_slot_unlock_impl (p_user_id, p_kind, p_source, p_days, p_notes);
$$;

comment on function public.grant_slot_unlock (uuid, text, text, integer, text) is
  'Server side only (service_role). Grants a group_slot / streak_mercy / saint_theme unlock. A group_slot expires after p_days (default 30). Idempotent: an active group_slot is never granted twice.';

revoke execute on function public.grant_slot_unlock (uuid, text, text, integer, text) from public, anon, authenticated;
grant  execute on function public.grant_slot_unlock (uuid, text, text, integer, text) to service_role;

grant execute on function private.grant_slot_unlock_impl (uuid, text, text, integer, text) to service_role;

-- -----------------------------------------------------------------------------
-- private.set_featured_group_impl()
-- -----------------------------------------------------------------------------
-- Server side only (service_role). A7 uses this to publish a Featured
-- Seasonal Challenge; it is the validated write path into group_featured.
create or replace function private.set_featured_group_impl (
  p_group_id      uuid,
  p_is_featured   boolean default true,
  p_starts_on     date default null,
  p_ends_on       date default null,
  p_display_order integer default 0
)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_group public.groups%rowtype;
  v_row   public.group_featured%rowtype;
begin
  select g.* into v_group
  from public.groups g
  where g.id = p_group_id;

  if not found then
    raise exception 'group not found' using errcode = 'P0002';
  end if;

  if v_group.archived_at is not null then
    raise exception 'an archived group cannot be featured' using errcode = 'P0001';
  end if;

  if v_group.group_type <> 'challenge' then
    raise exception 'only a challenge can be featured' using errcode = 'P0001';
  end if;

  if p_ends_on is not null and p_starts_on is not null and p_ends_on < p_starts_on then
    raise exception 'ends_on must not precede starts_on' using errcode = '22023';
  end if;

  insert into public.group_featured (group_id, is_featured, starts_on, ends_on, display_order)
  values (p_group_id, coalesce (p_is_featured, true), p_starts_on, p_ends_on, coalesce (p_display_order, 0))
  on conflict (group_id) do update
    set is_featured   = excluded.is_featured,
        starts_on     = excluded.starts_on,
        ends_on       = excluded.ends_on,
        display_order = excluded.display_order,
        updated_at    = now()
  returning * into v_row;

  return to_jsonb (v_row);
end;
$$;

comment on function private.set_featured_group_impl (uuid, boolean, date, date, integer) is
  'Publishes (or unpublishes) a Featured Seasonal Challenge. Only challenge groups may be featured.';

-- -----------------------------------------------------------------------------
-- public.set_featured_group()  — service_role only
-- -----------------------------------------------------------------------------
create or replace function public.set_featured_group (
  p_group_id      uuid,
  p_is_featured   boolean default true,
  p_starts_on     date default null,
  p_ends_on       date default null,
  p_display_order integer default 0
)
  returns jsonb
  language sql
  volatile
  security invoker
  set search_path = ''
as $$
  select private.set_featured_group_impl (p_group_id, p_is_featured, p_starts_on, p_ends_on, p_display_order);
$$;

comment on function public.set_featured_group (uuid, boolean, date, date, integer) is
  'Server side only (service_role). Publishes a Featured Seasonal Challenge in public.group_featured. A7 calls this from the promotions tooling.';

revoke execute on function public.set_featured_group (uuid, boolean, date, date, integer) from public, anon, authenticated;
grant  execute on function public.set_featured_group (uuid, boolean, date, date, integer) to service_role;

grant execute on function private.set_featured_group_impl (uuid, boolean, date, date, integer) to service_role;
