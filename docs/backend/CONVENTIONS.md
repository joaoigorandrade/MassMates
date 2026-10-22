# MassMates Backend — Shared Conventions

Read this file completely before writing any SQL. It is the contract for every backend agent.

## 0. Environment

| Item | Value |
|---|---|
| Repo root | `/Users/joaoigor/Developer/MassMates` |
| Supabase project ref | `khovpljkitslmjmonuzu` |
| Supabase MCP namespace | `supabase` (lowercase) |
| Schema contract | `supabase/SCHEMA.md` (written by A1 — read it before coding) |
| iOS app | `MassMates/` (Swift 6, `Navigation` + `Networking` packages only) |
| Supabase CLI | NOT installed. Install with `npm i -g supabase` ONLY if you need `supabase init` scaffolding. Never use it to apply migrations (no DB password). |

### Calling Supabase MCP tools

Tools are **not** directly callable. Use the `execute` tool with the code-mode runtime:

```js
// 1. find the tool
const hits = await search({ query: "apply_migration" });
// hits.items[0].path === "tools.supabase.apply_migration"

// 2. call it
const res = await tools["supabase"]["apply_migration"]({ name: "add_profiles", query: sqlString });
return JSON.stringify(res);
```

Key tools and their exact signatures:

```
tools["supabase"]["apply_migration"]({ name: string, query: string })
tools["supabase"]["execute_sql"]({ query: string })
tools["supabase"]["list_migrations"]()
tools["supabase"]["list_tables"]({ schemas: string[], verbose: boolean })  // verbose is REQUIRED
tools["supabase"]["list_extensions"]()
tools["supabase"]["get_advisors"]({ type: "security" | "performance" })
tools["supabase"]["deploy_edge_function"]({ name, entrypoint_path, import_map_path?, verify_jwt, files: [{name, content}] })
tools["supabase"]["list_edge_functions"]()
tools["supabase"]["get_project_url"]()
tools["supabase"]["get_publishable_keys"]()
tools["supabase"]["generate_typescript_types"]()
```

Use `search({query})` to discover any tool not listed here. Never guess a tool path.

### Applying a migration

1. Write the SQL to `supabase/migrations/<prefix>_<name>.sql` FIRST.
2. Apply it with `apply_migration({ name: "<name>", query: <same sql> })`.
3. Verify with `execute_sql` and `list_migrations`.
4. If `apply_migration` fails with a lock timeout, deadlock, or serialization failure
   (possible when sibling agents apply concurrently), **retry up to 5 times with a
   10s wait between attempts**. Do not change the SQL to work around a lock.

Never run destructive SQL against the shared project (no `drop table`, no `truncate`,
no `drop schema`) except for objects you created in your own prefix range.

## 1. Migration file layout & prefix ownership

`supabase/migrations/<prefix>_<name>.sql` — prefix is a 4-digit zero-padded number
that fixes the global ordering. Each agent owns a disjoint range:

| Agent | Prefix range | Domain |
|---|---|---|
| A1 | `0001`–`0099` | Foundation: profiles, groups, group_members, user_blocks, enums, RLS helpers |
| A2 | `0100`–`0199` | Auth & account lifecycle |
| A3 | `0200`–`0299` | Groups, invites, slots |
| A4 | `0300`–`0399` | Check-ins, streaks, scoring |
| A5 | `0400`–`0499` | Feed, prayer wall, chat |
| A6 | `0500`–`0599` | Storage, moderation, safety |
| A7 | `0600`–`0699` | Liturgical content & monetization |
| A8 | `0700`–`0799` | Guardian Angel & push |
| A9 | `0800`–`0899` | iOS client integration |
| A10 | `0900`–`0999` | Security & QA audit |

Filename format: `supabase/migrations/0102_handle_new_user_trigger.sql`.
The `name` passed to `apply_migration` must be the filename stem (snake_case, no prefix).

## 2. Ownership rules

- You may CREATE/ALTER objects **only** in your own domain (your own tables, your own
  functions, your own policies, your own Edge Functions).
- You may ADD policies and RPCs to foundation tables owned by A1 (`profiles`,
  `groups`, `group_members`, `user_blocks`) — that is your job, not a violation.
  But do **not** `ALTER TABLE` those tables to add columns: A1 already created every
  column you need. If you truly need a new column, report it in your final message
  instead of silently altering another agent's table.
- If you need a table owned by another agent, DO NOT create it. Report the exact
  request (table name, columns, purpose) in your final message and work around it
  (e.g. use a local staging table or a JSONB payload column you own).
- Never `DROP` or `TRUNCATE` another agent's table. Never `ALTER` another agent's
  table. Never edit another agent's migration file.

## 3. SQL conventions

- Schema: everything in `public` unless a strong reason not to. Extensions in
  `extensions` schema (Supabase convention).
- Table names, columns, indexes, functions: `snake_case`. Function names for RPCs:
  `verb_noun` (`submit_check_in`, `join_group_by_code`).
