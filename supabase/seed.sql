-- MassMates — local seed data
-- Intentionally empty. A1 (schema foundation) seeds no rows: the foundation
-- tables reference `auth.users`, which only exists for real accounts.
-- Agents that own demo/dev data may append idempotent INSERTs here, guarded by
-- `on conflict do nothing` and wrapped in `begin; ... rollback;` when the data
-- is only needed for local exploration.
--
-- A7 (liturgical content & monetization) appends the liturgical calendar:
-- the 2026 + 2027 seasons, colours, celebrations, saints and reward themes.
-- It lives in its own file so the same statements are also shipped as
-- migration 0605. `\ir` is a psql include, relative to this file, so
-- `supabase db reset` picks it up.
\ir seed_liturgical.sql

