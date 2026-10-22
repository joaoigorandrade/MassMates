-- =============================================================================
-- A8 · 0706 · index the foreign keys the performance advisor flagged
-- =============================================================================
-- Owner: A8.
--
-- get_advisors({type:"performance"}) reported two `unindexed_foreign_keys`
-- findings on A8 tables:
--   public.guardian_nudges      -> guardian_nudges_group_id_fkey
--   public.notification_outbox -> notification_outbox_group_id_fkey
-- Every foreign key needs a covering index (SCHEMA.md §11).
-- -----------------------------------------------------------------------------

create index if not exists idx_guardian_nudges_group_id
  on public.guardian_nudges (group_id);

create index if not exists idx_notification_outbox_group_id
  on public.notification_outbox (group_id);
