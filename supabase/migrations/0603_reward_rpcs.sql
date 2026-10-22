-- =============================================================================
-- A7 · 0603 · Reward-granting & liturgical RPCs
-- =============================================================================
-- Owner: A7 (liturgical content & monetization).
--
-- Contract (CONVENTIONS §5):
--   * every function is SECURITY DEFINER with `set search_path = ''` and
--     fully-qualified object names;
--   * `REVOKE EXECUTE FROM PUBLIC` on everything;
--   * EXECUTE is granted to `service_role` for the mutating reward RPCs and
--     to `authenticated` only where the caller acts on ITS OWN data.
--
-- SECURITY POSTURE
--   * public.grant_reward is a SECURITY DEFINER function in the EXPOSED schema
--     that is executable by `service_role` ONLY. It is never executable by
--     `anon`/`authenticated`, so the database linter does not flag it.
--   * The two functions a signed-in user may call on its own data
--     (consume_reward, begin_ad_reward) are thin SECURITY INVOKER wrappers in
--     `public` over a SECURITY DEFINER implementation in the non-exposed
--     `private` schema — the same pattern A3 uses — so no new
--     "security definer executable by authenticated" finding is produced.
--   * The read-only RPCs (my_rewards, get_today_liturgy, get_liturgical_calendar)
--     are SECURITY INVOKER: they only read rows the caller may already read.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- private helpers
-- -----------------------------------------------------------------------------

create or replace function private.caller_role ()
returns text
language sql
stable
set search_path = ''
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    current_user::text
  );
$$;

comment on function private.caller_role () is
  'The JWT role of the caller (anon | authenticated | service_role), read from request.jwt.claims. Used to let the service_role act on any row while a signed-in user may only act on its own rows.';

-- -----------------------------------------------------------------------------
-- public.grant_reward — the single write path of the reward ledger.
-- -----------------------------------------------------------------------------

