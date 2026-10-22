-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025037  ("create_group_tables")
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
-- A3 · 0201 · group_invites · slot_unlocks · group_featured
-- =============================================================================
-- Owner: A3. Columns AND policies are mine. Do not touch other agents'
-- tables — request a change instead (CONVENTIONS §2).
--
-- Privacy: none of these tables can hold Confession records, Spiritual Diary
-- text or private check-in content (CONVENTIONS §8). They hold group metadata,
-- invite codes and slot bookkeeping only.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- private schema — implementation home for the security-definer internals
-- -----------------------------------------------------------------------------
-- A1's warning: a `security definer` function living in `public` is callable
-- through PostgREST. The public RPCs in 0202-0205 are therefore thin wrappers;
-- every statement that touches a table the caller cannot read lives here.
-- `private` is NOT an exposed API schema, so nothing in it is reachable from
-- the REST API.
create schema if not exists private;

revoke all on schema private from public;

comment on schema private is
  'A3 implementation schema. SECURITY DEFINER internals for the group / invite / slot RPCs. Not an exposed PostgREST schema; USAGE is never granted to anon or authenticated.';

-- -----------------------------------------------------------------------------
-- public.group_invites — audit trail of every invite code ever issued
-- -----------------------------------------------------------------------------
create table public.group_invites (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references public.groups (id) on delete cascade,
  code       text not null check (code ~ '^[0-9]{6}$'),
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revoked_at timestamptz,
  max_uses   integer not null default 0 check (max_uses >= 0),
  uses       integer not null default 0 check (uses >= 0),
  constraint group_invites_usage_check check (max_uses = 0 or uses <= max_uses)
);

comment on table public.group_invites is
  'Audit trail of the 6-digit invite codes issued for a group. max_uses = 0 means unlimited. A row with revoked_at set is a retired code and can no longer be used to join.';

create index idx_group_invites_group_id on public.group_invites (group_id);
create index idx_group_invites_code      on public.group_invites (code);

-- -----------------------------------------------------------------------------
-- public.slot_unlocks — rewarded / bonus group slots
-- -----------------------------------------------------------------------------
create table public.slot_unlocks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  kind       text not null check (kind in ('group_slot', 'streak_mercy', 'saint_theme')),
  source     text not null check (source in ('rewarded_video', 'admin_grant', 'sponsored')),
  starts_at  timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  notes      text check (char_length(notes) <= 500)
);

comment on table public.slot_unlocks is
  'Rewarded / granted entitlements. kind = group_slot grants one extra personal group slot until expires_at (30 days after a rewarded video). A NULL expires_at means no expiry.';

-- NOT unique: a partial unique index on (user_id, kind) WHERE expires_at IS NULL
-- OR expires_at > now() is impossible because now() is not immutable.
-- The "no double grant" rule is enforced inside public.grant_slot_unlock().
create index idx_slot_unlocks_user_kind on public.slot_unlocks (user_id, kind);

-- -----------------------------------------------------------------------------
-- public.group_featured — the "Featured Seasonal Challenge" link table
-- -----------------------------------------------------------------------------
-- A7 owns public.sponsored_challenges and FKs to THIS table, so it must exist
-- in A3's first migration.
create table public.group_featured (
  group_id      uuid primary key references public.groups (id) on delete cascade,
  is_featured   boolean not null default true,
  starts_on     date,
  ends_on       date,
  display_order integer not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint group_featured_dates_check check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

comment on table public.group_featured is
  'Marks a group as a discoverable Featured Seasonal Challenge. Only challenge groups belong here (enforced by public.set_featured_group()). A7 FKs public.sponsored_challenges to this table.';

create index idx_group_featured_display_order on public.group_featured (display_order);

-- -----------------------------------------------------------------------------
-- updated_at triggers (A1's convention)
-- -----------------------------------------------------------------------------
select public.attach_updated_at ('public.group_invites'::regclass);
select public.attach_updated_at ('public.slot_unlocks'::regclass);
select public.attach_updated_at ('public.group_featured'::regclass);

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
alter table public.group_invites  enable row level security;
alter table public.group_invites  force  row level security;
alter table public.slot_unlocks   enable row level security;
alter table public.slot_unlocks   force  row level security;
alter table public.group_featured enable row level security;
alter table public.group_featured force  row level security;

-- group_invites: only the admins of the group see the invite audit trail.
create policy group_invites_select_admins
  on public.group_invites
  for select
  to authenticated
  using (public.is_group_admin (group_id));

create policy group_invites_insert_service
  on public.group_invites
  for insert
  to service_role
  with check (true);

create policy group_invites_update_service
  on public.group_invites
  for update
  to service_role
  using (true)
  with check (true);

-- slot_unlocks: strictly the owner's rows.
create policy slot_unlocks_select_own
  on public.slot_unlocks
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy slot_unlocks_insert_service
  on public.slot_unlocks
  for insert
  to service_role
  with check (true);

create policy slot_unlocks_update_service
  on public.slot_unlocks
  for update
  to service_role
  using (true)
  with check (true);

create policy slot_unlocks_delete_service
  on public.slot_unlocks
  for delete
  to service_role
  using (true);

-- group_featured: a public discovery list — readable by everybody, writable by
-- the server only (public.set_featured_group()).
create policy group_featured_select_authenticated
  on public.group_featured
  for select
  to authenticated
  using (true);

create policy group_featured_select_anon
  on public.group_featured
  for select
  to anon
  using (true);

create policy group_featured_insert_service
  on public.group_featured
  for insert
  to service_role
  with check (true);

create policy group_featured_update_service
  on public.group_featured
  for update
  to service_role
  using (true)
  with check (true);

create policy group_featured_delete_service
  on public.group_featured
  for delete
  to service_role
  using (true);

-- -----------------------------------------------------------------------------
-- Grants
-- -----------------------------------------------------------------------------
-- The platform's default privileges give every table in `public` to anon /
-- authenticated / service_role. Tighten what the app must not write.
revoke insert, update, delete on public.group_invites  from anon, authenticated;
revoke insert, update, delete on public.slot_unlocks   from anon, authenticated;
revoke insert, update, delete on public.group_featured from anon, authenticated;

-- Invite codes are capabilities: anon must never read them.
revoke select on public.group_invites from anon;
-- Slot entitlements are personal.
revoke select on public.slot_unlocks from anon;

grant select on public.group_featured to anon, authenticated;

-- -----------------------------------------------------------------------------
-- public.groups — a challenge always has a coherent window
-- -----------------------------------------------------------------------------
-- Granted by the orchestrator (A1 could not ALTER its own table after the
-- fact). A challenge is a dated season: it must have starts_on and ends_on and
-- ends_on must not precede starts_on.
alter table public.groups
  add constraint groups_challenge_dates_ck
  check (
    group_type <> 'challenge'
    or (starts_on is not null and ends_on is not null and ends_on >= starts_on)
  );

comment on constraint groups_challenge_dates_ck on public.groups is
  'A challenge (group_type = ''challenge'') must declare starts_on and ends_on, and ends_on must not precede starts_on. Fraternities are exempt (ends_on is normally NULL).';
