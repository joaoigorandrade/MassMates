-- =============================================================================
-- A7 · liturgical.sql · liturgical content & the public calendar RPCs
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish();
--   select public.pgtap_summary() as result;   -- always the last result set
--   rollback;
-- =============================================================================

begin;
set local search_path = extensions, public;

-- Helper: SECURITY INVOKER, so the INSERT is attempted with the CURRENT role
-- and therefore with the current RLS policies. true = the write was ALLOWED.
create function pg_temp.try_insert_liturgical_day ()
  returns boolean
  language plpgsql
as $$
begin
  insert into public.liturgical_days (calendar_date, season, liturgical_color)
  values (date '2030-01-01', 'advent', 'purple');
  return true;
exception
  when others then
    return false;
end;
$$;

create function pg_temp.try_insert_reading ()
  returns boolean
  language plpgsql
as $$
begin
  insert into public.daily_readings (calendar_date, translation, is_complete)
  values (date '2030-01-01', 'cnbb', true);
  return true;
exception
  when others then
    return false;
end;
$$;

select plan(81);

-- ---------------------------------------------------------------------------
-- A. Tables
-- ---------------------------------------------------------------------------
select has_table ('public', 'liturgical_days', 'liturgical_days table exists');
select has_table ('public', 'daily_readings', 'daily_readings table exists');
select has_table ('public', 'saints', 'saints table exists');
select has_table ('public', 'saint_icons', 'saint_icons table exists');
select has_table ('public', 'user_saint_unlocks', 'user_saint_unlocks table exists');

-- ---------------------------------------------------------------------------
-- B. RLS enabled AND forced
-- ---------------------------------------------------------------------------
select ok (public.pgtap_rls_enabled ('public.liturgical_days'::regclass), 'RLS is enabled on liturgical_days');
select ok (public.pgtap_rls_enabled ('public.daily_readings'::regclass), 'RLS is enabled on daily_readings');
select ok (public.pgtap_rls_enabled ('public.saints'::regclass), 'RLS is enabled on saints');
select ok (public.pgtap_rls_enabled ('public.saint_icons'::regclass), 'RLS is enabled on saint_icons');
select ok (public.pgtap_rls_enabled ('public.user_saint_unlocks'::regclass), 'RLS is enabled on user_saint_unlocks');
select ok (public.pgtap_rls_forced ('public.liturgical_days'::regclass), 'RLS is FORCED on liturgical_days');
select ok (public.pgtap_rls_forced ('public.daily_readings'::regclass), 'RLS is FORCED on daily_readings');
select ok (public.pgtap_rls_forced ('public.saints'::regclass), 'RLS is FORCED on saints');
select ok (public.pgtap_rls_forced ('public.saint_icons'::regclass), 'RLS is FORCED on saint_icons');
select ok (public.pgtap_rls_forced ('public.user_saint_unlocks'::regclass), 'RLS is FORCED on user_saint_unlocks');

-- ---------------------------------------------------------------------------
-- C. Policies: SELECT only, never INSERT/UPDATE/DELETE
-- ---------------------------------------------------------------------------
select ok (public.pgtap_policy_count ('public.liturgical_days') = public.pgtap_policy_count ('public.liturgical_days', 'r'), 'liturgical_days has SELECT policies only');
select ok (public.pgtap_policy_count ('public.daily_readings') = public.pgtap_policy_count ('public.daily_readings', 'r'), 'daily_readings has SELECT policies only');
select ok (public.pgtap_policy_count ('public.saints') = public.pgtap_policy_count ('public.saints', 'r'), 'saints has SELECT policies only');
select ok (public.pgtap_policy_count ('public.saint_icons') = public.pgtap_policy_count ('public.saint_icons', 'r'), 'saint_icons has SELECT policies only');
select ok (public.pgtap_policy_count ('public.user_saint_unlocks') = public.pgtap_policy_count ('public.user_saint_unlocks', 'r'), 'user_saint_unlocks has SELECT policies only');
select ok (public.pgtap_policy_count ('public.liturgical_days', 'r') > 0, 'liturgical_days has a SELECT policy');
select ok (public.pgtap_policy_count ('public.liturgical_days', 'a') = 0, 'liturgical_days has no INSERT policy');
select ok (public.pgtap_policy_count ('public.liturgical_days', 'w') = 0, 'liturgical_days has no UPDATE policy');
select ok (public.pgtap_policy_count ('public.liturgical_days', 'd') = 0, 'liturgical_days has no DELETE policy');

