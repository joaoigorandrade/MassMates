-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022030912  ("0606_index_reward_foreign_keys")
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
-- A7 · 0606 · Index the foreign keys flagged by the performance advisor
-- =============================================================================
-- Owner: A7 (liturgical content & monetization).
--
-- Every foreign key needs a covering index, otherwise the advisor reports
-- `unindexed_foreign_keys` and the ON DELETE CASCADE check has to scan the
-- table. Two of my tables were missing one:
--   * public.ssv_receipts.user_id        -> public.profiles(id)
--   * public.user_saint_unlocks.saint_icon_id -> public.saint_icons(id)
-- -----------------------------------------------------------------------------

create index if not exists idx_ssv_receipts_user_id
  on public.ssv_receipts (user_id);

create index if not exists idx_user_saint_unlocks_saint_icon_id
  on public.user_saint_unlocks (saint_icon_id);
