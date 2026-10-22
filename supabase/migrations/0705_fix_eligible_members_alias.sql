-- =============================================================================
-- A8 · 0705 · fix the eligible-members column alias
-- =============================================================================
-- Owner: A8.
--
-- `private.a8_eligible_members` returns `setof uuid`, so its output column is
-- named after the function, not `user_id`. Migration 0702 referenced it as
-- `e.user_id` and therefore failed with
--   ERROR: 42703: column e.user_id does not exist
-- This migration re-creates the function with the correct alias
-- (`as e (user_id)`). The 0702 source file carries the same fix so a fresh
-- install from the migration chain is correct.
-- -----------------------------------------------------------------------------

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

revoke execute on function private.a8_eligible_members (uuid) from public, anon, authenticated, service_role;

-- The caller must be re-created too: a PL/pgSQL body is compiled when the
-- function is created, so patching the callee alone is not enough.
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

revoke execute on function private.a8_pair_group_impl (uuid, text, date) from public, anon, authenticated, service_role;
