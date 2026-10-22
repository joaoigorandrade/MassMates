-- =============================================================================
-- A1 · 0005 · Row Level Security — baseline policies
-- =============================================================================
-- RLS is ENABLED and FORCED on every foundation table.
--
-- Note on FORCE RLS: the owner role `postgres` has BYPASSRLS on this project,
-- so FORCE does not restrict the owner. It is still declared so the tables
-- behave identically on a project where the owner does not bypass RLS.
-- A2's `handle_new_user` trigger MUST be SECURITY DEFINER (it is), which is
-- what makes the profile INSERT legal on a FORCE RLS table.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.profiles force  row level security;

-- A user can read their own profile, or the profile of somebody they share a
-- group with. No INSERT policy (A2's handle_new_user trigger inserts as
-- definer) and no DELETE policy (A2's account-deletion flow owns deletes).
create policy profiles_select_shared_or_own
  on public.profiles
  for select
  to authenticated
  using (
    id = (select auth.uid())
    or exists (
      select 1
      from public.group_members gm
      join public.group_members mine on mine.group_id = gm.group_id
      where gm.user_id  = public.profiles.id
        and mine.user_id = (select auth.uid())
    )
  );

create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- groups
-- -----------------------------------------------------------------------------
alter table public.groups enable row level security;
alter table public.groups force  row level security;

-- Any authenticated user can read a group that is not archived; members can
-- always read their own (archived or not).
create policy groups_select_visible
  on public.groups
  for select
  to authenticated
  using (
    archived_at is null
    or public.is_group_member (public.groups.id)
  );

create policy groups_insert_own
  on public.groups
  for insert
  to authenticated
  with check (created_by = (select auth.uid()));

create policy groups_update_admin
  on public.groups
  for update
  to authenticated
  using (public.is_group_admin (public.groups.id))
  with check (public.is_group_admin (public.groups.id));

create policy groups_delete_admin
  on public.groups
  for delete
  to authenticated
  using (public.is_group_admin (public.groups.id));

-- -----------------------------------------------------------------------------
-- group_members
-- -----------------------------------------------------------------------------
alter table public.group_members enable row level security;
alter table public.group_members force  row level security;

-- Members of a group can see the roster of that group.
create policy group_members_select_members
  on public.group_members
  for select
  to authenticated
  using (public.is_group_member (public.group_members.group_id));

-- Self-join only. A3's join_group_by_code() RPC (security definer) is the
-- real entry point and may add a member on the user's behalf.
create policy group_members_insert_self
  on public.group_members
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy group_members_update_admin
  on public.group_members
  for update
  to authenticated
  using (public.is_group_admin (public.group_members.group_id))
  with check (public.is_group_admin (public.group_members.group_id));

create policy group_members_delete_admin_or_self
  on public.group_members
  for delete
  to authenticated
  using (
    public.is_group_admin (public.group_members.group_id)
    or user_id = (select auth.uid())
  );

-- -----------------------------------------------------------------------------
-- user_blocks
-- -----------------------------------------------------------------------------
alter table public.user_blocks enable row level security;
alter table public.user_blocks force  row level security;

-- A user can only see their OWN blocks (never the blocks others placed on them).
create policy user_blocks_select_own
  on public.user_blocks
  for select
  to authenticated
  using (blocker_id = (select auth.uid()));

create policy user_blocks_insert_own
  on public.user_blocks
  for insert
  to authenticated
  with check (blocker_id = (select auth.uid()));

create policy user_blocks_delete_own
  on public.user_blocks
  for delete
  to authenticated
  using (blocker_id = (select auth.uid()));
