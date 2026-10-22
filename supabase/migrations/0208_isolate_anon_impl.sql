-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025721  ("isolate_anon_impl")
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
-- A3 · 0208 · isolate the anon-facing implementation + close the PUBLIC grants
-- =============================================================================
-- The `private` schema is shared with A2 / A4 / A5 / A6. Several of their
-- functions still carry the DEFAULT ACL (EXECUTE granted to PUBLIC), so
-- granting `anon` USAGE on that schema would make every one of them callable
-- by an unauthenticated client — including SECURITY DEFINER helpers such as
-- private.recompute_streak() and private.on_check_in_deleted().
--
-- Fix: the two functions that must be reachable by `anon` move to a schema
-- that contains NOTHING but them, and `anon` loses USAGE on `private`.
--
-- Second fix: every A3 implementation in `private` must not keep the default
-- PUBLIC EXECUTE grant. Only the roles that are supposed to call them keep it.
-- -----------------------------------------------------------------------------

create schema if not exists a3_preview;

revoke all on schema a3_preview from public;

comment on schema a3_preview is
  'A3 implementation schema for the two PUBLIC (anon) preview RPCs. It contains nothing else on purpose: `anon` is granted USAGE here, so no other agent''s function can be reached through it.';

-- -----------------------------------------------------------------------------
-- move the two anon implementations
-- -----------------------------------------------------------------------------
create or replace function a3_preview.preview_group_by_code_impl (p_code text)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_code         text;
  v_group        public.groups%rowtype;
  v_member_count integer;
  v_is_featured  boolean;
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
    'id',                  v_group.id,
    'name',                v_group.name,
    'group_type',          v_group.group_type,
    'scoring_mode',        v_group.scoring_mode,
    'sharing_requirement', v_group.sharing_requirement,
    'cover_path',          v_group.cover_path,
    'member_count',        v_member_count,
    'is_featured',         v_is_featured,
    'starts_on',           v_group.starts_on,
    'ends_on',             v_group.ends_on,
    'goal_target',         v_group.goal_target,
    'description_preview', left (coalesce (v_group.description, ''), 160)
  );
end;
$$;

comment on function a3_preview.preview_group_by_code_impl (text) is
  'Public, safe preview of a group behind a 6-digit code. Never returns invite_code, created_by or the full description.';

create or replace function a3_preview.list_featured_challenges_impl ()
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

comment on function a3_preview.list_featured_challenges_impl () is
  'The public discovery showcase: the featured seasonal challenges with safe fields only.';

drop function if exists private.preview_group_by_code_impl (text);
drop function if exists private.list_featured_challenges_impl ();

-- -----------------------------------------------------------------------------
-- point the public wrappers at the new home
-- -----------------------------------------------------------------------------
create or replace function public.preview_group_by_code (p_code text)
  returns jsonb
  language sql
  stable
  security invoker
  set search_path = ''
as $$
  select a3_preview.preview_group_by_code_impl (p_code);
$$;

create or replace function public.list_featured_challenges ()
  returns jsonb
  language sql
  stable
  security invoker
  set search_path = ''
as $$
  select a3_preview.list_featured_challenges_impl ();
$$;

-- -----------------------------------------------------------------------------
-- grants
-- -----------------------------------------------------------------------------
revoke usage on schema private from anon;

grant usage on schema a3_preview to anon;

grant execute on function a3_preview.preview_group_by_code_impl (text) to anon;
grant execute on function a3_preview.list_featured_challenges_impl () to anon;

revoke execute on function a3_preview.preview_group_by_code_impl (text) from public;
revoke execute on function a3_preview.list_featured_challenges_impl () from public;

-- no A3 implementation keeps the default PUBLIC EXECUTE grant
revoke execute on function private.my_group_slots_impl () from public, anon;
revoke execute on function private.grant_slot_unlock_impl (uuid, text, text, integer, text) from public, anon, authenticated;
revoke execute on function private.set_featured_group_impl (uuid, boolean, date, date, integer) from public, anon, authenticated;

grant execute on function private.my_group_slots_impl () to authenticated;
grant execute on function private.grant_slot_unlock_impl (uuid, text, text, integer, text) to service_role;
grant execute on function private.set_featured_group_impl (uuid, boolean, date, date, integer) to service_role;
