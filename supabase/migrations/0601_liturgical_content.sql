-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025720  ("0601_liturgical_content")
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
-- A7 · 0601 · Liturgical content (read-only public)
-- =============================================================================
-- Owner: A7 (liturgical content & monetization).
--
-- Liturgical content is genuinely PUBLIC: the calendar, the colours, the
-- celebrations and the saints of the day are the same for every Catholic in
-- Brazil. It is therefore SELECT-able by `anon` and `authenticated`, and it is
-- NEVER writable by a client: rows are written by `service_role` (seed / ingest
-- pipeline) only.
--
-- PRIVACY (CONVENTIONS §8): these tables hold NO confession record, NO
-- spiritual-diary text and NO private check-in content. `daily_readings` holds
-- public Scripture only.
--
-- Scripture text is NEVER paraphrased, summarised or generated. The seed in
-- 0605 writes structure + references only; the text columns stay NULL and
-- `is_complete` stays false until an authoritative CNBB feed is ingested.
-- -----------------------------------------------------------------------------

create table public.liturgical_days (
  id              uuid primary key default gen_random_uuid(),
  calendar_date   date not null unique,
  season          public.liturgical_season not null,
  liturgical_color text not null check (liturgical_color in ('green', 'purple', 'white', 'red', 'rose')),
  celebration     text check (char_length(celebration) between 1 and 200),
  "rank"          text check ("rank" in ('solemnity', 'feast', 'memorial', 'optional_memorial', 'ordinary')),
  notes           text check (char_length(notes) <= 2000),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table public.liturgical_days is
  'One row per calendar day: the liturgical season, the liturgical colour, the celebration of the day and its rank. Public content, seeded from the general Roman calendar rules and maintained by service_role only. Holds no private content.';

comment on column public.liturgical_days.liturgical_color is
  'The five design-system liturgical colours: green, purple, white, red, rose. A feast day overrides the colour of its season (e.g. 26 Dec = red, 08 Dec = white inside Advent).';

comment on column public.liturgical_days."rank" is
  'Liturgical rank of the celebration: solemnity | feast | memorial | optional_memorial | ordinary.';

create index idx_liturgical_days_season on public.liturgical_days (season);

create table public.daily_readings (
  id                uuid primary key default gen_random_uuid(),
  calendar_date     date not null unique references public.liturgical_days (calendar_date) on delete cascade,
  first_reading_ref text check (char_length(first_reading_ref) <= 200),
  first_reading_text text,
  psalm_ref         text check (char_length(psalm_ref) <= 200),
  psalm_text        text,
  gospel_ref        text check (char_length(gospel_ref) <= 200),
  gospel_text       text,
  liturgical_color  text check (liturgical_color in ('green', 'purple', 'white', 'red', 'rose')),
  translation       text not null default 'cnbb' check (translation in ('cnbb', 'vatican')),
  is_complete       boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint daily_readings_complete_check
    check (not is_complete or (first_reading_text is not null and gospel_text is not null))
);

comment on table public.daily_readings is
  'The First Reading, the Psalm and the Gospel of each day, in an official Church translation (CNBB by default). CONTENT INTEGRITY: the text columns must be verbatim from the official translation — never paraphrased, summarised, corrected or machine-generated. A row may only carry is_complete = true when BOTH first_reading_text and gospel_text are present; every unverified row keeps is_complete = false. Written by the service_role ingest pipeline only.';

comment on column public.daily_readings.translation is
  'Which official Church translation the text comes from: cnbb (Conferência Nacional dos Bispos do Brasil) or vatican.';

comment on column public.daily_readings.is_complete is
  'true only when the row was ingested from the authoritative feed AND carries both the First Reading and the Gospel verbatim. Unverified rows stay false so the app never shows a half-ingested day as complete.';

create table public.saints (
  id            uuid primary key default gen_random_uuid(),
  calendar_date date not null,
  name          text not null check (char_length(name) between 1 and 120),
  kind          text not null check (kind in ('saint', 'blessed', 'optional_saint', 'beato')),
  biography     text,
  patronage     text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint saints_calendar_name_key unique (calendar_date, name)
);

comment on table public.saints is
  'Saints of the day. The biography is NEVER invented: it stays NULL until an authoritative hagiographic source is ingested.';

create index idx_saints_calendar_date on public.saints (calendar_date);
create index idx_saints_lower_name on public.saints (lower(name));

create table public.saint_icons (
  id             uuid primary key default gen_random_uuid(),
  saint_id       uuid references public.saints (id) on delete cascade,
  slug           text not null unique check (slug ~ '^[a-z0-9-]{2,64}$'),
  name           text not null check (char_length(name) between 1 and 80),
  icon_sf_symbol text not null check (char_length(icon_sf_symbol) between 1 and 60),
  season         public.liturgical_season,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

comment on table public.saint_icons is
  'Unlockable app-icon / theme rewards. A user who watches a rewarded video may unlock one theme for 7 days (see public.user_saint_unlocks and public.grant_reward).';

create index idx_saint_icons_saint_id on public.saint_icons (saint_id);
create index idx_saint_icons_active on public.saint_icons (slug) where is_active;

create table public.user_saint_unlocks (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  saint_icon_id uuid not null references public.saint_icons (id) on delete cascade,
  granted_at   timestamptz not null default now(),
  expires_at   timestamptz not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint user_saint_unlocks_user_icon_key unique (user_id, saint_icon_id),
  constraint user_saint_unlocks_expiry_check check (expires_at > granted_at)
);

comment on table public.user_saint_unlocks is
  'A user entitlement: this theme is unlocked for this user until expires_at. Written only by public.grant_reward (service_role) — never by a client.';

create index idx_user_saint_unlocks_user_id on public.user_saint_unlocks (user_id);

-- -----------------------------------------------------------------------------
-- RLS — every table: RLS enabled AND forced, explicit policies, no default.
-- -----------------------------------------------------------------------------

alter table public.liturgical_days   enable row level security;
alter table public.liturgical_days   force  row level security;
alter table public.daily_readings    enable row level security;
alter table public.daily_readings    force  row level security;
alter table public.saints            enable row level security;
alter table public.saints            force  row level security;
alter table public.saint_icons       enable row level security;
alter table public.saint_icons       force  row level security;
alter table public.user_saint_unlocks enable row level security;
alter table public.user_saint_unlocks force  row level security;

-- Public content: readable by everybody, writable by nobody but service_role.
create policy liturgical_days_select_public
  on public.liturgical_days for select to anon, authenticated using (true);

create policy daily_readings_select_public
  on public.daily_readings for select to anon, authenticated using (true);

create policy saints_select_public
  on public.saints for select to anon, authenticated using (true);

create policy saint_icons_select_public
  on public.saint_icons for select to anon, authenticated using (true);

-- A user's own entitlements: readable by the owner only, never by anon.
create policy user_saint_unlocks_select_own
  on public.user_saint_unlocks for select to authenticated
  using (user_id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- Privileges — the platform grants ALL on new tables to anon/authenticated by
-- default, so the write privileges are revoked explicitly. No client may ever
-- INSERT/UPDATE/DELETE a liturgical row.
-- -----------------------------------------------------------------------------

revoke insert, update, delete, truncate, trigger, references
  on public.liturgical_days, public.daily_readings, public.saints, public.saint_icons
  from anon, authenticated;

revoke insert, update, delete, truncate, trigger, references
  on public.user_saint_unlocks
  from anon, authenticated;

grant select on public.liturgical_days, public.daily_readings, public.saints, public.saint_icons
  to anon, authenticated;

grant select on public.user_saint_unlocks to authenticated;

grant select, insert, update, delete on
  public.liturgical_days, public.daily_readings, public.saints, public.saint_icons, public.user_saint_unlocks
  to service_role;

-- updated_at triggers (A1 convention).
select public.attach_updated_at ('public.liturgical_days'::regclass);
select public.attach_updated_at ('public.daily_readings'::regclass);
select public.attach_updated_at ('public.saints'::regclass);
select public.attach_updated_at ('public.saint_icons'::regclass);
select public.attach_updated_at ('public.user_saint_unlocks'::regclass);
