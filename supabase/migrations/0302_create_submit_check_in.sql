-- =============================================================================
-- A4 · 0302 · check-in RPC + streak engine
-- =============================================================================
-- Owner: A4. The public RPC is the ONLY writer of check_ins /
-- check_in_destinations / streaks / streak_events. Implementation helpers live
-- in the non-exposed `private` schema.
--
-- ERROR MESSAGES are stable machine-readable keys (the iOS client maps them to
-- localized copy):
--   authentication required            28000
--   profile_not_found                  28000
--   invalid_sharing                    22023
--   confession_is_private_only         22023   <- the Confession Safeguard
--   private_check_in_cannot_hold_content 22023 <- the sacred-privacy invariant
--   reflection_text_too_long           22023
--   invalid_photo_path                 22023
--   invalid_timezone                   22023
--   local_date_in_future               22023
--   local_date_too_old                 22023
--   already_checked_in_today           23505
--   group_sharing_requires_destination 22023
--   not_a_group_member                 42501
--   blocked_by_group_creator           42501
--   group_archived                     22023
--   group_sharing_requirement_not_met  22023
--   no_streak_mercy_grant              22023
--   streak_mercy_already_used_this_month 23505
--   no_streak_to_repair                22023
--   repairs_date_not_missed            22023
--   repairs_date_not_adjacent_to_streak 22023
--   repairs_date_in_future             22023
--   repairs_date_too_old               22023
--   invalid_range                      22023
--   range_too_large                    22023
--   group_not_found                    22023
--   invalid_points                     22023
--   not_a_group_admin                  42501
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- private.compute_streak_state — the authoritative streak computation
-- -----------------------------------------------------------------------------
-- ACTIVE DAYS = { distinct local_date of the user's check_ins }
--            U { repairs_date of the user's consumed streak mercies }
-- CURRENT STREAK = the number of consecutive active days ending at the most
--                  recent active day (the "run" that ends at run_end).
-- LONGEST STREAK = the longest run anywhere in the active-day set.
-- The streak does NOT decay on its own: it is reset to 1 by the next check-in
-- that follows a gap (audited as a 'reset' event).
-- -----------------------------------------------------------------------------
create or replace function private.compute_streak_state (p_user_id uuid)
  returns jsonb
  language sql
  stable
  security definer
  set search_path = ''
as $$
  with days as (
    select distinct ci.local_date as d
    from public.check_ins ci
    where ci.user_id = p_user_id
    union
    select distinct u.repairs_date
    from public.streak_mercy_uses u
    where u.user_id = p_user_id
  ),
  islands as (
    select d, d - (row_number() over (order by d))::int as grp
    from days
  ),
  runs as (
    select grp, min(d) as run_start, max(d) as run_end, count(*)::int as len
    from islands
    group by grp
  ),
  tail as (
    select r.*
    from runs r
    where r.run_end = (select max(d) from days)
  )
  select jsonb_build_object(
    'current',         coalesce((select len from tail), 0),
    'longest_run',     coalesce((select max(len) from runs), 0),
    'run_start',       (select run_start from tail),
    'run_end',         (select run_end from tail),
    'active_days',     (select count(*)::int from days),
    'total_practices', (select count(*)::int from public.check_ins where user_id = p_user_id)
  );
$$;

comment on function private.compute_streak_state (uuid) is
  'Read-only streak computation. Active days = check_ins.local_date UNION streak_mercy_uses.repairs_date. current = consecutive run ending at the most recent active day; longest_run = longest run in the set.';

-- -----------------------------------------------------------------------------
-- private.recompute_streak — persist the computed state
-- -----------------------------------------------------------------------------
create or replace function private.recompute_streak (p_user_id uuid)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_state  jsonb;
  v_stored integer;
  v_longest integer;
begin
  v_state := private.compute_streak_state (p_user_id);

  select s.longest_streak into v_stored
  from public.streaks s
  where s.user_id = p_user_id;

  v_longest := greatest(coalesce(v_stored, 0), (v_state ->> 'longest_run')::int);

  insert into public.streaks (
    user_id, current_streak, longest_streak, last_practice_date, total_practices, updated_at
  )
  values (
    p_user_id,
    (v_state ->> 'current')::int,
    v_longest,
    (v_state ->> 'run_end')::date,
    (v_state ->> 'total_practices')::int,
    now()
  )
  on conflict (user_id) do update
    set current_streak     = excluded.current_streak,
        longest_streak     = excluded.longest_streak,
        last_practice_date = excluded.last_practice_date,
        total_practices    = excluded.total_practices,
        updated_at         = now();

  return jsonb_build_object(
    'current',            (v_state ->> 'current')::int,
    'longest',            v_longest,
    'last_practice_date', (v_state ->> 'run_end')::date,
    'total_practices',    (v_state ->> 'total_practices')::int,
    'run_start',          (v_state ->> 'run_start')::date,
    'run_end',            (v_state ->> 'run_end')::date
  );
end;
$$;

comment on function private.recompute_streak (uuid) is
  'Recomputes and persists public.streaks for a user from the authoritative active-day set. Called by submit_check_in, use_streak_mercy and the check-in delete trigger.';

-- -----------------------------------------------------------------------------
-- private.compute_ring — the Rule of Life Ring (independent from the Streak)
-- -----------------------------------------------------------------------------
-- total     = number of commitments in profiles.rule_of_life
-- completed = commitments whose `kind` was checked in on that local_date
-- percentage = completed * 100 / total  (0 when there is no commitment)
-- The Ring counts only the COMMITTED kinds; a private practice that is not in
-- the Rule of Life keeps the Streak alive but does not move the Ring.
-- -----------------------------------------------------------------------------
create or replace function private.compute_ring (p_user_id uuid, p_day date)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_rol       jsonb;
  v_kinds     text[];
  v_items     jsonb;
  v_total     integer;
  v_completed integer;
  v_pct       numeric(5, 2);
begin
  select p.rule_of_life into v_rol
  from public.profiles p
  where p.id = p_user_id;

  if v_rol is null or jsonb_typeof (v_rol) <> 'array' then
    v_rol := '[]'::jsonb;
  end if;

  select array_agg (distinct ci.practice_kind::text)
  into v_kinds
  from public.check_ins ci
  where ci.user_id = p_user_id
    and ci.local_date = p_day;

  v_kinds := coalesce (v_kinds, '{}'::text[]);

  with items as (
    select t.ord,
           coalesce (t.item ->> 'kind', '') as kind,
           coalesce (t.item ->> 'label', t.item ->> 'kind', '') as label
    from jsonb_array_elements (v_rol) with ordinality as t (item, ord)
  )
  select
    coalesce (
      jsonb_agg (
        jsonb_build_object ('kind', kind, 'label', label, 'done', kind = any (v_kinds))
        order by ord
      ),
      '[]'::jsonb
    ),
    count(*)::int,
    count(*) filter (where kind = any (v_kinds))::int
  into v_items, v_total, v_completed
  from items;

  v_pct := case
    when v_total = 0 then 0::numeric
    else round (v_completed * 100.0 / v_total, 2)
  end;

  return jsonb_build_object(
    'completed', v_completed,
    'total',     v_total,
    'percentage', v_pct,
    'items',     v_items
  );
end;
$$;

comment on function private.compute_ring (uuid, date) is
  'Rule of Life Ring for one local day: completed/total/percentage/items, computed from profiles.rule_of_life and the DISTINCT practice kinds checked in that day.';

-- -----------------------------------------------------------------------------
-- private.points_for_check_in — scoring per group
-- -----------------------------------------------------------------------------
-- faithful_days      -> 1 point per active day (1 per check-in)
-- collective_treasure-> the group's practice_points row, else the global row,
--                      else 1 unit (each check-in pours one unit into the goal)
-- custom_points      -> the group's practice_points row, else the global row,
--                      else 0
-- -----------------------------------------------------------------------------
create or replace function private.points_for_check_in (
  p_practice  public.practice_kind,
  p_group_id  uuid
)
  returns integer
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select case gr.scoring_mode
    when 'faithful_days'::public.scoring_mode then 1
    when 'collective_treasure'::public.scoring_mode then coalesce (pp.points, gpp.points, 1)
    else coalesce (pp.points, gpp.points, 0)
  end
  from public.groups gr
  left join lateral (
    select p.points
    from public.practice_points p
    where p.group_id = gr.id and p.practice_kind = p_practice
    limit 1
  ) pp on true
  left join lateral (
    select p.points
    from public.practice_points p
    where p.group_id is null and p.practice_kind = p_practice
    limit 1
  ) gpp on true
  where gr.id = p_group_id;
$$;

comment on function private.points_for_check_in (public.practice_kind, uuid) is
  'Points a check-in is worth in one group, per the group scoring mode. The check-in row stores the MAX across its destination groups; per-group contribution is recomputed by public.get_group_progress().';

-- -----------------------------------------------------------------------------
-- private.on_check_in_deleted — keep the streak consistent on DELETE
-- -----------------------------------------------------------------------------
create or replace function private.on_check_in_deleted ()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $$
begin
  perform private.recompute_streak (old.user_id);
  return old;
end;
$$;

drop trigger if exists trg_check_ins_after_delete on public.check_ins;
create trigger trg_check_ins_after_delete
  after delete on public.check_ins
  for each row execute function private.on_check_in_deleted ();

-- -----------------------------------------------------------------------------
-- public.submit_check_in — THE check-in engine
-- -----------------------------------------------------------------------------
create or replace function public.submit_check_in (
  p_practice   public.practice_kind,
  p_sharing    text,
  p_group_ids  uuid[] default '{}'::uuid[],
  p_reflection text     default null,
  p_photo_path text     default null,
  p_local_date date     default null,
  p_timezone   text     default null
)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid         uuid := public.current_user_id ();
  v_profile_tz  text;
  v_sharing     text;
  v_tz          text;
  v_today       date;
  v_local_date  date;
  v_reflection  text;
  v_photo       text;
  v_group_ids   uuid[];
  v_dest        uuid[] := '{}'::uuid[];
  v_points      integer := 0;
  v_check_in_id uuid;
  v_state       jsonb;
  v_ring        jsonb;
  v_prev_streak integer := 0;
  v_prev_last   date;
  v_new_streak  integer := 0;
  g             uuid;
  v_req         public.sharing_requirement;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select p.timezone into v_profile_tz
  from public.profiles p
  where p.id = v_uid;

  if not found then
    raise exception 'profile_not_found' using errcode = '28000';
  end if;

  -- (1) sharing is either private or group ---------------------------------
  if p_sharing is null or p_sharing not in ('private', 'group') then
    raise exception 'invalid_sharing' using errcode = '22023';
  end if;
  v_sharing := p_sharing;

  -- (2) CONFESSION SAFEGUARD: a confession check-in is private-only ----------
  if p_practice = 'confession' then
    if v_sharing <> 'private' then
      raise exception 'confession_is_private_only' using errcode = '22023';
    end if;
    v_sharing := 'private';
  end if;

  -- (3) content normalisation + the sacred-privacy invariant ---------------
  v_reflection := nullif (btrim (coalesce (p_reflection, '')), '');
  v_photo      := nullif (btrim (coalesce (p_photo_path, '')), '');

  if v_sharing = 'private' then
    if v_reflection is not null or v_photo is not null then
      raise exception 'private_check_in_cannot_hold_content' using errcode = '22023';
    end if;
  else
    if v_reflection is not null and char_length (v_reflection) > 2000 then
      raise exception 'reflection_text_too_long' using errcode = '22023';
    end if;
    if v_photo is not null and v_photo not like 'witness-photos/%' then
      raise exception 'invalid_photo_path' using errcode = '22023';
    end if;
  end if;

  -- (4) timezone-aware day boundary ----------------------------------------
  v_tz := coalesce (nullif (btrim (coalesce (p_timezone, '')), ''), v_profile_tz);

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = v_tz) then
    raise exception 'invalid_timezone' using errcode = '22023';
  end if;

  v_today := (now() at time zone v_tz)::date;
  v_local_date := coalesce (p_local_date, v_today);

  if v_local_date > v_today + 1 then
    raise exception 'local_date_in_future' using errcode = '22023';
  end if;

  if v_local_date < v_today - 365 then
    raise exception 'local_date_too_old' using errcode = '22023';
  end if;

  -- (5) one check-in per practice per local day ----------------------------
  if exists (
    select 1 from public.check_ins ci
    where ci.user_id = v_uid
      and ci.practice_kind = p_practice
      and ci.local_date = v_local_date
  ) then
    raise exception 'already_checked_in_today' using errcode = '23505';
  end if;

  -- (6) destinations: membership + per-group sharing requirement ------------
  v_group_ids := coalesce (p_group_ids, '{}'::uuid[]);

  if v_sharing = 'group' then
    if cardinality (v_group_ids) = 0 then
      raise exception 'group_sharing_requires_destination' using errcode = '22023';
    end if;

    for g in select distinct x from unnest (v_group_ids) x where x is not null loop
      if not public.is_group_member (g, v_uid) then
        raise exception 'not_a_group_member' using errcode = '42501';
      end if;

      if exists (
        select 1 from public.groups gr
        where gr.id = g and gr.archived_at is not null
      ) then
        raise exception 'group_archived' using errcode = '22023';
      end if;

      if exists (
        select 1 from public.groups gr
        where gr.id = g
          and gr.created_by is not null
          and public.is_blocked (v_uid, gr.created_by)
      ) then
        raise exception 'blocked_by_group_creator' using errcode = '42501';
      end if;
    end loop;

    for g in select distinct x from unnest (v_group_ids) x where x is not null loop
      select gr.sharing_requirement into v_req
      from public.groups gr
      where gr.id = g;

      if v_req = 'written_fruit' and v_reflection is null then
        continue;
      end if;

      if v_req = 'photo_witness' and v_photo is null then
        continue;
      end if;

      v_dest := array_append (v_dest, g);
    end loop;

    if cardinality (v_dest) = 0 then
      raise exception 'group_sharing_requirement_not_met' using errcode = '22023';
    end if;
  end if;

  -- (7) scoring: the MAX across the destination groups ----------------------
  if cardinality (v_dest) > 0 then
    select coalesce (max (private.points_for_check_in (p_practice, x)), 0)
    into v_points
    from unnest (v_dest) x;
  end if;

  -- (8) the check-in row ----------------------------------------------------
  insert into public.check_ins (
    user_id, practice_kind, sharing, local_date, timezone,
    reflection_text, photo_path, points
  )
  values (
    v_uid, p_practice, v_sharing, v_local_date, v_tz,
    v_reflection, v_photo, v_points
  )
  returning id into v_check_in_id;

  -- (9) the fan-out: ONE destination row per group. A private check-in
  --     creates ZERO destination rows — that is the privacy boundary.
  if v_sharing = 'group' then
    insert into public.check_in_destinations (check_in_id, group_id)
    select v_check_in_id, x from unnest (v_dest) x;
  end if;

  -- (10) the streak ---------------------------------------------------------
  select s.current_streak, s.last_practice_date into v_prev_streak, v_prev_last
  from public.streaks s
  where s.user_id = v_uid;

  v_prev_streak := coalesce (v_prev_streak, 0);

  v_state := private.recompute_streak (v_uid);
  v_new_streak := (v_state ->> 'current')::int;

  if v_prev_last is not null and v_local_date > v_prev_last + 1 then
    insert into public.streak_events (user_id, event_type, local_date, streak_after)
    values (v_uid, 'reset', v_local_date, v_new_streak);
  end if;

  insert into public.streak_events (user_id, event_type, local_date, streak_after)
  values (v_uid, 'practice', v_local_date, v_new_streak);

  if v_new_streak > v_prev_streak and v_new_streak % 7 = 0 then
    insert into public.streak_events (user_id, event_type, local_date, streak_after)
    values (v_uid, 'milestone', v_local_date, v_new_streak);
  end if;

  -- (11) the Rule of Life Ring (independent from the streak) ----------------
  v_ring := private.compute_ring (v_uid, v_local_date);

  return jsonb_build_object(
    'check_in_id', v_check_in_id,
    'streak', jsonb_build_object(
      'current',             v_new_streak,
      'longest',             (v_state ->> 'longest')::int,
      'last_practice_date',  v_state -> 'last_practice_date'
    ),
    'ring', v_ring,
    'destinations', to_jsonb (v_dest)
  );
end;
$$;

comment on function public.submit_check_in (public.practice_kind, text, uuid[], text, text, date, text) is
  'THE check-in engine. Validates sharing, the Confession Safeguard (confession => private only), the sacred-privacy invariant (a private check-in NEVER carries content), timezone-aware local_date, one check-in per practice per day, group membership and the per-group sharing_requirement; then writes the check-in, its destination fan-out, the streak and the streak events in ONE transaction. Returns { check_in_id, streak, ring, destinations }.';

revoke execute on function public.submit_check_in (public.practice_kind, text, uuid[], text, text, date, text) from public, anon;
grant execute on function public.submit_check_in (public.practice_kind, text, uuid[], text, text, date, text) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- public.set_practice_points — A4 owns the DATA of A1's practice_points
-- -----------------------------------------------------------------------------
create or replace function public.set_practice_points (
  p_group_id   uuid,
  p_practice   public.practice_kind,
  p_points     integer
)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := public.current_user_id ();
  v_id  uuid;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  if p_practice is null or p_points is null or p_points < 0 then
    raise exception 'invalid_points' using errcode = '22023';
  end if;

  if p_group_id is null then
    if not public.is_any_group_admin (v_uid) then
      raise exception 'not_a_group_admin' using errcode = '42501';
    end if;
  elsif not public.is_group_admin (p_group_id, v_uid) then
    raise exception 'not_a_group_admin' using errcode = '42501';
  end if;

  insert into public.practice_points (group_id, practice_kind, points)
  values (p_group_id, p_practice, p_points)
  on conflict on constraint practice_points_group_kind_unique
  do update set points = excluded.points, updated_at = now()
  returning id into v_id;

  return jsonb_build_object(
    'id', v_id,
    'group_id', p_group_id,
    'practice_kind', p_practice,
    'points', p_points
  );
end;
$$;

comment on function public.set_practice_points (uuid, public.practice_kind, integer) is
  'Sets the point value of a practice for a group (or the global default when p_group_id IS NULL). A4 owns the DATA of public.practice_points; A1 owns the table. Group admins may set their own values.';

revoke execute on function public.set_practice_points (uuid, public.practice_kind, integer) from public, anon;
grant execute on function public.set_practice_points (uuid, public.practice_kind, integer) to authenticated, service_role;
