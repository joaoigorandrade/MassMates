-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022030101  ("fix_set_updated_at")
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
-- A3 · 0209 · fix public.set_updated_at() for tables without an updated_at
-- =============================================================================
-- FOUND BY A3 (reported to the orchestrator).
--
-- A1's migration 0007 attached `trg_group_members_updated_at` to
-- public.group_members, but public.group_members has NO `updated_at` column
-- (SCHEMA.md §2.3). public.set_updated_at() does `new.updated_at := now()`
-- unconditionally, so EVERY UPDATE on public.group_members raises
--
--   ERROR:  record "new" has no field "updated_at"   (SQLSTATE 42703)
--
-- That breaks A1's own `group_members_update_admin` policy and A3's
-- public.transfer_admin() (the admin role can never be moved).
--
-- The fix is in the trigger FUNCTION, not in the table: the column is only
-- written when the relation really has one. Tables WITH an updated_at column
-- (profiles, groups, practice_points, ...) behave exactly as before.
-- -----------------------------------------------------------------------------

create or replace function public.set_updated_at ()
  returns trigger
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  if exists (
    select 1
    from pg_catalog.pg_attribute a
    where a.attrelid = tg_relid
      and a.attname = 'updated_at'
      and not a.attisdropped
  ) then
    new.updated_at := now();
  end if;
  return new;
end;
$$;

comment on function public.set_updated_at () is
  'BEFORE UPDATE trigger that keeps updated_at current — but only when the relation actually has an updated_at column. public.group_members has the trigger but no such column, so the old unconditional assignment made every UPDATE on it fail with 42703.';

-- the trigger stays in place (A1's contract lists it), it is now a no-op there
select public.attach_updated_at ('public.group_members'::regclass);
