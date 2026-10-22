-- =============================================================================
-- A1 · 0006 · practice_points + audit_log
-- =============================================================================
-- practice_points : lookup table for scoring_mode = 'custom_points'.
--                    A1 owns the table; A4 owns the DATA and the scoring RPC.
-- audit_log       : append-only trail of privileged actions
--                    (A2 account deletion, A3 admin transfers, A6 moderation).
--                    A1 owns the table + RLS; each agent writes through its
--                    own SECURITY DEFINER RPC / Edge Function.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- practice_points
-- -----------------------------------------------------------------------------
create table public.practice_points (
  id            uuid primary key default gen_random_uuid(),
  group_id      uuid references public.groups (id) on delete cascade,
  practice_kind public.practice_kind not null,
  points        integer not null check (points >= 0),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  -- PG15+ NULLS NOT DISTINCT: group_id IS NULL means "global default" and must
  -- still be unique per practice_kind (plain UNIQUE would allow duplicates
  -- because NULLs are distinct in Postgres).
  constraint practice_points_group_kind_unique unique nulls not distinct (group_id, practice_kind)
);

comment on table public.practice_points is
  'Point values per practice kind for groups using scoring_mode = ''custom_points''. group_id IS NULL = global default row. A1 owns the table; A4 owns the data and the scoring RPC.';

comment on column public.practice_points.group_id is
  'NULL = global default (applies to every custom_points group). NOT NULL = override for one group only.';

create index idx_practice_points_group_id on public.practice_points (group_id);

alter table public.practice_points enable row level security;
alter table public.practice_points force  row level security;

-- Global defaults are readable by any authenticated user; group-specific
-- values are readable by that group's members.
create policy practice_points_select
  on public.practice_points
  for select
  to authenticated
  using (
    group_id is null
    or public.is_group_member (public.practice_points.group_id)
  );

-- Only group admins (or service_role) may change point values.
create policy practice_points_insert_admin
  on public.practice_points
  for insert
  to authenticated
  with check (
    group_id is null
    or public.is_group_admin (public.practice_points.group_id)
  );

create policy practice_points_update_admin
  on public.practice_points
  for update
  to authenticated
  using (
    group_id is null
    or public.is_group_admin (public.practice_points.group_id)
  )
  with check (
    group_id is null
    or public.is_group_admin (public.practice_points.group_id)
  );

create policy practice_points_delete_admin
  on public.practice_points
  for delete
  to authenticated
  using (
    group_id is null
    or public.is_group_admin (public.practice_points.group_id)
  );

-- -----------------------------------------------------------------------------
-- audit_log (append-only)
-- -----------------------------------------------------------------------------
create table public.audit_log (
  id          bigint generated always as identity primary key,
  actor_id    uuid,
  action      text not null check (char_length(action) between 1 and 100),
  target_type text not null check (char_length(target_type) between 1 and 60),
  target_id   uuid,
  metadata    jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at  timestamptz not null default now()
);

comment on table public.audit_log is
  'Append-only trail of privileged actions (A2 account deletion, A3 admin transfers, A6 moderation). Rows are written by SECURITY DEFINER RPCs or by service_role. Never UPDATE or DELETE a row.';

comment on column public.audit_log.actor_id is
  'The user who performed the action. NULL for system/Edge-Function actions. Deliberately NOT a foreign key: an actor may have been hard-deleted by the erasure job and the audit trail must survive.';

comment on column public.audit_log.action is
  'Stable machine-readable verb, e.g. ''account.delete_requested'', ''group.admin_transferred'', ''content.report_resolved''.';

alter table public.audit_log enable row level security;
alter table public.audit_log force  row level security;

-- Readable by users who administer at least one group; everything else is
-- denied by default (no anon/authenticated INSERT/UPDATE/DELETE policy).
create policy audit_log_select_admin
  on public.audit_log
  for select
  to authenticated
  using (public.is_any_group_admin ());

-- Writes: service_role only (it bypasses RLS; the policy documents the intent
-- and keeps working on a project where service_role does not bypass RLS).
create policy audit_log_insert_service
  on public.audit_log
  for insert
  to service_role
  with check (true);

create index idx_audit_log_created_at on public.audit_log (created_at desc);
create index idx_audit_log_actor on public.audit_log (actor_id);
create index idx_audit_log_target on public.audit_log (target_type, target_id);
