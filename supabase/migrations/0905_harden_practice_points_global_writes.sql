-- 0905_harden_practice_points_global_writes.sql
--
-- Fixes a privilege hole found by A4 and confirmed by the orchestrator:
-- `practice_points` write policies allowed the `group_id IS NULL` branch for
-- EVERY authenticated user, so any signed-in member could INSERT/UPDATE/DELETE
-- a GLOBAL point row. A global row is the default applied to every
-- `custom_points` group in the app, so this was a data-tampering vector
-- affecting all groups, not just the caller's own.
--
-- The legitimate write path is `public.set_practice_points(p_group_id, ...)`,
-- an INVOKER wrapper over `private.set_practice_points_impl` (SECURITY DEFINER,
-- therefore RLS-exempt). That implementation already enforces the correct
-- rule: a global row requires `private.is_any_group_admin_impl(caller)`, a
-- group row requires `private.is_group_admin_impl(group_id, caller)`.
-- Tightening the policies therefore does NOT break the sanctioned path.
--
-- SELECT is intentionally unchanged: every authenticated user must be able to
-- READ the global defaults, otherwise `custom_points` groups cannot resolve
-- their point values.

drop policy if exists practice_points_insert_admin on public.practice_points;
drop policy if exists practice_points_update_admin on public.practice_points;
drop policy if exists practice_points_delete_admin on public.practice_points;

create policy practice_points_insert_admin
  on public.practice_points
  for insert
  to authenticated
  with check (group_id is not null and public.is_group_admin(group_id));

create policy practice_points_update_admin
  on public.practice_points
  for update
  to authenticated
  using (group_id is not null and public.is_group_admin(group_id))
  with check (group_id is not null and public.is_group_admin(group_id));

create policy practice_points_delete_admin
  on public.practice_points
  for delete
  to authenticated
  using (group_id is not null and public.is_group_admin(group_id));
