# MassMates — Backend Schema Contract

> **Owner: A1 (schema foundation).** Migration prefix range `0001`–`0099`.
> Every other backend agent MUST read this file before writing SQL.
> Shared conventions: [`docs/backend/CONVENTIONS.md`](../docs/backend/CONVENTIONS.md).
> Test harness: [`supabase/tests/README.md`](tests/README.md).
>
> **Live project:** `khovpljkitslmjmonizu` · PostgreSQL **17.11** · Supabase.
> **Applied migrations (A1):** `install_extensions`, `create_enums`,
> `create_core_tables`, `create_helper_functions`, `enable_rls_and_policies`,
> `create_practice_points_and_audit_log`, `attach_updated_at_triggers`,
> `create_pgtap_harness_helpers`, `fix_pgtap_summary`,
> `restrict_rls_helpers_from_anon`, `revoke_public_grant_on_helpers`.

---

## 1. Enums

All in schema `public`. The value lists are a **hard contract** — do not rename
or remove a value. Append new values at the **end** of the list only.

```sql
create type public.group_type as enum ('fraternity', 'challenge');

create type public.scoring_mode as enum (
  'faithful_days', 'collective_treasure', 'custom_points'
);

create type public.sharing_requirement as enum (
  'open', 'written_fruit', 'photo_witness'
);

create type public.member_role as enum ('admin', 'member');

create type public.liturgical_season as enum (
  'advent', 'christmas', 'lent', 'easter', 'ordinary_time'
);

create type public.practice_kind as enum (
  'rosary', 'holy_mass', 'daily_gospel', 'adoration', 'mental_prayer',
  'spiritual_reading', 'fasting', 'confession'
);
```

| Enum | Meaning |
|---|---|
| `group_type` | `fraternity` = continuous group, no end date. `challenge` = time-bounded season. |
| `scoring_mode` | `faithful_days` = 1 point per active day · `collective_treasure` = shared goal bar (uses `groups.goal_target`) · `custom_points` = per-practice point values from `public.practice_points`. |
| `sharing_requirement` | The **group-level** policy: `open` = one-tap check-in · `written_fruit` = a short reflection is required · `photo_witness` = a photo is required. **Not** the same thing as the per-check-in destination (`private`). |
| `member_role` | `admin` = may edit the group, manage members and invites · `member` = participant. |
| `liturgical_season` | Drives the Today header accent and the streak-ring tint. |
| `practice_kind` | The kind of spiritual practice a check-in records. |

> ### ⚠️ `practice_kind = 'confession'` — sacred privacy
> `'confession'` is a **valid kind to record**. It is *not* a valid kind to
> **share**. A check-in whose `practice_kind = 'confession'` **MUST** be
> `sharing = 'private'` (device-only), MUST NOT carry `reflection_text` or
> `photo_path`, and MUST NOT fan out to any group, feed or other user.
> Enforcement is A4's `check_ins` CHECK constraint (CONVENTIONS §8).
> **PostgreSQL has no `comment on enum value` syntax** (verified on PG 17), so
> the rule is carried by `comment on type public.practice_kind`:
>
> ```sql
> comment on type public.practice_kind is
>   'Kind of spiritual practice recorded by a check-in. "confession" is a valid practice kind to RECORD, but a check-in whose kind is "confession" MUST be private-only (sharing = private) and MUST NOT carry reflection text or a photo. ...';
> ```

---

## 2. Foundation tables

### 2.1 `public.profiles` — 1:1 with `auth.users`

```sql
create table public.profiles (
  id                     uuid primary key references auth.users (id) on delete cascade,
  display_name           text        not null check (char_length(display_name) between 1 and 60),
  avatar_path            text,
  parish                 text        check (char_length(parish) <= 120),
  city                   text        check (char_length(city) <= 120),
  timezone               text        not null default 'America/Sao_Paulo',
  locale                 text        not null default 'pt-BR' check (locale in ('pt-BR', 'en')),
  ad_consent_analytics   boolean     not null default false,
  ad_personalization     boolean     not null default false,
  rule_of_life           jsonb       not null default '[]'::jsonb check (jsonb_typeof(rule_of_life) = 'array'),
  guardian_angel_opt_in  boolean     not null default false,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  deleted_at             timestamptz
);
```

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | — | PK · FK → `auth.users(id)` `ON DELETE CASCADE` |
| `display_name` | `text` | NOT NULL | — | CHECK `char_length(display_name) between 1 and 60` |
| `avatar_path` | `text` | NULL | — | Storage object path in the `avatars` bucket (A6 owns the bucket). **Not a URL.** |
| `parish` | `text` | NULL | — | CHECK `char_length(parish) <= 120` |
| `city` | `text` | NULL | — | CHECK `char_length(city) <= 120` |
| `timezone` | `text` | NOT NULL | `'America/Sao_Paulo'` | IANA name. **Not** DB-validated: `pg_timezone_names()` is not immutable and cannot be used in a CHECK. |
| `locale` | `text` | NOT NULL | `'pt-BR'` | CHECK `locale in ('pt-BR', 'en')` |
| `ad_consent_analytics` | `boolean` | NOT NULL | `false` | Never derived from spiritual practice data. |
| `ad_personalization` | `boolean` | NOT NULL | `false` | Never derived from private check-ins or diary content. |
| `rule_of_life` | `jsonb` | NOT NULL | `'[]'::jsonb` | CHECK `jsonb_typeof(rule_of_life) = 'array'`. Array of `{ "kind": "<practice_kind>", "label": "<string>" }`. |
| `guardian_angel_opt_in` | `boolean` | NOT NULL | `false` | A8 owns the Guardian Angel mechanic. |
| `created_at` | `timestamptz` | NOT NULL | `now()` | |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | Kept current by `trg_profiles_updated_at`. |
| `deleted_at` | `timestamptz` | NULL | — | Soft-delete marker. A2 owns the deletion window. |

Constraint names: `profiles_pkey`, `profiles_id_fkey`,
`profiles_display_name_check`, `profiles_parish_check`, `profiles_city_check`,
`profiles_locale_check`, `profiles_rule_of_life_check`.

> `comment on table public.profiles` states that it holds **NO confession and NO
> spiritual diary content** — the sacred-privacy invariant (CONVENTIONS §8).

### 2.2 `public.groups`

```sql
create table public.groups (
  id                  uuid primary key default gen_random_uuid(),
  name                text                  not null check (char_length(name) between 1 and 80),
  description         text                  check (char_length(description) <= 500),
  group_type          public.group_type     not null default 'fraternity',
  scoring_mode        public.scoring_mode   not null default 'faithful_days',
  sharing_requirement public.sharing_requirement not null default 'open',
  cover_path          text,
  invite_code         text unique check (invite_code ~ '^[0-9]{6}$'),
  starts_on           date,
  ends_on             date,
  goal_target         integer check (goal_target > 0),
  created_by          uuid references public.profiles (id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  archived_at         timestamptz
);
```

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK |
| `name` | `text` | NOT NULL | — | CHECK `char_length(name) between 1 and 80` |
| `description` | `text` | NULL | — | CHECK `char_length(description) <= 500` |
| `group_type` | `public.group_type` | NOT NULL | `'fraternity'` | |
| `scoring_mode` | `public.scoring_mode` | NOT NULL | `'faithful_days'` | |
| `sharing_requirement` | `public.sharing_requirement` | NOT NULL | `'open'` | |
| `cover_path` | `text` | NULL | — | Storage path in the `group-covers` bucket (A6). |
| `invite_code` | `text` | NULL | — | **UNIQUE** · CHECK `invite_code ~ '^[0-9]{6}$'`. `NULL` until A3 generates one. `NULL`s are distinct in Postgres, so several groups may have a NULL code. |
| `starts_on` | `date` | NULL | — | Inclusive. NULL for fraternities. |
| `ends_on` | `date` | NULL | — | Inclusive. NULL for fraternities. |
| `goal_target` | `integer` | NULL | — | CHECK `goal_target > 0`. Collective-treasure goal. |
| `created_by` | `uuid` | NULL | — | FK → `public.profiles(id)` `ON DELETE SET NULL` |
| `created_at` | `timestamptz` | NOT NULL | `now()` | |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | Kept current by `trg_groups_updated_at`. |
| `archived_at` | `timestamptz` | NULL | — | An archived group is still readable by its members. |

Constraint names: `groups_pkey`, `groups_created_by_fkey`,
`groups_name_check`, `groups_description_check`, `groups_invite_code_check`,
`groups_invite_code_key`, `groups_goal_target_check`.

> **Not** enforced by a CHECK: a challenge must have both `starts_on` and
> `ends_on`, and `ends_on >= starts_on`. Enforce it in A3's create RPC (or add
> a CHECK — but the table is A1-owned, so **request it, do not alter it**).

### 2.3 `public.group_members`

```sql
create table public.group_members (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references public.groups (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  role       public.member_role not null default 'member',
  joined_at  timestamptz not null default now(),
  unique (group_id, user_id)
);
```

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK |
| `group_id` | `uuid` | NOT NULL | — | FK → `public.groups(id)` `ON DELETE CASCADE` |
| `user_id` | `uuid` | NOT NULL | — | FK → `public.profiles(id)` `ON DELETE CASCADE` |
| `role` | `public.member_role` | NOT NULL | `'member'` | |
| `joined_at` | `timestamptz` | NOT NULL | `now()` | |

Constraint names: `group_members_pkey`, `group_members_group_id_fkey`,
`group_members_user_id_fkey`, `group_members_group_id_user_id_key`.

### 2.4 `public.user_blocks`

```sql
create table public.user_blocks (
  id          uuid primary key default gen_random_uuid(),
  blocker_id  uuid not null references public.profiles (id) on delete cascade,
  blocked_id  uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
```

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK |
| `blocker_id` | `uuid` | NOT NULL | — | FK → `public.profiles(id)` `ON DELETE CASCADE`. The user who pressed "block". |
| `blocked_id` | `uuid` | NOT NULL | — | FK → `public.profiles(id)` `ON DELETE CASCADE`. |
| `created_at` | `timestamptz` | NOT NULL | `now()` | No `updated_at` — a block is immutable. |

