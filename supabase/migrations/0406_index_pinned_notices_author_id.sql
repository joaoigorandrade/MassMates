-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022030433  ("index_pinned_notices_author_id")
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
-- A5 · 0406 · Index the pinned_notices.author_id foreign key
-- =============================================================================
-- Owner: A5.
--
-- The performance advisor flagged `unindexed_foreign_keys` for
-- public.pinned_notices.author_id. Every foreign key needs a supporting index
-- or the join / cascade delete has to scan the table.
-- -----------------------------------------------------------------------------

create index if not exists idx_pinned_notices_author_id
  on public.pinned_notices (author_id);
