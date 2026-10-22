# MassMates — Supabase backend

The Supabase project that backs the MassMates iOS app.

| | |
|---|---|
| **Remote project ref** | `khovpljkitslmjmonuzu` |
| **Remote URL** | `https://khovpljkitslmjmonuzu.supabase.co` |
| **PostgreSQL** | 17.11 (managed Supabase) |
| **Schema contract** | [`SCHEMA.md`](SCHEMA.md) — read it before writing any SQL |
| **Client reference** | [`../docs/backend/API.md`](../docs/backend/API.md) |
| **Conventions** | [`../docs/backend/CONVENTIONS.md`](../docs/backend/CONVENTIONS.md) |
| **Generated types** | [`types/database.ts`](types/database.ts) |

```
supabase/
├── config.toml          the local stack (buckets, extensions, auth redirects)
├── migrations/          the ordered SQL history — 0001 … 0904
├── seed.sql             the local seed (includes seed_liturgical.sql)
├── functions/           the Edge Functions (Deno)
├── tests/               the pgTAP suites (a1 … a10)
└── types/database.ts    the generated TypeScript schema
```

---

## 1. The remote project is driven through the Supabase MCP

There is **no database password** in this repository and the Supabase CLI is
not installed, so the remote project is **never** driven by `psql` or by the
CLI. Every change goes through the Supabase MCP server:

| Tool | What it does |
|---|---|
| `tools["supabase"]["apply_migration"]` | applies a migration file (in a transaction) |
| `tools["supabase"]["execute_sql"]` | runs a read-only / ad-hoc statement |
| `tools["supabase"]["list_migrations"]` | the applied history |
| `tools["supabase"]["list_tables"]` | the tables (verbose is **required**) |
| `tools["supabase"]["get_advisors"]` | the security / performance lints |
| `tools["supabase"]["list_edge_functions"]` | the deployed functions |
| `tools["supabase"]["deploy_edge_function"]` | deploys a function |
| `tools["supabase"]["generate_typescript_types"]` | regenerates `types/database.ts` |

**The rule:** write the migration to `supabase/migrations/<prefix>_<name>.sql`
**first**, then apply the very same content with `apply_migration`. Never
apply an ad-hoc `execute_sql` DDL that is not in a migration file — the file
is the source of truth and the replay history.

The migration prefix ranges are owned per agent (see
`../docs/backend/CONVENTIONS.md` §1). **A10 owns `0900`–`0999`.**

---

## 2. The local stack (optional)

The remote project is the source of truth; the local stack exists to replay
the migrations from scratch and to run the pgTAP suites locally.

```bash
npm i -g supabase          # the CLI is NOT installed by default
supabase start              # starts the local Postgres + PostgREST + Storage
supabase db reset           # drops, re-applies every migration, runs seed.sql
supabase test db            # runs the pgTAP suites in supabase/tests/
supabase functions serve    # serves supabase/functions/ on :54321/functions/v1
```

`supabase db reset` replays `supabase/migrations/` in **filename order** and
then runs `supabase/seed.sql`. The seed is idempotent (it only contains the
A7 liturgical calendar).

To point the local stack at a different project id, change `project_id` in
`supabase/config.toml`.

### The local buckets and the auth redirects

`supabase/config.toml` mirrors the production buckets:

| Bucket | Public | Size | MIME |
|---|---|---|---|
| `avatars` | true | 5 MiB | png / jpeg / webp / heic |
| `group-covers` | true | 8 MiB | png / jpeg / webp / heic |
| `witness-photos` | **false** | 10 MiB | png / jpeg / webp / heic |

The auth redirects include the two deep links the iOS app registers:

```toml
site_url = "massmates://"
additional_redirect_urls = ["massmates://auth/callback", "massmates://join/:code", "http://localhost:3000/auth/callback"]
```

---

## 3. Running the pgTAP suites

The suites are plain SQL files. Against the **remote** project (no password
needed) they are sent to `execute_sql` as one batch:

