-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022031806  ("create_guardian_angel_rpcs")
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
-- A8 · 0702 · Guardian Angel pairing engine + A8 RPCs
-- =============================================================================
-- Owner: A8.
--
-- DESIGN (A1 §3.2 remediation, A3 §14.5 pattern)
--   * Every function that a CLIENT may call lives in `public` and is
--     SECURITY INVOKER: it only forwards to an implementation in `private`
--     (SECURITY DEFINER, set search_path = ''). This adds ZERO
--     `*_security_definer_function_executable` findings.
--   * Every function that only the SERVER may call lives in `public` and is
--     SECURITY DEFINER, with EXECUTE revoked from PUBLIC/anon/authenticated
--     and granted to service_role only.
--   * The caller is ALWAYS derived from `auth.uid()`; no RPC accepts a
--     user id that would let a client impersonate somebody else.
--
-- ANONYMITY GUARANTEES
--   * `public.my_guardian_assignment` never returns the guardian's identity
--     to a protected member before `revealed_at` is set.
--   * `public.send_guardian_nudge` never puts the sender's name or id in the
--     outbox row that the recipient reads.
-- -----------------------------------------------------------------------------

-- =============================================================================
-- private.a8_resolve_cycle — the cycle of a group
-- =============================================================================
-- fraternity : the current ISO week, Monday .. Sunday. Key:
--               'fraternity:<group_id>:<YYYY>-W<ww>'
-- challenge  : the whole challenge window. Key:
--               'challenge:<group_id>:<starts_on>'
--
-- The cycle key is GROUP SCOPED on purpose: a member may belong to several
-- fraternities in the same week and the pairings table has
-- UNIQUE (cycle_key, guardian_id) / UNIQUE (cycle_key, protected_id) — a
-- global week key would collide across groups.
create or replace function private.a8_resolve_cycle (
  p_group_id uuid,
  p_cycle_key text,
  p_cycle_starts_on date
) returns table (cycle_key text, cycle_starts_on date, cycle_ends_on date)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_type   public.group_type;
  v_gstart date;
  v_gend   date;
  v_key    text;
  v_start  date;
  v_end    date;
  v_isoy   integer;
  v_isow   integer;
begin
  select g.group_type, g.starts_on, g.ends_on
    into v_type, v_gstart, v_gend
    from public.groups g
   where g.id = p_group_id;

  if v_type is null then
    raise exception 'group not found' using errcode = 'P0002';
  end if;

  if v_type = 'challenge' then
    if v_gstart is null or v_gend is null then
      raise exception 'challenge has no date window' using errcode = '22023';
    end if;
    v_start := v_gstart;
    v_end   := v_gend;
    v_key   := coalesce (nullif (btrim (p_cycle_key), ''),
                         'challenge:' || p_group_id::text || ':' || v_gstart::text);
  else
    v_start := coalesce (
      p_cycle_starts_on,
      (current_date - ((extract (isodow from current_date)::int - 1))::int));
    v_end   := v_start + 6;
    v_isoy  := extract (year from v_start)::int;
    v_isow  := extract (week from v_start)::int;
    v_key   := coalesce (nullif (btrim (p_cycle_key), ''),
                         'fraternity:' || p_group_id::text || ':'
                         || lpad (v_isoy::text, 4, '0') || '-W'
                         || lpad (v_isow::text, 2, '0'));
  end if;

  return query select v_key, v_start, v_end;
end;
$$;

comment on function private.a8_resolve_cycle (uuid, text, date) is
  'Resolves the Guardian Angel cycle of a group. A fraternity cycles on the ISO week (Monday..Sunday) with key fraternity:<group_id>:<YYYY-Www>; a challenge cycles over its whole window with key challenge:<group_id>:<starts_on>.';

-- =============================================================================
-- private.a8_eligible_members — who may be drawn
-- =============================================================================
-- Eligible = master opt-in ON  +  a per-group opt-in row  +  an active
-- membership  +  not blocked (either direction) with any other candidate.
-- A member who did not opt in is never paired and never learns they were
-- excluded.
create or replace function private.a8_eligible_members (p_group_id uuid)
returns setof uuid
language sql stable security definer set search_path = ''
as $$
  with candidates as (
    select gm.user_id
      from public.group_members gm
      join public.profiles p on p.id = gm.user_id
     where gm.group_id = p_group_id
       and p.deleted_at is null
       and p.guardian_angel_opt_in
       and exists (
             select 1
               from public.guardian_angel_opt_ins o
              where o.user_id = gm.user_id
                and o.group_id = p_group_id)
  )
  select c.user_id
    from candidates c
   where not exists (
           select 1
             from candidates o
            where o.user_id <> c.user_id
              and public.is_blocked (c.user_id, o.user_id))
   order by c.user_id;
$$;

