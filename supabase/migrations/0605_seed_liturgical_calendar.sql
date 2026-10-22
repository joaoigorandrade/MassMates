-- =============================================================================
-- A7 · 0605 · Liturgical calendar seed (2026 + 2027)
-- =============================================================================
-- Owner: A7 (liturgical content & monetization).
--
-- The calendar is COMPUTED from the general Roman calendar rules, never typed
-- out day by day:
--
--   Advent          = the four Sundays before Christmas, i.e. from the Sunday
--                     falling between 23 and 29 November, up to 24 December.
--   Christmas       = 25 December up to (and including) the Baptism of the
--                     Lord, i.e. the Sunday on or after 6 January.
--   Lent            = Ash Wednesday (Easter - 46 days) up to Holy Saturday.
--   Easter          = Easter Sunday up to and including Pentecost
--                     (Easter + 49 days).
--   Ordinary Time   = the rest (the Monday after Pentecost, and the Monday
--                     after the Baptism of the Lord, up to the day before
--                     Advent).
--
-- Easter itself is computed with the anonymous Gregorian algorithm
-- (Meeus/Jones/Butcher), so the seed is reproducible for any year.
--
-- COLOUR RULE: a solemnity or a feast of martyrs has its own colour
-- (white / red); every other day takes the colour of its season:
--   advent = purple · christmas = white · lent = purple
--   easter = white · ordinary_time = green
--
-- CONTENT INTEGRITY: this seed writes the date/season/colour STRUCTURE and
-- the celebration names of the fixed-date solemnities we are certain about.
-- It writes NO Scripture text, NO psalm text, NO hagiography. The reading
-- text columns stay NULL and `is_complete` stays false until an authoritative
-- CNBB feed is ingested. Saints' biographies stay NULL for the same reason.
--
-- Idempotent: `on conflict do nothing` everywhere, so re-running the seed is
-- a no-op.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Calendar arithmetic
-- -----------------------------------------------------------------------------

create or replace function private.easter_sunday (p_year integer)
returns date
language plpgsql
immutable
set search_path = ''
as $$
declare
  a integer; b integer; c integer; d integer; e integer; f integer;
  g integer; h integer; i integer; k integer; l integer; m integer; n integer;
begin
  if p_year is null or p_year < 1583 or p_year > 4099 then
    raise exception 'unsupported year: %', p_year using errcode = '22023';
  end if;

  a := p_year % 19;
  b := p_year / 100;
  c := p_year % 100;
  d := b / 4;
  e := b % 4;
  f := (b + 8) / 25;
  g := (b - f + 1) / 3;
  h := (19 * a + b - d - g + 15) % 30;
  i := c / 4;
  k := c % 4;
  l := (32 + 2 * e + 2 * i - h - k) % 7;
  m := (a + 11 * h + 22 * l) / 451;
  n := h + l - 7 * m + 114;

  return make_date(p_year, n / 31, (n % 31) + 1);
end;
$$;

comment on function private.easter_sunday (integer) is
  'Easter Sunday of a year, computed with the anonymous Gregorian algorithm (Meeus/Jones/Butcher).';

create or replace function private.first_sunday_on_or_after (p_date date)
returns date
language sql
immutable
set search_path = ''
as $$
  select case
    when extract(dow from p_date) = 0 then p_date
    else p_date + (7 - extract(dow from p_date))::int
  end;
$$;

comment on function private.first_sunday_on_or_after (date) is
  'The first Sunday on or after the given date (used for Advent: the Sunday between 23 and 29 November; and for the Baptism of the Lord: the Sunday on or after 6 January).';

create or replace function private.liturgical_calendar (p_year integer)
returns table (
  calendar_date    date,
  season           public.liturgical_season,
  liturgical_color text,
  celebration      text,
  "rank"           text
)
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_easter        date := private.easter_sunday (p_year);
  v_ash_wednesday date := private.easter_sunday (p_year) - 46;
  v_pentecost     date := private.easter_sunday (p_year) + 49;
  v_advent_start  date := private.first_sunday_on_or_after (make_date(p_year, 11, 23));
  v_baptism       date := private.first_sunday_on_or_after (make_date(p_year, 1, 6));
  v_christmas     date := make_date(p_year, 12, 25);
  v_day           date;
  v_season        public.liturgical_season;
  v_color         text;
  v_celebration   text;
  v_rank          text;
  v_feast         record;