- Primary key: `uuid PRIMARY KEY DEFAULT gen_random_uuid()`.
- Timestamps: `created_at timestamptz NOT NULL DEFAULT now()`,
  `updated_at timestamptz NOT NULL DEFAULT now()` (kept current by A1's
  `public.set_updated_at()` trigger — attach it to every table you create).
- Foreign keys: always `REFERENCES public.<table>(id) ON DELETE CASCADE` unless
  there is a deliberate reason to retain the referencing row.
- Money/prices: `numeric(12,2)`. Percentages/ratios: `numeric(5,2)`.
- JSON payloads: `jsonb` with a `jsonb_typeof`/`jsonb_path` CHECK when shape matters.
- Free-text lengths: `text` with a `CHECK (char_length(x) BETWEEN 0 AND n)` so the
  limit is enforced server-side.
- Comments: `COMMENT ON TABLE/COLUMN/FUNCTION` for anything non-obvious. SQL comments
  in migration files are fine and encouraged.
- Never use `SecurityDefiner` without `SET search_path = ''` and fully-qualified
  object names.

## 4. Row Level Security (non-negotiable)

- **Enable RLS on every table at creation**: `ALTER TABLE public.x ENABLE ROW LEVEL SECURITY;`
- Also `ALTER TABLE public.x FORCE ROW LEVEL SECURITY;` for tables the table owner
  should not bypass — except tables where the owning app role must write.
- Write **explicit** policies. Never rely on the default (deny-all) behaviour alone
  for tables the app must read.
- Policy shape: `FOR <cmd> TO <role> USING (<predicate>) WITH CHECK (<predicate>)`.
  Roles: `anon`, `authenticated`, `service_role`.
- Use A1's helpers (do not re-implement membership logic):
  - `public.current_user_id() -> uuid`
  - `public.is_group_member(p_group_id uuid, p_user_id uuid DEFAULT auth.uid()) -> boolean`
  - `public.is_group_admin(p_group_id uuid, p_user_id uuid DEFAULT auth.uid()) -> boolean`
  - `public.is_blocked(p_user_id uuid, p_other_id uuid) -> boolean`
  - `public.set_updated_at() -> trigger`
- **Never** use a policy that references a table the reader cannot see without a
  `security definer` helper — that causes infinite recursion under RLS.
- Authenticated users must be able to read their own rows. `anon` (unauthenticated)
  must be able to read **only** genuinely public content (liturgical calendar,
  featured challenges, public group previews).
- **Privacy invariant (fails the build if violated):** no table, column, or storage
  bucket may hold Confession records, Spiritual Diary text, or "Only in My Private
  Diary" check-in content. See §8.

## 5. Server logic placement

| Concern | Where |
|---|---|
| Transactional rules, invariants, multi-row writes, anything a client could bypass | **Postgres RPC** (`security definer`, `set search_path = ''`, `REVOKE EXECUTE FROM PUBLIC; GRANT EXECUTE TO authenticated;`) |
| External calls (APNs, AdMob SSV, account deletion erasure) | **Edge Function** (Deno) in `supabase/functions/<slug>/index.ts` |
| Row reads / simple filtered lists | PostgREST (direct table access), always behind RLS |

- RPC naming: `verb_noun`. Return `jsonb` or a table type; never `void` for a
  mutation that has a result.
- RPCs that mutate must be idempotent where the client may retry.
- Edge Functions live in `supabase/functions/<slug>/index.ts` and are deployed with
  `tools["supabase"]["deploy_edge_function"]`. Always include a `deno.json` with
  the import map when the function uses `npm:`/`jsr:` specifiers, and pass its path
  as `import_map_path` (the deploy tool takes it, and it is how the import map
  actually reaches the deployed function).
- `verify_jwt`: keep `true` unless the function body does its own verification
  (AdMob SSV, signed webhooks). For those, set `verify_jwt: false` AND verify the
  provider signature inside the function.
- Edge Function secrets: read from `Deno.env.get(...)`. Never hard-code secrets.
  Never commit a `.env` with real values.

## 6. Testing (pgTAP)

- Test files: `supabase/tests/<agent_id>/<topic>.sql` (e.g. `supabase/tests/a4/streaks.sql`).
- Standard pgTAP shape:

```sql
begin;
select plan(2);
select has_table('public', 'check_ins', 'check_ins table exists');
select ok(not public.is_blocked('00000000-0000-0000-0000-000000000000'::uuid,
                               '00000000-0000-0000-0000-000000000001'::uuid),
          'is_blocked works on empty set');
with f as (select * from finish())
select coalesce((select f.finish::text from f), 'ALL TESTS PASSED') as verdict;
rollback;
```

### Verified remote invocation procedure

The Supabase CLI is not installed and there is no DB password, so a test file is
run by sending its **entire body** as the `query` argument of `execute_sql`:

```js
const res = await tools["supabase"]["execute_sql"]({ query: <file contents> });
return res;
```

Rules that are easy to get wrong (all verified against this project):

