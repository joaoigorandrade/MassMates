# pgTAP test harness — MassMates backend

**Owner: A1 (schema foundation).** Read this before writing any test file.
Every agent A2..A10 uses this exact procedure.

- Remote project ref: `khovpljkitslmjmonuzu`
- Schema contract: [`supabase/SCHEMA.md`](../SCHEMA.md)
- Shared conventions: [`docs/backend/CONVENTIONS.md`](../../docs/backend/CONVENTIONS.md)

---

## 1. TL;DR

A pgTAP test file is a **single SQL string** that you pass to the Supabase MCP
tool `execute_sql`. That is the whole procedure:

```js
// inside the code-mode `execute` runtime
const res = await fetch('http://<your-file-server>/supabase/tests/a1/foundation.sql'); // or inline the string
const sql  = await res.text();
const out  = await tools["supabase"]["execute_sql"]({ query: sql });
// out.result  ->  [{"result": {"verdict":"PASS","plan":81,"ran":81,"failed":0,"summary":"..."}}]
```

Read the verdict from `out.result[0].result.verdict`.

---

## 2. Why the file must end with `public.pgtap_summary()`

`execute_sql` returns **only the last non-empty result set** of a multi-statement
batch. That breaks the naive pgTAP shape:

| statement | rows returned | visible? |
|---|---|---|
| `select plan(81);` | 1 | no — superseded |
| `select ok(...)` × 81 | 1 each | no — superseded |
| `select * from finish();` | **0 on success**, 1 on failure | sometimes |
| `rollback;` | — | — |

`finish()` returns **zero rows when everything passed**, so a file ending in
`select * from finish();` returns the *last assertion's* line on success and the
*failure summary* on failure — neither is a reliable verdict, and a file whose
3rd assertion failed but whose 81st passed would look green.

**A1 therefore provides `public.pgtap_summary()`** (migration `0009`). It reads
pgTAP's internal counters and returns **exactly one jsonb row, always**:

```json
{"verdict": "PASS", "plan": 81, "ran": 81, "failed": 0, "summary": "Looks like you passed 81 test(s)"}
```

> `verdict` is `PASS` only when `ran = plan` **and** `failed = 0`.
> `summary` is `FAIL` when the plan count does not match the number of
> assertions, so a wrong `plan(n)` can never produce a false green.

---

## 3. The mandatory file skeleton

Copy this. Every agent's file follows it exactly.

```sql
-- supabase/tests/<agent_id>/<topic>.sql
begin;
set local search_path = extensions, public;

select plan(<N>);            -- N MUST equal the number of assertions

-- ... assertions (standard pgTAP calls) ...

select * from finish ();
select public.pgtap_summary () as result;

rollback;
```

### 3.1 `set local search_path = extensions, public;`

- pgTAP is installed in the **`extensions`** schema, so `plan()`, `ok()`,
  `has_table()`, `finish()` … only resolve when `extensions` is on the path.
- Use `set local` (not `set`): the MCP connection is pooled and a session-level
  `set` would leak into other agents' queries.
- `set local` requires a transaction — that is why `begin;` comes first.
- `public` stays on the path so `public.pgtap_summary()` and your own
  `public.*` helpers resolve. Fully qualifying (`public.is_group_member(...)`)
  is still recommended.

### 3.2 `begin;` … `rollback;`

`execute_sql` runs on a pooled connection that may already be inside a
transaction, so `begin;` can emit `WARNING: there is already a transaction in
progress`. **That warning is harmless** — the `rollback;` still discards every
change made by the file.

Verified: after running `supabase/tests/a1/foundation.sql` (which inserts
`auth.users` rows, profiles, a group, memberships and a block) the database
still reports `0` rows in `auth.users`, `public.profiles`, `public.groups`,
`public.group_members`, `public.user_blocks`, `public.practice_points` and
`public.audit_log`.

**Always wrap the file in `begin;` / `rollback;`.** A test that raises an
exception aborts the transaction, so the `rollback;` is what guarantees that a
failing test leaves nothing behind.

### 3.3 `plan(n)`