-- ---------------------------------------------------------------------------
-- D. Table privileges: clients may read, never write
-- ---------------------------------------------------------------------------
select ok (has_table_privilege ('anon', 'public.liturgical_days', 'SELECT'), 'anon may SELECT liturgical_days');
select ok (has_table_privilege ('authenticated', 'public.daily_readings', 'SELECT'), 'authenticated may SELECT daily_readings');
select ok (not has_table_privilege ('anon', 'public.liturgical_days', 'INSERT'), 'anon may not INSERT into liturgical_days');
select ok (not has_table_privilege ('authenticated', 'public.liturgical_days', 'UPDATE'), 'authenticated may not UPDATE liturgical_days');
select ok (not has_table_privilege ('authenticated', 'public.daily_readings', 'DELETE'), 'authenticated may not DELETE from daily_readings');
select ok (not has_table_privilege ('anon', 'public.saints', 'INSERT'), 'anon may not INSERT into saints');
select ok (not has_table_privilege ('authenticated', 'public.saint_icons', 'INSERT'), 'authenticated may not INSERT into saint_icons');
select ok (not has_table_privilege ('authenticated', 'public.user_saint_unlocks', 'INSERT'), 'authenticated may not INSERT into user_saint_unlocks');

-- ---------------------------------------------------------------------------
-- E. Reads as anon and as authenticated
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{}';
select ok ((select count(*) from public.liturgical_days) > 0, 'anon can read the liturgical calendar');
select ok ((select count(*) from public.daily_readings) > 0, 'anon can read the daily readings');
select ok (not pg_temp.try_insert_liturgical_day (), 'anon cannot insert a liturgical day');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select ok ((select count(*) from public.saints) > 0, 'authenticated can read the saints');
select ok ((select count(*) from public.saint_icons) > 0, 'authenticated can read the themes');
select ok (not pg_temp.try_insert_liturgical_day (), 'authenticated cannot insert a liturgical day');
select ok (not pg_temp.try_insert_reading (), 'authenticated cannot insert a reading');
reset role;
set local request.jwt.claims = '{}';

-- ---------------------------------------------------------------------------
-- F. get_today_liturgy()
-- ---------------------------------------------------------------------------
select ok (public.get_today_liturgy () ? 'day', 'get_today_liturgy returns a day payload');
select ok (public.get_today_liturgy () ? 'readings', 'get_today_liturgy returns a readings payload');
select ok (public.get_today_liturgy () ? 'saints', 'get_today_liturgy returns a saints array');
select ok (public.get_today_liturgy () -> 'day' ->> 'season' is not null, 'today has a liturgical season');
select ok (public.get_today_liturgy () -> 'day' ->> 'liturgical_color'
             in ('green', 'purple', 'white', 'red', 'rose'), 'today colour is one of the five allowed values');
select ok (public.get_today_liturgy () -> 'readings' ->> 'is_complete' = 'false', 'today readings are not marked complete (no invented text)');
select ok (public.get_today_liturgy () -> 'readings' ->> 'translation' = 'cnbb', 'today readings use the CNBB translation');
select ok (
  exists (
    select 1 from public.liturgical_days ld
     where ld.calendar_date = (public.get_today_liturgy () ->> 'date')::date
  ),
  'the date returned by get_today_liturgy exists in the calendar');
select ok (jsonb_typeof (public.get_today_liturgy () -> 'saints') = 'array', 'the saints of the day is an array');

-- ---------------------------------------------------------------------------
-- G. get_liturgical_calendar()
-- ---------------------------------------------------------------------------
select ok (public.get_liturgical_calendar (2026) ->> 'count' = '365', 'the 2026 calendar has 365 days');
select ok (public.get_liturgical_calendar (2027) ->> 'count' = '365', 'the 2027 calendar has 365 days');
select ok (public.get_liturgical_calendar (2026) -> 'days' -> 0 ->> 'date' = '2026-01-01', 'the 2026 calendar starts on 1 January');
select ok (public.get_liturgical_calendar (2026) -> 'days' -> 364 ->> 'date' = '2026-12-31', 'the 2026 calendar ends on 31 December');
select ok (public.get_liturgical_calendar (2027) -> 'days' -> 0 ->> 'date' = '2027-01-01', 'the 2027 calendar starts on 1 January');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
     where d ->> 'season' is null
  ),
  'every day of 2026 has a season');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
     where d ->> 'liturgical_color' is null
  ),
  'every day of 2026 has a colour');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
     where d ->> 'liturgical_color' not in ('green', 'purple', 'white', 'red', 'rose')
  ),
  'every colour of 2026 is one of the five allowed values');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
     where d ->> 'season' = 'lent' and d ->> 'liturgical_color' not in ('purple', 'white')
  ),
  'every Lent day of 2026 is purple (white only on a solemnity)');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
     where d ->> 'season' = 'easter' and d ->> 'liturgical_color' not in ('white', 'red')
  ),
  'every Easter day of 2026 is white (red only on a martyr feast)');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
     where d ->> 'season' = 'advent' and d ->> 'liturgical_color' not in ('purple', 'white')
  ),
  'every Advent day of 2026 is purple (white only on the Immaculate Conception)');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
     where d ->> 'season' = 'christmas' and d ->> 'liturgical_color' not in ('white', 'red')
  ),
  'every Christmas day of 2026 is white or red');