begin
  for v_day in
    select generate_series (make_date(p_year, 1, 1), make_date(p_year, 12, 31), interval '1 day')::date
  loop
    -- 1. the season of the day
    if v_day <= v_baptism then
      v_season := 'christmas';
    elsif v_day < v_ash_wednesday then
      v_season := 'ordinary_time';
    elsif v_day < v_easter then
      v_season := 'lent';
    elsif v_day <= v_pentecost then
      v_season := 'easter';
    elsif v_day < v_advent_start then
      v_season := 'ordinary_time';
    elsif v_day < v_christmas then
      v_season := 'advent';
    else
      v_season := 'christmas';
    end if;

    -- 2. the colour of the season
    v_color := case v_season
      when 'advent'    then 'purple'
      when 'christmas' then 'white'
      when 'lent'      then 'purple'
      when 'easter'    then 'white'
      else 'green'
    end;

    -- 3. the celebration of the day (fixed dates we are certain about)
    v_celebration := null;
    v_rank := 'ordinary';

    for v_feast in
      select *
        from (values
          (make_date(p_year, 1, 6),  'Epifania do Senhor',              'solemnity',        'white'),
          (v_baptism,               'Batismo do Senhor',              'solemnity',        'white'),
          (v_ash_wednesday,         'Quarta-feira de Cinzas',         'ordinary',         'purple'),
          (make_date(p_year, 3, 17),'São Patrício',                    'optional_memorial', null),
          (make_date(p_year, 3, 19),'São José',                        'solemnity',        'white'),
          (v_easter,                'Páscoa',                         'solemnity',        'white'),
          (make_date(p_year, 4, 23),'São Jorge',                       'optional_memorial', null),
          (make_date(p_year, 4, 25),'São Marcos',                      'feast',            'red'),
          (v_pentecost,             'Pentecostes',                    'solemnity',        'white'),
          (make_date(p_year, 6, 24),'Nascimento de São João Batista', 'solemnity',        'white'),
          (make_date(p_year, 6, 29),'São Pedro e São Paulo',           'solemnity',        'red'),
          (make_date(p_year, 8, 15),'Assunção de Nossa Senhora',      'solemnity',        'white'),
          (make_date(p_year, 9, 8), 'Natividade de Nossa Senhora',    'solemnity',        'white'),
          (make_date(p_year, 9, 14),'Exaltação da Santa Cruz',        'feast',            'red'),
          (make_date(p_year, 11, 1),'Todos os Santos',                'solemnity',        'white'),
          (make_date(p_year, 11, 2),'Finados',                        'memorial',         'purple'),
          (v_advent_start - 7,     'Cristo Rei',                     'feast',            'white'),
          (make_date(p_year, 12, 8),'Imaculada Conceição',            'solemnity',        'white'),
          (v_christmas,             'Natal do Senhor',                'solemnity',        'white'),
          (make_date(p_year, 12, 26),'São Estêvão, Protomártir',      'feast',            'red'),
          (make_date(p_year, 12, 27),'São João Evangelista',            'feast',            'white'),
          (make_date(p_year, 12, 28),'Santos Inocentes',               'feast',            'red')
        ) as f (celebration_date, celebration_name, celebration_rank, celebration_color)
    loop
      if v_feast.celebration_date = v_day then
        v_celebration := v_feast.celebration_name;
        v_rank := v_feast.celebration_rank;
        if v_feast.celebration_color is not null then
          v_color := v_feast.celebration_color;
        end if;
      end if;
    end loop;

    calendar_date := v_day;
    season := v_season;
    liturgical_color := v_color;
    celebration := v_celebration;
    "rank" := v_rank;
    return next;
  end loop;
end;
$$;

