-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025312  ("index_group_invites_created_by")
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
-- A3 · 0207 · index the group_invites.created_by foreign key
-- =============================================================================
-- The performance advisor flags `unindexed_foreign_keys` on
-- public.group_invites: `created_by` references public.profiles(id) and had
-- no index backing it.
-- -----------------------------------------------------------------------------

create index if not exists idx_group_invites_created_by on public.group_invites (created_by);
