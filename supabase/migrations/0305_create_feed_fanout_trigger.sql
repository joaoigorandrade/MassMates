-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025652  ("create_feed_fanout_trigger")
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
-- A4 · 0305 · feed fan-out bridge to A5's public.feed_posts
-- =============================================================================
-- Owner: A4. A5 owns public.feed_posts; A4 owns public.check_in_destinations.
--
-- The trigger below lives on MY table, so there is NO ordering dependency: the
-- function is a no-op while public.feed_posts does not exist yet, and it starts
-- fanning out the moment A5's table lands.
--
-- A5 does NOT need to create any trigger. (The statement A5 would have used is
-- documented in SCHEMA.md for reference only.)
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- public.on_check_in_destination_fanout — trigger function
-- -----------------------------------------------------------------------------
-- GUARDS (ordering + privacy):
--   * new.check_in_id IS NULL            -> no-op
--   * public.feed_posts does not exist   -> no-op
--   * the source check-in is 'private'   -> no-op  (a private check-in NEVER
--                                             reaches a feed)
-- -----------------------------------------------------------------------------
create or replace function public.on_check_in_destination_fanout ()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_ci public.check_ins%rowtype;
begin
  if new.check_in_id is null then
    return new;
  end if;

  if to_regclass ('public.feed_posts') is null then
    return new;
  end if;

  select ci.* into v_ci
  from public.check_ins ci
  where ci.id = new.check_in_id;

  if not found then
    return new;
  end if;

  if v_ci.sharing <> 'group' then
    return new;
  end if;

  insert into public.feed_posts (
    check_in_id, group_id, user_id, practice_kind,
    reflection_text, photo_path, points, created_at
  )
  values (
    v_ci.id, new.group_id, v_ci.user_id, v_ci.practice_kind,
    v_ci.reflection_text, v_ci.photo_path, v_ci.points, v_ci.created_at
  );

  return new;
exception
  when undefined_table then
    -- public.feed_posts vanished between the guard and the INSERT.
    return new;
end;
$$;

comment on function public.on_check_in_destination_fanout () is
  'Trigger function on public.check_in_destinations: copies a GROUP-SHARED check-in into public.feed_posts. No-ops when the table does not exist yet and never fans out a private check-in. A5 does not need to create any trigger.';

drop trigger if exists trg_check_in_destinations_fanout on public.check_in_destinations;

create trigger trg_check_in_destinations_fanout
  after insert on public.check_in_destinations
  for each row execute function public.on_check_in_destination_fanout ();

comment on trigger trg_check_in_destinations_fanout on public.check_in_destinations is
  'Fan-out to A5''s public.feed_posts. Owned by A4 (the table is A4''s).';

-- The trigger is fired by public.submit_check_in() (security definer, runs as
-- postgres) or by service_role; nobody else may insert into
-- public.check_in_destinations.
revoke execute on function public.on_check_in_destination_fanout () from public, anon, authenticated;
grant  execute on function public.on_check_in_destination_fanout () to service_role;

-- -----------------------------------------------------------------------------
-- Harden the `private` schema: the implementation helpers are not reachable
-- from the client.
-- -----------------------------------------------------------------------------
revoke execute on function private.compute_streak_state (uuid) from public, anon, authenticated;
revoke execute on function private.recompute_streak (uuid) from public, anon, authenticated;
revoke execute on function private.compute_ring (uuid, date) from public, anon, authenticated;
revoke execute on function private.points_for_check_in (public.practice_kind, uuid) from public, anon, authenticated;

-- The delete trigger fires for the DELETING role (the user), so `authenticated`
-- needs EXECUTE on it; the body still runs as postgres (security definer).
revoke execute on function private.on_check_in_deleted () from public, anon;
grant  execute on function private.on_check_in_deleted () to authenticated, service_role;