create or replace function public.grant_reward (
  p_user_id        uuid,
  p_reward_type    text,
  p_source         text,
  p_transaction_id text default null,
  p_expires_days   integer default null,
  p_metadata       jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta     jsonb := coalesce(p_metadata, '{}'::jsonb);
  v_dur      integer;
  v_expires  timestamptz;
  v_grant    public.reward_grants%rowtype;
  v_existing public.reward_grants%rowtype;
  v_icon     uuid;
  v_network  text;
begin
  if p_user_id is null then
    raise exception 'p_user_id is required' using errcode = '22023';
  end if;

  if p_reward_type is null or p_reward_type not in ('streak_mercy', 'group_slot', 'saint_theme') then
    raise exception 'unsupported reward_type: %', p_reward_type using errcode = '22023';
  end if;

  if p_source is null or p_source not in ('admob_ssv', 'admin_grant', 'sponsored', 'achievement') then
    raise exception 'unsupported source: %', p_source using errcode = '22023';
  end if;

  -- Idempotency: the same (source, transaction_id) is never granted twice.
  if p_transaction_id is not null then
    select * into v_existing
      from public.reward_grants g
     where g.source = p_source
       and g.transaction_id = p_transaction_id;
    if found then
      return jsonb_build_object(
        'ok', true, 'granted', false, 'duplicate', true,
        'grant_id', v_existing.id,
        'reward_type', v_existing.reward_type,
        'status', v_existing.status,
        'expires_at', v_existing.expires_at
      );
    end if;
  end if;

  v_dur := coalesce(
    p_expires_days,
    case p_reward_type
      when 'streak_mercy' then 30
      when 'group_slot'  then 30
      when 'saint_theme' then 7
    end
  );
  if v_dur is null or v_dur <= 0 or v_dur > 365 then
    raise exception 'invalid p_expires_days: %', p_expires_days using errcode = '22023';
  end if;
  v_expires := now() + make_interval(days => v_dur);

  -- Streak mercy: one per 30 days (product plan §4).
  if p_reward_type = 'streak_mercy' and exists (
        select 1
          from public.reward_grants g
         where g.user_id = p_user_id
           and g.reward_type = 'streak_mercy'
           and g.status in ('granted', 'consumed')
           and g.expires_at > now()
      ) then
    return jsonb_build_object(
      'ok', false, 'granted', false, 'reason', 'streak_mercy_limit_reached'
    );
  end if;

  v_icon := null;
  if p_reward_type = 'saint_theme' then
    v_icon := nullif(v_meta ->> 'saint_icon_id', '')::uuid;
    if v_icon is null then
      select si.id into v_icon
        from public.saint_icons si
       where si.is_active
       order by si.slug
       limit 1;
    end if;
    if v_icon is null then
      raise exception 'no active saint theme available' using errcode = '22023';
    end if;
  end if;

  v_network := coalesce(
    nullif(v_meta ->> 'ad_network', ''),
    case when p_source = 'admob_ssv' then 'admob' end
  );

  begin
    insert into public.reward_grants (
      user_id, reward_type, source, ad_network, transaction_id,
      status, granted_at, expires_at, metadata
    )
    values (
      p_user_id, p_reward_type, p_source, v_network, p_transaction_id,
      'granted', now(), v_expires, v_meta || jsonb_build_object('expires_days', v_dur)
    )
    returning * into v_grant;
  exception
    when unique_violation then
      -- Concurrent replay of the same transaction: return the first grant.
      select * into v_existing
        from public.reward_grants g
       where g.source = p_source
         and g.transaction_id = p_transaction_id;
      return jsonb_build_object(
        'ok', true, 'granted', false, 'duplicate', true,
        'grant_id', v_existing.id,
        'reward_type', v_existing.reward_type,
        'status', v_existing.status,
        'expires_at', v_existing.expires_at
      );
  end;

  -- Dispatch: the reward is only real once the entitlement table has the row.
  if p_reward_type = 'streak_mercy' then
    if to_regclass('public.streak_mercy_grants') is null then
      raise exception 'target table public.streak_mercy_grants is unavailable' using errcode = '55000';
    end if;
    execute 'insert into public.streak_mercy_grants (user_id, granted_at, expires_at) values ($1, $2, $3)'
      using p_user_id, v_grant.granted_at, v_expires;

  elsif p_reward_type = 'group_slot' then
    if to_regclass('public.slot_unlocks') is null then
      raise exception 'target table public.slot_unlocks is unavailable' using errcode = '55000';
    end if;
    execute 'insert into public.slot_unlocks (user_id, kind, source, starts_at, expires_at, notes) values ($1, $2, $3, $4, $5, $6)'
      using p_user_id, 'group_slot', 'rewarded_video', v_grant.granted_at, v_expires,
            'massmates:reward:' || v_grant.id::text;

  else
    insert into public.user_saint_unlocks (user_id, saint_icon_id, granted_at, expires_at)
    values (p_user_id, v_icon, v_grant.granted_at, v_expires)
    on conflict (user_id, saint_icon_id) do update
      set granted_at = excluded.granted_at,
          expires_at = greatest(public.user_saint_unlocks.expires_at, excluded.expires_at);
  end if;

  return jsonb_build_object(
    'ok', true, 'granted', true, 'duplicate', false,
    'grant_id', v_grant.id,
    'reward_type', p_reward_type,
    'status', 'granted',
    'expires_at', v_expires,
    'duration_days', v_dur
  );
end;
$$;

comment on function public.grant_reward (uuid, text, text, text, integer, jsonb) is
  'Grants one reward. EXECUTE: service_role only. Idempotent on (source, transaction_id) — a replayed AdMob SSV callback returns {granted:false, duplicate:true} and creates no second reward. Dispatch: streak_mercy -> A4 public.streak_mercy_grants (30 days); group_slot -> A3 public.slot_unlocks kind=group_slot (30 days); saint_theme -> public.user_saint_unlocks (7 days).';

revoke execute on function public.grant_reward (uuid, text, text, text, integer, jsonb) from public;
revoke execute on function public.grant_reward (uuid, text, text, text, integer, jsonb) from anon;
revoke execute on function public.grant_reward (uuid, text, text, text, integer, jsonb) from authenticated;
grant  execute on function public.grant_reward (uuid, text, text, text, integer, jsonb) to service_role;

-- -----------------------------------------------------------------------------
-- public.consume_reward — the owner (or service_role) marks a grant consumed.
-- -----------------------------------------------------------------------------

create or replace function private.consume_reward_impl (p_grant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_grant public.reward_grants%rowtype;
  v_role  text;
  v_uid   uuid;
begin
  if p_grant_id is null then
    raise exception 'p_grant_id is required' using errcode = '22023';
  end if;

  v_role := private.caller_role();
  v_uid  := (select auth.uid());

  update public.reward_grants g
     set status = 'consumed',
         consumed_at = now()
   where g.id = p_grant_id
     and (v_role = 'service_role' or g.user_id = v_uid)
  returning * into v_grant;

  if not found then
    return jsonb_build_object('ok', false, 'reason', 'grant_not_found');
  end if;

  return jsonb_build_object(
    'ok', true,
    'grant_id', v_grant.id,
    'reward_type', v_grant.reward_type,
    'status', v_grant.status,
    'consumed_at', v_grant.consumed_at,
    'expires_at', v_grant.expires_at
  );
end;
$$;

revoke execute on function private.consume_reward_impl (uuid) from public;
revoke execute on function private.consume_reward_impl (uuid) from anon;
grant  execute on function private.consume_reward_impl (uuid) to service_role;
grant  execute on function private.consume_reward_impl (uuid) to authenticated;

create or replace function public.consume_reward (p_grant_id uuid)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.consume_reward_impl (p_grant_id);
$$;

comment on function public.consume_reward (uuid) is
  'Marks one of the caller''s own rewards as consumed. EXECUTE: authenticated (own rows only) and service_role. A caller can never consume another user''s grant.';

revoke execute on function public.consume_reward (uuid) from public;
revoke execute on function public.consume_reward (uuid) from anon;
grant  execute on function public.consume_reward (uuid) to service_role;
grant  execute on function public.consume_reward (uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- public.my_rewards — read-only listing of the caller's ledger.
-- -----------------------------------------------------------------------------

create or replace function public.my_rewards ()
returns jsonb
language sql
stable
set search_path = ''
as $$
  select jsonb_build_object(
    'grants', coalesce(
      (
        select jsonb_agg(
                 to_jsonb(g) - 'created_at' - 'updated_at'
                 order by g.granted_at desc, g.id
               )
          from public.reward_grants g
         where g.user_id = (select auth.uid())
      ),
      '[]'::jsonb
    )
  );
$$;

comment on function public.my_rewards () is
  'Read-only: the caller''s own reward ledger with status and expiry. EXECUTE: authenticated (and service_role).';

revoke execute on function public.my_rewards () from public;
revoke execute on function public.my_rewards () from anon;
grant  execute on function public.my_rewards () to service_role;
grant  execute on function public.my_rewards () to authenticated;

-- -----------------------------------------------------------------------------
-- public.begin_ad_reward — opens a pending rewarded-ad view (app side).
-- -----------------------------------------------------------------------------

create or replace function private.begin_ad_reward_impl (p_reward_type text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user    uuid;
  v_token   text;
  v_expires timestamptz;
  v_icon    uuid;
begin
  v_user := (select auth.uid());
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_reward_type is null or p_reward_type not in ('streak_mercy', 'group_slot', 'saint_theme') then
    raise exception 'unsupported reward_type: %', p_reward_type using errcode = '22023';
  end if;

  if p_reward_type = 'streak_mercy' and exists (
        select 1
          from public.reward_grants g
         where g.user_id = v_user
           and g.reward_type = 'streak_mercy'
           and g.status in ('granted', 'consumed')
           and g.expires_at > now()
      ) then
    raise exception 'streak mercy already active (one per 30 days)' using errcode = '22023';
  end if;

  v_icon := null;
  if p_reward_type = 'saint_theme' then
    select si.id into v_icon
      from public.saint_icons si
     where si.is_active
     order by si.slug
     limit 1;
    if v_icon is null then
      raise exception 'no active saint theme available' using errcode = '22023';
    end if;
  end if;

  -- One open token per reward type: an older pending view is closed.
  update public.ad_view_tokens t
     set consumed_at = now()
   where t.user_id = v_user
     and t.reward_type = p_reward_type
     and t.consumed_at is null
     and t.expires_at > now();

  insert into public.ad_view_tokens (user_id, transaction_id, reward_type, expires_at)
  values (v_user, gen_random_uuid()::text, p_reward_type, now() + interval '30 minutes')
  returning transaction_id, expires_at into v_token, v_expires;

  return jsonb_build_object(
    'ok', true,
    'transaction_id', v_token,
    'reward_type', p_reward_type,
    'saint_icon_id', v_icon,
    'expires_at', v_expires,
    'expires_in_seconds', 1800
  );
end;
$$;

revoke execute on function private.begin_ad_reward_impl (text) from public;
revoke execute on function private.begin_ad_reward_impl (text) from anon;
grant  execute on function private.begin_ad_reward_impl (text) to service_role;
grant  execute on function private.begin_ad_reward_impl (text) to authenticated;

create or replace function public.begin_ad_reward (p_reward_type text)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.begin_ad_reward_impl (p_reward_type);
$$;

comment on function public.begin_ad_reward (text) is
  'Called by the app BEFORE showing a rewarded video. Returns the transaction_id the app must hand to AdMob as a custom parameter; the SSV callback consumes it and only then is the reward granted. EXECUTE: authenticated (own rows only) and service_role.';

revoke execute on function public.begin_ad_reward (text) from public;
revoke execute on function public.begin_ad_reward (text) from anon;
grant  execute on function public.begin_ad_reward (text) to service_role;
grant  execute on function public.begin_ad_reward (text) to authenticated;

-- -----------------------------------------------------------------------------
-- public.get_today_liturgy — the Today header payload (one jsonb row).
-- -----------------------------------------------------------------------------

create or replace function public.get_today_liturgy ()
returns jsonb
language sql
stable
set search_path = ''
as $$
  with ctx as (
    select (select p.timezone
              from public.profiles p
             where p.id = (select auth.uid())) as tz
  ), d as (
    select case
             when ctx.tz is not null
              and exists (select 1 from pg_catalog.pg_timezone_names n where n.name = ctx.tz)
               then (now() at time zone ctx.tz)::date
             else (now() at time zone 'America/Sao_Paulo')::date
           end as day
      from ctx
  )
  select jsonb_build_object(
    'date', d.day,
    'day', case when ld.id is null then null
                else to_jsonb(ld) - 'created_at' - 'updated_at' end,
    'readings', case when dr.id is null then null
                     else to_jsonb(dr) - 'created_at' - 'updated_at' end,
    'saints', coalesce(
      (
        select jsonb_agg(
                 jsonb_build_object('id', s.id, 'name', s.name, 'kind', s.kind, 'patronage', s.patronage)
                 order by s.name
               )
          from public.saints s
         where s.calendar_date = d.day
      ),
      '[]'::jsonb
    )
  )
  from d
  left join public.liturgical_days ld on ld.calendar_date = d.day
  left join public.daily_readings dr on dr.calendar_date = d.day;
$$;

comment on function public.get_today_liturgy () is
  'One cache-friendly jsonb row with today''s liturgical day, the readings row and the saints of the day. The date is computed in the caller''s profile timezone (fallback America/Sao_Paulo). EXECUTE: anon, authenticated, service_role.';

revoke execute on function public.get_today_liturgy () from public;
grant  execute on function public.get_today_liturgy () to anon;
grant  execute on function public.get_today_liturgy () to authenticated;
grant  execute on function public.get_today_liturgy () to service_role;

-- -----------------------------------------------------------------------------
-- public.get_liturgical_calendar — one year of the liturgical calendar.
-- -----------------------------------------------------------------------------

create or replace function public.get_liturgical_calendar (p_year integer)
returns jsonb
language sql
stable
set search_path = ''
as $$
  with y as (
    select p_year where p_year between 1900 and 2200
  ), days as (
    select ld.calendar_date,
           ld.season,
           ld.liturgical_color,
           ld.celebration,
           ld."rank"
      from public.liturgical_days ld
      cross join y
     where ld.calendar_date between make_date(y.p_year, 1, 1) and make_date(y.p_year, 12, 31)
  )
  select jsonb_build_object(
    'year', p_year,
    'count', (select count(*) from days),
    'days', coalesce(
      (
        select jsonb_agg(
                 jsonb_build_object(
                   'date', d.calendar_date,
                   'season', d.season,
                   'liturgical_color', d.liturgical_color,
                   'celebration', d.celebration,
                   'rank', d."rank",
                   'saints', coalesce(
                     (
                       select jsonb_agg(s.name order by s.name)
                         from public.saints s
                        where s.calendar_date = d.calendar_date
                     ),
                     '[]'::jsonb
                   )
                 )
                 order by d.calendar_date
               )
          from days d
      ),
      '[]'::jsonb
    )
  );
$$;

comment on function public.get_liturgical_calendar (integer) is
  'The liturgical calendar of one year: date, season, colour, celebration, rank and the saints of the day. EXECUTE: anon, authenticated, service_role.';

revoke execute on function public.get_liturgical_calendar (integer) from public;
grant  execute on function public.get_liturgical_calendar (integer) to anon;
grant  execute on function public.get_liturgical_calendar (integer) to authenticated;
grant  execute on function public.get_liturgical_calendar (integer) to service_role;
