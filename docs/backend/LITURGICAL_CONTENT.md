# Liturgical content & the CNBB text pipeline — A7

> **Owner:** A7 (liturgical content & monetization) · migrations `0601`–`0606`
> **Schema:** [`supabase/SCHEMA.md`](../../supabase/SCHEMA.md) · **Tests:** `supabase/tests/a7/`

This document explains how the liturgical calendar is seeded, how a real CNBB
text feed must be ingested, what `is_complete` means, and the hard rule that
Scripture text is never paraphrased or generated.

---

## 1. The tables (all read-only for clients)

| Table | Holds | Who writes |
|---|---|---|
| `public.liturgical_days` | one row per calendar day: season, liturgical colour, celebration, rank | `service_role` (seed / ingest) |
| `public.daily_readings` | First Reading, Psalm and Gospel of the day + `translation` + `is_complete` | `service_role` (ingest only) |
| `public.saints` | the saints of the day (name, kind, biography, patronage) | `service_role` (ingest only) |
| `public.saint_icons` | the unlockable reward themes (slug, SF Symbol, season) | `service_role` |
| `public.user_saint_unlocks` | a user's unlocked theme until `expires_at` | `public.grant_reward` only |

`SELECT` is granted to `anon` and `authenticated` (the content is genuinely
public); **no** client `INSERT`/`UPDATE`/`DELETE` is possible: the write
privileges are revoked from the platform's default grants and there is no
write policy at all.

> **Privacy (CONVENTIONS §8).** None of these tables holds a confession
> record, a spiritual-diary text or a private check-in. `daily_readings` holds
> public Scripture only.

---

## 2. How the calendar is seeded

The calendar is **computed**, never typed out day by day
(`supabase/migrations/0605_seed_liturgical_calendar.sql`, mirrored in
`supabase/seed_liturgical.sql` and included by `supabase/seed.sql`):

```
private.easter_sunday (p_year)        -- anonymous Gregorian algorithm
private.first_sunday_on_or_after (d)   -- the Sunday on/after a date
private.liturgical_calendar (p_year)   -- the whole year, row by row
```

The rules implemented (general Roman calendar):

| Season | Range |
|---|---|
| **Advent** | the four Sundays before Christmas: the Sunday falling between 23 and 29 November → 24 December |
| **Christmas** | 25 December → the **Baptism of the Lord** (the Sunday on or after 6 January) |
| **Lent** | **Ash Wednesday** (Easter − 46 days) → Holy Saturday (Easter − 1) |
| **Easter** | Easter Sunday → **Pentecost** (Easter + 49) |
| **Ordinary Time** | the rest: the Monday after Pentecost, and the Monday after the Baptism of the Lord, until the day before Advent |

The **colour** rule:

* a solemnity or a feast of martyrs carries its own colour (white / red);
* every other day takes the colour of its season:
  `advent = purple` · `christmas = white` · `lent = purple` ·
  `easter = white` · `ordinary_time = green`.

The five colours are exactly the design-system tokens
(`green`, `purple`, `white`, `red`, `rose`).

### Seeded years

`2026` and `2027` — 730 days, fully covered (365 + 365).

Verified anchors (asserted by `supabase/tests/a7/liturgical.sql`):

| | 2026 | 2027 |
|---|---|---|
| Ash Wednesday | 18 Feb | 10 Feb |
| Easter | 5 Apr | 28 Mar |
| Pentecost | 24 May | 16 May |
| First Sunday of Advent | 29 Nov | 28 Nov |
| Baptism of the Lord | 11 Jan | 10 Jan |

### What is seeded with certainty

Only the fixed-date solemnities and feasts whose **date and Portuguese
liturgical name** are certain are named. Everything else is a plain day of its
season with `celebration = NULL`.

| Date | Celebration (pt-BR) | Rank | Colour |
|---|---|---|---|
| 6 Jan | Epifania do Senhor | solemnity | white |
| (Sun after 6 Jan) | Batismo do Senhor | solemnity | white |
| Ash Wednesday | Quarta-feira de Cinzas | ordinary | purple |
| 17 Mar | São Patrício | optional_memorial | season |
| 19 Mar | São José | solemnity | white |
| Easter | Páscoa | solemnity | white |
| 23 Apr | São Jorge | optional_memorial | season |
| 25 Apr | São Marcos | feast | red |
| Pentecost | Pentecostes | solemnity | white |
| 24 Jun | Nascimento de São João Batista | solemnity | white |
| 29 Jun | São Pedro e São Paulo | solemnity | red |
| 15 Aug | Assunção de Nossa Senhora | solemnity | white |
| 8 Sep | Natividade de Nossa Senhora | solemnity | white |
| 14 Sep | Exaltação da Santa Cruz | feast | red |
| 1 Nov | Todos os Santos | solemnity | white |
| 2 Nov | Finados | memorial | purple |
| Sunday before Advent | Cristo Rei | feast | white |
| 8 Dec | Imaculada Conceição | solemnity | white |
| 25 Dec | Natal do Senhor | solemnity | white |
| 26 Dec | São Estêvão, Protomártir | feast | red |
| 27 Dec | São João Evangelista | feast | white |
| 28 Dec | Santos Inocentes | feast | red |

### What is deliberately LEFT EMPTY

* **Every Scripture text** (`first_reading_text`, `psalm_text`,
  `gospel_text`) — `NULL`. The only seeded references are the three fixed
  Gospels that never change across the lectionary cycle: `Lucas 2,1-20`
  (Christmas), `Mateus 2,1-12` (Epiphany), `João 20,1-9` (Easter).