comment on function private.a8_eligible_members (uuid) is
  'The sorted list of members eligible for the Guardian Angel draw in one group. Blocked pairs (either direction) remove the member from the set.';

-- =============================================================================
-- private.a8_pair_group_impl — the derangement
-- =============================================================================
-- The derangement is a DETERMINISTIC rotation by 1 over the eligible members
-- sorted by user_id:
--     members = [m1, m2, ..., mn]      (sorted by user_id)
--     m1 guards m2, m2 guards m3, ..., mn guards m1
-- A rotation by 1 over a sorted list of n >= 2 elements is a derangement:
-- nobody keeps its own position, so `guardian_id <> protected_id` always
-- holds, and every member appears exactly once as guardian and once as
-- protected. `random()` is NEVER used: re-running the same cycle reproduces
-- exactly the same draw.
create or replace function private.a8_pair_group_impl (
  p_group_id uuid,
  p_cycle_key text,
  p_cycle_starts_on date
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_key       text;
  v_start     date;
  v_end       date;
  v_members   uuid[] := '{}'::uuid[];
  v_n         integer := 0;
  v_i         integer;
  v_guardian  uuid;
  v_protected uuid;
  v_taken     uuid;
  v_inserted  integer := 0;
  v_updated   integer := 0;
  v_skipped   integer := 0;
  v_offset    integer := 1;
  v_exists    boolean;
begin
  select r.cycle_key, r.cycle_starts_on, r.cycle_ends_on
    into v_key, v_start, v_end
    from private.a8_resolve_cycle (p_group_id, p_cycle_key, p_cycle_starts_on) r;

  select coalesce (array_agg (e.user_id order by e.user_id), '{}'::uuid[])
    into v_members
    from private.a8_eligible_members (p_group_id) as e (user_id);

  v_n := coalesce (array_length (v_members, 1), 0);

  if v_n < 2 then
    return jsonb_build_object (
      'group_id', p_group_id,
      'cycle_key', v_key,
      'cycle_starts_on', v_start,
      'cycle_ends_on', v_end,
      'paired', 0,
      'member_count', v_n,
      'rotation_offset', v_offset,
      'reason', 'insufficient_opt_ins');
  end if;

  for v_i in 0 .. v_n - 1 loop
    v_guardian  := v_members [v_i + 1];
    v_protected := v_members [((v_i + 1) % v_n) + 1];

    select p.id
      into v_taken
      from public.guardian_angel_pairings p
     where p.cycle_key = v_key
       and p.protected_id = v_protected
       and p.guardian_id <> v_guardian;

    if v_taken is not null then
      v_skipped := v_skipped + 1;
      continue;
    end if;

    select exists (
             select 1
               from public.guardian_angel_pairings p
              where p.cycle_key = v_key
                and p.guardian_id = v_guardian)
      into v_exists;

    insert into public.guardian_angel_pairings (
      group_id, cycle_key, guardian_id, protected_id,
      cycle_starts_on, cycle_ends_on, is_active)
    values (
      p_group_id, v_key, v_guardian, v_protected,
      v_start, v_end, true)
    on conflict (cycle_key, guardian_id) do update
      set protected_id    = excluded.protected_id,
          group_id        = excluded.group_id,
          cycle_starts_on = excluded.cycle_starts_on,
          cycle_ends_on   = excluded.cycle_ends_on,
          is_active       = true;

    if v_exists then
      v_updated := v_updated + 1;
    else
      v_inserted := v_inserted + 1;
    end if;
  end loop;

  update public.guardian_angel_pairings p
     set is_active = false
   where p.cycle_key = v_key
     and (not exists (select 1 from public.group_members gm
                        where gm.group_id = p.group_id
                          and gm.user_id = p.guardian_id)
       or not exists (select 1 from public.group_members gm
                        where gm.group_id = p.group_id
                          and gm.user_id = p.protected_id));

  insert into public.audit_log (
    actor_id, action, target_type, target_id, metadata)
  values (
    null, 'guardian.pairing_created', 'guardian_angel_pairings', p_group_id,
    jsonb_build_object (
      'group_id', p_group_id,
      'cycle_key', v_key,
      'member_count', v_n,
      'rotation_offset', v_offset,
      'paired', v_inserted + v_updated));

  return jsonb_build_object (
    'group_id', p_group_id,
    'cycle_key', v_key,
    'cycle_starts_on', v_start,
    'cycle_ends_on', v_end,
    'paired', v_inserted + v_updated,
    'inserted', v_inserted,
    'updated', v_updated,
    'skipped', v_skipped,
    'member_count', v_n,
    'rotation_offset', v_offset,
    'reason', null);
end;
$$;

comment on function private.a8_pair_group_impl (uuid, text, date) is
  'Runs the Guardian Angel draw for one group/cycle. Deterministic derangement: the eligible members are sorted by user_id and rotated by 1. Idempotent on (cycle_key, guardian_id).';

-- =============================================================================
-- private.a8_opt_in_impl
-- =============================================================================
create or replace function private.a8_opt_in_impl (
  p_group_id uuid,
  p_opt_in boolean
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid ();
  v_master boolean;
  v_group  boolean;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_member (p_group_id, v_uid) then
    raise exception 'not_a_group_member' using errcode = '42501';
  end if;

  if coalesce (p_opt_in, false) then
    insert into public.guardian_angel_opt_ins (user_id, group_id)
    values (v_uid, p_group_id)
    on conflict (user_id, group_id) do nothing;
  else
    delete from public.guardian_angel_opt_ins
     where user_id = v_uid
       and group_id = p_group_id;
  end if;

  select exists (
           select 1 from public.guardian_angel_opt_ins o where o.user_id = v_uid)
    into v_master;

  update public.profiles
     set guardian_angel_opt_in = v_master
   where id = v_uid;

  select exists (
           select 1
             from public.guardian_angel_opt_ins o
            where o.user_id = v_uid
              and o.group_id = p_group_id)
    into v_group;

  return jsonb_build_object (
    'group_id', p_group_id,
    'opted_in', v_group,
    'group_opt_in', v_group,
    'master_opt_in', v_master);
end;
$$;

comment on function private.a8_opt_in_impl (uuid, boolean) is
  'Upserts/deletes the per-group Guardian Angel opt-in and keeps profiles.guardian_angel_opt_in (the master switch) true whenever the user opted into ANY group.';

-- =============================================================================
-- private.a8_assignment_impl — the redacted assignment
-- =============================================================================
create or replace function private.a8_assignment_impl (p_group_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_uid          uuid := auth.uid ();
  v_g_id         uuid;
  v_g_protected  uuid;
  v_g_cycle      text;
  v_g_start      date;
  v_g_end        date;
  v_g_revealed   timestamptz;
  v_p_id         uuid;
  v_p_guardian   uuid;
  v_p_cycle      text;
  v_p_start      date;
  v_p_end        date;
  v_p_revealed   timestamptz;
  v_cycle_key    text;
  v_cycle_start  date;
  v_cycle_end    date;
  v_revealed     timestamptz;
  v_display      text;
  v_guard_disp   text;
  v_intentions   jsonb := '[]'::jsonb;
  v_nudges       integer := 0;
  v_can_nudge    boolean := false;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select p.id, p.protected_id, p.cycle_key, p.cycle_starts_on, p.cycle_ends_on, p.revealed_at
    into v_g_id, v_g_protected, v_g_cycle, v_g_start, v_g_end, v_g_revealed
    from public.guardian_angel_pairings p
   where p.group_id = p_group_id
     and p.is_active
     and p.guardian_id = v_uid
     and p.cycle_starts_on <= current_date
   order by p.cycle_starts_on desc, p.created_at desc
   limit 1;

  select p.id, p.guardian_id, p.cycle_key, p.cycle_starts_on, p.cycle_ends_on, p.revealed_at
    into v_p_id, v_p_guardian, v_p_cycle, v_p_start, v_p_end, v_p_revealed
    from public.guardian_angel_pairings p
   where p.group_id = p_group_id
     and p.is_active
     and p.protected_id = v_uid
     and p.cycle_starts_on <= current_date
   order by p.cycle_starts_on desc, p.created_at desc
   limit 1;

  if v_g_start is null or (v_p_start is not null and v_p_start > v_g_start) then
    v_cycle_key   := v_p_cycle;
    v_cycle_start := v_p_start;
    v_cycle_end   := v_p_end;
    v_revealed    := v_p_revealed;
  else
    v_cycle_key   := v_g_cycle;
    v_cycle_start := v_g_start;
    v_cycle_end   := v_g_end;
    v_revealed    := v_g_revealed;
  end if;

  if v_g_protected is not null
     and not public.is_blocked (v_uid, v_g_protected) then
    select pr.display_name into v_display
      from public.profiles pr
     where pr.id = v_g_protected;

    select coalesce (
             jsonb_agg (x.obj order by x.created_at desc), '[]'::jsonb)
      into v_intentions
      from (
            select pi.id,
                   pi.created_at,
                   jsonb_build_object ('id', pi.id, 'body', left (pi.body, 280)) as obj
              from public.prayer_intentions pi
             where pi.user_id = v_g_protected
               and pi.group_id = p_group_id
               and not pi.is_hidden
             order by pi.created_at desc
             limit 3
           ) x;
  end if;

  if v_revealed is not null and v_p_guardian is not null then
    select pr.display_name into v_guard_disp
      from public.profiles pr
     where pr.id = v_p_guardian;
  end if;

  select count (*) into v_nudges
    from public.guardian_nudges n
   where n.sender_id = v_uid
     and n.local_date = current_date;

  v_can_nudge := (v_g_id is not null)
                 and v_cycle_end is not null
                 and v_cycle_end >= current_date
                 and v_nudges = 0;

  return jsonb_build_object (
    'is_guardian', v_g_id is not null,
    'is_protected', v_p_id is not null,
    'protected_display_name', v_display,
    'protected_intentions', v_intentions,
    'guardian_display_name', v_guard_disp,
    'revealed', v_revealed is not null,
    'cycle_key', v_cycle_key,
    'cycle_starts_on', v_cycle_start,
    'cycle_ends_on', v_cycle_end,
    'can_nudge', v_can_nudge,
    'nudges_today', v_nudges);
end;
$$;

comment on function private.a8_assignment_impl (uuid) is
  'The caller''s Guardian Angel assignment, REDACTED. A protected member never receives the guardian''s name or id before revealed_at is set; a guardian receives the protected member''s display name and up to 3 of their group prayer intentions (never private check-in content).';

-- =============================================================================
-- private.a8_state_impl
-- =============================================================================
create or replace function private.a8_state_impl (p_group_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid ();
  v_opted boolean := false;
  v_a     jsonb;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select exists (
           select 1
             from public.guardian_angel_opt_ins o
            where o.user_id = v_uid
              and o.group_id = p_group_id)
    into v_opted;

  v_a := private.a8_assignment_impl (p_group_id);

  return jsonb_build_object (
    'group_id', p_group_id,
    'opted_in', v_opted,
    'is_guardian', (v_a ->> 'is_guardian')::boolean,
    'is_protected', (v_a ->> 'is_protected')::boolean,
    'cycle_ends_on', v_a -> 'cycle_ends_on',
    'can_nudge', (v_a ->> 'can_nudge')::boolean,
    'nudges_today', (v_a ->> 'nudges_today')::integer);
end;
$$;

comment on function private.a8_state_impl (uuid) is
  'Everything the Guardian Angel card of the group needs: {opted_in, is_guardian, is_protected, cycle_ends_on, can_nudge, nudges_today}.';

-- =============================================================================
-- private.a8_send_nudge_impl — the anonymous nudge
-- =============================================================================
create or replace function private.a8_send_nudge_impl (
  p_group_id uuid,
  p_local_date date
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid      uuid := auth.uid ();
  v_local    date;
  v_pair_id  uuid;
  v_protect  uuid;
  v_cycle    text;
  v_end      date;
  v_nudge_id uuid;
  v_count    integer;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  v_local := coalesce (p_local_date, current_date);

  if v_local < current_date - 1 or v_local > current_date + 1 then
    raise exception 'invalid_local_date' using errcode = '22023';
  end if;

  select p.id, p.protected_id, p.cycle_key, p.cycle_ends_on
    into v_pair_id, v_protect, v_cycle, v_end
    from public.guardian_angel_pairings p
   where p.group_id = p_group_id
     and p.is_active
     and p.guardian_id = v_uid
     and p.cycle_starts_on <= current_date
   order by p.cycle_starts_on desc, p.created_at desc
   limit 1;

  if v_pair_id is null
     or v_end < current_date
     or public.is_blocked (v_uid, v_protect) then
    raise exception 'not_a_guardian' using errcode = '42501';
  end if;

  begin
    insert into public.guardian_nudges (
      group_id, pairing_id, sender_id, protected_id, cycle_key, local_date)
    values (
      p_group_id, v_pair_id, v_uid, v_protect, v_cycle, v_local)
    returning id into v_nudge_id;
  exception
    when unique_violation then
      raise exception 'nudge_already_sent_today' using errcode = 'P0001';
  end;

  -- The pushed notification is ANONYMOUS: neither the sender's name nor the
  -- sender's id may appear in the title, the body or the payload.
  insert into public.notification_outbox (
    user_id, channel, notification_type, title, body, payload, group_id, dedupe_key)
  values (
    v_protect, 'push', 'guardian_nudge',
    'Alguém rezou por você',
    'Alguém rezou por você hoje.',
    jsonb_build_object ('group_id', p_group_id, 'cycle_key', v_cycle),
    p_group_id,
    'nudge:' || v_nudge_id::text)
  on conflict (dedupe_key) do nothing;

  select count (*) into v_count
    from public.guardian_nudges n
   where n.sender_id = v_uid
     and n.local_date = v_local;

  return jsonb_build_object (
    'sent', true,
    'nudges_today', v_count,
    'remaining', greatest (0, 1 - v_count),
    'nudge_id', v_nudge_id,
    'local_date', v_local);
end;
$$;

comment on function private.a8_send_nudge_impl (uuid, date) is
  'Sends the anonymous "I prayed for my protected soul" nudge. One nudge per sender per local date (UNIQUE (sender_id, local_date)). The outbox row is anonymous: it never contains the sender''s name or id.';

-- =============================================================================
-- private.a8_register_device_impl
-- =============================================================================
create or replace function private.a8_register_device_impl (
  p_apns_token text,
  p_platform text,
  p_environment text,
  p_app_version text
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid ();
  v_token text;
  v_plat  text;
  v_env   text;
  v_id    uuid;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  v_token := btrim (coalesce (p_apns_token, ''));
  v_plat  := lower (coalesce (btrim (p_platform), 'ios'));
  v_env   := lower (coalesce (btrim (p_environment), 'production'));

  if char_length (v_token) < 8 or char_length (v_token) > 512 then
    raise exception 'invalid_push_token' using errcode = '22023';
  end if;

  if v_plat not in ('ios', 'android') then
    raise exception 'invalid_platform' using errcode = '22023';
  end if;

  if v_env not in ('sandbox', 'production') then
    raise exception 'invalid_environment' using errcode = '22023';
  end if;

  insert into public.device_tokens (
    user_id, platform, apns_token, environment, app_version, is_active, last_seen_at)
  values (
    v_uid, v_plat, v_token, v_env, nullif (left (p_app_version, 40), ''), true, now ())
  on conflict (platform, apns_token) do update
    set user_id      = excluded.user_id,
        environment  = excluded.environment,
        app_version  = excluded.app_version,
        is_active    = true,
        last_seen_at = now ()
  returning id into v_id;

  return jsonb_build_object (
    'id', v_id,
    'platform', v_plat,
    'environment', v_env,
    'app_version', nullif (left (p_app_version, 40), ''),
    'is_active', true,
    'registered', true);
end;
$$;

comment on function private.a8_register_device_impl (text, text, text, text) is
  'Registers (or re-registers) a push token for the caller. The same (platform, apns_token) is never stored twice: re-registering moves the row to the new user.';

-- =============================================================================
-- private.a8_claim_outbox_impl
-- =============================================================================
create or replace function private.a8_claim_outbox_impl (p_limit integer)
returns setof jsonb
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return query
  with claimed as (
         select o.id
           from public.notification_outbox o
          where o.status = 'pending'
            and o.scheduled_at <= now ()
          order by o.scheduled_at, o.id
          limit greatest (1, least (coalesce (p_limit, 50), 500))
            for update skip locked
       ),
       upd as (
         update public.notification_outbox o
            set status = 'processing',
                attempts = o.attempts + 1
           from claimed c
          where o.id = c.id
         returning o.*
       )
  select jsonb_build_object (
           'id', u.id,
           'user_id', u.user_id,
           'notification_type', u.notification_type,
           'title', u.title,
           'body', u.body,
           'payload', u.payload,
           'group_id', u.group_id,
           'attempts', u.attempts,
           'scheduled_at', u.scheduled_at)
    from upd u;
end;
$$;

comment on function private.a8_claim_outbox_impl (integer) is
  'Claims up to p_limit pending outbox rows with FOR UPDATE SKIP LOCKED so concurrent dispatchers never claim the same row.';

-- =============================================================================
-- private.a8_complete_outbox_impl
-- =============================================================================
create or replace function private.a8_complete_outbox_impl (
  p_outbox_id uuid,
  p_status text,
  p_error text,
  p_retry_at timestamptz
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_attempts integer;
  v_next     timestamptz;
  v_err      text;
  v_status   text;
begin
  if p_status not in ('sent', 'failed', 'pending', 'cancelled') then
    raise exception 'invalid_status' using errcode = '22023';
  end if;

  select o.attempts into v_attempts
    from public.notification_outbox o
   where o.id = p_outbox_id;

  if v_attempts is null then
    raise exception 'outbox row not found' using errcode = 'P0002';
  end if;

  v_err := left (coalesce (p_error, ''), 1000);

  if p_status = 'sent' then
    update public.notification_outbox o
       set status = 'sent',
           sent_at = now (),
           last_error = null
     where o.id = p_outbox_id;
    v_status := 'sent';
  elsif p_status = 'failed' then
    if v_attempts >= 5 then
      update public.notification_outbox o
         set status = 'failed',
             last_error = v_err
       where o.id = p_outbox_id;
      v_status := 'failed';
    else
      v_next := coalesce (
        p_retry_at,
        now () + (power (2, v_attempts)::integer * interval '1 minute'));
      update public.notification_outbox o
         set status = 'pending',
             scheduled_at = v_next,
             last_error = v_err
       where o.id = p_outbox_id;
      v_status := 'pending';
    end if;
  else
    update public.notification_outbox o
       set status = p_status,
           last_error = v_err
     where o.id = p_outbox_id;
    v_status := p_status;
  end if;

  return jsonb_build_object (
    'id', p_outbox_id,
    'status', v_status,
    'attempts', v_attempts,
    'scheduled_at', (select o.scheduled_at from public.notification_outbox o where o.id = p_outbox_id));
end;
$$;

comment on function private.a8_complete_outbox_impl (uuid, text, text, timestamptz) is
  'Completes a claimed outbox row. "failed" schedules an exponential backoff retry (2^attempts minutes) and becomes permanent after 5 attempts.';

-- =============================================================================
-- private.a8_deactivate_token_impl
-- =============================================================================
create or replace function private.a8_deactivate_token_impl (p_token_id uuid)
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user uuid;
begin
  update public.device_tokens d
     set is_active = false
   where d.id = p_token_id
  returning d.user_id into v_user;

  if v_user is null then
    raise exception 'device token not found' using errcode = 'P0002';
  end if;

  return jsonb_build_object ('id', p_token_id, 'is_active', false);
end;
$$;

comment on function private.a8_deactivate_token_impl (uuid) is
  'Deactivates a push token (APNs 400 BadDeviceToken / 410 Unregistered).';

-- =============================================================================
-- private.a8_dispatch_push_impl — cron -> Edge Function
-- =============================================================================
create or replace function private.a8_dispatch_push_impl ()
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_url    text;
  v_secret text;
  v_req    bigint;
  v_header jsonb := jsonb_build_object ('Content-Type', 'application/json');
begin
  select s.value into v_url
    from private.app_settings s
   where s.key = 'push_dispatch_url';

  select s.value into v_secret
    from private.app_settings s
   where s.key = 'push_dispatch_secret';

  if v_url is null or btrim (v_url) = '' then
    return jsonb_build_object (
      'dispatched', false,
      'reason', 'not_configured',
      'hint', 'set private.app_settings.push_dispatch_url');
  end if;

  if v_secret is not null and btrim (v_secret) <> '' then
    v_header := v_header || jsonb_build_object ('x-push-secret', v_secret);
  end if;

  v_req := net.http_post (
    url := btrim (v_url),
    body := jsonb_build_object ('source', 'pg_cron'),
    params := '{}'::jsonb,
    headers := v_header,
    timeout_milliseconds := 5000);

  return jsonb_build_object (
    'dispatched', true,
    'request_id', v_req);
end;
$$;

comment on function private.a8_dispatch_push_impl () is
  'Calls the push-dispatch Edge Function through pg_net. NO-OP when private.app_settings.push_dispatch_url is missing, so a project without push configured never makes an outbound call.';

-- =============================================================================
-- PUBLIC · client facing (SECURITY INVOKER wrappers)
-- =============================================================================

create or replace function public.opt_in_to_guardian_angel (
  p_group_id uuid,
  p_opt_in boolean
) returns jsonb
language plpgsql volatile security invoker set search_path = ''
as $$
begin
  return private.a8_opt_in_impl (p_group_id, p_opt_in);
end;
$$;

comment on function public.opt_in_to_guardian_angel (uuid, boolean) is
  'Opts the caller in/out of the Secret Guardian Angel draw of one group. Upserts the per-group opt-in and keeps the profiles.guardian_angel_opt_in master switch in sync (true when the user opted into ANY group). Returns {group_id, opted_in, group_opt_in, master_opt_in}.';

create or replace function public.my_guardian_assignment (p_group_id uuid)
returns jsonb
language plpgsql stable security invoker set search_path = ''
as $$
begin
  return private.a8_assignment_impl (p_group_id);
end;
$$;

comment on function public.my_guardian_assignment (uuid) is
  'The caller''s Guardian Angel assignment: {is_guardian, is_protected, protected_display_name, protected_intentions, guardian_display_name, revealed, cycle_key, cycle_starts_on, cycle_ends_on, can_nudge, nudges_today}. A protected member NEVER receives the guardian''s name or id before the cycle is revealed.';

create or replace function public.guardian_angel_state (p_group_id uuid)
returns jsonb
language plpgsql stable security invoker set search_path = ''
as $$
begin
  return private.a8_state_impl (p_group_id);
end;
$$;

comment on function public.guardian_angel_state (uuid) is
  'The Guardian Angel card state: {group_id, opted_in, is_guardian, is_protected, cycle_ends_on, can_nudge, nudges_today}.';

create or replace function public.send_guardian_nudge (
  p_group_id uuid,
  p_local_date date default null
) returns jsonb
language plpgsql volatile security invoker set search_path = ''
as $$
begin
  return private.a8_send_nudge_impl (p_group_id, p_local_date);
end;
$$;

comment on function public.send_guardian_nudge (uuid, date) is
  'The anonymous "I prayed for my protected soul" button. Requires an active pairing as guardian in the current cycle. At most ONE nudge per sender per local date (UNIQUE (sender_id, local_date)); a second one in the same day raises nudge_already_sent_today. The pushed notification never carries the sender''s name or id. Returns {sent, nudges_today, remaining, nudge_id, local_date}.';

create or replace function public.register_device_token (
  p_apns_token text,
  p_platform text default 'ios',
  p_environment text default 'production',
  p_app_version text default null
) returns jsonb
language plpgsql volatile security invoker set search_path = ''
as $$
begin
  return private.a8_register_device_impl (p_apns_token, p_platform, p_environment, p_app_version);
end;
$$;

comment on function public.register_device_token (text, text, text, text) is
  'Registers the caller''s push token. The same (platform, apns_token) is never stored twice: re-registering moves the row to the new user.';

-- =============================================================================
-- PUBLIC · server only (SECURITY DEFINER, service_role only)
-- =============================================================================

create or replace function public.run_guardian_angel_pairing (
  p_group_id uuid,
  p_cycle_key text default null,
  p_cycle_starts_on date default null
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return private.a8_pair_group_impl (p_group_id, p_cycle_key, p_cycle_starts_on);
end;
$$;

comment on function public.run_guardian_angel_pairing (uuid, text, date) is
  'Runs the Guardian Angel draw for one group/cycle (service_role only). A fraternity cycles on the current ISO week, a challenge over its whole window. Fewer than 2 eligible members -> {paired:0, reason:"insufficient_opt_ins"} and NO pair is created.';

create or replace function public.sweep_guardian_angel_pairings (
  p_scope text default 'all'
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_scope  text := lower (btrim (coalesce (p_scope, 'all')));
  v_groups uuid[];
  v_g      uuid;
  v_res    jsonb;
  v_total  integer := 0;
  v_done   integer := 0;
begin
  if v_scope not in ('all', 'fraternity', 'challenge') then
    raise exception 'invalid_scope' using errcode = '22023';
  end if;

  select coalesce (array_agg (g.id order by g.id), '{}'::uuid[])
    into v_groups
    from public.groups g
   where g.archived_at is null
     and (v_scope = 'all'
          or (v_scope = 'fraternity' and g.group_type = 'fraternity')
          or (v_scope = 'challenge'
              and g.group_type = 'challenge'
              and g.starts_on is not null
              and g.starts_on <= current_date
              and (g.ends_on is null or g.ends_on >= current_date)));

  foreach v_g in array v_groups loop
    v_res := private.a8_pair_group_impl (v_g, null, null);
    v_total := v_total + coalesce ((v_res ->> 'paired')::integer, 0);
    v_done  := v_done + 1;
  end loop;

  return jsonb_build_object (
    'scope', v_scope,
    'groups', v_done,
    'paired', v_total);
end;
$$;

comment on function public.sweep_guardian_angel_pairings (text) is
  'Runs the Guardian Angel draw for every group in scope (''all'' | ''fraternity'' | ''challenge'') (service_role only). Used by the pg_cron jobs.';

create or replace function public.reveal_guardian_identities (p_group_id uuid)
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_n integer;
begin
  update public.guardian_angel_pairings p
     set revealed_at = now ()
   where p.group_id = p_group_id
     and p.revealed_at is null;

  get diagnostics v_n = row_count;

  return jsonb_build_object (
    'group_id', p_group_id,
    'revealed', v_n,
    'revealed_at', now ());
end;
$$;

comment on function public.reveal_guardian_identities (uuid) is
  'Reveals the Guardian identities of a group (service_role only). Identities are revealed only at the end of a cycle — this is the explicit operator action.';

create or replace function public.sweep_reveal_guardian_identities ()
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_n integer;
begin
  update public.guardian_angel_pairings p
     set revealed_at = now ()
   where p.revealed_at is null
     and p.cycle_ends_on < current_date;

  get diagnostics v_n = row_count;

  return jsonb_build_object ('revealed', v_n);
end;
$$;

comment on function public.sweep_reveal_guardian_identities () is
  'Reveals the identities of every cycle that has ENDED (cycle_ends_on < today) (service_role only). Used by the daily pg_cron job.';

create or replace function public.claim_notification_outbox (
  p_limit integer default 50
) returns setof jsonb
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return query select * from private.a8_claim_outbox_impl (p_limit);
end;
$$;

comment on function public.claim_notification_outbox (integer) is
  'Claims up to p_limit pending notification_outbox rows (service_role only). Uses FOR UPDATE SKIP LOCKED so two dispatchers never claim the same row. Returns the claimed rows as jsonb.';

create or replace function public.complete_notification_outbox (
  p_outbox_id uuid,
  p_status text,
  p_error text default null,
  p_retry_at timestamptz default null
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return private.a8_complete_outbox_impl (p_outbox_id, p_status, p_error, p_retry_at);
end;
$$;

comment on function public.complete_notification_outbox (uuid, text, text, timestamptz) is
  'Completes a claimed outbox row (service_role only). p_status = ''sent'' | ''failed'' | ''pending'' | ''cancelled''. A ''failed'' row is rescheduled with an exponential backoff (2^attempts minutes) and becomes permanently ''failed'' after 5 attempts.';

create or replace function public.deactivate_device_token (p_token_id uuid)
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return private.a8_deactivate_token_impl (p_token_id);
end;
$$;

comment on function public.deactivate_device_token (uuid) is
  'Deactivates a push token (service_role only). Used when APNs answers 400 BadDeviceToken or 410 Unregistered.';

create or replace function public.dispatch_push_notifications ()
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return private.a8_dispatch_push_impl ();
end;
$$;

comment on function public.dispatch_push_notifications () is
  'Calls the push-dispatch Edge Function through pg_net (service_role / pg_cron only). It is a NO-OP when private.app_settings.push_dispatch_url is not configured.';

-- =============================================================================
-- Privileges
-- =============================================================================

-- client facing wrappers: authenticated only
revoke execute on function public.opt_in_to_guardian_angel (uuid, boolean) from public, anon;
revoke execute on function public.my_guardian_assignment (uuid)             from public, anon;
revoke execute on function public.guardian_angel_state (uuid)                from public, anon;
revoke execute on function public.send_guardian_nudge (uuid, date)           from public, anon;
revoke execute on function public.register_device_token (text, text, text, text) from public, anon;

grant execute on function public.opt_in_to_guardian_angel (uuid, boolean) to authenticated;
grant execute on function public.my_guardian_assignment (uuid)             to authenticated;
grant execute on function public.guardian_angel_state (uuid)                to authenticated;
grant execute on function public.send_guardian_nudge (uuid, date)           to authenticated;
grant execute on function public.register_device_token (text, text, text, text) to authenticated;

-- private implementations: only the roles that must run them
revoke execute on function private.a8_opt_in_impl (uuid, boolean)          from public, anon, authenticated, service_role;
revoke execute on function private.a8_assignment_impl (uuid)               from public, anon, authenticated, service_role;
revoke execute on function private.a8_state_impl (uuid)                    from public, anon, authenticated, service_role;
revoke execute on function private.a8_send_nudge_impl (uuid, date)         from public, anon, authenticated, service_role;
revoke execute on function private.a8_register_device_impl (text, text, text, text) from public, anon, authenticated, service_role;

grant execute on function private.a8_opt_in_impl (uuid, boolean)          to authenticated, service_role;
grant execute on function private.a8_assignment_impl (uuid)               to authenticated, service_role;
grant execute on function private.a8_state_impl (uuid)                    to authenticated, service_role;
grant execute on function private.a8_send_nudge_impl (uuid, date)         to authenticated, service_role;
grant execute on function private.a8_register_device_impl (text, text, text, text) to authenticated, service_role;

-- internal helpers: owner only
revoke execute on function private.a8_resolve_cycle (uuid, text, date)   from public, anon, authenticated, service_role;
revoke execute on function private.a8_eligible_members (uuid)             from public, anon, authenticated, service_role;
revoke execute on function private.a8_pair_group_impl (uuid, text, date)  from public, anon, authenticated, service_role;
revoke execute on function private.a8_claim_outbox_impl (integer)         from public, anon, authenticated, service_role;
revoke execute on function private.a8_complete_outbox_impl (uuid, text, text, timestamptz) from public, anon, authenticated, service_role;
revoke execute on function private.a8_deactivate_token_impl (uuid)        from public, anon, authenticated, service_role;
revoke execute on function private.a8_dispatch_push_impl ()               from public, anon, authenticated, service_role;

-- server only wrappers: service_role only
revoke execute on function public.run_guardian_angel_pairing (uuid, text, date) from public, anon, authenticated;
revoke execute on function public.sweep_guardian_angel_pairings (text)     from public, anon, authenticated;
revoke execute on function public.reveal_guardian_identities (uuid)        from public, anon, authenticated;
revoke execute on function public.sweep_reveal_guardian_identities ()      from public, anon, authenticated;
revoke execute on function public.claim_notification_outbox (integer)      from public, anon, authenticated;
revoke execute on function public.complete_notification_outbox (uuid, text, text, timestamptz) from public, anon, authenticated;
revoke execute on function public.deactivate_device_token (uuid)           from public, anon, authenticated;
revoke execute on function public.dispatch_push_notifications ()           from public, anon, authenticated;

grant execute on function public.run_guardian_angel_pairing (uuid, text, date) to service_role;
grant execute on function public.sweep_guardian_angel_pairings (text)     to service_role;
grant execute on function public.reveal_guardian_identities (uuid)        to service_role;
grant execute on function public.sweep_reveal_guardian_identities ()      to service_role;
grant execute on function public.claim_notification_outbox (integer)      to service_role;
grant execute on function public.complete_notification_outbox (uuid, text, text, timestamptz) to service_role;
grant execute on function public.deactivate_device_token (uuid)           to service_role;
grant execute on function public.dispatch_push_notifications ()           to service_role;
