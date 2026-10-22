-- =============================================================================
-- A4 · 0304 · Streak Mercy
-- =============================================================================
-- Owner: A4. A mercy repairs EXACTLY ONE missed day and may be used at most
-- ONCE per calendar month.
--
-- CONTRACT WITH A7 (rewards):
--   A7 INSERTS a row into public.streak_mercy_grants (or calls
--   public.grant_streak_mercy() with a service_role JWT). The user then calls
--   public.use_streak_mercy(p_repairs_date) to consume it.
--
-- The repair is applied to the AUTHORITATIVE ACTIVE-DAY SET:
--   active days = { check_ins.local_date } UNION { streak_mercy_uses.repairs_date }
-- so the streak is recomputed by private.recompute_streak() exactly like any
-- other mutation. The repaired day must be adjacent to the current streak
-- (the day before the streak's first day, or the day after its last day) so
-- the current streak grows by EXACTLY 1.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- public.use_streak_mercy
-- -----------------------------------------------------------------------------
create or replace function public.use_streak_mercy (p_repairs_date date)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid         uuid := public.current_user_id ();
  v_tz          text;
  v_today       date;
  v_state       jsonb;
  v_run_start   date;
  v_run_end     date;
  v_used_month  integer;
  v_grant_id    uuid;
  v_new_streak  integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  if p_repairs_date is null then
    raise exception 'repairs_date_required' using errcode = '22023';
  end if;

  select p.timezone into v_tz
  from public.profiles p
  where p.id = v_uid;

  v_tz := coalesce (v_tz, 'UTC');
  v_today := (now() at time zone v_tz)::date;

  if p_repairs_date > v_today then
    raise exception 'repairs_date_in_future' using errcode = '22023';
  end if;

  if p_repairs_date < v_today - 365 then
    raise exception 'repairs_date_too_old' using errcode = '22023';
  end if;

  -- (1) an unexpired, unused grant must exist -------------------------------
  select g.id into v_grant_id
  from public.streak_mercy_grants g
  where g.user_id = v_uid
    and g.used_at is null
    and (g.expires_at is null or g.expires_at > now())
  order by g.granted_at
  limit 1;

  if v_grant_id is null then
    raise exception 'no_streak_mercy_grant' using errcode = '22023';
  end if;

  -- (2) at most one mercy per calendar month --------------------------------
  select count(*)::int into v_used_month
  from public.streak_mercy_uses u
  where u.user_id = v_uid
    and date_trunc ('month', u.used_on) = date_trunc ('month', v_today);

  if v_used_month > 0 then
    raise exception 'streak_mercy_already_used_this_month' using errcode = '23505';
  end if;

  -- (3) the repaired day must be a MISSED day adjacent to the current streak -
  v_state := private.compute_streak_state (v_uid);
  v_run_start := (v_state ->> 'run_start')::date;
  v_run_end := (v_state ->> 'run_end')::date;

  if v_run_end is null then
    raise exception 'no_streak_to_repair' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.check_ins ci
    where ci.user_id = v_uid and ci.local_date = p_repairs_date
  ) or exists (
    select 1 from public.streak_mercy_uses u
    where u.user_id = v_uid and u.repairs_date = p_repairs_date
  ) then
    raise exception 'repairs_date_not_missed' using errcode = '22023';
  end if;

  if p_repairs_date <> v_run_start - 1 and p_repairs_date <> v_run_end + 1 then
    raise exception 'repairs_date_not_adjacent_to_streak' using errcode = '22023';
  end if;

  -- (4) apply ---------------------------------------------------------------
  insert into public.streak_mercy_uses (user_id, used_on, repairs_date)
  values (v_uid, v_today, p_repairs_date);

  update public.streak_mercy_grants g
  set used_at = now()
  where g.id = v_grant_id;

  v_state := private.recompute_streak (v_uid);
  v_new_streak := (v_state ->> 'current')::int;

  insert into public.streak_events (user_id, event_type, local_date, streak_after)
  values (v_uid, 'mercy', p_repairs_date, v_new_streak);

  return jsonb_build_object(
    'applied',             true,
    'repairs_date',        p_repairs_date,
    'current_streak',      v_new_streak,
    'longest_streak',      (v_state ->> 'longest')::int,
    'last_practice_date',  v_state -> 'last_practice_date',
    'mercy_used_this_month', v_used_month + 1
  );
end;
$$;

comment on function public.use_streak_mercy (date) is
  'Consumes one Streak Mercy to repair EXACTLY ONE missed day. Requires an unexpired, unused public.streak_mercy_grants row and no mercy used in the current calendar month. The repaired day must be adjacent to the current streak. Returns { applied, repairs_date, current_streak, longest_streak, last_practice_date, mercy_used_this_month }.';

revoke execute on function public.use_streak_mercy (date) from public, anon;
grant execute on function public.use_streak_mercy (date) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- public.grant_streak_mercy — A7's entry point (service_role only)
-- -----------------------------------------------------------------------------
create or replace function public.grant_streak_mercy (
  p_user_id    uuid,
  p_expires_at timestamptz default null
)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_id uuid;
begin
  if coalesce (auth.role (), current_setting ('role', true), '') <> 'service_role' then
    raise exception 'service_role_required' using errcode = '42501';
  end if;

  if p_user_id is null then
    raise exception 'user_required' using errcode = '22023';
  end if;

  insert into public.streak_mercy_grants (user_id, expires_at)
  values (p_user_id, coalesce (p_expires_at, now() + interval '30 days'))
  returning id into v_id;

  return jsonb_build_object (
    'id', v_id,
    'user_id', p_user_id,
    'granted_at', now(),
    'expires_at', coalesce (p_expires_at, now() + interval '30 days')
  );
end;
$$;

comment on function public.grant_streak_mercy (uuid, timestamptz) is
  'Grants one Streak Mercy to a user. service_role ONLY (A7 calls it from the rewarded-video Edge Function). A user must never be able to grant mercy to themselves.';

revoke execute on function public.grant_streak_mercy (uuid, timestamptz) from public, anon, authenticated;
grant execute on function public.grant_streak_mercy (uuid, timestamptz) to service_role;