`plan(n)` must equal the number of assertions. `pgtap_summary()` reports
`ran` vs `plan` separately, so a mismatch is visible in the verdict instead of
silently passing.

Count them with:

```bash
grep -cE "^select (ok|has_[a-z_]+|is|isnt|throws_ok|lives_ok|results_eq|enum_has_labels|pass|fail) " supabase/tests/<agent_id>/<topic>.sql
```

---

## 4. pgTAP API notes (verified against pgTAP 1.3.3 in this project)

| call | verified behaviour |
|---|---|
| `has_extension('extensions', 'pgcrypto', 'desc')` | **argument order is `(schema, extension)`** — `has_extension('pgcrypto','public')` FAILS. |
| `has_enum('public', 'group_type', 'desc')` | ok |
| `has_table('public', 'profiles', 'desc')` | ok |
| `has_column('public', 'profiles', 'display_name', 'desc')` | ok |
| `has_function('public', 'is_group_member', array['uuid','uuid']::name[], 'desc')` | ok — third arg is the argument-type list |
| `has_trigger('public', 'profiles', 'trg_profiles_updated_at', 'desc')` | ok — `(schema, table, trigger)` |
| `enum_has_labels('public', 'group_type', array['a','b']::name[], 'desc')` | ok — but it only checks that the labels EXIST. To assert the **exact** value set, compare the ordered array yourself (see §5). |
| `throws_ok(sql, errcode, errmsg, desc)` | **the only reliable form.** The 3-arg `throws_ok(sql, errcode, desc)` treats the 2nd argument as the expected *message*, and the 2-arg `throws_ok(sql, desc)` also demands a matching message. |
| `lives_ok(sql, desc)` | ok — prints the full server error on failure, which is the best diagnostic in the toolkit. |
| `ok(bool, 'desc')`, `is(a, b, 'desc')`, `isnt(a, b, 'desc')` | ok |

`errcode` is the SQLSTATE: `23514` check violation, `23503` foreign key
violation, `42501` RLS / permission denied, `22012` division by zero.

`errmsg` must match **exactly**, e.g. for a column check:

```
new row for relation "profiles" violates check constraint "profiles_display_name_check"
```

Constraint names are auto-generated: column-level → `<table>_<column>_check`;
table-level → `<table>_check` (or `<table>_check1`, `<table>_check2`, … when a
table has more than one table-level CHECK).

### 4.1 A1-provided helper assertions (pgTAP 1.3.3 has no RLS assertions)

```sql
select ok (public.pgtap_rls_enabled  ('public.profiles'::regclass), 'RLS is enabled on profiles');
select ok (public.pgtap_rls_forced  ('public.profiles'::regclass), 'RLS is FORCED on profiles');
select ok (public.pgtap_policy_count('public.profiles'::regclass) > 0,      'profiles has policies');
select ok (public.pgtap_policy_count('public.profiles'::regclass, 'r') = 1, 'profiles has exactly 1 SELECT policy');
```

`pgtap_policy_count(table, cmd)` — `cmd` is `'r'` select, `'a'` insert,
`'w'` update, `'d'` delete; `NULL` = all policies.

These four functions have `EXECUTE` revoked from `anon`/`authenticated`, so they
are **not** callable while the test file has switched role — call them before
`set local role authenticated`, or `reset role` first.

---

## 5. Asserting an EXACT enum value set

pgTAP's `enum_has_labels` only checks membership. Use a local helper:

```sql
create function pg_temp.enum_labels (p_schema text, p_type text)
  returns text[]
  language sql
  stable
as $$
  select array_agg (e.enumlabel::text order by e.enumsortorder)
  from pg_catalog.pg_type t
  join pg_catalog.pg_namespace n on n.oid = t.typnamespace
  join pg_catalog.pg_enum e on e.enumtypid = t.oid
  where n.nspname = p_schema and t.typname = p_type;
$$;

select ok (pg_temp.enum_labels ('public', 'group_type') = array['fraternity', 'challenge'],
            'group_type has exactly [fraternity, challenge]');
```