select ok (
  (select count(*) from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
    where d ->> 'season' = 'ordinary_time' and d ->> 'liturgical_color' <> 'green') = 8,
  'the 2026 Ordinary Time has exactly the 8 documented feast overrides');
select ok (
  (select count(*) from jsonb_array_elements (public.get_liturgical_calendar (2027) -> 'days') d
    where d ->> 'season' = 'ordinary_time' and d ->> 'liturgical_color' <> 'green') = 8,
  'the 2027 Ordinary Time has exactly the 8 documented feast overrides');
select ok (
  (select array_agg (d ->> 'date' order by (d ->> 'date')::date)
     from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
    where d ->> 'season' = 'ordinary_time' and d ->> 'liturgical_color' <> 'green')
  = array['2026-06-24', '2026-06-29', '2026-08-15', '2026-09-08',
           '2026-09-14', '2026-11-01', '2026-11-02', '2026-11-22'],
  'the 2026 Ordinary Time overrides are exactly the expected solemnities');
select ok (
  (select array_agg (d ->> 'date' order by (d ->> 'date')::date)
     from jsonb_array_elements (public.get_liturgical_calendar (2027) -> 'days') d
    where d ->> 'season' = 'ordinary_time' and d ->> 'liturgical_color' <> 'green')
  = array['2027-06-24', '2027-06-29', '2027-08-15', '2027-09-08',
           '2027-09-14', '2027-11-01', '2027-11-02', '2027-11-21'],
  'the 2027 Ordinary Time overrides are exactly the expected solemnities');
select ok (
  not exists (
    select 1 from jsonb_array_elements (public.get_liturgical_calendar (2026) -> 'days') d
     where d ->> 'season' = 'ordinary_time'
       and d ->> 'liturgical_color' <> 'green'
       and d ->> 'celebration' is null
  ),
  'every Ordinary Time colour override carries a celebration name');

-- ---------------------------------------------------------------------------
-- H. The general Roman calendar anchors
-- ---------------------------------------------------------------------------
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2026-04-05' and season = 'easter' and celebration = 'Páscoa'), 'Easter 2026 is 5 April');
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2027-03-28' and season = 'easter' and celebration = 'Páscoa'), 'Easter 2027 is 28 March');
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2026-02-18' and season = 'lent' and celebration = 'Quarta-feira de Cinzas'), 'Ash Wednesday 2026 is 18 February');
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2027-02-10' and season = 'lent' and celebration = 'Quarta-feira de Cinzas'), 'Ash Wednesday 2027 is 10 February');
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2026-11-29' and season = 'advent'), 'Advent 2026 starts on 29 November (the fourth Sunday before Christmas)');
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2027-11-28' and season = 'advent'), 'Advent 2027 starts on 28 November');
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2026-12-25' and season = 'christmas' and celebration = 'Natal do Senhor'), 'Christmas 2026 is in the Christmas season');
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2026-01-11' and celebration = 'Batismo do Senhor'), 'the Baptism of the Lord 2026 is on 11 January');
select ok (exists (select 1 from public.liturgical_days where calendar_date = date '2026-05-24' and season = 'easter' and celebration = 'Pentecostes'), 'Pentecost 2026 is 24 May');
select ok ((select count(*) from public.liturgical_days where calendar_date between date '2026-01-01' and date '2027-12-31') = 730, 'the seed covers 2026 and 2027 completely');

-- ---------------------------------------------------------------------------
-- I. Content integrity: nothing is invented
-- ---------------------------------------------------------------------------
select ok ((select count(*) from public.daily_readings where is_complete) = 0, 'no reading is marked complete');
select ok ((select count(*) from public.daily_readings where first_reading_text is not null or psalm_text is not null or gospel_text is not null) = 0, 'no Scripture text is stored');
select ok ((select count(*) from public.daily_readings where translation <> 'cnbb') = 0, 'every reading uses the CNBB translation');
select ok ((select count(*) from public.saints where biography is not null) = 0, 'no saint biography is invented');
select ok ((select count(*) from public.saint_icons where is_active) > 0, 'there is at least one unlockable theme');
select throws_ok (
  $$insert into public.daily_readings (calendar_date, translation, is_complete)
    values (date '2030-06-01', 'cnbb', true)$$,
  '23514',
  'new row for relation "daily_readings" violates check constraint "daily_readings_complete_check"',
  'a reading can only be complete when it carries the First Reading AND the Gospel');

-- ---------------------------------------------------------------------------
-- Verdict
-- ---------------------------------------------------------------------------
select * from finish ();
select public.pgtap_summary () as result;

rollback;