Constraint names: `user_blocks_pkey`, `user_blocks_blocker_id_fkey`,
`user_blocks_blocked_id_fkey`, `user_blocks_blocker_id_blocked_id_key`,
`user_blocks_check`.

> **Ownership split:** A1 owns the table + the `is_blocked()` helper.
> **A6 owns the `block_user` / `unblock_user` RPCs and every moderation flow
> that writes here.** A1 wrote no RPC on this table.

### 2.5 `public.practice_points` (A1 owns the table, A4 owns the data)

```sql
create table public.practice_points (
  id            uuid primary key default gen_random_uuid(),
  group_id      uuid references public.groups (id) on delete cascade,
  practice_kind public.practice_kind not null,
  points        integer not null check (points >= 0),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint practice_points_group_kind_unique unique nulls not distinct (group_id, practice_kind)
);
```

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK |
| `group_id` | `uuid` | NULL | — | FK → `public.groups(id)` `ON DELETE CASCADE`. **`NULL` = global default** row applying to every `custom_points` group. |
| `practice_kind` | `public.practice_kind` | NOT NULL | — | |
| `points` | `integer` | NOT NULL | — | CHECK `points >= 0` |
| `created_at` / `updated_at` | `timestamptz` | NOT NULL | `now()` | `updated_at` kept current by `trg_practice_points_updated_at`. |

> **Why `unique nulls not distinct`:** plain `unique (group_id, practice_kind)`
> would allow **many** global rows, because Postgres treats `NULL`s as distinct
> in a unique index. `UNIQUE NULLS NOT DISTINCT` (PostgreSQL 15+) treats them as
> equal, so at most one global default per `practice_kind` can exist.
> Verified on this project (PG 17.11) — the index is created as
> `... USING btree (group_id, practice_kind) NULLS NOT DISTINCT`.

### 2.6 `public.audit_log` (append-only)

```sql
create table public.audit_log (
  id          bigint generated always as identity primary key,
  actor_id    uuid,
  action      text not null check (char_length(action) between 1 and 100),
  target_type text not null check (char_length(target_type) between 1 and 60),
  target_id   uuid,
  metadata    jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at  timestamptz not null default now()
);
```

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `bigint` | NOT NULL | identity | PK |
| `actor_id` | `uuid` | NULL | — | The acting user. **Deliberately NOT a foreign key** — the audit trail must survive the hard deletion of the actor. |
| `action` | `text` | NOT NULL | — | CHECK `char_length(action) between 1 and 100`. Stable machine-readable verb, e.g. `account.delete_requested`, `group.admin_transferred`, `content.report_resolved`. |
| `target_type` | `text` | NOT NULL | — | CHECK `char_length(target_type) between 1 and 60`. |
| `target_id` | `uuid` | NULL | — | Generic target id (no FK — it may point at any table). |
| `metadata` | `jsonb` | NOT NULL | `'{}'::jsonb` | CHECK `jsonb_typeof(metadata) = 'object'` |
| `created_at` | `timestamptz` | NOT NULL | `now()` | |

No `updated_at`: the log is append-only. **Never UPDATE or DELETE a row.**

---

## 3. RLS helper functions

All live in `public`. **Every one is `security definer` with
`set search_path = ''` and fully-qualified object names**, so it can read
tables the caller cannot read (no RLS recursion) and cannot be hijacked through
a mutable search path. The definer is the table owner (`postgres`), which has
`BYPASSRLS` on this project, so the inner reads are not re-filtered by RLS.

| Signature | Semantics | `security definer` |
|---|---|---|
| `public.current_user_id() → uuid` | `auth.uid()` of the caller; `NULL` for `anon` / no JWT. | no (invoker) |
| `public.is_group_member(p_group_id uuid, p_user_id uuid default auth.uid()) → boolean` | `true` when `p_user_id` is a member of `p_group_id`. `NULL` user ⇒ `false`. | **yes** |
| `public.is_group_admin(p_group_id uuid, p_user_id uuid default auth.uid()) → boolean` | `true` when `p_user_id` is an **admin** of `p_group_id` (`member_role = 'admin'`). | **yes** |
| `public.is_group_member_of_any(p_user_id uuid default auth.uid()) → boolean` | `true` when `p_user_id` belongs to at least one group. Used by A5 feed/chat policies. | **yes** |
| `public.is_any_group_admin(p_user_id uuid default auth.uid()) → boolean` | `true` when `p_user_id` is an admin of at least one group. Gates `audit_log` reads. | **yes** |
| `public.is_blocked(p_user_id uuid, p_other_id uuid) → boolean` | `true` when a block exists **in either direction** between the two users. Symmetric by design: a block hides both the blocker's and the blocked user's content from the other side. | **yes** |
| `public.set_updated_at() → trigger` | `BEFORE UPDATE` trigger body: `new.updated_at := now()`. | no (invoker) |
| `public.attach_updated_at(p_table regclass) → void` | Creates/replaces the trigger `trg_<table>_updated_at` on `p_table`, wired to `public.set_updated_at()`. **Owner-only** (`EXECUTE` revoked from `public, anon, authenticated, service_role`) — call it from a migration running as `postgres`. | no (invoker) |

> ### RLS recursion rule (CONVENTIONS §4)
> **Never** write a policy that reads a table the reader cannot see, unless the
> read goes through a `security definer` helper like the ones above. A policy
> that queries `public.group_members` directly from a `public.group_members`
> policy is an infinite loop. The helpers above are the only sanctioned way to
> read membership data from inside a policy.
>
> `public.profiles_select_shared_or_own` is the one deliberate exception: it
> reads `public.group_members` directly, but that read is filtered by
> `group_members`' own policy, which calls `is_group_member()` (a definer
> function) — so the chain terminates. **Verified by test** (A1 suite,
> assertions 65–74).

### 3.1 Privileges on the helpers (important)

| Role | `EXECUTE` on the 5 `security definer` helpers? | Why |
|---|---|---|
| `postgres` (owner) | yes | the definer |
| `authenticated` | **yes — mandatory** | PostgreSQL evaluates an RLS policy expression with the **querying role's** privileges, so the querying role needs `EXECUTE` on every function the policy calls. Verified: with the grant removed, every policy using a helper fails with `ERROR: 42501 permission denied for function is_group_member`. |
| `service_role` | yes | direct server-side calls |
| `anon` | **no** | `anon` is fully unauthenticated and no policy in this schema targets it. The default `PUBLIC` grant was revoked (migration `0011`) so `anon` has no path to these functions. |

**Do not** `revoke execute ... from public` on these functions without
re-granting to `authenticated` — that silently breaks every policy that uses
them.

If you need one of them inside an **`anon`** policy (A3's public group
preview, for example), re-grant it explicitly for that case only:

```sql
grant execute on function public.is_group_member (uuid, uuid) to anon;
```

### 3.2 Known security finding (open — A10 owns the decision)

`get_advisors({type: "security"})` reports **one** remaining lint:

```
authenticated_security_definer_function_executable   WARN   5 findings
```

Because the helpers live in `public` (the schema PostgREST exposes) and
`authenticated` must keep `EXECUTE` (policies need it), a signed-in user can
call them directly as an RPC:

```
POST /rest/v1/rpc/is_group_member   {"p_group_id":"…","p_user_id":"…"}
POST /rest/v1/rpc/is_blocked        {"p_user_id":"…","p_other_id":"…"}
```

and learn whether an arbitrary user is a member of an arbitrary group, or
whether an arbitrary pair of users has blocked each other. **A1 could not
close this without breaking the contract** (the function names are mandated by
CONVENTIONS §4 and used by 9 agents; the `p_user_id` argument is needed by
policies that ask "is *this other user* a member of this group?").

**Recommended remediation (A10 / orchestrator decision):** move the
`security definer` implementations into a schema that PostgREST does **not**
expose, and point every policy at that schema.

```sql
-- 1. create a non-exposed schema
create schema if not exists app;
grant usage on schema app to authenticated, service_role;

-- 2. move the implementation there (security definer, set search_path = '')
create function app.is_group_member (p_group_id uuid, p_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path = '' as $$ … $$;

-- 3. re-point the policies: public.is_group_member(...) -> app.is_group_member(...)
-- 4. drop the public wrappers once no policy references them
drop function public.is_group_member (uuid, uuid);
```

The functions must keep working for **policies** — that is the only reason
`authenticated` keeps the grant.

### 3.3 pgTAP harness helpers (development only)

| Signature | Semantics |
|---|---|
| `public.pgtap_summary() → jsonb` | Exactly one row: `{"verdict":"PASS"\|"FAIL","plan":n,"ran":n,"failed":n,"summary":"..."}`. **Must be the last statement of a test file.** |
| `public.pgtap_rls_enabled(p_table regclass) → boolean` | RLS enabled on the table. |
| `public.pgtap_rls_forced(p_table regclass) → boolean` | `FORCE ROW LEVEL SECURITY` on the table. |
| `public.pgtap_policy_count(p_table regclass, p_cmd text default null) → boolean/int` | Number of policies; `p_cmd` ∈ `'r'`,`'a'`,`'w'`,`'d'`, `NULL` = all. |

All four have `EXECUTE` revoked from `anon`/`authenticated`/`service_role` —
they are **not** reachable through PostgREST and not callable from a test file
that has switched to `set local role authenticated` (call `reset role;` first).

---

## 4. RLS policy matrix

RLS is **enabled and forced** on every table below. `FORCE` matters even
though the owner role `postgres` has `BYPASSRLS` on this project: it keeps the
behaviour identical on a project where the owner does not bypass RLS.

### 4.1 `public.profiles`

