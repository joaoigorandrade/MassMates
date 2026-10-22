-- =============================================================================
-- A10 · rls_matrix.sql · the systematic RLS matrix
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
--
-- WHAT IT PROVES
--   For EVERY table of the `public` schema (40 tables) and for EVERY one of
--   the five personas, the number of rows that SELECT / UPDATE / DELETE can
--   reach is asserted against an EXPLICIT, hand-written expectation -- not
--   merely "no error".
--
--   The personas (the order used by every array in the expectation table):
--     1 anon      -- unauthenticated            (set local role anon)
--     2 outsider  -- authenticated, NOT in the group
--     3 member    -- authenticated, member of the group
--     4 admin     -- authenticated, admin of the group
--     5 blocked   -- authenticated, member of the group, BLOCKED BY the member
--
--   Fixture
--     u1 Ana    a1000000-0000-0000-0000-000000000001  admin  of G1
--     u2 Bruno  a1000000-0000-0000-0000-000000000002  member of G1
--     u3 Carla  a1000000-0000-0000-0000-000000000003  admin  of G2 (outsider)
--     u4 Daniel a1000000-0000-0000-0000-000000000004  member of G1, blocked by u2
--     u5 Eve    a1000000-0000-0000-0000-000000000005  member of G1 (never a persona)
--     G1       a1000000-0000-0000-0000-000000000101  'A10 Main'
--     G2       a1000000-0000-0000-0000-000000000102  'A10 Other'
--     PROBE_G  a1000000-0000-0000-0000-000000000103  archived, used by the INSERT probes
--
--   The block u2 -> u4 is SYMMETRIC (public.is_blocked), so it hides the
--   content of BOTH parties: `member` cannot see `blocked`'s content and
--   `blocked` cannot see `member`'s content. Section G asserts that.
-- =============================================================================

begin;
set local search_path = extensions, public;

-- 40 tables x 5 personas x 3 commands  = 600
-- + 10 behavioural INSERT probes x 5 personas = 50
-- + 8 structural assertions + 4 symmetry assertions + 5 oracle assertions = 17
select plan(667);

-- The expectation table is created FIRST: it materialises the temp namespace,
-- which the pg_temp.* probe helpers below then live in.
create temporary table a10_expect (
  tbl       text primary key,
  sel       int[] not null,
  upd       int[] not null,
  del       int[] not null,
  ins_stmt  text,
  ins_cnt   int[]
) on commit drop;

