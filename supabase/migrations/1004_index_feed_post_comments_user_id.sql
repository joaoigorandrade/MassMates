-- =============================================================================
-- 1004 · index_feed_post_comments_user_id
-- =============================================================================
-- The `unindexed_foreign_keys` lint reported the `user_id` foreign key of
-- public.feed_post_comments without a covering index. The project keeps this
-- lint at ZERO (A8 fixed the same lint in migration 0706), so the index is
-- added here.
--
-- It also backs a documented lookup path: "the comments of a user" (used by
-- the moderation trail of a group and by the "my comments" filter of the
-- client).
-- =============================================================================

create index idx_feed_post_comments_user_id
  on public.feed_post_comments (user_id);