| Command | Role | Predicate (`USING` / `WITH CHECK`) |
|---|---|---|
| `SELECT` | `authenticated` | `id = (select auth.uid())` **OR** the user shares a group: `exists (select 1 from public.group_members gm join public.group_members mine on mine.group_id = gm.group_id where gm.user_id = public.profiles.id and mine.user_id = (select auth.uid()))` |
| `INSERT` | — | **no policy** — clients cannot insert. A2's `handle_new_user` trigger inserts as `security definer`. |
| `UPDATE` | `authenticated` | `USING (id = (select auth.uid()))` · `WITH CHECK (id = (select auth.uid()))` |
| `DELETE` | — | **no policy** — A2's account-deletion flow owns deletes. |
| any | `anon` | **no policy** — `anon` reads nothing from `profiles`. |

### 4.2 `public.groups`

| Command | Role | Predicate |
|---|---|---|
| `SELECT` | `authenticated` | `archived_at is null` **OR** `public.is_group_member(public.groups.id)` |
| `INSERT` | `authenticated` | `WITH CHECK (created_by = (select auth.uid()))` |
| `UPDATE` | `authenticated` | `USING (public.is_group_admin(public.groups.id))` · `WITH CHECK (public.is_group_admin(public.groups.id))` |
| `DELETE` | `authenticated` | `USING (public.is_group_admin(public.groups.id))` |
| any | `anon` | **no policy.** See §11 — A3 owns the "public group preview" policy. |

### 4.3 `public.group_members`

| Command | Role | Predicate |
|---|---|---|
| `SELECT` | `authenticated` | `USING (public.is_group_member(public.group_members.group_id))` |
| `INSERT` | `authenticated` | `WITH CHECK (user_id = (select auth.uid()))` — self-join only. A3's `join_group_by_code` RPC (`security definer`) is the real entry point. |
| `UPDATE` | `authenticated` | `USING (public.is_group_admin(public.group_members.group_id))` · `WITH CHECK (same)` |
| `DELETE` | `authenticated` | `USING (public.is_group_admin(...) or user_id = (select auth.uid()))` |
| any | `anon` | **no policy** |

### 4.4 `public.user_blocks`

| Command | Role | Predicate |
|---|---|---|
| `SELECT` | `authenticated` | `USING (blocker_id = (select auth.uid()))` — a user sees **only their own** blocks, never the blocks others placed on them. |
| `INSERT` | `authenticated` | `WITH CHECK (blocker_id = (select auth.uid()))` — A6's `block_user` RPC (`security definer`) is the real entry point. |
| `DELETE` | `authenticated` | `USING (blocker_id = (select auth.uid()))` |
| any | `anon` | **no policy** |

### 4.5 `public.practice_points` (A1 baseline — A4 may request changes)

| Command | Role | Predicate |
|---|---|---|
| `SELECT` | `authenticated` | `group_id is null` (global defaults) **OR** `public.is_group_member(public.practice_points.group_id)` |
| `INSERT` / `UPDATE` / `DELETE` | `authenticated` | `group_id is null` **OR** `public.is_group_admin(public.practice_points.group_id)` |

### 4.6 `public.audit_log`

| Command | Role | Predicate |
|---|---|---|
| `SELECT` | `authenticated` | `USING (public.is_any_group_admin())` — admins of at least one group. |
| `INSERT` | `service_role` | `WITH CHECK (true)`. `service_role` has `BYPASSRLS`, so this policy is belt-and-braces; every real write goes through a `security definer` RPC. |
| `UPDATE` / `DELETE` | — | **no policy** — the log is append-only. |

### 4.7 Policy names (drop/replace by name when widening)

```
profiles_select_shared_or_own      profiles_update_own
groups_select_visible               groups_insert_own
groups_update_admin                 groups_delete_admin
group_members_select_members        group_members_insert_self
group_members_update_admin          group_members_delete_admin_or_self
user_blocks_select_own              user_blocks_insert_own      user_blocks_delete_own
practice_points_select              practice_points_insert_admin
practice_points_update_admin        practice_points_delete_admin
audit_log_select_admin              audit_log_insert_service
```

---

## 5. Trigger conventions

Every table that has an `updated_at` column gets a `BEFORE UPDATE` trigger
named **`trg_<table>_updated_at`** that calls `public.set_updated_at()`.

Attached so far:

| Table | Trigger |
|---|---|
| `public.profiles` | `trg_profiles_updated_at` |
| `public.groups` | `trg_groups_updated_at` |
| `public.group_members` | `trg_group_members_updated_at` |
| `public.practice_points` | `trg_practice_points_updated_at` |

`public.user_blocks` and `public.audit_log` have **no** `updated_at` and
therefore no trigger.

**Attach it to your own table with one line in your migration:**

```sql
select public.attach_updated_at ('public.your_table'::regclass);
```

That creates (or replaces) `trg_your_table_updated_at`. It is `SECURITY
INVOKER`, so it must be executed by the table owner — migrations run as
`postgres`, so this works.

<details>
<summary>Equivalent explicit DDL (if you prefer not to use the helper)</summary>

```sql
create trigger trg_your_table_updated_at
  before update on public.your_table
  for each row execute function public.set_updated_at();
```
</details>

---

## 6. Cron (`pg_cron`)

**Status: INSTALLED AND VERIFIED WORKING** on this project.

- Extension catalog entry: `pg_extension.extnamespace = pg_catalog` (the
  extension pins itself to `pg_catalog`; `WITH SCHEMA extensions` is accepted
  but the entry still lands in `pg_catalog`).
- The **callables live in their own schema `cron`**: `cron.schedule`,
  `cron.unschedule`, `cron.alter_job`.
- `USAGE` on schema `cron` granted to `postgres` and `service_role`.
- `cron.job` is the job table (`jobid`, `jobname`, `schedule`, `command`,
  `active`, …).

**Working syntax (verified: scheduled a job, read it back, unscheduled it):**

```sql
-- 3-arg: named job
select cron.schedule (
  'a1_probe_cron',            -- job_name
  '0 4 1 1 *',                -- 5-field cron expression (minute hour dom mon dow)
  'select 1'                 -- command, run as the job's database role
);                            -- -> 2  (the jobid)

-- 2-arg: anonymous job
select cron.schedule ('0 4 1 1 *', 'select 1');

-- read the schedule
select jobid, jobname, schedule, command, active from cron.job;

-- remove
select cron.unschedule ('a1_probe_cron');   -- -> true
select cron.unschedule (2);                 -- by jobid
```

**Gotchas**

- `cron.schedule()` **requires the job to be scheduled as a role that owns the
  job table** — run it as `postgres` (the MCP `execute_sql` role) or as a
  `service_role`-privileged role.
- The command string runs as the role that created the job. Use
  `security definer` RPCs for anything privileged, never raw SQL that trusts
  `search_path`.
- `cron.schedule` **is** available (the pg_cron background worker is running);
  there was no "pg_cron not loaded" error. If a future agent sees
  `cron.schedule` failing with *"pg_cron is not loaded"*, the alternative is
  `pg_net` (§7) plus an external scheduler (GitHub Actions / Supabase Cron
  edge function), not `pg_cron`.
- `cron.schedule` and `cron.unschedule` are **not** `security definer`; they
  write to `cron.job` directly, so the calling role needs INSERT/DELETE on it.

---

## 7. pg_net — calling an Edge Function from the database

**Status: INSTALLED AND VERIFIED WORKING** (two real HTTPS round trips
completed; the response bodies were read back).

- Extension catalog entry: `pg_extension.extnamespace = extensions`.
- The **callables live in their own schema `net`**: `net.http_post`,
  `net.http_get`, `net.http_delete`, `net._http_collect_response`,
  `net.check_worker_is_up`, …
- `USAGE` on schema `net` granted to `postgres`, `anon`, `authenticated`,
  `service_role`.
- Project URL: `https://khovpljkitslmjmonizu.supabase.co`.

### 7.1 Exact signatures (pg_net 0.20.4)

```
net.http_post(url text, body jsonb default '{}', params jsonb default '{}',
              headers jsonb default '{"Content-Type":"application/json"}',
              timeout_milliseconds integer default 5000) → bigint
net.http_get(url text, params jsonb default '{}', headers jsonb default '{}',
             timeout_milliseconds integer default 5000) → bigint
net.http_delete(url text, body jsonb, params jsonb, headers jsonb,
                timeout_milliseconds integer) → bigint
net.http_collect_response(request_id bigint, async boolean default true) → net.http_response_result
net._http_collect_response(request_id bigint, async boolean default true) → net.http_response_result
```

### 7.2 Working call (verified)

```sql
-- POST a JSON body; returns the request id
select net.http_post (
  url     := 'https://khovpljkitslmjmonizu.supabase.co/functions/v1/my-function',
  body    := '{"probe":"a1"}'::jsonb,
  params  := '{}'::jsonb,
  headers := jsonb_build_object (
    'Content-Type',  'application/json',
    'Authorization', 'Bearer <service-role-key>'
  ),
  timeout_milliseconds := 5000
);                            -- -> 1  (the request id)

-- GET with query parameters
select net.http_get (
  url     := 'https://khovpljkitslmjmonizu.supabase.co/functions/v1/my-function',
  params  := jsonb_build_object ('limit', 10),
  timeout_milliseconds := 5000
);
```

### 7.3 Reading the asynchronous response

pg_net is **asynchronous**: `net.http_post` returns a request id immediately;
the background worker performs the call and writes the result to
`net._http_response`.

```sql
-- (a) read the result rows
select id, status_code, content_type, content, timed_out, error_msg, created
from net._http_response
where id = 1;                -- the id returned by net.http_post

-- (b) or use the collector, which also tells you the outcome
select (net._http_collect_response (1, false)).status::text,   -- 'SUCCESS'
       (net._http_collect_response (1, false)).message;        -- 'ok'
```

> ### ⚠️ `net.http_collect_response()` is deprecated **and broken** in 0.20.4
> Its body is
> ```sql
> begin
>   raise notice 'The net.http_collect_response function is deprecated.';
>   select net._http_collect_response(request_id, async);
> end;
> ```
> — a `SELECT` with no destination inside a PL/pgSQL function. Calling it
> raises:
> ```
> ERROR: 42601: query has no destination for result data
> HINT:  If you want to discard the results of a SELECT, use PERFORM instead.
> CONTEXT:  PL/pgSQL function net.http_collect_response(bigint,boolean) line 4
> ```
> **Use `net._http_collect_response(request_id, false)` instead** (verified
> working: returns `status = 'SUCCESS'`, `message = 'ok'`), or read
> `net._http_response` directly.

