-- =============================================================================
-- A4 · 0306 · fix get_group_progress() CTE alias
-- =============================================================================
-- The final `from mem` needed an explicit alias (`from mem m`): the aggregate
-- in the select list refers to `m.user_id` / `m.display_name`.
-- The function is re-created in full (CREATE OR REPLACE) with the fix.
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
