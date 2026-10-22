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
