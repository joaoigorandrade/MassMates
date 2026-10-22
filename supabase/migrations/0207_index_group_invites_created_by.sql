-- =============================================================================
-- A3 · 0207 · index the group_invites.created_by foreign key
-- =============================================================================
-- The performance advisor flags `unindexed_foreign_keys` on
-- public.group_invites: `created_by` references public.profiles(id) and had
-- no index backing it.
-- -----------------------------------------------------------------------------

create index if not exists idx_group_invites_created_by on public.group_invites (created_by);