comment on function private.liturgical_calendar (integer) is
  'The liturgical calendar of one year, computed from the general Roman calendar rules. Returns the date, the season, the liturgical colour, the celebration and its rank for every day of the year.';

-- -----------------------------------------------------------------------------
-- The seed
-- -----------------------------------------------------------------------------

insert into public.liturgical_days (calendar_date, season, liturgical_color, celebration, "rank")
select c.calendar_date, c.season, c.liturgical_color, c.celebration, c."rank"
  from private.liturgical_calendar (2026) c
on conflict (calendar_date) do nothing;

insert into public.liturgical_days (calendar_date, season, liturgical_color, celebration, "rank")
select c.calendar_date, c.season, c.liturgical_color, c.celebration, c."rank"
  from private.liturgical_calendar (2027) c
on conflict (calendar_date) do nothing;

-- A reading slot per day. The TEXT columns stay NULL and is_complete stays
-- false: no Scripture is ever invented here.
insert into public.daily_readings (calendar_date, liturgical_color, translation, is_complete)
select ld.calendar_date, ld.liturgical_color, 'cnbb', false
  from public.liturgical_days ld
 where ld.calendar_date between date '2026-01-01' and date '2027-12-31'
on conflict (calendar_date) do nothing;

-- The Gospel reference of the three fixed readings we are certain about
-- (the same in every lectionary cycle). The TEXT is still not seeded.
update public.daily_readings dr
   set gospel_ref = f.gospel_ref
  from (values
    (date '2026-12-25', 'Lucas 2,1-20'),
    (date '2027-12-25', 'Lucas 2,1-20'),
    (date '2026-01-06', 'Mateus 2,1-12'),
    (date '2027-01-06', 'Mateus 2,1-12'),
    (date '2026-04-05', 'João 20,1-9'),
    (date '2027-03-28', 'João 20,1-9')
  ) as f (d, gospel_ref)
 where dr.calendar_date = f.d;

-- The saints of the day. NO biography is invented: the column stays NULL.
insert into public.saints (calendar_date, name, kind)
select f.d, f.n, 'saint'
  from (values
    (date '2026-03-17', 'São Patrício'),
    (date '2027-03-17', 'São Patrício'),
    (date '2026-03-19', 'São José'),
    (date '2027-03-19', 'São José'),
    (date '2026-04-23', 'São Jorge'),
    (date '2027-04-23', 'São Jorge'),
    (date '2026-04-25', 'São Marcos'),
    (date '2027-04-25', 'São Marcos'),
    (date '2026-06-24', 'São João Batista'),
    (date '2027-06-24', 'São João Batista'),
    (date '2026-06-29', 'São Pedro e São Paulo'),
    (date '2027-06-29', 'São Pedro e São Paulo'),
    (date '2026-12-26', 'São Estêvão'),
    (date '2027-12-26', 'São Estêvão'),
    (date '2026-12-27', 'São João Evangelista'),
    (date '2027-12-27', 'São João Evangelista'),
    (date '2026-12-28', 'Santos Inocentes'),
    (date '2027-12-28', 'Santos Inocentes')
  ) as f (d, n)
on conflict (calendar_date, name) do nothing;

-- The unlockable themes (reward catalogue). SF Symbol names only.
insert into public.saint_icons (slug, name, icon_sf_symbol, season, is_active)
select f.slug, f.n, f.icon, f.season::public.liturgical_season, true
  from (values
    ('vela-do-advento',      'Vela do Advento',        'flame',           'advent'),
    ('estrela-de-natal',     'Estrela de Natal',       'star.fill',       'christmas'),
    ('chama-do-espirito',    'Chama do Espírito Santo','flame.fill',      'easter'),
    ('agua-da-ressurreicao', 'Água da Ressurreição',   'drop.fill',       'easter'),
    ('oliva-da-paz',         'Oliva da Paz',           'leaf.fill',       'ordinary_time'),
    ('livro-da-sabedoria',   'Livro da Sabedoria',     'book.closed.fill', null)
  ) as f (slug, n, icon, season)
on conflict (slug) do nothing;
