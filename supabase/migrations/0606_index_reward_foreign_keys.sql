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