- **`has_table` is SCHEMA-FIRST when given 3 arguments.** The 3-arg overload is
  `has_table(schema, table, description)`. The 2-arg overload is
  `has_table(table, description)` and resolves the table through `search_path`.
  A dot-qualified string like `'public.check_ins'` is **not** valid — it is parsed
  as a bare table name and the assertion fails. Use `('public', 'check_ins', ...)`.
  Same schema-first rule for `has_column(schema, table, column, description)` and
  `has_function(schema, function, description)`.
- **`finish()` returns zero rows when every test passes.** The MCP tool returns the
  last statement's result set, so a bare `select * from finish();` makes a fully
  green run look like it produced a random earlier assertion's output. Always wrap
  it in the `with f as (select * from finish()) select coalesce(...)` verdict
  query above, which always returns exactly one row:
  - `ALL TESTS PASSED` → green.
  - `# Looks like you failed N test of M` → red; re-read the assertion.
- `plan(n)` must exactly equal the number of assertions or `finish()` errors.
- Always `begin; ... rollback;` so tests never leave data behind. The rollback
  also discards a `create extension` performed inside the test, so the extension
  must already be installed on the project (see below).
- Tests must be runnable against the live project and must pass before you report done.

### pgtap extension

`pgtap` must be installed on the project before any test can run:

```sql
create extension if not exists pgtap with schema extensions;
```

The `postgres` role's default `search_path` is already `"$user", public, extensions`,
so `plan()` / `has_table()` / `ok()` / `finish()` resolve without an explicit
`set search_path`. A `set search_path = extensions, public;` line at the top of a
test file is harmless but not required.

This is a project-level change, not a per-test one. A1 installs it as part of the
foundation migration (`0001_install_extensions.sql`); agents other than A1 must not
create it. If a test fails with `function has_table(...) does not exist`, the
extension is missing — report it to the orchestrator instead of creating it yourself.

- `supabase/tests/README.md` (written by A1) may extend this section. It
  supersedes this one when they disagree.

## 7. "Done" checklist for every agent

1. Migration file written to `supabase/migrations/<prefix>_*.sql` **and** applied via
   `apply_migration` (confirmed in `list_migrations`).
2. `get_advisors({type:"security"})` and `get_advisors({type:"performance"})` show
   **no new findings** attributable to your objects. Fix what you introduced.
3. pgTAP tests written under `supabase/tests/<agent_id>/` and **passing**.
4. Edge Functions (if any) deployed and returning a correct response.
5. Your 1-line decision appended to **`docs/memory/decisions/<agent_id>.md`** (create
   the file). Format:
   `[YYYY-MM-DD] [Topic]: Decision -> Reason (why alternatives failed)`
   Do **not** edit `docs/memory/DECISIONS.md` directly — the orchestrator merges the
   per-agent files to avoid concurrent-write conflicts.
6. Final message: a concise report (see §9). No file dumps.

## 8. Sacred privacy (sacred privacy is a hard build gate)

- **NEVER** create a table or column that can hold: Confession records (date,
  confessor notes, penance), Spiritual Diary text, or check-ins whose destination is
  "Only in My Private Diary" (`sharing = 'private'`).
- Private check-ins must **never** fan out to groups, feeds, or other users. The
  check-in engine must be the only writer, and it must not create a `feed_posts` row
  for a private check-in.
- "Private" (`sharing_requirement = 'private'`) is a valid **destination** value on
  the check-in, but the *content* of a private check-in stays on the device. The
  backend may record only the minimal metadata needed to keep streak/ring maths
  correct (practice kind, local date, user id) and must never store the reflection
  text or photo for a private check-in.
  - Practical rule: `check_ins.reflection_text` and `check_ins.photo_path` are
    `NULL` whenever `sharing = 'private'`. Enforce with a CHECK constraint.
- No bucket may be writable by the public with a path pattern that could hold
  confessional or diary content.
- Any agent that notices a violation elsewhere reports it to the orchestrator; it
  does not silently fix another agent's object.

## 9. Final report format

Each agent ends with a report containing, in this order:

1. `STATUS:` one of `DONE`, `DONE_WITH_ISSUES`, `BLOCKED`.
2. `MIGRATIONS:` list of applied migration names + versions.
3. `OBJECTS:` tables / functions / policies / edge functions created (names only).
4. `TESTS:` pgTAP file paths and the pass/fail counts. Edge function smoke test result.
5. `ADVISORS:` counts of security + performance findings before/after your work.
6. `DECISIONS:` the decision lines you wrote.
7. `CROSS_DOMAIN_REQUESTS:` anything you need from another agent (be specific).
8. `NOTES:` anything the orchestrator must know (deviations, quirks, follow-ups).

Keep it under 60 lines. No code dumps, no SQL echo.

## 10. Git rules for agents

- **Do NOT run `git add`, `git commit`, or `git push`.** The orchestrator commits per wave.
- **Do NOT** run `git checkout`, `git stash`, `git reset`, or any command that mutates
  git state of files you do not own.
- You may use `git status` / `git diff` read-only to check what you changed.
- Never delete or overwrite files outside your ownership scope. If a file you were
  told to create already exists, read it and extend it rather than replacing it.
