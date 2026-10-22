-- =============================================================================
-- A1 · 0001 · Foundation extensions
-- =============================================================================
-- Extensions live in schema `extensions` (Supabase convention, CONVENTIONS §3).
-- NOBODY ELSE MAY `create extension` — see supabase/SCHEMA.md §9.
--
-- Two extensions own a dedicated schema of their own and cannot be relocated:
--   * pg_cron -> schema `cron`   (cron.schedule / cron.unschedule / cron.alter_job)
--   * pg_net  -> schema `net`    (net.http_post / net.http_get)
-- Their callables are created *inside* those schemas by the extension script,
-- so `WITH SCHEMA extensions` only changes the extension catalog entry.
-- -----------------------------------------------------------------------------

-- pgcrypto: the platform already installed it into `extensions` (v1.3).
-- PostgreSQL 17 also ships `pg_catalog.gen_random_uuid()` natively, so every
-- uuid default in this schema works with or without pgcrypto.
-- Guarded so this migration is safe to replay on a fresh project.
do $$
begin
  if not exists (select 1 from pg_catalog.pg_extension where extname = 'pgcrypto') then
    create extension pgcrypto with schema extensions;
  end if;
end
$$;

-- pg_cron: job scheduler. The extension script creates schema `cron` itself.
create extension if not exists pg_cron with schema extensions;

-- pg_net: async HTTP client used to call Supabase Edge Functions from the DB.
-- The extension script creates schema `net` itself.
create extension if not exists pg_net with schema extensions;

-- pgtap: unit-testing harness. Lives in `extensions`; test files must
-- `set search_path = extensions, public;` so plan()/has_table()/ok()/finish()
-- resolve. See supabase/tests/README.md.
create extension if not exists pgtap with schema extensions;

-- The `net` schema must be reachable by the role that owns the scheduled jobs.
grant usage on schema net to postgres, anon, authenticated, service_role;
grant usage on schema cron to postgres, service_role;