```js
const res = await tools["supabase"]["execute_sql"]({ query: <file contents> });
// res.result[0].result -> { verdict: "PASS", plan: 81, ran: 81, failed: 0, summary: "…" }
```

Every file follows the same skeleton:

```sql
begin;
set local search_path = extensions, public;
select plan(<N>);
… assertions …
select * from finish ();
select public.pgtap_summary () as result;   -- exactly one jsonb row
rollback;
```

`public.pgtap_summary()` is **A1's** helper: it always returns exactly one
row, and `verdict` is `PASS` only when `ran = plan` **and** `failed = 0`.
`finish()` returns zero rows on success, so it is never a verdict.

| Suite | Agent | Topic |
|---|---|---|
| `tests/a1/foundation.sql` | A1 | the schema foundation |
| `tests/a2/*` | A2 | auth & account lifecycle |
| `tests/a3/*` | A3 | groups, invites, slots |
| `tests/a4/*` | A4 | check-ins, streaks, scoring |
| `tests/a5/*` | A5 | feed, prayer wall, chat |
| `tests/a6/*` | A6 | storage, moderation, safety |
| `tests/a7/*` | A7 | liturgical content & monetization |
| `tests/a8/*` | A8 | guardian angel & push |
| `tests/a9/*` | A9 | iOS client integration |
| `tests/a10/*` | A10 | **the security & QA audit** — the RLS matrix, the RPC matrix, the privacy audit |

To debug a failing assertion, `sh supabase/tests/tap_transcript.sh <file>
<out.sql>` rewrites the file so every TAP line is returned.

---

## 4. The Edge Functions

```bash
supabase functions serve                      # locally
supabase functions deploy delete-account      # to the remote project
```

| Slug | `verify_jwt` | What it does |
|---|---|---|
| `delete-account` | true | erases the caller's account (own JWT only) |
| `signed-witness-url` | true | signs a private witness-photo URL for the caller |
| `admob-ssv` | **false** | the AdMob server-to-server callback (verifies the RSA signature itself) |
| `push-dispatch` | **false** | the APNs dispatcher (verifies the service-role bearer or `x-push-secret` itself) |

The two `verify_jwt: false` functions **fail closed**. Their secrets are
read from `Deno.env` and must be set by the operator:

```bash
supabase secrets set ADMOBSIGNING_KEY="-----BEGIN PUBLIC KEY-----\n…\n-----END PUBLIC KEY-----"
supabase secrets set PUSH_DISPATCH_SECRET="<random 32+ bytes>"
supabase secrets set APNS_KEY_ID="…" APNS_TEAM_ID="…" APNS_TOPIC="joaoigor.MassMates"
supabase secrets set APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n…\n-----END PRIVATE KEY-----"
```

See `../docs/backend/API.md` §6 for the full contract and
`../docs/backend/PUSH.md` for the APNs encoding note.

---

## 5. The operator runbook

| Task | Where |
|---|---|
| Configure the auth providers (Apple, Google) and the SMTP relay | `../docs/backend/AUTH_SETUP.md` |
| The moderation and safety contract | `../docs/backend/MODERATION.md` |
| The liturgical content and the monetization contract | `../docs/backend/LITURGICAL_CONTENT.md` |
| The push delivery notes | `../docs/backend/PUSH.md` |
| The complete client API reference | `../docs/backend/API.md` |

---

## 6. House rules

1. **Never** edit an applied migration file in place — add a new one with the
   next prefix of your range.
2. **Never** `drop` / `truncate` / `alter` another agent's table; report the
   request instead (CONVENTIONS §2).
3. Every `security definer` function: `set search_path = ''` + fully
   qualified names + `REVOKE EXECUTE FROM PUBLIC, anon` (the platform's
   default ACL grants `anon` a direct grant — revoking "from public" alone
   is not enough).
4. Every table: RLS **enabled and forced**, with explicit policies.
5. No table, column or bucket may hold a Confession, a Spiritual Diary text
   or the content of a private check-in (CONVENTIONS §8).
6. Tests must be wrapped in `begin; … rollback;` and must leave zero rows.