> `e.enumlabel` is of type `name` and `information_schema.columns.column_name`
> is of type `sql_identifier` — **cast to `::text`**, otherwise the comparison
> fails with `operator does not exist: sql_identifier[] = text[]`.

---

## 6. Testing RLS as a real user

`postgres` is a member of the `anon`, `authenticated` and `service_role` roles
on this project, so a test file can impersonate a user and exercise the actual
policies:

```sql
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select ok ((select count(*) from public.profiles where id = '33333333-3333-3333-3333-333333333333') = 0,
            'RLS: an outsider cannot read another profile');

reset role;                 -- back to postgres
set local request.jwt.claims = '{}';
```

- `auth.uid()` reads `request.jwt.claims` (or `request.jwt.claim.sub`) — set it
  with `set local request.jwt.claims = '{"sub":"<uuid>","role":"authenticated"}'`.
- `set local request.jwt.claims = '{}'` simulates an **anon** call: `auth.uid()`
  returns `NULL`.
- A temp table created before the role switch is **not** writable by
  `authenticated` (temp tables are owned by the creating role). `grant insert,
  select on <temp_table> to authenticated, anon;` and `grant usage, select on
  all sequences in schema pg_temp to authenticated, anon;` fix that — needed by
  the transcript procedure in §7.
- `reset role;` restores the session role. Always call it before the final
  `pgtap_summary()` call, which the `authenticated` role may not execute.

### 6.1 Asserting that a write is REJECTED by a policy

A rejected `INSERT` raises `42501` and aborts the transaction. Catch it in a
`SECURITY INVOKER` helper (so it runs with the current role and the current
policies) and assert on the boolean:

```sql
create function pg_temp.insert_third_party ()
  returns boolean
  language plpgsql
as $$
begin
  insert into public.group_members (group_id, user_id)
  values ('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333');
  return true;            -- the insert was ALLOWED
exception
  when others then
    return false;           -- blocked by RLS / privilege
end;
$$;

select ok (not pg_temp.insert_third_party (), 'RLS: a member cannot add a third party to the roster');
```

---

## 7. Getting the FULL TAP transcript (debugging a failure)

`pgtap_summary()` tells you **how many** tests failed, not **which**. To see
every TAP line, transform the file so each assertion writes into a temp table
and the last statement returns the log.

```bash
sh supabase/tests/tap_transcript.sh \
   supabase/tests/<agent_id>/<topic>.sql \
   /tmp/<topic>_transcript.sql
```

`tap_transcript.sh` performs three mechanical rewrites:

1. inserts `create temporary table tap_log (n serial primary key, line text) on commit drop;`
   (plus the two `grant` statements required by §6) after the `set local search_path` line;
2. rewrites `select <assertion>(` into `insert into tap_log (line) select <assertion>(`;
3. replaces `select public.pgtap_summary () as result;` with
   `select n, line from tap_log order by n;`.

Run the transformed file exactly like the original. The tool returns **one row
per assertion** with the raw TAP line, e.g.

```
{"n":42,"line":"ok 42 - is_group_member: admin is a member"}
{"n":43,"line":"not ok 43 - is_group_member: member is a member\n# Failed test 43: ...\n#       have: ...\n#       want: ..."}
```

A failed assertion's line carries the `have:` / `want:` diff, which is the
fastest way to see what went wrong.

> The Postgres server log cannot be used for this: `log_min_messages` is
> `warning` on this project, so pgTAP's NOTICE output is not persisted, and
> `query_logs` therefore never contains the TAP lines.

---

## 8. Copy-paste example (the smallest possible passing test)

```sql
begin;
set local search_path = extensions, public;

select plan(3);

select has_table ('public', 'profiles', 'profiles table exists');
select ok (public.pgtap_rls_enabled ('public.profiles'::regclass), 'RLS is enabled on profiles');
select ok (not public.is_group_member ('55555555-5555-5555-5555-555555555555', null), 'is_group_member: null user is not a member');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
```

Result returned by the tool:

```json
{"result": {"ran": 3, "plan": 3, "failed": 0, "summary": "Looks like you passed 3 test(s)", "verdict": "PASS"}}
```

