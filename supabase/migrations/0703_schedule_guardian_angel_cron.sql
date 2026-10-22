-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022031851  ("schedule_guardian_angel_cron")
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
-- A8 · 0703 · pg_cron scheduling (Guardian Angel + push dispatch)
-- =============================================================================
-- Owner: A8.
--
-- Verified syntax (supabase/SCHEMA.md §6):
--   select cron.schedule (job_name, '<cron expr>', '<command>');
--   select cron.unschedule (job_name);
--   select jobid, jobname, schedule, command, active from cron.job;
--
-- IDEMPOTENCY: every job is unscheduled (if it exists) BEFORE it is
-- scheduled, so re-running this migration never produces a duplicate row in
-- cron.job. `cron.schedule` upserts on (jobname, username, schedule).
--
-- JOBS
--   a8_pairing_weekly_fraternities  0 5 * * 1    Monday 05:00 UTC
--   a8_pairing_daily_challenges     0 6 * * *    every day 06:00 UTC
--   a8_reveal_ended_cycles          15 6 * * *   every day 06:15 UTC
--   a8_push_dispatch                */5 * * * *  every 5 minutes
--
-- The push dispatch job calls the Edge Function through pg_net
-- (public.dispatch_push_notifications -> private.a8_dispatch_push_impl).
-- It is a NO-OP while private.app_settings.push_dispatch_url is missing.
-- To enable it:
--   insert into private.app_settings (key, value) values
--     ('push_dispatch_url',
--      'https://khovpljkitslmjmonizu.supabase.co/functions/v1/push-dispatch')
--   on conflict (key) do update set value = excluded.value, updated_at = now();
--   insert into private.app_settings (key, value) values
--     ('push_dispatch_secret', '<a long random string>')
--   on conflict (key) do update set value = excluded.value, updated_at = now();
-- The secret must match the PUSH_DISPATCH_SECRET environment secret of the
-- push-dispatch Edge Function.
-- -----------------------------------------------------------------------------

do $$
declare
  v_job text;
begin
  foreach v_job in array array [
    'a8_pairing_weekly_fraternities',
    'a8_pairing_daily_challenges',
    'a8_reveal_ended_cycles',
    'a8_push_dispatch'
  ] loop
    begin
      perform cron.unschedule (v_job);
    exception
      when others then
        null;
    end;
  end loop;
end;
$$;

-- 1 · Weekly draw for every fraternity (the ISO week starts on Monday).
select cron.schedule (
  'a8_pairing_weekly_fraternities',
  '0 5 * * 1',
  'select public.sweep_guardian_angel_pairings(''fraternity'');'
);

-- 2 · Daily draw for every ACTIVE challenge (they are paired when they start).
select cron.schedule (
  'a8_pairing_daily_challenges',
  '0 6 * * *',
  'select public.sweep_guardian_angel_pairings(''challenge'');'
);

-- 3 · Reveal the Guardian identities of every cycle that has ended.
select cron.schedule (
  'a8_reveal_ended_cycles',
  '15 6 * * *',
  'select public.sweep_reveal_guardian_identities();'
);

-- 4 · Dispatch the pending notification outbox rows (5 minutes).
select cron.schedule (
  'a8_push_dispatch',
  '*/5 * * * *',
  'select public.dispatch_push_notifications();'
);

comment on function public.dispatch_push_notifications () is
  'Calls the push-dispatch Edge Function through pg_net. NO-OP until private.app_settings.push_dispatch_url is set. Scheduled by the a8_push_dispatch cron job (*/5 * * * *).';
