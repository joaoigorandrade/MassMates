-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022031503  ("create_guardian_angel_tables")
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
-- A8 · 0701 · Guardian Angel + push tables
-- =============================================================================
-- Owner: A8 (Guardian Angel mechanic & push notifications).
-- Columns AND policies are mine. Do not touch other agents' tables — request a
-- change instead (CONVENTIONS §2).
--
-- SACRED PRIVACY (CONVENTIONS §8)
--   * Nothing here can hold Confession records, Spiritual Diary text or the
--     content of a private check-in. `guardian_angel_pairings` and
--     `guardian_nudges` hold uuids and dates only.
--   * The identity of a Guardian is a SECRET until the cycle ends. There is
--     NO client SELECT policy on `public.guardian_angel_pairings` and the
--     table privilege is revoked, so no client can ever read `guardian_id`
--     directly. Every read goes through a redacting RPC.
--   * A nudge is anonymous: the recipient never learns who sent it.
-- -----------------------------------------------------------------------------

-- =============================================================================
-- public.guardian_angel_opt_ins — per-group opt-in
-- =============================================================================
create table public.guardian_angel_opt_ins (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  group_id   uuid not null references public.groups (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint guardian_angel_opt_ins_user_group_key unique (user_id, group_id)
);

comment on table public.guardian_angel_opt_ins is
  'Per-group Guardian Angel opt-in. A member is only ever drawn into the Secret Guardian Angel when a row exists here for (user_id, group_id) AND profiles.guardian_angel_opt_in is true. Holds no spiritual content.';

create index idx_guardian_angel_opt_ins_group_id
  on public.guardian_angel_opt_ins (group_id);

alter table public.guardian_angel_opt_ins enable row level security;
alter table public.guardian_angel_opt_ins force  row level security;

create policy guardian_angel_opt_ins_select
  on public.guardian_angel_opt_ins
  for select
  to authenticated
  using (user_id = (select auth.uid())
         or public.is_group_member (group_id, (select auth.uid())));

create policy guardian_angel_opt_ins_insert
  on public.guardian_angel_opt_ins
  for insert
  to authenticated
  with check (user_id = (select auth.uid())
              and public.is_group_member (group_id, (select auth.uid())));

create policy guardian_angel_opt_ins_delete
  on public.guardian_angel_opt_ins
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

create policy guardian_angel_opt_ins_service
  on public.guardian_angel_opt_ins
  for all
  to service_role
  using (true)
  with check (true);

-- =============================================================================
-- public.guardian_angel_pairings — the (secret) draw
-- =============================================================================
create table public.guardian_angel_pairings (
  id               uuid primary key default gen_random_uuid(),
  group_id         uuid not null references public.groups (id) on delete cascade,
  cycle_key        text not null check (char_length (cycle_key) between 1 and 120),
  guardian_id      uuid not null references public.profiles (id) on delete cascade,
  protected_id     uuid not null references public.profiles (id) on delete cascade,
  cycle_starts_on  date not null,
  cycle_ends_on    date not null,
  is_active        boolean not null default true,
  revealed_at      timestamptz,
  created_at       timestamptz not null default now(),
  constraint guardian_angel_pairings_no_self
    check (guardian_id <> protected_id),
  constraint guardian_angel_pairings_cycle_window
    check (cycle_ends_on >= cycle_starts_on),
  constraint guardian_angel_pairings_cycle_guardian_key unique (cycle_key, guardian_id),
  constraint guardian_angel_pairings_cycle_protected_key unique (cycle_key, protected_id)
);

comment on table public.guardian_angel_pairings is
  'The Secret Guardian Angel draw. `guardian_id` guards `protected_id` for one cycle. The guardian identity is SECRET until `revealed_at` is set: there is no client SELECT policy and the table privilege is revoked for anon/authenticated — reads go exclusively through the redacting RPCs (public.my_guardian_assignment, public.guardian_angel_state). A member is never paired with themselves.';

create index idx_guardian_angel_pairings_group_cycle
  on public.guardian_angel_pairings (group_id, cycle_key);
create index idx_guardian_angel_pairings_protected_id
  on public.guardian_angel_pairings (protected_id);
create index idx_guardian_angel_pairings_guardian_id
  on public.guardian_angel_pairings (guardian_id);

alter table public.guardian_angel_pairings enable row level security;
alter table public.guardian_angel_pairings force  row level security;

-- The ONLY policy: the server. `authenticated` has no table privilege at all.
create policy guardian_angel_pairings_service
  on public.guardian_angel_pairings
  for all
  to service_role
  using (true)
  with check (true);

revoke all on public.guardian_angel_pairings from anon, authenticated;
grant select, insert, update, delete on public.guardian_angel_pairings to service_role;

-- =============================================================================
-- public.guardian_nudges — the anonymous "I prayed for my protected soul"
-- =============================================================================
create table public.guardian_nudges (
  id           uuid primary key default gen_random_uuid(),
  group_id     uuid not null references public.groups (id) on delete cascade,
  pairing_id   uuid not null references public.guardian_angel_pairings (id) on delete cascade,
  sender_id    uuid not null references public.profiles (id) on delete cascade,
  protected_id uuid not null references public.profiles (id) on delete cascade,
  cycle_key    text not null check (char_length (cycle_key) between 1 and 120),
  local_date   date not null,
  created_at   timestamptz not null default now(),
  constraint guardian_nudges_sender_local_date_key unique (sender_id, local_date)
);

comment on table public.guardian_nudges is
  'One anonymous nudge per Guardian per local day. The recipient NEVER learns who sent it: the client grant omits `sender_id` and the RLS policy only exposes the sender''s own rows. The pushed body is anonymous too.';

create index idx_guardian_nudges_protected_created
  on public.guardian_nudges (protected_id, created_at desc);
create index idx_guardian_nudges_pairing_id
  on public.guardian_nudges (pairing_id);

alter table public.guardian_nudges enable row level security;
alter table public.guardian_nudges force  row level security;

create policy guardian_nudges_select_own
  on public.guardian_nudges
  for select
  to authenticated
  using (sender_id = (select auth.uid()));

create policy guardian_nudges_service
  on public.guardian_nudges
  for all
  to service_role
  using (true)
  with check (true);

revoke all on public.guardian_nudges from anon, authenticated;
grant select (id, group_id, pairing_id, protected_id, cycle_key, local_date, created_at)
  on public.guardian_nudges to authenticated;
grant select, insert, update, delete on public.guardian_nudges to service_role;

-- =============================================================================
-- public.device_tokens — APNs / FCM registration tokens
-- =============================================================================
create table public.device_tokens (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  platform     text not null default 'ios' check (platform in ('ios', 'android')),
  apns_token   text not null check (char_length (apns_token) between 8 and 512),
  environment  text not null default 'production' check (environment in ('sandbox', 'production')),
  app_version  text check (char_length (app_version) <= 40),
  is_active    boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  constraint device_tokens_platform_token_key unique (platform, apns_token)
);

comment on table public.device_tokens is
  'Push registration tokens. UNIQUE (platform, apns_token): the same token is never stored twice — re-registering it moves the row to the new user (public.register_device_token). Holds no spiritual content.';

create index idx_device_tokens_user_active
  on public.device_tokens (user_id, is_active);

alter table public.device_tokens enable row level security;
alter table public.device_tokens force  row level security;

create policy device_tokens_select_own
  on public.device_tokens
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy device_tokens_insert_own
  on public.device_tokens
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy device_tokens_update_own
  on public.device_tokens
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy device_tokens_delete_own
  on public.device_tokens
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

create policy device_tokens_service
  on public.device_tokens
  for all
  to service_role
  using (true)
  with check (true);

-- =============================================================================
-- public.notification_outbox — the transactional outbox
-- =============================================================================
create table public.notification_outbox (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles (id) on delete cascade,
  channel           text not null default 'push' check (channel in ('push')),
  notification_type text not null check (notification_type in (
                     'prayed_for_you', 'amen', 'guardian_nudge',
                     'pinned_notice', 'streak_milestone')),
  title             text not null check (char_length (title) between 1 and 120),
  body              text not null check (char_length (body) between 1 and 500),
  payload           jsonb not null default '{}'::jsonb check (jsonb_typeof (payload) = 'object'),
  group_id          uuid references public.groups (id) on delete cascade,
  dedupe_key        text not null check (char_length (dedupe_key) between 1 and 200),
  status            text not null default 'pending' check (status in (
                     'pending', 'processing', 'sent', 'failed', 'cancelled')),
  attempts          integer not null default 0 check (attempts >= 0),
  scheduled_at      timestamptz not null default now(),
  sent_at           timestamptz,
  last_error        text check (char_length (last_error) <= 1000),
  created_at        timestamptz not null default now(),
  constraint notification_outbox_dedupe_key_key unique (dedupe_key)
);

comment on table public.notification_outbox is
  'Transactional outbox for push notifications. UNIQUE (dedupe_key) makes emission idempotent. The client may only READ its own rows; every write comes from a security-definer RPC or the service_role push-dispatch Edge Function. A payload never contains private check-in content, Confession content or Spiritual Diary text. LITURGICAL REMINDERS ARE LOCAL-ONLY: this table never receives a liturgical row.';

create index idx_notification_outbox_status_scheduled
  on public.notification_outbox (status, scheduled_at);
create index idx_notification_outbox_user_id
  on public.notification_outbox (user_id, created_at desc);

alter table public.notification_outbox enable row level security;
alter table public.notification_outbox force  row level security;

create policy notification_outbox_select_own
  on public.notification_outbox
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy notification_outbox_service
  on public.notification_outbox
  for all
  to service_role
  using (true)
  with check (true);

-- No client write privilege at all.
revoke insert, update, delete, truncate on public.notification_outbox from anon, authenticated;
revoke select on public.notification_outbox from anon, authenticated;
grant select (id, user_id, channel, notification_type, title, body, payload,
              group_id, status, attempts, scheduled_at, sent_at, created_at)
  on public.notification_outbox to authenticated;
grant select, insert, update, delete on public.notification_outbox to service_role;

-- =============================================================================
-- private.app_settings — operational settings (not exposed to clients)
-- =============================================================================
create table private.app_settings (
  key        text primary key check (char_length (key) between 1 and 100),
  value      text check (char_length (value) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table private.app_settings is
  'Operational key/value settings owned by A8. Known keys: push_dispatch_url (full URL of the push-dispatch Edge Function), push_dispatch_secret (shared secret the Edge Function accepts in the x-push-secret header). Never read by a client.';

alter table private.app_settings enable row level security;
alter table private.app_settings force  row level security;

create policy app_settings_service
  on private.app_settings
  for all
  to service_role
  using (true)
  with check (true);

revoke all on private.app_settings from anon, authenticated;
grant select, insert, update, delete on private.app_settings to service_role;

select public.attach_updated_at ('private.app_settings'::regclass);
