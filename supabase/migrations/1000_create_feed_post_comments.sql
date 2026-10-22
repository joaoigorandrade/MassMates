-- =============================================================================
-- 1000 · create_feed_post_comments
-- =============================================================================
-- Gap closure (A9 report): the product plan requires that members can "leave
-- encouraging comments" on a feed post. Until now the comment was a silent
-- no-op because the table did not exist.
--
-- PRIVACY (CONVENTIONS §8 / SCHEMA.md §8):
--   A comment is PUBLIC GROUP CONTENT by design. It can never hold a
--   Spiritual Diary text, a Confession record or a "private" check-in
--   reflection -- those never leave the device (public.feed_posts carries a
--   `feed_posts_no_confession` CHECK, and public.check_ins carries
--   `check_ins_private_has_no_content_ck`).
--
-- APPEND-ONLY:
--   There is no `updated_at` column and no `public.attach_updated_at` trigger
--   (mirrors public.moderation_actions). The body may still be edited by its
--   author; the moderation state is server-owned.
-- =============================================================================

create table public.feed_post_comments (
  id            uuid primary key default gen_random_uuid(),
  post_id       uuid not null references public.feed_posts (id) on delete cascade,
  group_id      uuid not null references public.groups (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  body          text not null check (char_length (body) between 1 and 500),
  is_hidden     boolean not null default false,
  hidden_reason text,
  hidden_at     timestamptz,
  created_at    timestamptz not null default now()
);

comment on table public.feed_post_comments is
  'Encouraging comments on a community-feed post. A comment is PUBLIC GROUP CONTENT by design: it is readable by every member of the post''s group (unless a block applies) and it must never hold Spiritual Diary text, a Confession record or a private check-in reflection -- those stay on the device. Append-only: no updated_at column and no updated_at trigger (mirrors public.moderation_actions).';

comment on column public.feed_post_comments.body is
  'The comment text. 1..500 characters, enforced by a CHECK constraint. Empty and over-long bodies are rejected by the database AND by public.create_feed_post_comment().';

comment on column public.feed_post_comments.is_hidden is
  'Server-owned moderation flag. Set by public.soft_delete_feed_post_comment() (group admin). A hidden comment stays visible to the group admins.';

-- -----------------------------------------------------------------------------
-- Indexes
--   * (post_id, created_at desc, id desc) -> the comment pagination of
--     public.get_feed_post_comments() (cursor order: created_at DESC, id DESC)
--   * (group_id, created_at desc)         -> the group-scoped comment list
--   * partial (group_id, created_at desc) where is_hidden -> the moderation
--     query of a group admin
-- -----------------------------------------------------------------------------

create index idx_feed_post_comments_post_created_at
  on public.feed_post_comments (post_id, created_at desc, id desc);

create index idx_feed_post_comments_group_created_at
  on public.feed_post_comments (group_id, created_at desc);

create index idx_feed_post_comments_hidden
  on public.feed_post_comments (group_id, created_at desc)
  where is_hidden;

-- -----------------------------------------------------------------------------
-- RLS -- enabled AND forced (SCHEMA.md §4: every public table is forced).
-- The single-argument helpers (public.is_group_member / is_group_admin /
-- is_blocked) are self-scoped: they always evaluate against auth.uid().
-- -----------------------------------------------------------------------------

alter table public.feed_post_comments enable row level security;
alter table public.feed_post_comments force row level security;

create policy feed_post_comments_select_members
  on public.feed_post_comments
  for select
  to authenticated
  using (
    public.is_group_member (group_id)
    and not public.is_blocked (user_id)
    and (not is_hidden or public.is_group_admin (group_id))
  );

create policy feed_post_comments_insert_own
  on public.feed_post_comments
  for insert
  to authenticated
  with check (
    user_id = (select auth.uid ())
    and public.is_group_member (group_id)
  );

create policy feed_post_comments_update_own
  on public.feed_post_comments
  for update
  to authenticated
  using (user_id = (select auth.uid ()))
  with check (user_id = (select auth.uid ()));

create policy feed_post_comments_delete_own_or_admin
  on public.feed_post_comments
  for delete
  to authenticated
  using (user_id = (select auth.uid ()) or public.is_group_admin (group_id));

-- -----------------------------------------------------------------------------
-- Table privileges
--   anon         -> nothing
--   authenticated -> SELECT, INSERT (own columns), UPDATE (body only), DELETE
--   service_role -> everything (it has BYPASSRLS anyway)
-- The column-level UPDATE grant is what makes the moderation columns
-- server-owned: a client may edit the body of its own comment, never
-- `is_hidden` / `hidden_reason` / `hidden_at`.
-- -----------------------------------------------------------------------------

revoke all on public.feed_post_comments from anon;
revoke all on public.feed_post_comments from authenticated;

grant select on public.feed_post_comments to authenticated;
grant insert (post_id, group_id, user_id, body) on public.feed_post_comments to authenticated;
grant update (body) on public.feed_post_comments to authenticated;
grant delete on public.feed_post_comments to authenticated;

grant all on public.feed_post_comments to service_role;
