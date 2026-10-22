-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025500  ("create_feed_prayer_chat_tables")
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
-- A5 · 0401 · Feed, Prayer Wall, Chat & Pinned Notices — tables, indexes, RLS
-- =============================================================================
-- Owner: A5 (prefix range 0400-0499).
--
-- Tables created here:
--   public.feed_posts       — group feed derived from SHARED check-ins
--   public.amen_reactions   — "Amen" / "United in Prayer" reactions
--   public.prayer_intentions— the Prayer Wall (public prayer requests)
--   public.intention_prayers— the "I Prayed for You" counter rows
--   public.chat_messages    — realtime group chat
--   public.pinned_notices   — one active pinned notice per group
--
-- SACRED PRIVACY (CONVENTIONS §8)
--   * No table below may hold Confession records, Spiritual Diary text or
--     private-only ("Only in My Private Diary") check-in content.
--   * feed_posts is fed ONLY by A4's fan-out trigger on check_in_destinations,
--     which already refuses to fan out a private (or confession) check-in.
--   * The hard guarantee is the CHECK constraint feed_posts_no_confession:
--     practice_kind <> 'confession'. A confession check-in can NEVER reach the
--     feed, even if a future writer tries.
--   * prayer_intentions is a PUBLIC prayer request by design. The Spiritual
--     Diary never reaches the backend — see the table comment.
-- -----------------------------------------------------------------------------

-- The `private` schema holds implementation helpers that must NOT be exposed
-- through PostgREST. A3 created it; A5 reuses it (never drops it).
create schema if not exists private;
revoke all on schema private from public;

-- -----------------------------------------------------------------------------
-- public.feed_posts
-- -----------------------------------------------------------------------------
create table public.feed_posts (
  id              uuid primary key default gen_random_uuid(),
  check_in_id     uuid references public.check_ins (id) on delete cascade,
  group_id        uuid not null references public.groups (id) on delete cascade,
  user_id         uuid not null references public.profiles (id) on delete cascade,
  practice_kind   public.practice_kind not null,
  reflection_text text check (reflection_text is null or char_length (reflection_text) <= 2000),
  photo_path      text,
  points          integer not null default 0 check (points >= 0),
  is_hidden       boolean not null default false,
  hidden_reason   text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint feed_posts_no_confession
    check (practice_kind <> 'confession'::public.practice_kind)
);

comment on table public.feed_posts is
  'Group feed. Rows are created ONLY by A4''s fan-out trigger on check_in_destinations, i.e. only from check-ins explicitly SHARED with a group. Holds NO confession, NO spiritual diary text and NO private-only check-in content — the CHECK constraint feed_posts_no_confession makes practice_kind = ''confession'' impossible here (sacred privacy, CONVENTIONS §8).';

comment on column public.feed_posts.check_in_id is
  'Origin check-in (A4). NULL is allowed so the table can exist before A4''s check_ins table; the FK is added by migration 0405 when check_ins exists.';

comment on column public.feed_posts.photo_path is
  'Storage object path inside the `witness-photos` bucket (bucket owned by A6). NOT a URL.';

comment on column public.feed_posts.is_hidden is
  'True when the post is hidden from plain members (auto-hide after N reports — A6; or admin removal via public.soft_delete_feed_post). A group admin still sees it.';

comment on column public.feed_posts.hidden_reason is
  'Why the post is hidden. ''admin_removed'' is written by public.soft_delete_feed_post; A6 may use its own reasons.';

create index idx_feed_posts_group_created_at
  on public.feed_posts (group_id, created_at desc);
create index idx_feed_posts_user_created_at
  on public.feed_posts (user_id, created_at desc);
create index idx_feed_posts_visible_group_created_at
  on public.feed_posts (group_id, created_at desc) where not is_hidden;
create index idx_feed_posts_check_in_id
  on public.feed_posts (check_in_id);