-- -----------------------------------------------------------------------------
-- A. Probe helpers (SECURITY INVOKER: they run with the CURRENT role, so the
--    table's own RLS policy applies).
--
--    Every probe raises a deliberate exception on purpose: the surrounding
--    PL/pgSQL block is a sub-transaction, so the INSERT/UPDATE/DELETE is
--    ROLLED BACK while the row counter survives. The fixture therefore stays
--    intact for the next persona.
-- -----------------------------------------------------------------------------

create function pg_temp.a10_probe_select (p_table text)
  returns bigint
  language plpgsql
as $$
declare
  n bigint;
begin
  begin
    execute format ('select count(*) from %s', p_table) into n;
  exception when others then
    -- no table privilege for this role: the table is unreachable (count 0)
    n := 0;
  end;
  return coalesce (n, 0);
end;
$$;

create function pg_temp.a10_probe_update (p_table text)
  returns bigint
  language plpgsql
as $$
declare
  v_col text;
  n     bigint;
begin
  select a.attname into v_col
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace ns on ns.oid = c.relnamespace
  join pg_catalog.pg_attribute a on a.attrelid = c.oid
  where ns.nspname = split_part (p_table, '.', 1)
    and c.relname  = split_part (p_table, '.', 2)
    and a.attnum > 0 and not a.attisdropped
    and a.attidentity = '' and a.attgenerated = ''
    and has_column_privilege (current_user, p_table, a.attname, 'UPDATE')
    and not exists (
      select 1 from pg_catalog.pg_index i
      where i.indrelid = c.oid and i.indisprimary
        and a.attnum = any (i.indkey::smallint[]))
  order by a.attnum
  limit 1;

  if v_col is null then
    return 0;
  end if;

  begin
    execute format ('update %s set %I = %I', p_table, v_col, v_col);
    get diagnostics n = row_count;
    raise exception 'a10_rollback';
  exception when others then
    null;
  end;
  return coalesce (n, 0);
end;
$$;

create function pg_temp.a10_probe_delete (p_table text)
  returns bigint
  language plpgsql
as $$
declare
  n bigint;
begin
  begin
    execute format ('delete from %s', p_table);
    get diagnostics n = row_count;
    raise exception 'a10_rollback';
  exception when others then
    null;
  end;
  return coalesce (n, 0);
end;
$$;

create function pg_temp.a10_probe_insert (p_stmt text)
  returns bigint
  language plpgsql
as $$
declare
  n bigint;
begin
  begin
    execute p_stmt;
    get diagnostics n = row_count;
    raise exception 'a10_rollback';
  exception when others then
    null;
  end;
  return coalesce (n, 0);
end;
$$;

-- The temp namespace already grants USAGE to PUBLIC and the functions get the
-- default EXECUTE grant, so `anon` and `authenticated` can call the probes.
-- (`GRANT … ON SCHEMA pg_temp` does NOT work: GRANT resolves the schema name
--  literally and the real namespace is `pg_temp_<pid>`.)

-- -----------------------------------------------------------------------------
-- B. Fixture
-- -----------------------------------------------------------------------------

insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a1000000-0000-0000-0000-000000000001', 'a10_ana@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a1000000-0000-0000-0000-000000000002', 'a10_bruno@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a1000000-0000-0000-0000-000000000003', 'a10_carla@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a1000000-0000-0000-0000-000000000004', 'a10_daniel@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('a1000000-0000-0000-0000-000000000005', 'a10_eve@example.test',    'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.profiles (id, display_name)
values
  ('a1000000-0000-0000-0000-000000000001', 'Ana'),
  ('a1000000-0000-0000-0000-000000000002', 'Bruno'),
  ('a1000000-0000-0000-0000-000000000003', 'Carla'),
  ('a1000000-0000-0000-0000-000000000004', 'Daniel'),
  ('a1000000-0000-0000-0000-000000000005', 'Eve')
on conflict (id) do update set display_name = excluded.display_name;

insert into public.groups (id, name, group_type, created_by, archived_at)
values
  ('a1000000-0000-0000-0000-000000000101', 'A10 Main',   'fraternity', 'a1000000-0000-0000-0000-000000000001', null),
  ('a1000000-0000-0000-0000-000000000102', 'A10 Other',  'fraternity', 'a1000000-0000-0000-0000-000000000003', null),
  ('a1000000-0000-0000-0000-000000000103', 'A10 Probe',  'fraternity', 'a1000000-0000-0000-0000-000000000001', now());

insert into public.group_members (group_id, user_id, role)
values
  ('a1000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000001', 'admin'),
  ('a1000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000002', 'member'),
  ('a1000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000004', 'member'),
  ('a1000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000005', 'member'),
  ('a1000000-0000-0000-0000-000000000102', 'a1000000-0000-0000-0000-000000000003', 'admin');

-- The block is SYMMETRIC: u2 blocks u4, so BOTH hide each other.
insert into public.user_blocks (blocker_id, blocked_id)
values ('a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000004');

-- The A7 liturgical seed is removed so every count is deterministic.
delete from public.daily_readings;
delete from public.liturgical_days;
delete from public.saint_icons;
delete from public.saints;

-- One row per table, owned by u2 unless stated otherwise.
insert into public.practice_points (group_id, practice_kind, points) values (null, 'rosary', 1);

insert into public.group_invites (group_id, code, created_by)
values ('a1000000-0000-0000-0000-000000000101', '100001', 'a1000000-0000-0000-0000-000000000001');

insert into public.slot_unlocks (user_id, kind, source)
values ('a1000000-0000-0000-0000-000000000002', 'group_slot', 'admin_grant');

insert into public.check_ins (id, user_id, practice_kind, sharing, local_date, timezone, reflection_text)
values ('a1000000-0000-0000-0000-000000000201', 'a1000000-0000-0000-0000-000000000002',
        'rosary', 'group', current_date, 'America/Sao_Paulo', 'a10 reflection');

insert into public.check_in_destinations (check_in_id, group_id)
values ('a1000000-0000-0000-0000-000000000201', 'a1000000-0000-0000-0000-000000000101');

-- The feed post is created by A4's fan-out trigger
-- (`trg_check_in_destinations_fanout`), which is NOT idempotent: the post
-- therefore exists exactly once and every dependent row references it through
-- the check-in.
insert into public.amen_reactions (post_id, user_id, reaction_type)
select id, 'a1000000-0000-0000-0000-000000000002', 'amen'
from public.feed_posts where check_in_id = 'a1000000-0000-0000-0000-000000000201' limit 1;

-- Three comments on that post: one by the member (u2), one by the admin (u1)
-- and one by the blocked member (u4). The block u2 -> u4 hides the u4 comment
-- from u2 AND the u2 comment from u4.
insert into public.feed_post_comments (post_id, group_id, user_id, body)
select id, 'a1000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000002', 'a10 comment by the member'
from public.feed_posts where check_in_id = 'a1000000-0000-0000-0000-000000000201' limit 1;

insert into public.feed_post_comments (post_id, group_id, user_id, body)
select id, 'a1000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000001', 'a10 comment by the admin'
from public.feed_posts where check_in_id = 'a1000000-0000-0000-0000-000000000201' limit 1;

insert into public.feed_post_comments (post_id, group_id, user_id, body)
select id, 'a1000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000004', 'a10 comment by the blocked member'
from public.feed_posts where check_in_id = 'a1000000-0000-0000-0000-000000000201' limit 1;

insert into public.streaks (user_id, current_streak, longest_streak, total_practices)
values ('a1000000-0000-0000-0000-000000000002', 1, 1, 1);

insert into public.streak_events (user_id, event_type, local_date, streak_after)
values ('a1000000-0000-0000-0000-000000000002', 'practice', current_date, 1);

insert into public.streak_mercy_uses (user_id, used_on, repairs_date)
values ('a1000000-0000-0000-0000-000000000002', current_date - 2, current_date - 1);

insert into public.streak_mercy_grants (user_id) values ('a1000000-0000-0000-0000-000000000002');

insert into public.prayer_intentions (id, group_id, user_id, body)
values ('a1000000-0000-0000-0000-000000000203', 'a1000000-0000-0000-0000-000000000101',
        'a1000000-0000-0000-0000-000000000002', 'a10 intention');

insert into public.intention_prayers (intention_id, prayer_id)
values ('a1000000-0000-0000-0000-000000000203', 'a1000000-0000-0000-0000-000000000002');

insert into public.chat_messages (id, group_id, user_id, body)
values ('a1000000-0000-0000-0000-000000000204', 'a1000000-0000-0000-0000-000000000101',
        'a1000000-0000-0000-0000-000000000002', 'a10 chat');

insert into public.pinned_notices (group_id, author_id, body)
values ('a1000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000001', 'a10 notice');

insert into public.content_reports (reporter_id, target_type, target_id, group_id, reason)
select 'a1000000-0000-0000-0000-000000000002', 'post', id, 'a1000000-0000-0000-0000-000000000101', 'spam'
from public.feed_posts where check_in_id = 'a1000000-0000-0000-0000-000000000201' limit 1;

insert into public.moderation_actions (actor_id, action_type, target_type, target_id, group_id)
select 'a1000000-0000-0000-0000-000000000001', 'hide_post', 'post', id, 'a1000000-0000-0000-0000-000000000101'
from public.feed_posts where check_in_id = 'a1000000-0000-0000-0000-000000000201' limit 1;

insert into public.audit_log (actor_id, action, target_type, target_id)
values ('a1000000-0000-0000-0000-000000000001', 'a10.audit', 'group',
        'a1000000-0000-0000-0000-000000000101');

insert into public.account_deletion_requests (user_id, confirmation_token, status, confirmed_at)
values ('a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000301',
        'confirmed', now());

insert into public.ad_view_tokens (user_id, transaction_id, reward_type, expires_at)
values ('a1000000-0000-0000-0000-000000000002', 'a10-transaction-0001', 'group_slot', now() + interval '1 hour');

insert into public.reward_grants (user_id, reward_type, source)
values ('a1000000-0000-0000-0000-000000000002', 'group_slot', 'admin_grant');

insert into public.device_tokens (user_id, apns_token, platform, environment)
values ('a1000000-0000-0000-0000-000000000002', 'a10-device-token', 'ios', 'production');

insert into public.notification_outbox (user_id, notification_type, title, body, dedupe_key)
values ('a1000000-0000-0000-0000-000000000002', 'guardian_nudge', 'a10', 'a10', 'a10-dedupe-0001');

-- A8's notification triggers (amen / prayer / pinned notice) enqueue rows of
-- their own; they are removed here so the outbox count is deterministic for
-- the RLS matrix (A8's own suite covers the notification fan-out).
delete from public.notification_outbox where dedupe_key <> 'a10-dedupe-0001';

insert into public.liturgical_days (calendar_date, season, liturgical_color)
values (current_date, 'ordinary_time', 'green');

insert into public.daily_readings (calendar_date) values (current_date);

insert into public.saints (calendar_date, name, kind) values (current_date, 'a10 saint', 'saint');

insert into public.saint_icons (saint_id, slug, name, icon_sf_symbol)
select id, 'a10-icon', 'a10 icon', 'heart' from public.saints limit 1;

insert into public.user_saint_unlocks (user_id, saint_icon_id, expires_at)
select 'a1000000-0000-0000-0000-000000000002', id, now() + interval '7 days' from public.saint_icons limit 1;

insert into public.sponsors (name, slug) values ('a10 sponsor', 'a10-sponsor');

insert into public.sponsored_challenges (group_id, sponsor_id, headline)
values ('a1000000-0000-0000-0000-000000000101',
        (select id from public.sponsors where slug = 'a10-sponsor'), 'a10 headline');

insert into public.group_featured (group_id) values ('a1000000-0000-0000-0000-000000000101');

insert into public.guardian_angel_opt_ins (user_id, group_id)
values ('a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000101');

insert into public.guardian_angel_pairings (group_id, cycle_key, guardian_id, protected_id, cycle_starts_on, cycle_ends_on)
values ('a1000000-0000-0000-0000-000000000101', 'a10-cycle',
        'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000004',
        current_date, current_date + 6);

insert into public.guardian_nudges (group_id, pairing_id, sender_id, protected_id, cycle_key, local_date)
select 'a1000000-0000-0000-0000-000000000101', id,
       'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000004',
       'a10-cycle', current_date
from public.guardian_angel_pairings limit 1;

insert into public.ssv_receipts (outcome, transaction_id) values ('granted', 'a10-ssv-0001');

-- -----------------------------------------------------------------------------
-- C. The expectations (hand written, one row per table)
--
--    sel / upd / del are the number of rows each persona can reach.
--    ins_stmt is NULL when no behavioural INSERT probe is defined for the
--    table (the policy-level INSERT coverage is asserted in section D).
-- -----------------------------------------------------------------------------

insert into a10_expect (tbl, sel, upd, del, ins_stmt, ins_cnt) values
 ('public.account_deletion_requests', '{0,0,1,0,0}', '{0,0,1,0,0}', '{0,0,0,0,0}',
   $i$insert into public.account_deletion_requests (user_id, confirmation_token, status) values ('%s'::uuid, gen_random_uuid(), 'cancelled')$i$, '{0,1,1,1,1}'),
 ('public.ad_view_tokens',           '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.amen_reactions',           '{0,0,1,1,0}', '{0,0,0,0,0}', '{0,0,1,0,0}',
   $i$insert into public.amen_reactions (post_id, user_id, reaction_type) select id, '%s'::uuid, 'united_in_prayer' from public.feed_posts where check_in_id = 'a1000000-0000-0000-0000-000000000201' limit 1$i$, '{0,0,1,1,0}'),
 ('public.audit_log',                '{0,1,0,1,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.chat_messages',            '{0,0,1,1,0}', '{0,0,0,0,0}', '{0,0,1,1,0}',
   $i$insert into public.chat_messages (group_id, user_id, body) values ('a1000000-0000-0000-0000-000000000101'::uuid, '%s'::uuid, 'a10 probe')$i$, '{0,0,1,1,1}'),
 ('public.check_in_destinations',    '{0,0,1,1,1}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.check_ins',                '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,1,0,0}', null, null),
 ('public.content_reports',          '{0,0,1,1,0}', '{0,0,0,1,0}', '{0,0,0,0,0}',
   $i$insert into public.content_reports (reporter_id, target_type, target_id, group_id, reason) values ('%s'::uuid, 'post', 'a1000000-0000-0000-0000-000000000299'::uuid, 'a1000000-0000-0000-0000-000000000101'::uuid, 'spam')$i$, '{0,1,1,1,1}'),
 ('public.daily_readings',           '{1,1,1,1,1}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.device_tokens',            '{0,0,1,0,0}', '{0,0,1,0,0}', '{0,0,1,0,0}',
   $i$insert into public.device_tokens (user_id, apns_token) values ('%s'::uuid, 'a10-probe-token')$i$, '{0,1,1,1,1}'),
 ('public.feed_post_comments',       '{0,0,2,3,2}', '{0,0,1,1,1}', '{0,0,1,3,1}',
   $i$insert into public.feed_post_comments (post_id, group_id, user_id, body) select id, 'a1000000-0000-0000-0000-000000000101'::uuid, '%s'::uuid, 'a10 probe' from public.feed_posts where check_in_id = 'a1000000-0000-0000-0000-000000000201' limit 1$i$, '{0,0,1,1,0}'),
  ('public.feed_posts',               '{0,0,1,1,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.group_featured',           '{1,1,1,1,1}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.group_invites',            '{0,0,0,1,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.group_members',            '{0,1,4,4,4}', '{0,1,0,4,0}', '{0,1,1,4,1}',
   $i$insert into public.group_members (group_id, user_id) values ('a1000000-0000-0000-0000-000000000103'::uuid, '%s'::uuid)$i$, '{0,1,1,1,1}'),
 ('public.groups',                   '{0,2,2,2,2}', '{0,1,0,1,0}', '{0,1,0,1,0}',
   $i$insert into public.groups (name, created_by) values ('a10 probe', '%s'::uuid)$i$, '{0,1,1,1,1}'),
 ('public.guardian_angel_opt_ins',   '{0,0,1,1,1}', '{0,0,0,0,0}', '{0,0,1,0,0}', null, null),
 ('public.guardian_angel_pairings',  '{0,0,0,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.guardian_nudges',          '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.intention_prayers',        '{0,0,1,1,0}', '{0,0,0,0,0}', '{0,0,1,0,0}', null, null),
 ('public.liturgical_days',           '{1,1,1,1,1}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.moderation_actions',       '{0,0,0,1,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.notification_outbox',      '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.pinned_notices',           '{0,0,1,1,1}', '{0,0,0,1,0}', '{0,0,0,1,0}', null, null),
 ('public.practice_points',          '{0,1,1,1,1}', '{0,1,1,1,1}', '{0,1,1,1,1}', null, null),
 ('public.prayer_intentions',        '{0,0,1,1,0}', '{0,0,1,0,0}', '{0,0,1,1,0}',
   $i$insert into public.prayer_intentions (group_id, user_id, body) values ('a1000000-0000-0000-0000-000000000101'::uuid, '%s'::uuid, 'a10 probe')$i$, '{0,0,1,1,1}'),
 ('public.profiles',                 '{0,1,4,4,4}', '{0,1,1,1,1}', '{0,0,0,0,0}', null, null),
 ('public.reward_grants',            '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.saint_icons',              '{1,1,1,1,1}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.saints',                   '{1,1,1,1,1}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.slot_unlocks',             '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.sponsored_challenges',     '{1,1,1,1,1}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.sponsors',                 '{1,1,1,1,1}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.ssv_receipts',             '{0,0,0,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.streak_events',            '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.streak_mercy_grants',      '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.streak_mercy_uses',        '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.streaks',                  '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null),
 ('public.user_blocks',              '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,1,0,0}',
   $i$insert into public.user_blocks (blocker_id, blocked_id) values ('%s'::uuid, 'a1000000-0000-0000-0000-000000000005'::uuid)$i$, '{0,1,1,1,1}'),
 ('public.user_saint_unlocks',       '{0,0,1,0,0}', '{0,0,0,0,0}', '{0,0,0,0,0}', null, null);

grant select on a10_expect to anon, authenticated;

-- -----------------------------------------------------------------------------
-- D. Structure
-- -----------------------------------------------------------------------------

select ok (not exists (
         select 1 from pg_catalog.pg_class c
         join pg_catalog.pg_namespace n on n.oid = c.relnamespace
         where n.nspname = 'public' and c.relkind = 'r'
           and (not c.relrowsecurity or not c.relforcerowsecurity)),
       'every public table has RLS enabled AND forced');

select ok (not exists (
         select 1 from pg_catalog.pg_class c
         join pg_catalog.pg_namespace n on n.oid = c.relnamespace
         where n.nspname = 'public' and c.relkind = 'r'
           and not exists (select 1 from pg_catalog.pg_policy p where p.polrelid = c.oid)),
       'every public table has at least one policy');

select is ((select string_agg (n.nspname || '.' || c.relname, ',' order by c.relname)
            from pg_catalog.pg_class c
            join pg_catalog.pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'public' and c.relkind = 'r'),
           (select string_agg (tbl, ',' order by tbl) from a10_expect),
           'the expectation table covers EXACTLY the public tables');

select is ((select string_agg (DISTINCT tablename, ',' order by tablename)
            from pg_catalog.pg_policies
            where schemaname = 'public' and cmd = 'INSERT' and 'authenticated'::name = any (roles)),
           'account_deletion_requests,amen_reactions,chat_messages,content_reports,device_tokens,feed_post_comments,group_members,groups,guardian_angel_opt_ins,intention_prayers,pinned_notices,practice_points,prayer_intentions,user_blocks',
           'exactly the expected tables grant INSERT to authenticated');

select is ((select string_agg (DISTINCT tablename, ',' order by tablename)
            from pg_catalog.pg_policies
            where schemaname = 'public' and cmd = 'UPDATE' and 'authenticated'::name = any (roles)),
           'account_deletion_requests,content_reports,device_tokens,feed_post_comments,group_members,groups,pinned_notices,practice_points,prayer_intentions,profiles',
           'exactly the expected tables grant UPDATE to authenticated');

select is ((select string_agg (DISTINCT tablename, ',' order by tablename)
            from pg_catalog.pg_policies
            where schemaname = 'public' and cmd = 'DELETE' and 'authenticated'::name = any (roles)),
           'amen_reactions,chat_messages,check_ins,device_tokens,feed_post_comments,group_members,groups,guardian_angel_opt_ins,intention_prayers,pinned_notices,practice_points,prayer_intentions,user_blocks',
           'exactly the expected tables grant DELETE to authenticated');

select ok (not exists (
         select 1 from pg_catalog.pg_policies
         where schemaname = 'public' and cmd in ('INSERT', 'UPDATE', 'DELETE') and 'anon'::name = any (roles)),
       'anon may never write to any public table');

select ok (not exists (
         select 1 from pg_catalog.pg_policies
         where schemaname = 'public' and cmd = 'SELECT' and 'anon'::name = any (roles)
           and tablename not in ('daily_readings', 'group_featured', 'liturgical_days', 'saint_icons', 'saints', 'sponsored_challenges', 'sponsors')),
       'anon may only SELECT the public liturgical/discovery tables');

-- -----------------------------------------------------------------------------
-- E. THE MATRIX -- 40 tables x 5 personas x (SELECT, UPDATE, DELETE)
--    plus the behavioural INSERT probes.
-- -----------------------------------------------------------------------------

do $$
declare
  r        record;
  i        int;
  v_p      text;
  v_uid    uuid;
  v_n      bigint;
  v_personas text[] := array['anon', 'outsider', 'member', 'admin', 'blocked'];
  v_uids     uuid[] := array[
      'a1000000-0000-0000-0000-000000000005'::uuid,  -- anon   (payload owner only)
      'a1000000-0000-0000-0000-000000000003'::uuid,  -- outsider
      'a1000000-0000-0000-0000-000000000002'::uuid,  -- member
      'a1000000-0000-0000-0000-000000000001'::uuid,  -- admin
      'a1000000-0000-0000-0000-000000000004'::uuid]; -- blocked
begin
  for i in 1..5 loop
    v_p   := v_personas[i];
    v_uid := v_uids[i];

    if v_p = 'anon' then
      execute 'set local role anon';
      execute $q$set local request.jwt.claims = '{}'$q$;
    else
      execute 'set local role authenticated';
      execute format ('set local request.jwt.claims = %L',
                      json_build_object ('sub', v_uid, 'role', 'authenticated')::text);
    end if;

    for r in select * from a10_expect order by tbl loop
      v_n := pg_temp.a10_probe_select (r.tbl);
      perform is (v_n, r.sel[i]::bigint,
                  format ('%s / %s: SELECT reaches %s row(s)', r.tbl, v_p, r.sel[i])::text);

      v_n := pg_temp.a10_probe_update (r.tbl);
      perform is (v_n, r.upd[i]::bigint,
                  format ('%s / %s: UPDATE reaches %s row(s)', r.tbl, v_p, r.upd[i])::text);

      v_n := pg_temp.a10_probe_delete (r.tbl);
      perform is (v_n, r.del[i]::bigint,
                  format ('%s / %s: DELETE reaches %s row(s)', r.tbl, v_p, r.del[i])::text);

      if r.ins_stmt is not null then
        v_n := pg_temp.a10_probe_insert (format (r.ins_stmt, v_uid));
        perform is (v_n, r.ins_cnt[i]::bigint,
                    format ('%s / %s: INSERT reaches %s row(s)', r.tbl, v_p, r.ins_cnt[i])::text);
      end if;
    end loop;

    execute 'reset role';
  end loop;
end;
$$;

-- -----------------------------------------------------------------------------
-- F. The block relation is SYMMETRIC (both directions hide the content)
-- -----------------------------------------------------------------------------

select ok (private.is_blocked_impl ('a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000004'),
           'is_blocked: the member sees the block');
select ok (private.is_blocked_impl ('a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002'),
           'is_blocked: the blocked member sees the block too (symmetric)');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a1000000-0000-0000-0000-000000000004","role":"authenticated"}';
select is ((select count(*) from public.feed_posts), 0::bigint,
           'the blocked member cannot read the blocker feed post');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"a1000000-0000-0000-0000-000000000002","role":"authenticated"}';
select is ((select count(*) from public.feed_posts), 1::bigint,
           'the blocker still reads its own feed post');
reset role;

-- -----------------------------------------------------------------------------
-- G. The enumeration oracle is closed (A10 / migration 0900)
-- -----------------------------------------------------------------------------

select ok (not exists (
         select 1 from pg_catalog.pg_proc p
         join pg_catalog.pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public'
           and p.proname in ('is_group_member', 'is_group_admin', 'is_blocked')
           and pg_get_function_identity_arguments (p.oid) like '%p_user_id%'),
       'the two-argument RLS helpers no longer exist (no enumeration oracle)');

select ok (not has_function_privilege ('anon', 'public.is_group_member (uuid)', 'execute'),
           'anon may not execute public.is_group_member');
select ok (not has_function_privilege ('anon', 'public.is_blocked (uuid)', 'execute'),
           'anon may not execute public.is_blocked');
select ok (not has_function_privilege ('anon', 'private.is_group_member_impl (uuid, uuid)', 'execute'),
           'anon may not execute the private membership implementation');
select ok (not has_schema_privilege ('anon', 'private', 'usage'),
           'anon has no USAGE on the private schema');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
