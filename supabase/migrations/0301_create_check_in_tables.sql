-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025307  ("create_check_in_tables")
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
-- A4 · 0301 · check-in engine tables
-- =============================================================================
-- Owner: A4 (prefix 0300-0399). Columns AND policies are mine.
--
-- SACRED PRIVACY (CONVENTIONS §8) — the two CHECK constraints below are a hard
-- build gate, not decoration:
--   * a `private` check-in may NEVER carry a reflection or a photo;
--   * a `confession` check-in may NEVER be shared with a group.
-- A private check-in also produces ZERO rows in `check_in_destinations`, which
-- is what keeps its content out of every group feed.
-- -----------------------------------------------------------------------------

-- Implementation helpers live in a schema PostgREST does not expose.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to postgres;

-- -----------------------------------------------------------------------------
-- check_ins — the immutable record of a practice being completed
-- -----------------------------------------------------------------------------
create table public.check_ins (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  practice_kind   public.practice_kind not null,
  sharing         text not null check (sharing in ('private', 'group')),
  local_date      date not null,
  timezone        text not null,
  reflection_text text check (char_length(reflection_text) <= 2000),
  photo_path      text check (photo_path is null or photo_path like 'witness-photos/%'),
  points          integer not null default 0 check (points >= 0),
  created_at      timestamptz not null default now(),
  -- one check-in per practice per local calendar day
  constraint check_ins_user_practice_day_uniq unique (user_id, practice_kind, local_date),
  -- PRIVACY GATE 1: a private check-in carries no content, ever.
  constraint check_ins_private_has_no_content_ck check (
    sharing = 'group' or (reflection_text is null and photo_path is null)
  ),
  -- PRIVACY GATE 2: confession is private-only.
  constraint check_ins_confession_is_private_ck check (
    practice_kind <> 'confession' or sharing = 'private'
  )
);

comment on table public.check_ins is
  'One completed spiritual practice. sharing = ''group'' rows may carry a reflection/photo; sharing = ''private'' rows NEVER carry content (check_ins_private_has_no_content_ck) and a ''confession'' practice is private-only (check_ins_confession_is_private_ck). Immutable: no updated_at, no client INSERT/UPDATE policy — writes go through public.submit_check_in().';

comment on column public.check_ins.local_date is
  'The user''s local calendar day, derived from `timezone` (IANA). The streak and the Rule of Life Ring are computed over this column, never over created_at.';
comment on column public.check_ins.timezone is
  'IANA timezone used to compute local_date (e.g. America/Sao_Paulo).';
comment on column public.check_ins.points is
  'MAX points across the destination groups (0 for a private check-in). The per-group contribution is recomputed by public.get_group_progress().';

create index idx_check_ins_user_local_date
  on public.check_ins (user_id, local_date desc);
create index idx_check_ins_user_created_at
  on public.check_ins (user_id, created_at desc);
create index idx_check_ins_group_shared_user_local_date
  on public.check_ins (user_id, local_date desc) where sharing = 'group';

-- -----------------------------------------------------------------------------
-- check_in_destinations — the fan-out of a group-shared check-in
-- -----------------------------------------------------------------------------
create table public.check_in_destinations (
  id          uuid primary key default gen_random_uuid(),
  check_in_id uuid not null references public.check_ins (id) on delete cascade,
  group_id    uuid not null references public.groups (id) on delete cascade,
  created_at  timestamptz not null default now(),
  constraint check_in_destinations_check_in_group_uniq unique (check_in_id, group_id)
);

comment on table public.check_in_destinations is
  'Which groups received a group-shared check-in. A PRIVATE check-in produces ZERO rows here — that is the privacy boundary. Rows are written only by public.submit_check_in().';

create index idx_check_in_destinations_group_id
  on public.check_in_destinations (group_id);

-- -----------------------------------------------------------------------------
-- streaks — the persisted daily streak summary (one row per user)
-- -----------------------------------------------------------------------------
create table public.streaks (
  user_id            uuid primary key references public.profiles (id) on delete cascade,
  current_streak     integer not null default 0 check (current_streak >= 0),
  longest_streak     integer not null default 0 check (longest_streak >= 0),
  last_practice_date date,
  total_practices    integer not null default 0 check (total_practices >= 0),
  updated_at         timestamptz not null default now()
);

comment on table public.streaks is
  'Daily Streak summary: >= 1 practice per day keeps it alive (private OR shared). Recomputed from the authoritative set of active days by private.recompute_streak().';