### 7.4 Gotchas

- The call is made from the **database**, so it leaves the Supabase project
  over the public internet — always set `timeout_milliseconds`, and never call
  a non-idempotent endpoint unless the Edge Function itself is.
- `verify_jwt: true` Edge Functions need the caller's JWT in the
  `Authorization` header. A database-side call has **no user JWT**, so either
  send a `service_role` key or set `verify_jwt: false` and verify the payload
  signature inside the function (CONVENTIONS §5).
- **There is no `app.settings.service_role_key` GUC on this project** (verified:
  `current_setting('app.settings', true)` is NULL) and `vault` currently holds
  no secrets. To give the database a service-role key, put it in Supabase
  **Vault** (`vault.create_secret(...)`) and read it with
  `select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key';`
  — or call an Edge Function with `verify_jwt: false` and verify the payload
  yourself.
- `net._http_response` and `net._http_collect_response` are **internal**
  pg_net objects; they work today but are not part of a stable public API.
  Prefer `net.http_post` + `net._http_response`.

---

## 8. pgTAP invocation

Read **[`supabase/tests/README.md`](tests/README.md)** — it is the verified
procedure. One-line summary:

```js
// whole file as ONE execute_sql query
const r = await tools["supabase"]["execute_sql"]({ query: <entire .sql file> });
// r.result[0].result -> {"verdict":"PASS"|"FAIL","plan":n,"ran":n,"failed":n,"summary":"..."}
```

The file **must** end with:

```sql
select * from finish ();
select public.pgtap_summary () as result;
rollback;
```

---

## 9. Extension installation rules

- Extensions live in schema **`extensions`** (Supabase convention). A1 has
  already installed every extension the project needs.
- **No other agent may run `create extension`.** If you need one, report it
  to the orchestrator.

| Extension | Installed | Schema of the extension entry | Where the callables live |
|---|---|---|---|
| `pgcrypto` | yes (pre-installed by the platform, v1.3) | `extensions` | `extensions` |
| `pg_cron` | yes (1.6.4) | `pg_catalog` | **`cron`** |
| `pg_net` | yes (0.20.4) | `extensions` | **`net`** |
| `pgtap` | yes (1.3.3) | `extensions` | `extensions` |
| `uuid-ossp` | yes (pre-installed) | `extensions` | `extensions` |
| `pg_stat_statements` | yes (pre-installed) | `extensions` | `extensions` |

> **`gen_random_uuid()` does not need pgcrypto.** PostgreSQL 13+ ships
> `pg_catalog.gen_random_uuid()` natively, and this project is PG 17.11 —
> `pg_extension` shows both `pg_catalog.gen_random_uuid` and
> `extensions.gen_random_uuid` (the pgcrypto one). Every `uuid` default in
> this schema uses the built-in. A1 did **not** force-install a duplicate
> pgcrypto.

`pg_cron` and `pg_net` each create and own a dedicated schema (`cron`, `net`)
from inside their extension script, so `WITH SCHEMA extensions` only changes
the extension catalog entry — the functions still end up in `cron` / `net`.
Always call them fully qualified: `cron.schedule(...)`, `net.http_post(...)`.

---

## 10. Ownership map

| Object | Table owner | Policies / RPCs owner | Notes |
|---|---|---|---|
| `public.profiles` | **A1 (columns)** | **A1 (policies)**, A2 (`handle_new_user` trigger, account deletion), A9 (client) | A2 may **add** policies/RPCs; A2 must **not** `ALTER` the table — report the request instead. |
| `public.groups` | **A1 (columns)** | **A1 (policies)**, **A3** (`join_group_by_code`, invite codes, slot rules, admin transfer) | A3 may add policies and RPCs. |
| `public.group_members` | **A1 (columns)** | **A1 (policies)**, **A3** (join / leave / role RPCs) | A3 may add policies and RPCs. |
| `public.user_blocks` | **A1 (table + `is_blocked()`)** | **A6** (`block_user` / `unblock_user` RPCs, moderation flows) | A1 wrote **no** RPC here on purpose. |
| `public.practice_points` | **A1 (table)** | **A1 (baseline policies)**, **A4** (data + scoring RPC) | A4 may request policy changes. |
| `public.audit_log` | **A1 (table + RLS)** | A2 / A3 / A6 write through their own `security definer` RPCs | Append-only. No UPDATE/DELETE policies exist. |
| `public.set_updated_at()`, `public.attach_updated_at()` | **A1** | — | Use for every table you create. |
| `public.is_*` helpers | **A1** | — | Use for every policy you write. |
| `public.pgtap_*` helpers | **A1** | — | Test-only. |
| `cron.schedule` / `net.http_post` | **A1** (installed) | **A8** (uses both) | Verified working — see §6, §7. |
| storage buckets `avatars`, `group-covers`, `check-in-proofs` | **A6** | A6 | A1 only declared them in `config.toml`; **no bucket was created**. |
| `auth.users` | **A2** | A2 | A1 references it; A1 created no trigger on it. |
| `check_ins`, `streaks`, `feed_posts`, `chat_messages`, `prayer_intentions`, `group_invites`, `slot_unlocks`, `liturgical_days`, `reward_grants`, `device_tokens`, `notification_outbox`, `content_reports`, `moderation_actions`, `daily_readings`, `saints`, `sponsors`, `sponsored_challenges`, `amen_reactions`, `intention_prayers`, `pinned_notices`, `check_in_destinations`, `streak_mercy_uses`, `guardian_angel_pairings`, `guardian_nudges` | **A2–A8 respectively** | — | **A1 did not create any of these.** Do not create another agent's table — report the request. |

### 10.1 Cross-domain requests still open (A1 → other agents)

| To | Request |
|---|---|
| **A3** | Decide the `anon` SELECT policy on `public.groups` for the logged-out "public group preview". A1 shipped **no** `anon` policy on `groups` (a fraternity is private; a `challenge` is public). A3 should add e.g. `using (archived_at is null and group_type = 'challenge')` to `anon` if discovery must work logged-out. |
| **A3** | `groups` has no CHECK that a challenge has `starts_on`/`ends_on` with `ends_on >= starts_on` (the table is A1-owned). Enforce it in the create RPC, or request the CHECK from A1. |
| **A4** | `practice_points` policies are A1's baseline. A4 owns the data — request changes instead of altering the table. |
| **A6** | `user_blocks` has **no** `block_user`/`unblock_user` RPC. A6 owns them. A1 only owns the table + `is_blocked()`. |
| **A2** | `profiles` has **no** INSERT or DELETE policy for clients. A2's `handle_new_user` trigger must be `SECURITY DEFINER` (it is the only way to insert a profile on a `FORCE RLS` table) and A2 owns the account-deletion flow. |
| **A10** | `audit_log` is readable by any admin of any group. If A10 wants a tighter scope, request it — do not `ALTER` the table. |

---

## 11. Recipe: how to add a new table

Copy this template. Replace `your_table` / `your_column`.

```sql
-- supabase/migrations/0XXX_create_your_table.sql
-- =============================================================================
-- <AGENT> · 0XXX · <your table>
-- =============================================================================
-- Owner: <AGENT>. Columns AND policies are yours. Do not touch other agents'
-- tables — request a change instead (CONVENTIONS §2).
-- -----------------------------------------------------------------------------

create table public.your_table (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid not null references public.profiles (id) on delete cascade,
  payload    jsonb       not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.your_table is 'What this table holds and who owns it.';

-- Indexes: every foreign key needs one, or the performance advisor flags it.
create index idx_your_table_owner_id on public.your_table (owner_id);

-- RLS: enable AND force, always.
alter table public.your_table enable row level security;
alter table public.your_table force  row level security;

-- Policies: explicit, per command, per role.
-- Use A1's helpers; never re-implement membership logic.
create policy your_table_select_own
  on public.your_table
  for select
  to authenticated
  using (owner_id = (select auth.uid()));

create policy your_table_insert_own
  on public.your_table
  for insert
  to authenticated
  with check (owner_id = (select auth.uid()));

create policy your_table_update_own
  on public.your_table
  for update
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy your_table_delete_own
  on public.your_table
  for delete
  to authenticated
  using (owner_id = (select auth.uid()));

-- updated_at trigger (A1's convention).
select public.attach_updated_at ('public.your_table'::regclass);
```

**Then write the test** (`supabase/tests/<agent_id>/<topic>.sql`):

```sql
begin;
set local search_path = extensions, public;

select plan(4);

select has_table ('public', 'your_table', 'your_table table exists');
select ok (public.pgtap_rls_enabled ('public.your_table'::regclass), 'RLS is enabled on your_table');
select ok (public.pgtap_rls_forced ('public.your_table'::regclass), 'RLS is FORCED on your_table');
select has_trigger ('public', 'your_table', 'trg_your_table_updated_at', 'updated_at trigger is attached');

select * from finish ();
select public.pgtap_summary () as result;

rollback;
```

**Checklist before you report DONE**

1. `apply_migration` applied and visible in `list_migrations`.
2. `get_advisors({type:"security"})` and `get_advisors({type:"performance"})`
   show no new findings.
3. pgTAP suite passes: `verdict = "PASS"`, `ran = plan`, `failed = 0`.
4. One line appended to `docs/memory/decisions/<agent_id>.md`.
5. Nothing persisted: the test file is wrapped in `begin; … rollback;`.

---

## 12. Rules that apply to every agent

1. Schema `public` unless there is a strong reason not to. Extensions in
   `extensions`.
2. `uuid primary key default gen_random_uuid()`.
3. `created_at timestamptz not null default now()` **and**
   `updated_at timestamptz not null default now()` on every table, plus
   `select public.attach_updated_at('public.<table>'::regclass);`.
4. `REFERENCES public.<table>(id) ON DELETE CASCADE` unless you deliberately
   retain the referencing row.
5. `text` free-text columns get `CHECK (char_length(x) between 0 and n)`.
6. `jsonb` payloads that have a required shape get a
   `jsonb_typeof(...)` / `jsonb_path` CHECK.
