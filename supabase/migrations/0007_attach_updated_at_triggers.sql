-- =============================================================================
-- A1 · 0007 · Attach the updated_at triggers
-- =============================================================================
-- Convention (supabase/SCHEMA.md §5): every table that has an `updated_at`
-- column gets a BEFORE UPDATE trigger named `trg_<table>_updated_at` that
-- calls public.set_updated_at().
--
-- The trigger is created through public.attach_updated_at(), which is
-- SECURITY INVOKER and must run as the table owner (this migration runs as
-- `postgres`).
--
-- Copy/paste for a new table (you own it):
--   select public.attach_updated_at('public.your_table'::regclass);
-- -----------------------------------------------------------------------------

select public.attach_updated_at ('public.profiles'::regclass);
select public.attach_updated_at ('public.groups'::regclass);
select public.attach_updated_at ('public.group_members'::regclass);
select public.attach_updated_at ('public.practice_points'::regclass);

-- user_blocks and audit_log have no updated_at column (append-only /
-- immutable-by-design), so they get no trigger.
