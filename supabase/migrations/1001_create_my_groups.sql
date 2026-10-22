-- =============================================================================
-- 1001 · create_my_groups
-- =============================================================================
-- Gap closure (A9 report): the "Meus Grupos" screen needed FOUR round trips
-- (group_members -> groups -> member count -> group_featured). This RPC
-- returns the whole list in ONE call.
--
-- PATTERN (A10's private + INVOKER split, SCHEMA.md §21.4):
--   private.my_groups_impl()  -- SECURITY DEFINER, SET search_path = ''
--   public.my_groups()        -- thin SECURITY INVOKER wrapper
--
-- RULES (mirroring A3's ACTIVE-membership rule, SCHEMA.md §14.2):
--   * the group is not archived;
--   * for a CHALLENGE the season has not ended
--     (`ends_on IS NULL OR ends_on >= current_date`);
--   * the caller is not blocked by the group's creator (the project's block
--     relation is symmetric -- private.is_blocked_impl).
--
-- SECURITY:
--   * `invite_code` is a CAPABILITY. It is returned ONLY to the admin of the
--     group. A plain member always receives `invite_code: null`.
--   * `anon` may not execute the RPC.
-- =============================================================================

create or replace function private.my_groups_impl ()
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid ();
  v_items jsonb;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  with mine as (
    select g.id,
           g.name,
           g.description,
           g.group_type,
           g.scoring_mode,
           g.sharing_requirement,
           g.cover_path,
           g.invite_code,
           g.starts_on,
           g.ends_on,
           g.goal_target,
           g.archived_at,
           gm.role    as member_role,
           gm.joined_at,
           (select count (*)::int
              from public.group_members gm2
             where gm2.group_id = g.id) as member_count,
           (select coalesce (bool_or (gf.is_featured), false)
              from public.group_featured gf
             where gf.group_id = g.id) as is_featured
      from public.group_members gm
      join public.groups g on g.id = gm.group_id
     where gm.user_id = v_uid
       and g.archived_at is null
       and (g.group_type <> 'challenge' or g.ends_on is null or g.ends_on >= current_date)
       and not (g.created_by is not null and private.is_blocked_impl (v_uid, g.created_by))
  )
  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'id',                  m.id,
               'name',                m.name,
               'description',         m.description,
               'group_type',          m.group_type,
               'scoring_mode',        m.scoring_mode,
               'sharing_requirement', m.sharing_requirement,
               'cover_path',          m.cover_path,
               'starts_on',           m.starts_on,
               'ends_on',             m.ends_on,
               'goal_target',         m.goal_target,
               'member_count',        m.member_count,
               'role',                m.member_role,
               'is_featured',         m.is_featured,
               'invite_code',         case when m.member_role = 'admin' then m.invite_code else null end,
               'archived_at',         m.archived_at
             )
             order by
               (case when m.group_type = 'challenge' and m.ends_on >= current_date then 0 else 1 end),
               m.joined_at desc,
               m.id
           ),
           '[]'::jsonb
         )
    into v_items
    from mine m;

  return jsonb_build_object ('items', v_items);
end;
$$;

comment on function private.my_groups_impl () is
  'Implementation of public.my_groups(). Returns { "items": [...] } with the ACTIVE groups of the caller (not archived; a challenge whose season has ended is excluded). `invite_code` is present ONLY for the group admin.';

create or replace function public.my_groups ()
  returns jsonb
  language plpgsql
  stable
  set search_path = ''
as $$
begin
  return private.my_groups_impl ();
end;
$$;

comment on function public.my_groups () is
  'The caller''s ACTIVE groups in ONE call: { "items": [ { id, name, description, group_type, scoring_mode, sharing_requirement, cover_path, starts_on, ends_on, goal_target, member_count, role, is_featured, invite_code, archived_at } ] }. `invite_code` is returned ONLY to the group admin (a member always gets null). Archived groups and challenges whose season has ended are excluded. Ordered: running challenge first, then most recently joined, then id.';

-- The privileged body lives in `private`; the public function is a thin
-- INVOKER wrapper, so the security advisor sees no SECURITY DEFINER function
-- in the exposed schema.
revoke all on function private.my_groups_impl () from public, anon;
grant execute on function private.my_groups_impl () to authenticated, service_role;

revoke all on function public.my_groups () from public, anon;
grant execute on function public.my_groups () to authenticated, service_role;