7. RLS enabled **and** forced on every table; explicit policies per command.
8. `security definer` functions: `set search_path = ''` + fully-qualified names
   + `REVOKE EXECUTE FROM PUBLIC;` (then `GRANT EXECUTE TO authenticated;`).
9. RPC names are `verb_noun`; they return `jsonb` or a table type, never
   `void` for a mutation with a result; they are idempotent where the client
   may retry.
10. **Privacy invariant (hard build gate):** no table, column or bucket may
    hold Confession records, Spiritual Diary text, or private ("Only in My
    Private Diary") check-in content. A private check-in's `reflection_text`
    and `photo_path` are always `NULL`. See CONVENTIONS §8.
11. Never `DROP`, `TRUNCATE` or `ALTER` another agent's table. Report the
    request in your final message.

---

## 13. Advisor status (A1 baseline)

`get_advisors` after A1's work:

| Type | Lint | Level | Count | Status |
|---|---|---|---|---|
| security | `anon_security_definer_function_executable` | WARN | 5 | **fixed** — `revoke … from public` + re-grant to `authenticated`/`service_role` (migration `0011`). |
| security | `authenticated_security_definer_function_executable` | WARN | 5 | **open by design** — see §3.2. A10 owns the decision. |
| performance | `unused_index` | INFO | 6 | **accepted** — the tables are empty, so no index can have been used yet. They are all needed: `idx_groups_created_by` and `idx_practice_points_group_id` back foreign keys (removing them would trip the `unindexed_foreign_keys` lint), and the `audit_log` / `user_blocks` indexes back the queries A2/A3/A6 will run. |

> `idx_user_blocks_blocker_id` is technically redundant — the
> `user_blocks_blocker_id_blocked_id_key` unique index already has
> `blocker_id` as its leading column. A1 kept it because the spec asked for an
> index on `blocker_id`; it costs nothing on a table this small.

---

## 14. A3 additions — groups, invites, slots

> **Owner: A3 (groups, invites, slots).** Migration prefix range `0200`–`0299`.
> Applied migrations: `create_group_tables` (0201), `create_group` (0202),
> `join_group` (0203), `group_administration` (0204), `harden_rpc_wrappers`
> (0205), `featured_and_slots` (0206), `index_group_invites_created_by` (0207),
> `isolate_anon_impl` (0208), `fix_set_updated_at` (0209).

### 14.1 Tables owned by A3

#### `public.group_invites` — audit trail of every invite code ever issued

```sql
create table public.group_invites (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references public.groups (id) on delete cascade,
  code       text not null check (code ~ '^[0-9]{6}$'),
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revoked_at timestamptz,
  max_uses   integer not null default 0 check (max_uses >= 0),
  uses       integer not null default 0 check (uses >= 0),
  constraint group_invites_usage_check check (max_uses = 0 or uses <= max_uses)
);
```

* `max_uses = 0` means **unlimited**. `uses` is incremented by
  `public.join_group_by_code()` on every successful join.
* A row with `revoked_at` set is a **retired** code: it can no longer be used
  to join, and `public.groups.invite_code` no longer points at it.
* Indexes: `idx_group_invites_group_id`, `idx_group_invites_code`,
  `idx_group_invites_created_by`.

#### `public.slot_unlocks` — rewarded / granted entitlements

```sql
create table public.slot_unlocks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  kind       text not null check (kind in ('group_slot', 'streak_mercy', 'saint_theme')),
  source     text not null check (source in ('rewarded_video', 'admin_grant', 'sponsored')),
  starts_at  timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  notes      text check (char_length(notes) <= 500)
);
```

* `kind = 'group_slot'` = one extra **personal** group slot, valid until
  `expires_at` (30 days after a rewarded video).
* `expires_at IS NULL` = no expiry.
* `idx_slot_unlocks_user_kind` is **not unique** on purpose: a partial unique
  index `(user_id, kind) WHERE expires_at IS NULL OR expires_at > now()` is
  impossible (`now()` is not immutable). The "no double grant" rule is
  enforced inside `public.grant_slot_unlock()`.

#### `public.group_featured` — the Featured Seasonal Challenge link

```sql
create table public.group_featured (
  group_id      uuid primary key references public.groups (id) on delete cascade,
  is_featured   boolean not null default true,
  starts_on     date,
  ends_on       date,
  display_order integer not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint group_featured_dates_check check (ends_on is null or starts_on is null or ends_on >= starts_on)
);
```

* **A7 FKs `public.sponsored_challenges` to this table** (`sponsored_challenges_featured_group_id_fkey`) — that is why A3 ships it in the first migration of the wave.
* Only **challenge** groups may appear here; the rule is enforced by
  `public.set_featured_group()` (service_role only).

### 14.2 The slot rules (single source of truth: `private.slot_state()`)

| Rule | Value |
|---|---|
| Free tier | **2 personal groups + 1 seasonal challenge** |
| Rewarded video | **+1 personal slot for 30 days** (`slot_unlocks.kind = 'group_slot'`, `source = 'rewarded_video'`) |
| `personal_max` | `2 + (1 when an active group_slot unlock exists else 0)` |
| `seasonal_max` | `1` (never raised by a bonus) |
| `personal_used` | ACTIVE memberships in groups with `group_type = 'fraternity'` |
| `seasonal_used` | ACTIVE memberships in groups with `group_type = 'challenge'` |
| **ACTIVE membership** | the group is **not archived** and, for a challenge, the season has not ended (`ends_on IS NULL OR ends_on >= current_date`) |
| A **fraternity** consumes a **personal** slot | `create_group` / `join_group_by_code` reject the 3rd one |
| A **challenge** consumes the **seasonal** slot | `create_group` / `join_group_by_code` / `join_featured_challenge` reject the 2nd one |

The rule is enforced **server side only** — inside `private.create_group_impl()`,
`private.join_group_impl()`, `private.join_featured_impl()` and
`private.assert_slot_available()`. The client is never trusted. A user may
hold **at most 1 seasonal (featured/official) group at a time**.

`public.my_group_slots()` returns the live state:

```json
{
  "personal_used": 0, "personal_max": 2,
  "seasonal_used": 0, "seasonal_max": 1,
  "bonus_active": false, "bonus_expires_at": null,
  "personal_available": 2, "seasonal_available": 1
}
```

### 14.3 Invite code generation algorithm

`private.generate_invite_code(p_max_attempts integer default 20) → text`

1. Takes the **transaction-scoped advisory lock** `pg_advisory_xact_lock(hashtext('massmates.group_invite_code'))` so the "is it free?" check and the following INSERT are serialised across concurrent sessions.
2. Up to **20 bounded attempts** (never an infinite loop):
   * `code := lpad(floor(random() * 1000000)::bigint::text, 6, '0')` → always exactly 6 digits, leading zeros preserved;
   * the candidate is **free** when it is not the `invite_code` of ANY group (archived groups included) **and** not the `code` of a live (not revoked) `group_invites` row.
3. If no candidate is free it raises `P0001` — the caller never loops forever.
4. `private.create_group_impl()` and `private.reset_invite_code_impl()` wrap the INSERT/UPDATE in a `unique_violation` handler and retry (20 times) in case another transaction took the code between the check and the write.

Codes are **capabilities**: they are never returned by the public preview and
`anon` has no `SELECT` privilege on `public.group_invites`.

### 14.4 RPCs added by A3 (verbatim signatures — A9 uses these)

```sql
public.create_group(
  p_name                text,
  p_description         text                       default null,
  p_group_type          public.group_type          default 'fraternity'::public.group_type,
  p_scoring_mode        public.scoring_mode        default 'faithful_days'::public.scoring_mode,
  p_sharing_requirement public.sharing_requirement default 'open'::public.sharing_requirement,
  p_starts_on           date                       default null,
  p_ends_on             date                       default null,
  p_goal_target         integer                    default null
) returns jsonb
-- → { "group": {…}, "invite_code": "123456" }
```

```sql
public.join_group_by_code(p_code text) returns jsonb
-- → { "group": {…}, "invite_code": "123456", "member_role": "member", "already_member": false }
```

```sql
public.join_featured_challenge(p_group_id uuid) returns jsonb
-- → { "group": {…}, "member_role": "member", "already_member": false }
```

```sql
public.reset_invite_code(p_group_id uuid) returns jsonb
-- → { "group_id": "…", "invite_code": "123456" }
```

```sql
public.leave_group(p_group_id uuid) returns jsonb
-- → { "group_id": "…", "left": true, "archived": false }
```

```sql
public.remove_member(p_group_id uuid, p_member_id uuid) returns jsonb
-- → { "group_id": "…", "removed_user": "…", "removed_self": false }
```

```sql
public.transfer_admin(p_group_id uuid, p_new_admin_id uuid) returns jsonb
-- → { "group_id": "…", "new_admin": "…", "previous_admin": "…" }
```

```sql
public.preview_group_by_code(p_code text) returns jsonb
-- → { "id", "name", "group_type", "scoring_mode", "sharing_requirement",
--     "cover_path", "member_count", "is_featured", "starts_on", "ends_on",
--     "goal_target", "description_preview" }        -- NEVER invite_code / created_by
```

```sql
public.list_featured_challenges() returns jsonb
-- → [ { "id", "name", "group_type", "scoring_mode", "sharing_requirement",
--       "cover_path", "starts_on", "ends_on", "goal_target", "display_order",
--       "created_at", "description_preview", "member_count" }, … ]
```

```sql
public.my_group_slots() returns jsonb
-- → { "personal_used", "personal_max", "seasonal_used", "seasonal_max",
--     "bonus_active", "bonus_expires_at", "personal_available", "seasonal_available" }
```

```sql
public.grant_slot_unlock(
  p_user_id uuid, p_kind text, p_source text,
  p_days integer default 30, p_notes text default null
) returns jsonb
-- service_role only
```

```sql
public.set_featured_group(
  p_group_id uuid, p_is_featured boolean default true,
  p_starts_on date default null, p_ends_on date default null,
  p_display_order integer default 0
) returns jsonb
-- service_role only
```

#### Grant matrix

| RPC | `anon` | `authenticated` | `service_role` |
|---|---|---|---|
| `preview_group_by_code` | ✅ | ✅ | ✅ |
| `list_featured_challenges` | ✅ | ✅ | ✅ |
| all the other RPCs | ❌ | ✅ | ✅ |
| `grant_slot_unlock`, `set_featured_group` | ❌ | ❌ | ✅ |

`EXECUTE` is revoked from `PUBLIC` on every A3 function.

#### Error convention

| SQLSTATE | Meaning |
|---|---|
| `42501` | authentication / authorisation failure ("authentication required", "only a group admin …") |
| `22023` | invalid argument ("invalid invite code", "a challenge requires both starts_on and ends_on", …) |
| `P0001` | business rule violated ("slot limit: …", "you are the last admin …") |
| `P0002` | not found ("invite code not found", "group not found") |
| `23503` | the caller has no `public.profiles` row yet |

### 14.5 Implementation schemas

| Schema | Contents | `USAGE` granted to |
|---|---|---|
| `private` | the A3 implementations of the authenticated RPCs (`*_impl`) | `authenticated`, `service_role` |
| `a3_preview` | **only** the two public preview implementations | `anon` |

`private` is shared with A2 / A4 / A5 / A6 and several of their functions still
carry the **default ACL** (`EXECUTE` granted to `PUBLIC`). Granting `anon`
`USAGE` on `private` would therefore expose those functions to an
unauthenticated client — so the two functions that `anon` must reach live in
`a3_preview`, which contains nothing else.

**Design rule used by A3** (A1 §3.2 remediation):

* the **exposed** function in `public` is `SECURITY INVOKER` and only forwards
  to the implementation;
* the **implementation** in `private` / `a3_preview` is `SECURITY DEFINER`,
  `set search_path = ''`, fully qualified, and executable only by the roles
  that are supposed to call it.

Result: **no new `*_security_definer_function_executable` finding** — A3
contributes **0** to the two lints A1 left open.

### 14.6 Policies added by A3

| Table | Command | Role | Predicate |
|---|---|---|---|
| `group_invites` | SELECT | `authenticated` | `public.is_group_admin (group_id)` — only the admins of the group see the invite audit trail |
| `group_invites` | INSERT / UPDATE | `service_role` | `true` |
| `slot_unlocks` | SELECT | `authenticated` | `user_id = (select auth.uid())` |
| `slot_unlocks` | INSERT / UPDATE / DELETE | `service_role` | `true` |
| `group_featured` | SELECT | `authenticated`, `anon` | `true` (public discovery list) |
| `group_featured` | INSERT / UPDATE / DELETE | `service_role` | `true` |

Table privileges: `anon` has **no** `SELECT` on `group_invites` and
`slot_unlocks`; `anon` and `authenticated` have **no** write privilege on any
A3 table.

### 14.7 The logged-out preview — why there is NO `anon` policy on `public.groups`

A1's open request (§10.1) was to let `anon` preview a public challenge.
**RLS is row level, not column level**: any `anon` row policy on
`public.groups` also exposes the `invite_code` and `created_by` columns of
every visible row. A3 therefore did **not** add an `anon` policy to
`public.groups` and exposes the preview through the RPCs instead:

* `public.preview_group_by_code(code)` — the deep link `massmates://join/:code`;
* `public.list_featured_challenges()` — the logged-out Discovery Showcase.

If A10 later wants direct table access for `anon`, it must first drop the
table-level grant and re-grant column by column:

```sql
revoke select on public.groups from anon;
grant select (id, name, description, group_type, scoring_mode, sharing_requirement,
               cover_path, starts_on, ends_on, goal_target, created_at, updated_at)
  on public.groups to anon;
create policy groups_select_public_challenge on public.groups
  for select to anon using (group_type = 'challenge' and archived_at is null);
```

### 14.8 `public.groups` — the challenge window CHECK (orchestrator-granted)

```sql
alter table public.groups
  add constraint groups_challenge_dates_ck
  check (group_type <> 'challenge'
         or (starts_on is not null and ends_on is not null and ends_on >= starts_on));
```

A challenge is a dated season: it must declare `starts_on` **and** `ends_on`,
and `ends_on` must not precede `starts_on`. Fraternities are exempt.
`public.create_group()` enforces the same rule at the RPC level (plus
"a challenge cannot end in the past" and "a fraternity cannot have an `ends_on`
in the past").

### 14.9 Group administration rules

* A group has **exactly one admin**; the creator starts as that admin.
* The **last admin** cannot leave and cannot be removed — the role must be
  transferred first (`public.transfer_admin`).
* An admin **may** remove another admin, as long as the group keeps at least
  one admin.
* `public.transfer_admin()` demotes every other admin to `member` and promotes
  the new one, so the group always ends up with a single admin.
* When the **last member** leaves, the group is **archived**
  (`archived_at` is set) and the membership row is removed.

### 14.10 Fix to A1's `public.set_updated_at()` (migration 0209)

A1 attached `trg_group_members_updated_at` to `public.group_members`, but
that table has **no `updated_at` column**, so the unconditional
`new.updated_at := now()` made **every** `UPDATE` on `public.group_members`
fail with `42703 record "new" has no field "updated_at"` — which broke A1's
own `group_members_update_admin` policy and A3's `public.transfer_admin()`.

The trigger function now only writes the column when the relation really has
one. Tables with an `updated_at` column behave exactly as before.


---

## 15. A5 additions — Community feed, prayer wall & realtime chat

> **Owner: A5** (prefix range `0400`–`0499`).
> Migrations: `create_feed_prayer_chat_tables` (0401),
> `create_feed_prayer_rpcs` (0402), `create_chat_notice_rpcs` (0403),
> `create_moderation_and_realtime_rpcs` (0404),
> `fix_feed_rpc_page_scope` (0405), `index_pinned_notices_author_id` (0406).
> Tests: `supabase/tests/a5/community.sql` — **131 assertions, PASS**.

### 15.1 Tables

| Table | Purpose | Writes |
|---|---|---|
| `public.feed_posts` | Group feed derived from **group-shared** check-ins. | A4's fan-out trigger only. **No** client INSERT/UPDATE/DELETE policy. |
| `public.amen_reactions` | `amen` / `united_in_prayer` reactions on a post. | Own rows only. |
| `public.prayer_intentions` | The **Prayer Wall** — a *public* prayer request. | Own rows + group admin. |
| `public.intention_prayers` | One row per "I Prayed for You". | Own rows only. |
| `public.chat_messages` | Realtime group chat. | Own rows + group admin (delete). |
| `public.pinned_notices` | One active notice per group. | Group admins only. |

```sql
-- public.feed_posts
create table public.feed_posts (
  id              uuid primary key default gen_random_uuid(),
  check_in_id     uuid references public.check_ins (id) on delete cascade,   -- A4
  group_id        uuid not null references public.groups (id) on delete cascade,
  user_id         uuid not null references public.profiles (id) on delete cascade,
  practice_kind   public.practice_kind not null,
  reflection_text text check (reflection_text is null or char_length (reflection_text) <= 2000),
  photo_path      text check (photo_path is null or photo_path like 'witness-photos/%'),
  points          integer not null default 0 check (points >= 0),
  is_hidden       boolean not null default false,
  hidden_reason   text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint feed_posts_no_confession
    check (practice_kind <> 'confession'::public.practice_kind)   -- SACRED PRIVACY
);

-- public.amen_reactions
create table public.amen_reactions (
  id            uuid primary key default gen_random_uuid(),
  post_id       uuid not null references public.feed_posts (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  reaction_type text not null default 'amen'
    check (reaction_type in ('amen', 'united_in_prayer')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (post_id, user_id, reaction_type)
);

-- public.prayer_intentions
create table public.prayer_intentions (
  id           uuid primary key default gen_random_uuid(),
  group_id     uuid not null references public.groups (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  body         text not null check (char_length (body) between 1 and 1000),
  prayer_count integer not null default 0 check (prayer_count >= 0),
  is_hidden    boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- public.intention_prayers
create table public.intention_prayers (
  id           uuid primary key default gen_random_uuid(),
  intention_id uuid not null references public.prayer_intentions (id) on delete cascade,
  prayer_id    uuid not null references public.profiles (id) on delete cascade,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (intention_id, prayer_id)
);

-- public.chat_messages
create table public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  group_id    uuid not null references public.groups (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  body        text not null check (char_length (body) between 1 and 2000),
  reply_to_id uuid references public.chat_messages (id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- public.pinned_notices
create table public.pinned_notices (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references public.groups (id) on delete cascade,
  author_id  uuid not null references public.profiles (id) on delete cascade,
  body       text not null check (char_length (body) between 1 and 500),
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index uq_pinned_notices_active_group
  on public.pinned_notices (group_id) where is_active;
```

**Counter trigger** — `trg_intention_prayers_count` (AFTER INSERT `+1`,
AFTER DELETE `-1`, floored at 0) on `public.intention_prayers`, implemented by
`private.a5_sync_intention_prayer_count()` (SECURITY DEFINER). Clients have
**no** UPDATE privilege on `prayer_intentions.prayer_count` (column-level
grant: `grant update (body)` only).

### 15.2 RPC signatures (verbatim — A9 uses these)

All of them are `SECURITY DEFINER`, `SET search_path = ''`, `REVOKE EXECUTE
FROM PUBLIC, anon` and `GRANT EXECUTE TO authenticated` (except the two
server-only seams below, which are granted to `service_role` only).

```
public.get_feed_posts(p_group_id uuid, p_before text default null, p_limit integer default 20) -> jsonb
public.get_prayer_intentions(p_group_id uuid, p_before text default null, p_limit integer default 20) -> jsonb
public.get_chat_messages(p_group_id uuid, p_before text default null, p_limit integer default 30) -> jsonb
public.toggle_amen(p_post_id uuid, p_reaction_type text default 'amen') -> jsonb
public.toggle_prayed_for(p_intention_id uuid) -> jsonb
public.create_prayer_intention(p_group_id uuid, p_body text) -> jsonb
public.create_chat_message(p_group_id uuid, p_body text, p_reply_to_id uuid default null) -> jsonb
public.set_pinned_notice(p_group_id uuid, p_body text) -> jsonb
public.clear_pinned_notice(p_group_id uuid) -> jsonb
public.soft_delete_feed_post(p_post_id uuid) -> jsonb
public.emit_prayer_notification(p_intention_id uuid, p_prayer_id uuid) -> jsonb   -- service_role only
public.insert_feed_post(p_check_in_id uuid, p_group_id uuid, p_user_id uuid,
                         p_practice_kind public.practice_kind,
                         p_reflection_text text default null,
                         p_photo_path text default null,
                         p_points integer default 0) -> jsonb                      -- service_role only
```

Return shapes:

| RPC | Returns |
|---|---|
| `get_feed_posts` | `{"items":[{id, check_in_id, group_id, user_id, practice_kind, reflection_text, photo_path, points, created_at, amens, united_in_prayer, my_reactions[]}], "next_cursor":"…"}` |
| `get_prayer_intentions` | `{"items":[{id, group_id, user_id, body, prayer_count, prayed, created_at}], "next_cursor":"…"}` |
| `get_chat_messages` | `{"items":[{id, group_id, user_id, body, reply_to_id, created_at}], "next_cursor":"…"}` |
| `toggle_amen` | `{"amens":n, "united_in_prayer":n, "reacted":bool}` |
| `toggle_prayed_for` | `{"prayer_count":n, "prayed":bool}` |
| `create_prayer_intention` | `{id, group_id, user_id, body, prayer_count, created_at}` |
| `create_chat_message` | `{id, group_id, user_id, body, reply_to_id, created_at}` |
| `set_pinned_notice` | `{id, group_id, author_id, body, is_active, replaced, created_at}` |
| `clear_pinned_notice` | `{group_id, cleared}` |
| `soft_delete_feed_post` | `{post_id, group_id, hidden, hidden_reason, changed}` |
| `insert_feed_post` | `{id, check_in_id, group_id, user_id, practice_kind}` |

Every `created_at` is a **UTC ISO-8601 string with microseconds**, e.g.
`2026-10-21T23:39:12.345678Z`.

### 15.3 Cursor format (A9 — read this one)

* `next_cursor` is a **composite keyset cursor**:
  `"<created_at ISO-8601 UTC>|<row uuid>"` — e.g.
  `2026-10-21T23:39:12.345678Z|9f0e…`.
* Pass it back **unchanged** as `p_before` of the next call.
* `p_before` is `text` (not `timestamptz`) precisely so the composite cursor
  round-trips. A **bare** ISO-8601 timestamp is also accepted; it then compares
  **strictly** on `created_at` (`created_at < cursor`) and therefore *skips*
  rows that share the cursor timestamp. Always use the composite form.
* Ordering is `created_at DESC, id DESC` (newest first) for the feed, the
  prayer wall **and** the chat. The chat is read bottom-up, so the client
  reverses `items` when rendering.
* `next_cursor` is `null` only when the page is empty. Stop when a page comes
  back with fewer than `p_limit` items, or when `items` is empty.
* `p_limit` is clamped: feed/prayer wall `1..50`, chat `1..100`.

### 15.4 Realtime publication — **DONE**

`public.chat_messages`, `public.amen_reactions` and `public.intention_prayers`
are members of the `supabase_realtime` publication (verified with
`select * from pg_publication_tables where pubname = 'supabase_realtime';` →
3 rows). The three tables also have `REPLICA IDENTITY FULL`, so an
INSERT/UPDATE/DELETE `postgres_changes` event carries the whole row.

> **RLS is enforced for Realtime.** Supabase's `postgres_changes` channel
> applies the table's RLS policies to `authenticated` subscribers, so the
> policies in §15.5 already protect the channel — a subscriber only receives
> the rows it is allowed to `SELECT`.

### 15.5 RLS summary

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `feed_posts` | group member **AND** not blocked **AND** (`not is_hidden` **OR** group admin) | — | — | — |
| `amen_reactions` | the post is visible **AND** not blocked | own rows, on a visible post | — | own rows |
| `prayer_intentions` | group member **AND** not blocked **AND** (`not is_hidden` **OR** group admin) | own rows, in a group you belong to | own rows (body only) | own rows or group admin |
| `intention_prayers` | the intention is visible **AND** not blocked | own rows | — | own rows |
| `chat_messages` | group member **AND** not blocked | own rows, in a group you belong to | — | own rows or group admin |
| `pinned_notices` | group member | group admin | group admin (body only) | group admin |

> A blocked pair hides content **in both directions** (`public.is_blocked()` is
> symmetric).

### 15.6 A8 seam — "someone prayed for you" notification

A8 owns `public.notification_outbox`. A5 exposes a safe seam that A8 wires up:

```
public.emit_prayer_notification(p_intention_id uuid, p_prayer_id uuid) -> jsonb
```

* It is **safe to call before `notification_outbox` exists**: it detects the
  table with `to_regclass('public.notification_outbox')` and returns
  `{"emitted":false,"reason":"notification_outbox_not_available"}` instead of
  raising.
* `public.toggle_prayed_for()` already calls it on every new prayer, so the
  notification works as soon as A8 creates the outbox table and the trigger.
* A5 also calls it with the exact same payload shape A8 should use:
  `recipient_id` = the intention author, `actor_id` = the prayer, `kind` =
  `'intention.prayed_for'`, `payload` =
  `{"intention_id": …, "prayer_id": …}`.

**The exact trigger A8 should create** (on A5's table):

```sql
create or replace function private.a8_notify_prayer_notification ()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $$
begin
  perform public.emit_prayer_notification (new.intention_id, new.prayer_id);
  return new;
end;
$$;

create trigger trg_intention_prayers_notify
  after insert on public.intention_prayers
  for each row execute function private.a8_notify_prayer_notification ();
```

(A8 may instead replace the body of `public.emit_prayer_notification()` with
its own `INSERT INTO public.notification_outbox …`; the trigger above then
becomes optional. A5's function swallows any error from the insert, so a
column mismatch cannot break the prayer wall.)

### 15.7 A6 contract — removing a feed post

```
public.soft_delete_feed_post(p_post_id uuid) -> jsonb
```

* **Caller must be an admin of the post's group** (`public.is_group_admin`).
  A6's `admin_delete_post` should call it with the end user's JWT, so the
  group-admin check is enforced.
* It sets `is_hidden = true` and `hidden_reason = 'admin_removed'` — the row
  is **kept** (soft delete) and stays visible to the group admins.
* It appends **one** row to `public.audit_log`:
  `action = 'feed.post_removed'`, `target_type = 'feed_post'`,
  `target_id = <post id>`, `metadata = {"group_id":…,"post_author_id":…,"reason":"admin_removed"}`.
* Returns `{"post_id":…, "group_id":…, "hidden":true, "hidden_reason":"admin_removed", "changed":n}`.
* A **platform-moderator** (not a group admin) must be served by A6's own
  `SECURITY DEFINER` RPC that sets `is_hidden` on `public.feed_posts` — A5's
  function deliberately refuses non-admins.

### 15.8 A4 seam — the feed fan-out

A4 owns the fan-out trigger `trg_check_in_destinations_fanout` on
`public.check_in_destinations` (migration `0305`); it inserts directly into
`public.feed_posts` and therefore works without any A5 object. A5 also exposes
`public.insert_feed_post(...)` as a **validated, idempotent** alternative: it
re-checks the check-in against `public.check_ins` / `public.check_in_destinations`
and refuses a private check-in or a confession. The feed has **no** client
INSERT policy, so a client can never forge a post.

### 15.9 A9 — how to call these from Swift

```swift
// POST /rest/v1/rpc/get_feed_posts
// { "p_group_id": "<uuid>", "p_before": "<next_cursor or null>", "p_limit": 20 }
```

`next_cursor` is a plain `String?`; pass it straight back in `p_before`.
Every RPC that mutates is idempotent under a retry
(`toggle_amen`, `toggle_prayed_for`, `insert_feed_post`) or returns the
existing row (`create_prayer_intention` is **not** idempotent — it always
creates a new intention).

### 15.10 Known deviation

`p_before` is `text` instead of the `timestamptz` of the original brief. A
`timestamptz` parameter cannot carry the composite `created_at|id` cursor, so
the round-trip would be impossible and keyset pagination would skip or
duplicate rows that share a `created_at`. The composite cursor is the only
form that is strictly correct; `p_before` still accepts a bare ISO-8601
timestamp for convenience.

---

## 16. A4 additions — check-in engine, streaks & scoring

> **Owner: A4** (migration prefix `0300`–`0399`). Applied migrations:
> `create_check_in_tables`, `create_submit_check_in`, `create_streak_and_ring_rpcs`,
> `create_streak_mercy`, `create_feed_fanout_trigger`, `fix_group_progress_alias`.
> A4 owns the **data** of `public.practice_points` (A1 owns the table).

### 16.1 Tables

#### `public.check_ins` — one recorded practice (immutable)

```sql
create table public.check_ins (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  practice_kind   public.practice_kind not null,
  sharing         text not null check (sharing in ('private', 'group')),
  local_date      date not null,
  timezone        text not null,
  reflection_text text check (char_length(reflection_text) <= 2000),
  photo_path      text check (photo_path is null or photo_path like 'witness-photos/%'),
  points          integer not null default 0 check (points >= 0),
  created_at      timestamptz not null default now(),
  constraint check_ins_user_practice_day_uniq unique (user_id, practice_kind, local_date),
  constraint check_ins_private_has_no_content_ck check (
    sharing = 'group' or (reflection_text is null and photo_path is null)
  ),
  constraint check_ins_confession_is_private_ck check (
    practice_kind <> 'confession' or sharing = 'private'
  )
);
```

**The two privacy CHECKs are a hard build gate (CONVENTIONS §8):**

| Constraint | Rule |
|---|---|
| `check_ins_private_has_no_content_ck` | a `private` check-in **NEVER** carries a reflection nor a photo. |
| `check_ins_confession_is_private_ck` | a `confession` check-in **MUST** be `sharing = 'private'`. |

Plus: `UNIQUE (user_id, practice_kind, local_date)` = **one check-in per practice
per local day** (a single check-in may fan out to several groups).

Indexes: `idx_check_ins_user_local_date (user_id, local_date desc)`,
`idx_check_ins_user_created_at (user_id, created_at desc)`,
`idx_check_ins_group_shared_user_local_date (user_id, local_date desc) where sharing = 'group'`.
**No `updated_at`** — a check-in is never edited. **No client INSERT/UPDATE
policy** — writes go through `public.submit_check_in()`.

#### `public.check_in_destinations` — the group fan-out

```sql
create table public.check_in_destinations (
  id          uuid primary key default gen_random_uuid(),
  check_in_id uuid not null references public.check_ins (id) on delete cascade,
  group_id    uuid not null references public.groups (id) on delete cascade,
  created_at  timestamptz not null default now(),
  constraint check_in_destinations_check_in_group_uniq unique (check_in_id, group_id)
);
```

> **A private check-in produces ZERO destination rows.** That is the privacy
> boundary: a private check-in never reaches a group, a feed or another user.

#### `public.streaks` — the persisted Daily Streak summary

`user_id uuid PK REFERENCES public.profiles(id) ON DELETE CASCADE`,
`current_streak integer NOT NULL DEFAULT 0 CHECK (>= 0)`,
`longest_streak integer NOT NULL DEFAULT 0 CHECK (>= 0)`,
`last_practice_date date`, `total_practices integer NOT NULL DEFAULT 0`,
`updated_at timestamptz NOT NULL DEFAULT now()` (+ `trg_streaks_updated_at`).

#### `public.streak_mercy_uses` — consumed mercies

`id`, `user_id`, `used_on date`, `repairs_date date`, `created_at`,
`UNIQUE (user_id, used_on)`, `UNIQUE (user_id, repairs_date)`.

#### `public.streak_mercy_grants` — **A7 WRITES HERE**

```sql
create table public.streak_mercy_grants (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  granted_at timestamptz not null default now(),
  used_at    timestamptz,
  expires_at timestamptz not null default (now() + interval '30 days'),
  constraint streak_mercy_grants_used_after_granted_ck check (used_at is null or used_at >= granted_at)
);
```

> **Contract for A7 (rewards):** after the rewarded video is verified, **INSERT
> one row into `public.streak_mercy_grants`** (`user_id`, optional `expires_at`).
> `used_at` is set by A4's `use_streak_mercy()`. A user can never self-grant:
> the only INSERT policy is `to service_role`; the convenience RPC
> `public.grant_streak_mercy(uuid, timestamptz)` is **service_role only**.

#### `public.streak_events` — the streak audit trail

`id`, `user_id`, `event_type text CHECK IN ('practice','mercy','reset','milestone')`,
`local_date date`, `streak_after integer`, `created_at`.
`practice` = every check-in · `reset` = a gap broke the streak ·
`mercy` = a missed day was repaired · `milestone` = 7 / 14 / 21 … days.

### 16.2 RLS (A4's tables)

| Table | SELECT | INSERT / UPDATE / DELETE |
|---|---|---|
| `check_ins` | own rows only (`user_id = auth.uid()`) | **no INSERT/UPDATE policy**; DELETE own rows only (the `trg_check_ins_after_delete` trigger recomputes the streak) |
| `check_in_destinations` | group members (`public.is_group_member(group_id, auth.uid())`) | **none** — RPC only |
| `streaks`, `streak_events`, `streak_mercy_uses` | own rows only | **none** — RPC only |
| `streak_mercy_grants` | own rows only | INSERT: `service_role` only |

### 16.3 RPC signatures (verbatim — A9 uses these)

```sql
public.submit_check_in(
  p_practice   public.practice_kind,
  p_sharing    text,
  p_group_ids  uuid[] default '{}',
  p_reflection text    default null,
  p_photo_path text    default null,
  p_local_date date    default null,
  p_timezone   text    default null
) returns jsonb

public.get_rule_of_life_ring(p_local_date date default null) returns jsonb
public.get_streak_summary() returns jsonb
public.get_consistency_heatmap(p_from date, p_to date) returns jsonb
public.get_group_progress(p_group_id uuid) returns jsonb
public.use_streak_mercy(p_repairs_date date) returns jsonb
public.set_practice_points(p_group_id uuid, p_practice public.practice_kind, p_points integer) returns jsonb
public.grant_streak_mercy(p_user_id uuid, p_expires_at timestamptz default null) returns jsonb  -- service_role only
public.on_check_in_destination_fanout() returns trigger                                     -- trigger function
```

All are `security definer set search_path = ''`, `REVOKE EXECUTE FROM PUBLIC`,
`GRANT EXECUTE TO authenticated` (except `grant_streak_mercy`, which is
`service_role` only, and `on_check_in_destination_fanout`, which is
`service_role` only).

**Returns**

```jsonc
// submit_check_in
{ "check_in_id": "<uuid>",
  "streak":   { "current": 3, "longest": 7, "last_practice_date": "2026-10-22" },
  "ring":     { "completed": 1, "total": 2, "percentage": 50.00, "items": [ … ] },
  "destinations": [ "<group uuid>" ] }

// get_streak_summary
{ "current_streak": 3, "longest_streak": 7, "last_practice_date": "2026-10-22",
  "total_practices": 12, "mercy_available": true, "mercy_used_this_month": 0 }

// get_rule_of_life_ring
{ "completed": 1, "total": 2, "percentage": 50.00,
  "items": [ { "kind": "rosary", "label": "Rosary", "done": true } ],
  "local_date": "2026-10-22" }

// get_consistency_heatmap  -> a plain map
{ "2026-10-21": 2, "2026-10-22": 1 }

// get_group_progress
{ "group_id": "<uuid>", "goal_current": 4, "goal_target": 100, "percentage": 4.00,
  "active_today_count": 1, "member_count": 3, "scoring_mode": "faithful_days",
  "per_member": [ { "user_id": "<uuid>", "display_name": "Alice", "points": 3, "days_active": 3 } ] }

// use_streak_mercy
{ "applied": true, "repairs_date": "2026-10-21", "current_streak": 4,
  "longest_streak": 7, "last_practice_date": "2026-10-22", "mercy_used_this_month": 1 }
```

**Error keys** (the message IS the key — the client maps it to localized copy):

| SQLSTATE | message |
|---|---|
| `22023` | `invalid_sharing` · `confession_is_private_only` · `private_check_in_cannot_hold_content` · `reflection_text_too_long` · `invalid_photo_path` · `invalid_timezone` · `local_date_in_future` · `local_date_too_old` · `group_sharing_requires_destination` · `group_archived` · `group_sharing_requirement_not_met` · `no_streak_mercy_grant` · `no_streak_to_repair` · `repairs_date_not_missed` · `repairs_date_not_adjacent_to_streak` · `repairs_date_in_future` · `repairs_date_too_old` · `invalid_range` · `range_too_large` · `group_not_found` · `invalid_points` |
| `23505` | `already_checked_in_today` · `streak_mercy_already_used_this_month` |
| `42501` | `not_a_group_member` · `blocked_by_group_creator` · `not_a_group_admin` · `service_role_required` |
| `28000` | `authentication required` · `profile_not_found` |

### 16.4 The Daily Streak algorithm

1. **Active days** = `{ distinct check_ins.local_date }` ∪ `{ streak_mercy_uses.repairs_date }`.
2. `current_streak` = the number of **consecutive** active days ending at the most
   recent active day (the "run"). A day with ≥ 1 practice (public **or** private)
   keeps it alive; a second practice on the same day does not increase it.
3. A **gap** breaks it: the next check-in after a gap starts a new run of 1
   (audited as a `reset` event). A **back-filled** older date can only lengthen a
   run — it never decreases the streak.
4. `longest_streak` = the longest run anywhere in the active-day set.
5. `last_practice_date` = the most recent active day · `total_practices` = the
   number of check-ins.
6. The streak does **not** decay on its own; it is reset by the next check-in.

### 16.5 The Rule of Life Ring algorithm (independent from the Streak)

1. `total` = the number of commitments in `profiles.rule_of_life`.
2. `completed` = the commitments whose `kind` was checked in on that `local_date`
   (DISTINCT `practice_kind`).
3. `percentage` = `completed * 100 / total` (0 when there is no commitment).
4. A private practice that is **not** in the Rule of Life keeps the Streak alive
   but does **not** move the Ring — the two are computed independently.

### 16.6 Scoring rules per group mode

| `groups.scoring_mode` | points of a check-in | `goal_current` of the group |
|---|---|---|
| `faithful_days` | `1` (1 point per active day) | the number of **distinct member-days** |
| `collective_treasure` | the group's `practice_points` row → else the global row → else **1** unit | the sum of the poured units |
| `custom_points` | the group's `practice_points` row → else the **global** row → else **0** | the sum of the points |

`check_ins.points` stores the **MAX** across the destination groups (0 for a
private check-in). The per-group contribution is recomputed by
`public.get_group_progress()`. Blocked members are excluded from every
aggregate and from `per_member`; `member_count` is the raw roster size.

### 16.7 The feed fan-out (bridge to A5) — ALREADY ATTACHED

`public.on_check_in_destination_fanout()` is the trigger function and
**A4 already created the trigger** on A4's own table:

```sql
create trigger trg_check_in_destinations_fanout
  after insert on public.check_in_destinations
  for each row execute function public.on_check_in_destination_fanout ();
```

> **A5: you do NOT need to create this trigger** — A4 owns
> `check_in_destinations` and it is already live. The function no-ops when
> `public.feed_posts` does not exist (`if to_regclass('public.feed_posts') is
> null then return new; end if;`) and never copies a private check-in.
> A5's `feed_posts` must keep the columns
> `check_in_id, group_id, user_id, practice_kind, reflection_text, photo_path,
> points, created_at` (all other NOT NULL columns need defaults).