select public.attach_updated_at ('public.streaks'::regclass);

-- -----------------------------------------------------------------------------
-- streak_mercy_uses — one mercy per calendar month, repairing exactly one day
-- -----------------------------------------------------------------------------
create table public.streak_mercy_uses (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  used_on      date not null,
  repairs_date date not null,
  created_at   timestamptz not null default now(),
  constraint streak_mercy_uses_user_used_on_uniq unique (user_id, used_on),
  constraint streak_mercy_uses_user_repairs_date_uniq unique (user_id, repairs_date)
);

comment on table public.streak_mercy_uses is
  'Consumed Streak Mercy. At most one per calendar month (UNIQUE (user_id, used_on) + the monthly guard in public.use_streak_mercy()); repairs exactly ONE missed day.';

-- -----------------------------------------------------------------------------
-- streak_mercy_grants — A7 writes here to grant a mercy
-- -----------------------------------------------------------------------------
create table public.streak_mercy_grants (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  granted_at timestamptz not null default now(),
  used_at    timestamptz,
  expires_at timestamptz not null default (now() + interval '30 days'),
  constraint streak_mercy_grants_used_after_granted_ck check (
    used_at is null or used_at >= granted_at
  )
);

comment on table public.streak_mercy_grants is
  'Streak Mercy entitlements. A7 (rewards) INSERTS here after a rewarded video; the user then calls public.use_streak_mercy(). Clients cannot self-grant: no INSERT policy for `authenticated` (service_role or public.grant_streak_mercy() only).';

create index idx_streak_mercy_grants_user_id
  on public.streak_mercy_grants (user_id);

-- -----------------------------------------------------------------------------
-- streak_events — audit of every streak transition
-- -----------------------------------------------------------------------------
create table public.streak_events (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  event_type   text not null check (event_type in ('practice', 'mercy', 'reset', 'milestone')),
  local_date   date not null,
  streak_after integer not null check (streak_after >= 0),
  created_at   timestamptz not null default now()
);

comment on table public.streak_events is
  'Append-only audit of streak transitions: practice (every check-in), reset (a gap broke the streak), mercy (a missed day was repaired), milestone (7/14/21... days).';

create index idx_streak_events_user_id
  on public.streak_events (user_id);
create index idx_streak_events_user_local_date
  on public.streak_events (user_id, local_date desc);

-- -----------------------------------------------------------------------------
-- RLS — enabled AND forced on every table
-- -----------------------------------------------------------------------------
alter table public.check_ins             enable row level security;
alter table public.check_ins             force  row level security;
alter table public.check_in_destinations enable row level security;
alter table public.check_in_destinations force  row level security;
alter table public.streaks               enable row level security;
alter table public.streaks               force  row level security;
alter table public.streak_mercy_uses    enable row level security;
alter table public.streak_mercy_uses    force  row level security;
alter table public.streak_mercy_grants  enable row level security;
alter table public.streak_mercy_grants  force  row level security;
alter table public.streak_events         enable row level security;
alter table public.streak_events         force  row level security;

-- A check-in is visible ONLY to its author. Group visibility comes from the
-- feed, not from this table.
create policy check_ins_select_own
  on public.check_ins
  for select
  to authenticated
  using (user_id = (select auth.uid()));

-- No INSERT / UPDATE policy: a client can never forge a check-in (in
-- particular it can never forge a private one). Writes go through
-- public.submit_check_in() (security definer).
create policy check_ins_delete_own
  on public.check_ins
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- Destination rows are readable by the members of the destination group.
create policy check_in_destinations_select_members
  on public.check_in_destinations
  for select
  to authenticated
  using (public.is_group_member (group_id, (select auth.uid())));

-- Streaks: own rows only.
create policy streaks_select_own
  on public.streaks
  for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Streak events: own rows only (this is the user's own audit trail).
create policy streak_events_select_own
  on public.streak_events
  for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Mercy usage: own rows only.
create policy streak_mercy_uses_select_own
  on public.streak_mercy_uses
  for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Mercy grants: the user may see their own entitlements; only service_role
-- may create them (A7). A user must never be able to grant themselves mercy.
create policy streak_mercy_grants_select_own
  on public.streak_mercy_grants
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy streak_mercy_grants_insert_service
  on public.streak_mercy_grants
  for insert
  to service_role
  with check (true);