-- -----------------------------------------------------------------------------
-- public.amen_reactions
-- -----------------------------------------------------------------------------
create table public.amen_reactions (
  id            uuid primary key default gen_random_uuid(),
  post_id       uuid not null references public.feed_posts (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  reaction_type text not null default 'amen'
    check (reaction_type in ('amen', 'united_in_prayer')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (post_id, user_id, reaction_type)
);

comment on table public.amen_reactions is
  'Reactions on a feed post: ''amen'' and ''united_in_prayer''. One row per (post, user, type). Part of the supabase_realtime publication.';

comment on column public.amen_reactions.user_id is
  'The reactor. The row itself carries no free text — a reaction is never confession or diary content.';

create index idx_amen_reactions_post_id on public.amen_reactions (post_id);
create index idx_amen_reactions_user_id on public.amen_reactions (user_id);

-- -----------------------------------------------------------------------------
-- public.prayer_intentions — the Prayer Wall
-- -----------------------------------------------------------------------------
create table public.prayer_intentions (
  id            uuid primary key default gen_random_uuid(),
  group_id      uuid not null references public.groups (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  body          text not null check (char_length (body) between 1 and 1000),
  prayer_count  integer not null default 0 check (prayer_count >= 0),
  is_hidden     boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.prayer_intentions is
  'The Prayer Wall: a PUBLIC prayer request posted by a member of a group, visible to that group''s members. It is NOT a Spiritual Diary entry — the Spiritual Diary never reaches the backend, and no confession or private check-in content may be written here. prayer_count is maintained by the trigger trg_intention_prayers_count and must not be written by clients.';

comment on column public.prayer_intentions.prayer_count is
  'Number of distinct members who pressed "I Prayed for You". Maintained by a trigger (AFTER INSERT +1 / AFTER DELETE -1 on public.intention_prayers). Clients may not write it.';

comment on column public.prayer_intentions.is_hidden is
  'True when the intention is hidden from plain members (moderation — A6). A group admin still sees it.';

create index idx_prayer_intentions_group_created_at
  on public.prayer_intentions (group_id, created_at desc);
create index idx_prayer_intentions_user_id on public.prayer_intentions (user_id);

-- -----------------------------------------------------------------------------
-- public.intention_prayers
-- -----------------------------------------------------------------------------
create table public.intention_prayers (
  id           uuid primary key default gen_random_uuid(),
  intention_id uuid not null references public.prayer_intentions (id) on delete cascade,
  prayer_id    uuid not null references public.profiles (id) on delete cascade,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (intention_id, prayer_id)
);

comment on table public.intention_prayers is
  'One row per member who pressed "I Prayed for You" on a prayer intention. The visible counter lives on public.prayer_intentions.prayer_count. Part of the supabase_realtime publication.';

create index idx_intention_prayers_intention_id on public.intention_prayers (intention_id);
create index idx_intention_prayers_prayer_id on public.intention_prayers (prayer_id);

-- -----------------------------------------------------------------------------
-- public.chat_messages
-- -----------------------------------------------------------------------------
create table public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  group_id    uuid not null references public.groups (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  body        text not null check (char_length (body) between 1 and 2000),
  reply_to_id uuid references public.chat_messages (id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.chat_messages is
  'Group chat for logistics and encouragement. Messages are immutable (no UPDATE policy). Part of the supabase_realtime publication.';

create index idx_chat_messages_group_created_at
  on public.chat_messages (group_id, created_at);
create index idx_chat_messages_user_id on public.chat_messages (user_id);
create index idx_chat_messages_reply_to_id on public.chat_messages (reply_to_id);

-- -----------------------------------------------------------------------------
-- public.pinned_notices
-- -----------------------------------------------------------------------------
create table public.pinned_notices (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references public.groups (id) on delete cascade,
  author_id  uuid not null references public.profiles (id) on delete cascade,
  body       text not null check (char_length (body) between 1 and 500),
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.pinned_notices is
  'Weekly announcements / parish schedules pinned at the top of a group. At most ONE active notice per group (partial unique index uq_pinned_notices_active_group). Only a group admin may write.';

create unique index uq_pinned_notices_active_group
  on public.pinned_notices (group_id) where is_active;
create index idx_pinned_notices_group_id on public.pinned_notices (group_id);

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------
select public.attach_updated_at ('public.feed_posts'::regclass);
select public.attach_updated_at ('public.amen_reactions'::regclass);
select public.attach_updated_at ('public.prayer_intentions'::regclass);
select public.attach_updated_at ('public.intention_prayers'::regclass);
select public.attach_updated_at ('public.chat_messages'::regclass);
select public.attach_updated_at ('public.pinned_notices'::regclass);

-- The "I Prayed for You" counter.
create or replace function private.a5_sync_intention_prayer_count ()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.prayer_intentions
       set prayer_count = prayer_count + 1,
           updated_at = now()
     where id = new.intention_id;
    return new;
  end if;

  update public.prayer_intentions
     set prayer_count = greatest (0, prayer_count - 1),
         updated_at = now()
   where id = old.intention_id;
  return old;
end;
$$;

comment on function private.a5_sync_intention_prayer_count () is
  'Keeps public.prayer_intentions.prayer_count in sync with public.intention_prayers (AFTER INSERT +1, AFTER DELETE -1). SECURITY DEFINER so the counter can be written even though clients have no UPDATE privilege on the column. Never lets the counter fall below 0.';

revoke execute on function private.a5_sync_intention_prayer_count () from public, anon, authenticated, service_role;

create trigger trg_intention_prayers_count
  after insert or delete on public.intention_prayers
  for each row execute function private.a5_sync_intention_prayer_count ();

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
alter table public.feed_posts        enable row level security;
alter table public.feed_posts        force  row level security;
alter table public.amen_reactions    enable row level security;
alter table public.amen_reactions    force  row level security;
alter table public.prayer_intentions enable row level security;
alter table public.prayer_intentions force  row level security;
alter table public.intention_prayers enable row level security;
alter table public.intention_prayers force  row level security;
alter table public.chat_messages     enable row level security;
alter table public.chat_messages     force  row level security;
alter table public.pinned_notices    enable row level security;
alter table public.pinned_notices    force  row level security;

-- feed_posts -----------------------------------------------------------------
-- A member of the group sees the post, unless one of them blocked the other.
-- A hidden post stays visible to the group admins only.
create policy feed_posts_select_members
  on public.feed_posts
  for select
  to authenticated
  using (
    public.is_group_member (group_id, (select auth.uid ()))
    and not public.is_blocked ((select auth.uid ()), user_id)
    and (not is_hidden or public.is_group_admin (group_id, (select auth.uid ())))
  );

-- No INSERT / UPDATE / DELETE policy: writes go through A4's fan-out trigger
-- (which runs as the table owner) and through A5's security definer RPCs.

-- amen_reactions ------------------------------------------------------------
create policy amen_reactions_select_members
  on public.amen_reactions
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.feed_posts p
      where p.id = amen_reactions.post_id
        and public.is_group_member (p.group_id, (select auth.uid ()))
        and not public.is_blocked ((select auth.uid ()), p.user_id)
        and not public.is_blocked ((select auth.uid ()), amen_reactions.user_id)
    )
  );

create policy amen_reactions_insert_own
  on public.amen_reactions
  for insert
  to authenticated
  with check (
    user_id = (select auth.uid ())
    and exists (
      select 1
      from public.feed_posts p
      where p.id = amen_reactions.post_id
        and public.is_group_member (p.group_id, (select auth.uid ()))
        and not public.is_blocked ((select auth.uid ()), p.user_id)
    )
  );

create policy amen_reactions_delete_own
  on public.amen_reactions
  for delete
  to authenticated
  using (user_id = (select auth.uid ()));

-- prayer_intentions ---------------------------------------------------------
create policy prayer_intentions_select_members
  on public.prayer_intentions
  for select
  to authenticated
  using (
    public.is_group_member (group_id, (select auth.uid ()))
    and not public.is_blocked ((select auth.uid ()), user_id)
    and (not is_hidden or public.is_group_admin (group_id, (select auth.uid ())))
  );

create policy prayer_intentions_insert_own
  on public.prayer_intentions
  for insert
  to authenticated
  with check (
    user_id = (select auth.uid ())
    and public.is_group_member (group_id, (select auth.uid ()))
  );

create policy prayer_intentions_update_own
  on public.prayer_intentions
  for update
  to authenticated
  using (user_id = (select auth.uid ()))
  with check (user_id = (select auth.uid ()));

create policy prayer_intentions_delete_own_or_admin
  on public.prayer_intentions
  for delete
  to authenticated
  using (
    user_id = (select auth.uid ())
    or public.is_group_admin (group_id, (select auth.uid ()))
  );

-- intention_prayers ---------------------------------------------------------
create policy intention_prayers_select_members
  on public.intention_prayers
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.prayer_intentions i
      where i.id = intention_prayers.intention_id
        and public.is_group_member (i.group_id, (select auth.uid ()))
        and not public.is_blocked ((select auth.uid ()), i.user_id)
        and not public.is_blocked ((select auth.uid ()), intention_prayers.prayer_id)
    )
  );

create policy intention_prayers_insert_own
  on public.intention_prayers
  for insert
  to authenticated
  with check (
    prayer_id = (select auth.uid ())
    and exists (
      select 1
      from public.prayer_intentions i
      where i.id = intention_prayers.intention_id
        and public.is_group_member (i.group_id, (select auth.uid ()))
        and not public.is_blocked ((select auth.uid ()), i.user_id)
    )
  );

create policy intention_prayers_delete_own
  on public.intention_prayers
  for delete
  to authenticated
  using (prayer_id = (select auth.uid ()));

-- chat_messages -------------------------------------------------------------
create policy chat_messages_select_members
  on public.chat_messages
  for select
  to authenticated
  using (
    public.is_group_member (group_id, (select auth.uid ()))
    and not public.is_blocked ((select auth.uid ()), user_id)
  );

create policy chat_messages_insert_own
  on public.chat_messages
  for insert
  to authenticated
  with check (
    user_id = (select auth.uid ())
    and public.is_group_member (group_id, (select auth.uid ()))
  );

create policy chat_messages_delete_own_or_admin
  on public.chat_messages
  for delete
  to authenticated
  using (
    user_id = (select auth.uid ())
    or public.is_group_admin (group_id, (select auth.uid ()))
  );

-- pinned_notices ------------------------------------------------------------
create policy pinned_notices_select_members
  on public.pinned_notices
  for select
  to authenticated
  using (public.is_group_member (group_id, (select auth.uid ())));

create policy pinned_notices_insert_admin
  on public.pinned_notices
  for insert
  to authenticated
  with check (public.is_group_admin (group_id, (select auth.uid ())));

create policy pinned_notices_update_admin
  on public.pinned_notices
  for update
  to authenticated
  using (public.is_group_admin (group_id, (select auth.uid ())))
  with check (public.is_group_admin (group_id, (select auth.uid ())));

create policy pinned_notices_delete_admin
  on public.pinned_notices
  for delete
  to authenticated
  using (public.is_group_admin (group_id, (select auth.uid ())));

-- -----------------------------------------------------------------------------
-- Column-level privileges
-- -----------------------------------------------------------------------------
-- Clients may edit the TEXT of their own intention / notice, but they may never
-- write the counter or the moderation flags (those are server-owned).
revoke update on public.prayer_intentions from authenticated;
grant update (body) on public.prayer_intentions to authenticated;

revoke update on public.pinned_notices from authenticated;
grant update (body) on public.pinned_notices to authenticated;

-- -----------------------------------------------------------------------------
-- Deferred FK to A4's check_ins
-- -----------------------------------------------------------------------------
-- A4 owns public.check_ins. When it exists the FK is created right away;
-- otherwise migration 0405 adds it. The column stays NULLable either way.
do $$
begin
  if to_regclass ('public.check_ins') is not null then
    if not exists (
      select 1
      from pg_constraint c
      join pg_class r on r.oid = c.conrelid
      where r.relname = 'feed_posts'
        and c.conname = 'feed_posts_check_in_id_fkey'
    ) then
      execute 'alter table public.feed_posts
                 add constraint feed_posts_check_in_id_fkey
                 foreign key (check_in_id)
                 references public.check_ins (id) on delete cascade';
    end if;
  end if;
end;
$$;