* **Every first-reading and psalm reference** except those three.
* **Every saint biography and patronage** — `NULL`.
* **The Annunciation (25 March)** — deliberately not seeded: in 2026 **and**
  2027 it falls in Holy Week and is *transferred* to the Monday after the
  Second Sunday of Easter. That transfer rule must come from the
  authoritative calendar, not from a hand-written table. (The day itself stays
  a normal Lent day, which is liturgically correct.)
* **Trinity Sunday and Corpus Christi** — not seeded: they are solemnities
  that *move* Ordinary Time, and the `liturgical_season` enum has no value for
  them. They arrive with the authoritative feed.
* **Movable memorials** that depend on the transfer rules (e.g. saints moved
  by an octave).

> **Accuracy beats completeness.** A day left empty shows the app "no
> celebration for this day yet"; a day with a wrong name is a religious error.
> Everything that is not certain is left empty on purpose.

---

## 3. The CNBB text pipeline (how the texts must arrive)

The product plan is explicit:

> *"All Scripture readings, Psalms, and Saints of the Day use official,
> unaltered Church translations (e.g. CNBB approved texts in Brazil)."*

Therefore:

1. **The source is the CNBB** (Conferência Nacional dos Bispos do Brasil)
   — the official Portuguese text of the Roman lectionary. The Vatican
   translation (`translation = 'vatican'`) is the only other accepted source.
2. **The transport is server-side and authenticated.** The ingest is a
   `service_role` write (a scheduled job / Edge Function / admin pipeline).
   There is **no client write path**: `anon` and `authenticated` have no
   `INSERT`/`UPDATE` privilege and no write policy on `daily_readings` or
   `saints`. A compromised client can never alter the Word of God shown in the
   app.
3. **The ingest is idempotent**: `daily_readings.calendar_date` and
   `saints (calendar_date, name)` are unique, so a re-run upserts instead of
   duplicating.
4. **The pipeline validates before it writes**: the row is only written with
   `is_complete = true` when it carries the First Reading **and** the Gospel
   of the official translation, both non-null. A partial ingest keeps
   `is_complete = false`.

### The `is_complete` flag

| value | meaning | what the app shows |
|---|---|---|
| `false` | the day exists in the calendar but the official text has not been ingested (or was ingested partially) | the celebration/colour, and an explicit "readings not available yet" state — **never a partial or invented passage** |
| `true` | the row was ingested from the authoritative feed and carries both the First Reading and the Gospel verbatim | the full reading, with the translation labelled |

`is_complete = true` is **impossible** without the texts — it is enforced by
the CHECK constraint:

```sql
constraint daily_readings_complete_check
  check (not is_complete or (first_reading_text is not null and gospel_text is not null))
```

---

## 4. The non-negotiable content policy

> **Scripture text is NEVER paraphrased, summarised, corrected, "improved",
> translated by hand or generated by an AI.** It is copied verbatim from the
> official CNBB (or Vatican) text, with its footnotes and its liturgical
> divisions.

Concretely:

* No agent, script, model or human may **write** Scripture into
  `daily_readings` by hand. The columns are only ever filled by the ingest
  pipeline that reads the official text.
* The seed writes **structure only** (dates, seasons, colours, celebration
  names, three fixed Gospel references). `is_complete` is `false` for every
  seeded row and the test suite asserts that no text is stored.
* The same rule applies to `saints.biography`: it stays `NULL` until an
  authoritative hagiographic source is ingested.
* The `public.ssv_receipts` / `reward_grants` tables record **that** a reward
  was earned — never anything about what the user prayed.

This is enforced by the pgTAP suite:

```
no reading is marked complete
no Scripture text is stored
every reading uses the CNBB translation
no saint biography is invented
a reading can only be complete when it carries the First Reading AND the Gospel
```

---

## 5. How the app reads the calendar

| RPC | Returns | Roles |
|---|---|---|
| `public.get_today_liturgy ()` | one jsonb row: the day, the readings and the saints of today. The date is computed in the caller's profile timezone (`America/Sao_Paulo` fallback) | `anon`, `authenticated` |
| `public.get_liturgical_calendar (p_year integer)` | one jsonb row: the whole year (date, season, colour, celebration, rank, saints) | `anon`, `authenticated` |

Both are cache-friendly (a single jsonb row) and read-only (SECURITY
INVOKER), so they cannot be used to reach data the caller could not already
read.

The direct PostgREST reads are also available for the plain lists:

```
GET /rest/v1/liturgical_days?calendar_date=eq.2026-12-25
GET /rest/v1/saints?calendar_date=eq.2026-12-26
GET /rest/v1/saint_icons?is_active=eq.true
```

---

## 6. Adding a new year

```sql
-- 2028
insert into public.liturgical_days (calendar_date, season, liturgical_color, celebration, "rank")
select c.calendar_date, c.season, c.liturgical_color, c.celebration, c."rank"
  from private.liturgical_calendar (2028) c
on conflict (calendar_date) do nothing;

insert into public.daily_readings (calendar_date, liturgical_color, translation, is_complete)
select ld.calendar_date, ld.liturgical_color, 'cnbb', false
  from public.liturgical_days ld
 where ld.calendar_date between date '2028-01-01' and date '2028-12-31'
on conflict (calendar_date) do nothing;
```

`private.liturgical_calendar` is valid for any year between 1583 and 4099 and
takes care of the leap years and the 19-year Metonic cycle by itself.
