-- =============================================================================
-- A1 · 0003 · Foundation tables
-- =============================================================================
-- profiles, groups, group_members, user_blocks.
--
-- OWNERSHIP SPLIT (see supabase/SCHEMA.md §10):
--   * A1 owns the COLUMNS of all four tables.
--   * A2 owns the `handle_new_user` trigger on auth.users (inserts a profile)
--     and the account-deletion flow (soft delete via profiles.deleted_at).
--   * A3 owns groups/group_members RPCs (join_group_by_code, invite codes,
--     slot rules) and the RLS policies it needs to widen.
--   * A6 owns the block_user / unblock_user RPCs and all moderation flows on
--     user_blocks; A1 only owns the table and the is_blocked() helper.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- profiles : 1:1 with auth.users
-- -----------------------------------------------------------------------------
create table public.profiles (
  id                     uuid primary key references auth.users (id) on delete cascade,
  display_name           text        not null check (char_length(display_name) between 1 and 60),
  avatar_path            text,
  parish                 text        check (char_length(parish) <= 120),
  city                   text        check (char_length(city) <= 120),
  timezone               text        not null default 'America/Sao_Paulo',
  locale                 text        not null default 'pt-BR' check (locale in ('pt-BR', 'en')),
  ad_consent_analytics   boolean     not null default false,
  ad_personalization     boolean     not null default false,
  rule_of_life           jsonb       not null default '[]'::jsonb check (jsonb_typeof(rule_of_life) = 'array'),
  guardian_angel_opt_in  boolean     not null default false,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  deleted_at             timestamptz
);

comment on table public.profiles is
  'Public profile of an app user (1:1 with auth.users). Holds NO confession, NO spiritual diary text and NO private check-in content — sacred privacy invariant, CONVENTIONS §8.';

comment on column public.profiles.rule_of_life is
  'JSON array of { "kind": "<practice_kind>", "label": "<string>" } — the user''s personal Rule of Life checklist used by the daily progress ring.';

comment on column public.profiles.timezone is
  'IANA timezone name (e.g. America/Sao_Paulo). Not validated by the DB: pg_timezone_names() is not immutable and cannot be used in a CHECK.';

comment on column public.profiles.deleted_at is
  'Soft-delete marker. A2 owns the account-deletion window: rows are hidden from other users while this is set, then hard-deleted by the erasure job.';

comment on column public.profiles.avatar_path is
  'Storage object path inside the `avatars` bucket (bucket owned by A6). Not a URL.';

comment on column public.profiles.ad_consent_analytics is
  'Consent for analytics. NEVER derived from spiritual practice data.';

comment on column public.profiles.ad_personalization is
  'Consent for personalised ads. NEVER derived from private check-ins or diary content.';

-- -----------------------------------------------------------------------------
-- groups : fraternity or challenge
-- -----------------------------------------------------------------------------
create table public.groups (
  id                  uuid primary key default gen_random_uuid(),
  name                text                  not null check (char_length(name) between 1 and 80),
  description         text                  check (char_length(description) <= 500),
  group_type          public.group_type     not null default 'fraternity',
  scoring_mode        public.scoring_mode   not null default 'faithful_days',
  sharing_requirement public.sharing_requirement not null default 'open',
  cover_path          text,
  invite_code         text unique check (invite_code ~ '^[0-9]{6}$'),
  starts_on           date,
  ends_on             date,
  goal_target         integer check (goal_target > 0),
  created_by          uuid references public.profiles (id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  archived_at         timestamptz
);

comment on table public.groups is
  'A fraternity (continuous) or a challenge (time-bounded). A3 owns invite codes, slot rules and the join/create RPCs; A1 owns the columns and the baseline RLS policies.';

comment on column public.groups.invite_code is
  '6-digit numeric join code. NULL until A3 generates one. Regenerating the code must clear this column first (the UNIQUE constraint treats NULLs as distinct).';

comment on column public.groups.goal_target is
  'Collective-treasure goal (number of practices) for scoring_mode = collective_treasure.';

comment on column public.groups.starts_on is
  'Inclusive start date. NULL for continuous fraternities.';

comment on column public.groups.ends_on is
  'Inclusive end date. NULL for continuous fraternities. A challenge must have both starts_on and ends_on (enforced by A3''s RPC, not by a CHECK).';

-- -----------------------------------------------------------------------------
-- group_members
-- -----------------------------------------------------------------------------
create table public.group_members (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references public.groups (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  role       public.member_role not null default 'member',
  joined_at  timestamptz not null default now(),
  unique (group_id, user_id)
);

comment on table public.group_members is
  'Membership of a group. A3 owns the join/leave/admin-transfer RPCs; A1 owns the columns, the baseline RLS policies and the is_group_member()/is_group_admin() helpers.';

comment on column public.group_members.role is
  'admin = may edit the group, manage members and invites; member = regular participant.';

-- -----------------------------------------------------------------------------
-- user_blocks : moderation
-- -----------------------------------------------------------------------------
create table public.user_blocks (
  id          uuid primary key default gen_random_uuid(),
  blocker_id  uuid not null references public.profiles (id) on delete cascade,
  blocked_id  uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

comment on table public.user_blocks is
  'Block list. A1 owns the table + the symmetric is_blocked() helper; A6 owns the block_user/unblock_user RPCs and every moderation flow that writes here.';

comment on column public.user_blocks.blocker_id is
  'User who pressed "block".';

comment on column public.user_blocks.blocked_id is
  'User who was blocked. A block hides content in BOTH directions — see public.is_blocked().';

-- -----------------------------------------------------------------------------
-- Indexes (foreign keys need supporting indexes or the performance advisor
-- flags them).
-- -----------------------------------------------------------------------------
create index idx_group_members_user_id on public.group_members (user_id);
create index idx_group_members_group_role on public.group_members (group_id, role);
create index idx_groups_created_by on public.groups (created_by);
create index idx_user_blocks_blocker_id on public.user_blocks (blocker_id);
create index idx_user_blocks_blocked_id on public.user_blocks (blocked_id);
