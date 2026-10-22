-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025502  ("create_streak_and_ring_rpcs")
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
-- A4 · 0303 · streak / ring / heatmap / group-progress RPCs
-- =============================================================================
-- Owner: A4. All read-only, all `security definer set search_path = ''`.
--
-- The Daily Streak and the Rule of Life Ring are SEPARATE computations:
--   * STREAK  = >= 1 practice per day (public OR private) keeps it alive.
--   * RING    = the percentage of the user's `profiles.rule_of_life`
--               commitments completed on a given day.
-- A private check-in increments the Streak but only moves the Ring when the
-- practice is one of the user's committed kinds.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- public.get_rule_of_life_ring
-- -----------------------------------------------------------------------------
create or replace function public.get_rule_of_life_ring (p_local_date date default null)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_uid   uuid := public.current_user_id ();
  v_tz    text;
  v_day   date;
  v_ring  jsonb;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select p.timezone into v_tz
  from public.profiles p
  where p.id = v_uid;

  v_tz := coalesce (v_tz, 'UTC');
  v_day := coalesce (p_local_date, (now() at time zone v_tz)::date);

  v_ring := private.compute_ring (v_uid, v_day);

  return v_ring || jsonb_build_object ('local_date', v_day);
end;
$$;

comment on function public.get_rule_of_life_ring (date) is
  'Rule of Life Ring for a local day: { completed, total, percentage, items[], local_date }. total comes from profiles.rule_of_life; completed counts the DISTINCT practice kinds checked in that day. Independent from the Daily Streak.';

revoke execute on function public.get_rule_of_life_ring (date) from public, anon;
grant execute on function public.get_rule_of_life_ring (date) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- public.get_streak_summary
-- -----------------------------------------------------------------------------
create or replace function public.get_streak_summary ()
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_uid        uuid := public.current_user_id ();
  v_tz         text;
  v_today      date;
  v_state      jsonb;
  v_used_month integer;
  v_granted    boolean;
  v_longest    integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select p.timezone into v_tz
  from public.profiles p
  where p.id = v_uid;

  v_tz := coalesce (v_tz, 'UTC');
  v_today := (now() at time zone v_tz)::date;

  v_state := private.compute_streak_state (v_uid);

  select greatest (
    (v_state ->> 'longest_run')::int,
    coalesce ((select s.longest_streak from public.streaks s where s.user_id = v_uid), 0)
  ) into v_longest;

  select count(*)::int into v_used_month
  from public.streak_mercy_uses u
  where u.user_id = v_uid
    and date_trunc ('month', u.used_on) = date_trunc ('month', v_today);

  select exists (
    select 1
    from public.streak_mercy_grants g
    where g.user_id = v_uid
      and g.used_at is null
      and (g.expires_at is null or g.expires_at > now())
  ) into v_granted;

  return jsonb_build_object(
    'current_streak',       (v_state ->> 'current')::int,
    'longest_streak',       v_longest,
    'last_practice_date',   v_state -> 'run_end',
    'total_practices',      (v_state ->> 'total_practices')::int,
    'mercy_available',      v_granted and v_used_month = 0,
    'mercy_used_this_month', v_used_month
  );
end;
$$;

comment on function public.get_streak_summary () is
  'Daily Streak summary: { current_streak, longest_streak, last_practice_date, total_practices, mercy_available, mercy_used_this_month }.';

revoke execute on function public.get_streak_summary () from public, anon;
grant execute on function public.get_streak_summary () to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- public.get_consistency_heatmap
-- -----------------------------------------------------------------------------
create or replace function public.get_consistency_heatmap (p_from date, p_to date)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := public.current_user_id ();
  v_map jsonb;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  if p_from is null or p_to is null or p_to < p_from then
    raise exception 'invalid_range' using errcode = '22023';
  end if;

  if (p_to - p_from) > 366 then
    raise exception 'range_too_large' using errcode = '22023';
  end if;

  select coalesce (jsonb_object_agg (s.d::text, s.c), '{}'::jsonb)
  into v_map
  from (
    select ci.local_date as d, count(*)::int as c
    from public.check_ins ci
    where ci.user_id = v_uid
      and ci.local_date between p_from and p_to
    group by ci.local_date
  ) s;

  return v_map;
