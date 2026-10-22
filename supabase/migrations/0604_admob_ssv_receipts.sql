-- =============================================================================
-- A7 · 0604 · AdMob SSV support (receipt log)
-- =============================================================================
-- Owner: A7 (liturgical content & monetization).
--
-- `ssv_receipts` is the operational trace of the AdMob Server-Side
-- Verification callback: every ping the Edge Function receives ends up here
-- with its outcome (`granted` | `duplicate` | `rejected`) and, when it was
-- rejected, the reason. It is written ONLY by the `admob-ssv` Edge Function
-- (service_role) and is NEVER readable by a client: a receipt is a
-- monetization audit record, not user content.
--
-- PRIVACY (CONVENTIONS §8): a receipt records THAT a rewarded ad was
-- verified. It never records what the user prayed, nor any check-in, diary
-- or confession content.
-- -----------------------------------------------------------------------------

create table public.ssv_receipts (
  id             uuid primary key default gen_random_uuid(),
  transaction_id text check (char_length(transaction_id) <= 200),
  reward_type    text check (reward_type in ('streak_mercy', 'group_slot', 'saint_theme')),
  user_id        uuid references public.profiles (id) on delete set null,
  ad_type        text check (char_length(ad_type) <= 40),
  ad_value       numeric(12, 2),
  currency       text check (char_length(currency) <= 8),
  package_name   text check (char_length(package_name) <= 120),
  outcome        text not null check (outcome in ('granted', 'duplicate', 'rejected')),
  reason         text check (char_length(reason) <= 200),
  received_at    timestamptz not null default now(),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

comment on table public.ssv_receipts is
  'Operational trace of every AdMob SSV callback handled by the admob-ssv Edge Function. Written and read by service_role only. Holds no prayer, diary or check-in content.';

comment on column public.ssv_receipts.outcome is
  'granted = the reward was granted · duplicate = the transaction was already granted (idempotent replay) · rejected = the ping failed verification.';

create index idx_ssv_receipts_received_at on public.ssv_receipts (received_at desc);
create index idx_ssv_receipts_transaction_id on public.ssv_receipts (transaction_id);

-- -----------------------------------------------------------------------------
-- RLS — service_role only. A client may neither read nor write a receipt.
-- -----------------------------------------------------------------------------

alter table public.ssv_receipts enable row level security;
alter table public.ssv_receipts force  row level security;

create policy ssv_receipts_select_service
  on public.ssv_receipts for select to service_role using (true);

create policy ssv_receipts_insert_service
  on public.ssv_receipts for insert to service_role with check (true);

revoke insert, update, delete, truncate, trigger, references
  on public.ssv_receipts from anon, authenticated;

revoke select on public.ssv_receipts from anon, authenticated;

grant select, insert, update, delete on public.ssv_receipts to service_role;

select public.attach_updated_at ('public.ssv_receipts'::regclass);
