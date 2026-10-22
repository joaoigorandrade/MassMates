-- =============================================================================
-- A1 · 0002 · Core enums
-- =============================================================================
-- The exact value lists below are a hard contract: A2..A10 reference them.
-- Do not rename or remove values — add new values at the END of the list.
-- -----------------------------------------------------------------------------

create type public.group_type as enum (
  'fraternity',
  'challenge'
);

create type public.scoring_mode as enum (
  'faithful_days',
  'collective_treasure',
  'custom_points'
);

create type public.sharing_requirement as enum (
  'open',
  'written_fruit',
  'photo_witness'
);

create type public.member_role as enum (
  'admin',
  'member'
);

create type public.liturgical_season as enum (
  'advent',
  'christmas',
  'lent',
  'easter',
  'ordinary_time'
);

create type public.practice_kind as enum (
  'rosary',
  'holy_mass',
  'daily_gospel',
  'adoration',
  'mental_prayer',
  'spiritual_reading',
  'fasting',
  'confession'
);

comment on type public.group_type is
  'fraternity = continuous group with no end date; challenge = time-bounded season.';

comment on type public.scoring_mode is
  'faithful_days = 1 point per active day; collective_treasure = shared goal bar; custom_points = per-practice point values from public.practice_points.';

comment on type public.sharing_requirement is
  'open = one tap check-in; written_fruit = short reflection required; photo_witness = photo required. This is the GROUP policy, not the per-check-in destination (private check-ins are destination-level, see CONVENTIONS §8).';

comment on type public.member_role is
  'admin = may edit the group, manage members and invites; member = regular participant.';

comment on type public.liturgical_season is
  'Liturgical season used for the Today header accent and the streak ring tint.';

comment on type public.practice_kind is
  'Kind of spiritual practice recorded by a check-in. "confession" is a valid practice kind to RECORD, but a check-in whose kind is "confession" MUST be private-only (sharing = private) and MUST NOT carry reflection text or a photo. PostgreSQL has no per-enum-value comment syntax, so the rule is documented here and enforced by the check_ins CHECK constraint owned by A4 (CONVENTIONS §8).';