end;
$$;

comment on function public.get_consistency_heatmap (date, date) is
  'Profile heatmap: a jsonb map { ''YYYY-MM-DD'': practice_count } over the requested range (own check-ins only, max 366 days).';

revoke execute on function public.get_consistency_heatmap (date, date) from public, anon;
grant execute on function public.get_consistency_heatmap (date, date) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- public.get_group_progress
-- -----------------------------------------------------------------------------
-- Collective Goal Bar + member consistency view.
--   goal_current  = distinct member-days (faithful_days) | sum of points
--   goal_target   = groups.goal_target
--   active_today_count = members with a group check-in today
--   per_member    = [{ user_id, display_name, points, days_active }]
-- Blocked members are excluded from every aggregate.
-- -----------------------------------------------------------------------------
create or replace function public.get_group_progress (p_group_id uuid)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_uid         uuid := public.current_user_id ();
  v_mode        public.scoring_mode;
  v_target      integer;
  v_tz          text;
  v_today       date;
  v_members     integer;
  v_active      integer;
  v_current     numeric;
  v_pct         numeric(5, 2);
  v_per_member  jsonb;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  if p_group_id is null then
    raise exception 'group_not_found' using errcode = '22023';
  end if;

  if not public.is_group_member (p_group_id, v_uid) then
    raise exception 'not_a_group_member' using errcode = '42501';
  end if;

  select g.scoring_mode, g.goal_target into v_mode, v_target
  from public.groups g
  where g.id = p_group_id;

  select p.timezone into v_tz
  from public.profiles p
  where p.id = v_uid;

  v_tz := coalesce (v_tz, 'UTC');
  v_today := (now() at time zone v_tz)::date;

  select count(*)::int into v_members
  from public.group_members gm
  where gm.group_id = p_group_id;

  with acts as (
    select ci.user_id, ci.local_date, ci.points
    from public.check_in_destinations d
    join public.check_ins ci on ci.id = d.check_in_id
    where d.group_id = p_group_id
      and (ci.user_id = v_uid or not public.is_blocked (v_uid, ci.user_id))
  ),
  mem as (
    select gm.user_id, coalesce (pr.display_name, '') as display_name
    from public.group_members gm
    left join public.profiles pr on pr.id = gm.user_id
    where gm.group_id = p_group_id
      and (gm.user_id = v_uid or not public.is_blocked (v_uid, gm.user_id))
  )
  select
    coalesce (
      jsonb_agg (
        jsonb_build_object (
          'user_id',     m.user_id,
          'display_name', m.display_name,
          'points',      case
                           when v_mode = 'faithful_days'::public.scoring_mode
                             then (select count (distinct a.local_date) from acts a where a.user_id = m.user_id)
                           else (select coalesce (sum (a.points), 0) from acts a where a.user_id = m.user_id)
                         end,
          'days_active', (select count (distinct a.local_date) from acts a where a.user_id = m.user_id)
        )
        order by m.display_name
      ),
      '[]'::jsonb
    ),
    (select count (distinct a.user_id) from acts a where a.local_date = v_today),
    case
      when v_mode = 'faithful_days'::public.scoring_mode
        then (select count (*) from (select distinct a.user_id, a.local_date from acts a) x)
      else (select coalesce (sum (a.points), 0) from acts a)
    end
  into v_per_member, v_active, v_current
  from mem m;

  v_pct := case
    when v_target is null or v_target <= 0 then 0::numeric
    else round (v_current * 100.0 / v_target, 2)
  end;

  return jsonb_build_object(
    'group_id',          p_group_id,
    'goal_current',      v_current,
    'goal_target',       v_target,
    'percentage',        v_pct,
    'active_today_count', v_active,
    'member_count',      v_members,
    'scoring_mode',      v_mode,
    'per_member',        v_per_member
  );
end;
$$;

comment on function public.get_group_progress (uuid) is
  'Group Progress tab: { group_id, goal_current, goal_target, percentage, active_today_count, member_count, scoring_mode, per_member[{user_id, display_name, points, days_active}] }. Members only; blocked members are excluded.';

revoke execute on function public.get_group_progress (uuid) from public, anon;
grant execute on function public.get_group_progress (uuid) to authenticated, service_role;