---

## 9. Gotchas (all hit and verified while building this harness)

1. **`execute_sql` returns only the last non-empty result set.** Never rely on
   seeing more than one.
2. **`finish()` returns 0 rows on success** — it is not a verdict. Use
   `public.pgtap_summary()`.
3. **pgTAP lives in `extensions`** — `set local search_path = extensions, public;`
   is mandatory, otherwise `plan()` raises
   `ERROR: You tried to run a test without a plan! Gotta have a plan`.
4. **`set local`, never `set`** — the MCP connection is pooled.
5. **`has_extension(schema, extension)`** — that argument order.
6. **`throws_ok` needs the 4-argument form** `(sql, errcode, errmsg, desc)`.
7. **Cast `enumlabel` / `column_name` to `::text`** before comparing arrays.
8. **`extensions.num_failed()` cannot be called from a function with
   `set search_path = ''`** — its body calls `_get()` unqualified. Use
   `extensions._get('failed')` instead (that is what `public.pgtap_summary()`
   does).
9. **A temp table is not writable by `authenticated`** — grant explicitly, and
   grant on the `pg_temp` sequences too.
10. **`reset role;` before the final summary** — `pgtap_summary()` has EXECUTE
    revoked from `authenticated`.
11. **PostgreSQL 17 has no `comment on enum value`** — the `confession`
    privacy rule is documented in `comment on type public.practice_kind`.
12. **`select plan(n)` before any assertion**, or pgTAP raises.

---

## 10. Where each agent's tests live

```
supabase/tests/
  README.md              <- this file
  tap_transcript.sh      <- the transcript rewriter used in §7
  a1/foundation.sql      <- A1: schema foundation (81 assertions, PASS)
  a2/...                 <- A2: auth & account lifecycle
  a3/...                 <- A3: groups, invites, slots
  a4/...                 <- A4: check-ins, streaks, scoring
  a5/...                 <- A5: feed, prayer wall, chat
  a6/...                 <- A6: storage, moderation, safety
  a7/...                 <- A7: liturgical content & monetization
  a8/...                 <- A8: guardian angel & push
  a9/...                 <- A9: iOS client integration
  a10/...                <- A10: security & QA audit
```

## 11. The A10 suites (the security & QA audit)

| File | Assertions | What it proves |
|---|---|---|
| `a10/rls_matrix.sql` | 647 | For EVERY one of the 39 public tables and for EACH of the five personas (`anon`, outsider, member, admin, blocked) the number of rows reachable with SELECT / UPDATE / DELETE is asserted against a hand-written expectation. The probe helpers raise a deliberate exception, so the probe runs in a sub-transaction and the fixture survives for the next persona. |
| `a10/rpc_matrix.sql` | 96 | The whole privilege matrix (who may execute what), the exact SQLSTATE + message of the non-member error contract of 23 RPCs, and the JSON shape of 50+ happy paths. |
| `a10/privacy.sql` | 65 | The sacred-privacy invariants end to end: the catalog scan, the enforced CHECK constraints, the create-group → join → group check-in → private check-in → confession flow, the fan-out counts, the streak / Rule of Life maths, the outbox and audit-log silence, the Guardian Angel anonymity, and the moderation path. |

Two mechanics are worth copying:

* **A probe that must not change the fixture** runs inside a PL/pgSQL block
  with an `EXCEPTION` handler and raises a deliberate exception at the end —
  the block is a sub-transaction, so the DML is rolled back while the row
  counter survives.
* **A probe that runs as a persona** is `SECURITY INVOKER` and is called
  while the session role is switched (`set local role authenticated;`), so
  the table's own RLS policy applies. The temp helpers are reachable by
  `anon` / `authenticated` through the default ACL — but note that
  `GRANT … ON SCHEMA pg_temp` does **NOT** work: `GRANT` resolves the schema
  name literally and the real namespace is `pg_temp_<pid>`.

Never create a table owned by another agent just to make your test pass
(CONVENTIONS §2). Report the request instead.
