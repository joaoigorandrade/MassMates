-- =============================================================================
-- A6 · 0503 · moderation tables (content_reports, moderation_actions)
-- =============================================================================
-- Owner: A6 (storage, moderation & safety).
--
-- App Store UGC compliance (UGC-1.1 / UGC-2.0): the app must let a user report
-- objectionable content and let a group leader act on it. These two tables are
-- the server-side record of that flow.
--
-- Privacy (CONVENTIONS §8): neither table holds Confession records, Spiritual
-- Diary text or private check-in content. `content_reports.details` is a short
-- free-text explanation written by the REPORTER about someone else's content.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- content_reports — one row per "this content/reportable thing is a problem".
-- -----------------------------------------------------------------------------
create table public.content_reports (
  id           uuid primary key default gen_random_uuid(),
  reporter_id  uuid not null references public.profiles (id) on delete cascade,
  target_type  text not null
                 check (target_type in ('post','chat_message','prayer_intention','check_in','profile','group')),
  target_id    uuid not null,
  group_id     uuid references public.groups (id) on delete cascade,
  reason       text not null
                 check (reason in ('inappropriate_photo','inappropriate_text','spam','harassment','hate','self_harm','other')),
  details      text check (char_length(details) <= 500),
  status       text not null default 'open'
                 check (status in ('open','reviewing','actioned','dismissed')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  resolved_at  timestamptz,
  -- Deliberately NOT a foreign key: the moderation history must survive the
  -- deletion of the moderator (same reasoning as public.audit_log.actor_id).
  resolved_by  uuid
);

comment on table public.content_reports is
  'User reports about group content. Holds no confession, diary or private check-in content — only a reporter-authored short explanation (max 500 chars).';

comment on column public.content_reports.target_type is
  'What was reported: post | chat_message | prayer_intention | check_in | profile | group.';

comment on column public.content_reports.group_id is
  'The group whose administrator owns the moderation decision. NULL when the reported item is not tied to a group.';

create index idx_content_reports_target
  on public.content_reports (target_type, target_id);
create index idx_content_reports_status_created
  on public.content_reports (status, created_at desc);
create index idx_content_reports_reporter
  on public.content_reports (reporter_id);
create index idx_content_reports_group
  on public.content_reports (group_id);

alter table public.content_reports enable row level security;
alter table public.content_reports force  row level security;

-- A reporter sees their own reports; a group administrator sees the reports
-- filed against their group; service_role sees everything.
create policy content_reports_select_own_or_admin
  on public.content_reports for select
  to authenticated
  using (
    reporter_id = (select auth.uid())
    or (
      group_id is not null
      and public.is_group_admin (public.content_reports.group_id, (select auth.uid()))
    )
  );

create policy content_reports_insert_own
  on public.content_reports for insert
  to authenticated
  with check (reporter_id = (select auth.uid()));

create policy content_reports_update_admin
  on public.content_reports for update
  to authenticated
  using (
    group_id is not null
    and public.is_group_admin (public.content_reports.group_id, (select auth.uid()))
  )
  with check (
    group_id is not null
    and public.is_group_admin (public.content_reports.group_id, (select auth.uid()))
  );

create policy content_reports_select_service
  on public.content_reports for select
  to service_role
  using (true);

create policy content_reports_insert_service
  on public.content_reports for insert
  to service_role
  with check (true);

create policy content_reports_update_service
  on public.content_reports for update
  to service_role
  using (true)
  with check (true);

select public.attach_updated_at ('public.content_reports'::regclass);

-- -----------------------------------------------------------------------------
-- moderation_actions — append-only trail of every moderation decision.
-- No updated_at on purpose: the row is a log entry, like public.audit_log.
-- -----------------------------------------------------------------------------
create table public.moderation_actions (
  id          uuid primary key default gen_random_uuid(),
  actor_id    uuid not null references public.profiles (id) on delete cascade,
  action_type text not null
                check (action_type in ('hide_post','restore_post','delete_post','hide_chat_message',
                                       'hide_intention','remove_member','warn_user','suspend_user',
                                       'dismiss_report','auto_hide')),
  target_type text not null,
  target_id   uuid not null,
  group_id    uuid references public.groups (id) on delete set null,
  report_id   uuid references public.content_reports (id) on delete set null,
  reason      text check (char_length(reason) <= 200),
  metadata    jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at  timestamptz not null default now()
);

comment on table public.moderation_actions is
  'Append-only trail of moderation decisions (hide, restore, remove member, auto-hide). Written exclusively by A6 security-definer RPCs.';

comment on column public.moderation_actions.actor_id is
  'The user whose action caused the entry. For auto_hide this is the reporter whose report crossed the threshold.';

create index idx_moderation_actions_target
  on public.moderation_actions (target_type, target_id);
create index idx_moderation_actions_group_created
  on public.moderation_actions (group_id, created_at desc);
create index idx_moderation_actions_actor
  on public.moderation_actions (actor_id);
create index idx_moderation_actions_report
  on public.moderation_actions (report_id);

alter table public.moderation_actions enable row level security;
alter table public.moderation_actions force  row level security;

-- Administrators of the acting group read the trail; everyone else does not.
create policy moderation_actions_select_admin
  on public.moderation_actions for select
  to authenticated
  using (
    group_id is not null
    and public.is_group_admin (public.moderation_actions.group_id, (select auth.uid()))
  );

create policy moderation_actions_select_service
  on public.moderation_actions for select
  to service_role
  using (true);

-- NOTE: there is deliberately NO insert policy for `authenticated` — rows are
-- written only through A6's security-definer RPCs, so a client can never
-- forge a moderation action.

-- -----------------------------------------------------------------------------
-- v_target_report_counts — open-report counter per target, used to drive the
-- auto-hide threshold. security_invoker = true so the underlying RLS applies:
-- a user only ever sees counts for targets they are allowed to see.
-- -----------------------------------------------------------------------------
create or replace view public.v_target_report_counts
  with (security_invoker = true)
as
  select target_type,
         target_id,
         count(*)::int as report_count
    from public.content_reports
   where status in ('open','reviewing')
   group by 1,2;

comment on view public.v_target_report_counts is
  'Number of unresolved (open/reviewing) reports per target. security_invoker=true so content_reports RLS applies to the reader.';

grant select on public.v_target_report_counts to authenticated, service_role;
