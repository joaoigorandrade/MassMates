-- =============================================================================
-- A7 · 0602 · Monetization (sponsors, sponsored challenges, reward ledger)
-- =============================================================================
-- Owner: A7 (liturgical content & monetization).
--
-- PRIVACY (CONVENTIONS §8): none of these tables holds a confession record, a
-- spiritual-diary text or a private check-in content. `reward_grants` records
-- THAT a reward was earned — never what the user prayed.
--
-- `reward_grants` is the monetization ledger: one row per earned reward.
-- It is written ONLY by service_role (the AdMob SSV Edge Function) and by
-- public.grant_reward. There is no client INSERT path, by construction.
-- -----------------------------------------------------------------------------

create table public.sponsors (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 120),
  slug        text not null unique check (slug ~ '^[a-z0-9-]{2,80}$'),
  logo_path   text check (char_length(logo_path) <= 400),
  website_url text check (char_length(website_url) <= 300),
  description text check (char_length(description) <= 1000),
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.sponsors is
  'Catholic publishers, bookstores or ministries that sponsor an official challenge. Written by service_role only.';

comment on column public.sponsors.logo_path is
  'Storage object path (NOT a URL) in the EXISTING group-covers bucket, owned by A6. A dedicated sponsor-logos bucket is NOT created on purpose: one bucket is enough and the sponsor artwork is public.';

create table public.sponsored_challenges (
  id               uuid primary key default gen_random_uuid(),
  group_id         uuid not null references public.groups (id) on delete cascade,
  sponsor_id       uuid not null references public.sponsors (id) on delete cascade,
  headline         text not null check (char_length(headline) between 1 and 120),
  description      text check (char_length(description) <= 1000),
  coupon_code      text check (char_length(coupon_code) <= 40),
  coupon_url       text check (char_length(coupon_url) <= 300),
  starts_on        date,
  ends_on          date,
  is_active        boolean not null default true,
  display_order    integer not null default 0,
  featured_group_id uuid references public.group_featured (group_id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint sponsored_challenges_window_check
    check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

comment on table public.sponsored_challenges is
  'A sponsored challenge shown in the Groups discovery showcase. Written by service_role only; readable by everybody (public discovery).';

comment on column public.sponsored_challenges.featured_group_id is
  'Optional link to the featured-challenge row owned by A3 (public.group_featured). ON DELETE SET NULL so removing a featured group never deletes the sponsor record.';

create index idx_sponsored_challenges_group_id on public.sponsored_challenges (group_id);
create index idx_sponsored_challenges_sponsor_id on public.sponsored_challenges (sponsor_id);
create index idx_sponsored_challenges_featured_group_id on public.sponsored_challenges (featured_group_id);
create index idx_sponsored_challenges_active on public.sponsored_challenges (display_order)
  where is_active;

create table public.reward_grants (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  reward_type    text not null check (reward_type in ('streak_mercy', 'group_slot', 'saint_theme')),
  source         text not null check (source in ('admob_ssv', 'admin_grant', 'sponsored', 'achievement')),
  ad_network     text check (char_length(ad_network) <= 40),
  transaction_id text check (char_length(transaction_id) <= 200),
  status         text not null default 'granted' check (status in ('granted', 'consumed', 'expired', 'revoked')),
  granted_at     timestamptz not null default now(),
  expires_at     timestamptz,
  consumed_at    timestamptz,
  metadata       jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

comment on table public.reward_grants is
  'The monetization ledger: one row per earned reward (streak mercy, extra group slot, saint theme). IDEMPOTENCY: the partial unique index reward_grants_txn_uk on (source, transaction_id) makes a replayed AdMob SSV callback a no-op instead of a second reward. Written ONLY by service_role and by public.grant_reward — there is no client INSERT path. Holds NO prayer content, only the fact that a reward was earned.';

comment on column public.reward_grants.transaction_id is
  'The ad-network transaction id (AdMob SSV) or the ad-view token id. NULL for manual grants. Unique per source when present.';

comment on column public.reward_grants.metadata is
  'Non-sensitive bookkeeping only (ad network, reward duration, ad-view token id). Never contains check-in text, prayer intentions or any private content.';

-- The AdMob SSV callback can be replayed: a replay must NOT grant twice.
create unique index reward_grants_txn_uk
  on public.reward_grants (source, transaction_id)
  where transaction_id is not null;

create index idx_reward_grants_user_id on public.reward_grants (user_id);
create index idx_reward_grants_user_status on public.reward_grants (user_id, status);
create index idx_reward_grants_user_reward_type on public.reward_grants (user_id, reward_type);

create table public.ad_view_tokens (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  transaction_id text not null unique check (char_length(transaction_id) between 8 and 200),
  reward_type    text not null check (reward_type in ('streak_mercy', 'group_slot', 'saint_theme')),
  created_at     timestamptz not null default now(),
  expires_at     timestamptz not null,
  consumed_at    timestamptz,
  updated_at     timestamptz not null default now(),
  constraint ad_view_tokens_window_check check (expires_at > created_at)
);

comment on table public.ad_view_tokens is
  'A pending rewarded-ad view. The app calls public.begin_ad_reward BEFORE showing the rewarded video; the returned transaction_id is passed to AdMob as a custom parameter and is echoed back in the SSV ping. The SSV Edge Function consumes the token before granting, which is what binds the reward to the user who actually watched the ad. Written only by private.begin_ad_reward_impl.';

create index idx_ad_view_tokens_user_id on public.ad_view_tokens (user_id);
create index idx_ad_view_tokens_open on public.ad_view_tokens (user_id, reward_type)
  where consumed_at is null;

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------

alter table public.sponsors            enable row level security;
alter table public.sponsors            force  row level security;
alter table public.sponsored_challenges enable row level security;
alter table public.sponsored_challenges force  row level security;
alter table public.reward_grants        enable row level security;
alter table public.reward_grants        force  row level security;
alter table public.ad_view_tokens       enable row level security;
alter table public.ad_view_tokens       force  row level security;

-- Public discovery content.
create policy sponsors_select_public
  on public.sponsors for select to anon, authenticated using (true);

create policy sponsored_challenges_select_public
  on public.sponsored_challenges for select to anon, authenticated using (true);

-- A user sees only their own rewards.
create policy reward_grants_select_own
  on public.reward_grants for select to authenticated
  using (user_id = (select auth.uid()));

-- A user may see their own pending ad-view tokens (the app polls them).
create policy ad_view_tokens_select_own
  on public.ad_view_tokens for select to authenticated
  using (user_id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- Privileges — the platform grants ALL on new tables to anon/authenticated by
-- default: the write privileges are revoked explicitly. A client may only
-- SELECT its own reward rows; every write goes through service_role or a
-- SECURITY DEFINER RPC.
-- -----------------------------------------------------------------------------

revoke insert, update, delete, truncate, trigger, references
  on public.sponsors, public.sponsored_challenges, public.reward_grants, public.ad_view_tokens
  from anon, authenticated;

grant select on public.sponsors, public.sponsored_challenges to anon, authenticated;
grant select on public.reward_grants, public.ad_view_tokens to authenticated;

grant select, insert, update, delete on
  public.sponsors, public.sponsored_challenges, public.reward_grants, public.ad_view_tokens
  to service_role;

-- updated_at triggers (A1 convention).
select public.attach_updated_at ('public.sponsors'::regclass);
select public.attach_updated_at ('public.sponsored_challenges'::regclass);
select public.attach_updated_at ('public.reward_grants'::regclass);
select public.attach_updated_at ('public.ad_view_tokens'::regclass);
