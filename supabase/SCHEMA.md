# MassMates — Backend Schema Contract

> **Owner: A1 (schema foundation).** Migration prefix range `0001`–`0099`.
> Every other backend agent MUST read this file before writing SQL.
> Shared conventions: [`docs/backend/CONVENTIONS.md`](../docs/backend/CONVENTIONS.md).
> Test harness: [`supabase/tests/README.md`](tests/README.md).
>
> **Live project:** `khovpljkitslmjmonuzu` · PostgreSQL **17.11** · Supabase.
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
| `public.current_user_id() → uuid` | `auth.uid()` of the caller; `NULL` for `anon` / no JWT. **Not executable by `anon`** (migration 0902). | no (invoker) |
| `public.is_group_member(p_group_id uuid) → boolean` | `true` when the **caller** is a member of `p_group_id`. | no (invoker) |
| `public.is_group_admin(p_group_id uuid) → boolean` | `true` when the **caller** is an **admin** of `p_group_id` (`member_role = 'admin'`). | no (invoker) |
| `public.is_group_member_of_any() → boolean` | `true` when the **caller** belongs to at least one group. | no (invoker) |
| `public.is_any_group_admin() → boolean` | `true` when the **caller** is an admin of at least one group. Gates `audit_log` reads. | no (invoker) |
| `public.is_blocked(p_other_id uuid) → boolean` | `true` when a block exists **in either direction** between the caller and `p_other_id`. Symmetric by design: a block hides both the blocker's and the blocked user's content from the other side. | no (invoker) |
| `public.set_updated_at() → trigger` | `BEFORE UPDATE` trigger body: `new.updated_at := now()`. | no (invoker) |
| `public.attach_updated_at(p_table regclass) → void` | Creates/replaces the trigger `trg_<table>_updated_at` on `p_table`, wired to `public.set_updated_at()`. **Owner-only** (`EXECUTE` revoked from `public, anon, authenticated, service_role`) — call it from a migration running as `postgres`. | no (invoker) |

> ### ⚠️ The helpers are SELF-SCOPED since migration 0900
> Before A10's audit the helpers took a **second argument**
> (`p_user_id uuid DEFAULT auth.uid()`) and were `SECURITY DEFINER` in the
> exposed `public` schema. Because `authenticated` MUST keep `EXECUTE` on
> them (PostgreSQL evaluates a policy expression with the *querying role's*
> privileges), any signed-in user could call
> `POST /rest/v1/rpc/is_group_member {"p_group_id":"…","p_user_id":"…"}` and
> learn whether an **arbitrary** user belonged to an **arbitrary** group —
> and `is_blocked` leaked the whole block graph. That was the
> `authenticated_security_definer_function_executable` finding and an
> enumeration oracle.
>
> Every policy in the project already passed the **caller's own** id as the
> second argument, so the two-user form was never needed by a policy. The
> fix was therefore a pure signature simplification:
>
> | Before | After |
> |---|---|
> | `public.is_group_member(uuid, uuid DEFAULT auth.uid())` | `public.is_group_member(uuid)` |
> | `public.is_group_admin(uuid, uuid DEFAULT auth.uid())` | `public.is_group_admin(uuid)` |
> | `public.is_blocked(uuid, uuid)` | `public.is_blocked(uuid)` |
> | `public.is_group_member_of_any(uuid DEFAULT auth.uid())` | `public.is_group_member_of_any()` |
> | `public.is_any_group_admin(uuid DEFAULT auth.uid())` | `public.is_any_group_admin()` |
>
> The privileged bodies now live in the **non-exposed** `private` schema as
> `SECURITY DEFINER` (`private.is_group_member_impl(uuid, uuid)` …) and the
> public helpers are thin `SECURITY INVOKER` wrappers that supply
> `auth.uid()` themselves. Server-side code (the `private.*_impl` bodies of
> A3/A5/A8) calls the private implementation directly and keeps the
> two-user form. See §21.


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
grant execute on function public.is_group_member (uuid) to anon;
```

### 3.2 Known security finding — **CLOSED by A10 (migration 0900)**

`get_advisors({type: "security"})` reported **one** lint:

```
authenticated_security_definer_function_executable   WARN   33 findings
```

Because the helpers lived in `public` (the schema PostgREST exposes) and
`authenticated` must keep `EXECUTE` (policies need it), a signed-in user
could call them directly as an RPC:

```
POST /rest/v1/rpc/is_group_member   {"p_group_id":"…","p_user_id":"…"}
POST /rest/v1/rpc/is_blocked        {"p_user_id":"…","p_other_id":"…"}
```

and learn whether an arbitrary user is a member of an arbitrary group, or
whether an arbitrary pair of users has blocked each other.

**A10 closed it (2026-10-22).** The 5 helpers became self-scoped (§3) and
the 28 domain RPCs moved to `private.<name>_impl` behind a thin
`SECURITY INVOKER` wrapper (migration 0901). The advisor now reports
**0 findings**. See §21.

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
- Project URL: `https://khovpljkitslmjmonuzu.supabase.co`.

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
  url     := 'https://khovpljkitslmjmonuzu.supabase.co/functions/v1/my-function',
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
  url     := 'https://khovpljkitslmjmonuzu.supabase.co/functions/v1/my-function',
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

## 13. Advisor status (A1 baseline → A10 final)

`get_advisors` after A1's work, and after A10's audit:

| Type | Lint | Level | Count (A1) | Count (A10) | Status |
|---|---|---|---|---|---|
| security | `anon_security_definer_function_executable` | WARN | 5 | **0** | **fixed** — `revoke … from public` + re-grant to `authenticated`/`service_role` (migration `0011`), and every later agent revoked `anon` explicitly. |
| security | `authenticated_security_definer_function_executable` | WARN | 5 (33 by the time A10 started) | **0** | **fixed by A10** — the 5 helpers became self-scoped (migration `0900`) and the 28 domain RPCs moved behind a `SECURITY INVOKER` wrapper over a `private.*_impl` implementation (migration `0901`). See §21. |
| security | `function_search_path_mutable` | WARN | 0 | **0** | never regressed. |
| performance | `unindexed_foreign_keys` | INFO | 0 | **0** | the 2 findings A8 created (`guardian_nudges.group_id`, `notification_outbox.group_id`) were fixed by A8 in `0706_index_guardian_angel_foreign_keys`. |
| performance | `unused_index` | INFO | 6 | **26** | **accepted baseline** — the tables are empty, so the planner cannot prove an index unused. Every one of them backs a foreign key, a unique constraint or a documented lookup path. The full list is in §21. |


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
  updated_at  timestamptz not null default now(),
  -- moderation (added by migration 0407 — see §15.11)
  is_hidden     boolean not null default false,
  hidden_reason text,
  hidden_at     timestamptz
);
create index chat_messages_hidden_idx
  on public.chat_messages (group_id, created_at desc) where is_hidden;

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
public.soft_delete_chat_message(p_message_id uuid) -> jsonb
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
| `soft_delete_chat_message` | `{message_id, group_id, hidden, hidden_reason, hidden_at, changed}` |
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
| `chat_messages` | group member **AND** not blocked **AND** (`not is_hidden` **OR** group admin) | own rows, in a group you belong to | — | own rows or group admin |
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

> **STATUS: DONE by A8** (migration `0704_create_notification_outbox_triggers`).
> A8 created `trg_intention_prayers_notify` exactly as documented above and
> **replaced the body** of `public.emit_prayer_notification` with its own
> `INSERT INTO public.notification_outbox … ON CONFLICT (dedupe_key) DO
> NOTHING` implementation (dedupe key `prayed:<intention_prayer_id>`).
> A5's `toggle_prayed_for()` still calls the function, so **both** paths fire
> for the same prayer — the outbox `dedupe_key` makes them idempotent, so the
> author receives exactly **one** push. Verified end-to-end
> (`supabase/tests/a5/community.sql`, "the 'prayed for you' notification is
> emitted exactly ONCE per prayer").

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


### 15.11 Chat moderation (migration `0407_chat_message_moderation`)

> Added after A6 reported the gap: `public.chat_messages` had no `is_hidden`
> column, so A6's `public.hide_content('chat_message', …)` could record the
> `moderation_actions` + `audit_log` trail but could not actually hide the
> message. Chat moderation is **in scope** (group admins must be able to
> remove inappropriate content; App Store UGC compliance needs a working
> report → hide path).

**New columns on `public.chat_messages`:**

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `is_hidden` | `boolean` | NOT NULL | `false` | Set only by the server. A hidden message is invisible to ordinary members. |
| `hidden_reason` | `text` | NULL | — | `'admin_removed'` is written by `public.soft_delete_chat_message`. A6's `hide_content` path sets **only** `is_hidden`, so this can be NULL for an A6-hidden message. |
| `hidden_at` | `timestamptz` | NULL | — | **No default, never set automatically on UPDATE** — only the moderation RPC stamps it. The `updated_at` convention (`trg_chat_messages_updated_at`) is unchanged. |

**New index:** `chat_messages_hidden_idx on public.chat_messages (group_id, created_at desc) where is_hidden`.

**Updated SELECT policy** (identical semantics to `feed_posts`):

```sql
create policy chat_messages_select_members
  on public.chat_messages
  for select
  to authenticated
  using (
    public.is_group_member (group_id, (select auth.uid ()))
    and not public.is_blocked ((select auth.uid ()), user_id)
    and (not is_hidden or public.is_group_admin (group_id, (select auth.uid ())))
  );
```

**New RPC** (mirrors `public.soft_delete_feed_post`):

```
public.soft_delete_chat_message(p_message_id uuid) -> jsonb
```

* `SECURITY DEFINER SET search_path = ''`;
  `REVOKE EXECUTE FROM PUBLIC, anon;` `GRANT EXECUTE TO authenticated, service_role;`
  (**the explicit `anon` revoke is required** — this project grants EXECUTE on
  new `public` functions to `anon` by default, so `from public` alone is not
  enough. Verified: `has_function_privilege('anon', …, 'execute') = false`).
* **Group-admin only** (admin of the message's group). Otherwise `42501`
  `only a group admin can remove a message`.
* Sets `is_hidden = true`, `hidden_reason = 'admin_removed'`,
  `hidden_at = now()`. The row is **kept** (soft delete) and stays visible to
  the group admins.
* Appends **one** row to `public.audit_log`: `action = 'chat.message_removed'`,
  `target_type = 'chat_message'`, `target_id = <message id>`,
  `metadata = {"group_id":…,"message_author_id":…,"reason":"admin_removed"}`.
* Returns `{message_id, group_id, hidden, hidden_reason, hidden_at, changed}`.
* Idempotent: a second call returns `changed = 0` and writes **no** second
  audit row.

**`public.get_chat_messages` was updated too** — it is `SECURITY DEFINER`, so
it bypasses RLS and has to apply the visibility rules itself. Hidden messages
are now returned **to a group admin only**, exactly like the feed.
`public.create_chat_message` also refuses to reply to a hidden message (it
reads as non-existent) so the moderation state is not leaked.

#### Cross-agent verification with A6 — **WORKS, no A6 change needed**

A6's `private.auto_hide_content()` already contained

```sql
update public.chat_messages set is_hidden = true where id = …
```

guarded by `private.has_column (v_tbl, 'is_hidden')`. The guard now passes, so
**A6's `public.hide_content('chat_message', …)` actually hides the message.**
Proven in `supabase/tests/a5/chat_moderation.sql`:

| Assertion | Result |
|---|---|
| `hide_content('chat_message', <id>, 'test') ->> 'hidden'` | `'true'` |
| `chat_messages.is_hidden` after the call | `true` |
| `chat_messages.hidden_reason` after the call | `NULL` (A6 sets only `is_hidden`) |
| `chat_messages.hidden_at` after the call | `NULL` (set only by A5's RPC) |
| `moderation_actions` row (`action_type = 'hide_chat_message'`) | 1 |
| the message for an ordinary member | invisible |

A6's `public.admin_delete_post` still delegates to
`public.soft_delete_feed_post` (dynamic `select public.soft_delete_feed_post(…)`),
still writes the `moderation_actions` + `audit_log` trail, and the
`feed_posts.is_hidden` visibility policy is unchanged — all verified in the
same file (section G).


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

---

## 17. A7 additions — liturgical content & monetization

> **Owner:** A7 (liturgical content & monetization) · migrations `0601`–`0606` ·
> Edge Function `admob-ssv` · tests `supabase/tests/a7/`.
> Full prose: [`docs/backend/LITURGICAL_CONTENT.md`](../../docs/backend/LITURGICAL_CONTENT.md).

### 18.1 Tables

| Table | Owner | Purpose |
|---|---|---|
| `public.liturgical_days` | A7 | one row per day: season, liturgical colour, celebration, rank |
| `public.daily_readings` | A7 | First Reading / Psalm / Gospel of the day + `translation` + `is_complete` |
| `public.saints` | A7 | the saints of the day |
| `public.saint_icons` | A7 | the unlockable reward themes (SF Symbol + season) |
| `public.user_saint_unlocks` | A7 | a user's unlocked theme until `expires_at` |
| `public.sponsors` | A7 | Catholic publishers / ministries behind a sponsored challenge |
| `public.sponsored_challenges` | A7 | a sponsored challenge in the Groups discovery showcase |
| `public.reward_grants` | A7 | **the monetization ledger** — one row per earned reward |
| `public.ad_view_tokens` | A7 | a pending rewarded-ad view (binds the SSV callback to a user) |
| `public.ssv_receipts` | A7 | operational trace of every AdMob SSV callback |

```sql
create table public.liturgical_days (
  id               uuid primary key default gen_random_uuid(),
  calendar_date    date not null unique,
  season           public.liturgical_season not null,
  liturgical_color text not null check (liturgical_color in ('green','purple','white','red','rose')),
  celebration      text check (char_length(celebration) between 1 and 200),
  "rank"           text check ("rank" in ('solemnity','feast','memorial','optional_memorial','ordinary')),
  notes            text check (char_length(notes) <= 2000),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table public.daily_readings (
  id                 uuid primary key default gen_random_uuid(),
  calendar_date      date not null unique references public.liturgical_days (calendar_date) on delete cascade,
  first_reading_ref  text check (char_length(first_reading_ref) <= 200),
  first_reading_text text,
  psalm_ref          text check (char_length(psalm_ref) <= 200),
  psalm_text         text,
  gospel_ref         text check (char_length(gospel_ref) <= 200),
  gospel_text        text,
  liturgical_color   text check (liturgical_color in ('green','purple','white','red','rose')),
  translation        text not null default 'cnbb' check (translation in ('cnbb','vatican')),
  is_complete        boolean not null default false,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint daily_readings_complete_check
    check (not is_complete or (first_reading_text is not null and gospel_text is not null))
);

create table public.saints (
  id            uuid primary key default gen_random_uuid(),
  calendar_date date not null,
  name          text not null check (char_length(name) between 1 and 120),
  kind          text not null check (kind in ('saint','blessed','optional_saint','beato')),
  biography     text,
  patronage     text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint saints_calendar_name_key unique (calendar_date, name)
);

create table public.saint_icons (
  id             uuid primary key default gen_random_uuid(),
  saint_id       uuid references public.saints (id) on delete cascade,
  slug           text not null unique check (slug ~ '^[a-z0-9-]{2,64}$'),
  name           text not null check (char_length(name) between 1 and 80),
  icon_sf_symbol text not null check (char_length(icon_sf_symbol) between 1 and 60),
  season         public.liturgical_season,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table public.user_saint_unlocks (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  saint_icon_id uuid not null references public.saint_icons (id) on delete cascade,
  granted_at    timestamptz not null default now(),
  expires_at    timestamptz not null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint user_saint_unlocks_user_icon_key unique (user_id, saint_icon_id),
  constraint user_saint_unlocks_expiry_check check (expires_at > granted_at)
);

create table public.sponsors (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 120),
  slug        text not null unique check (slug ~ '^[a-z0-9-]{2,80}$'),
  logo_path   text check (char_length(logo_path) <= 400),
  website_url text check (char_length(website_url) <= 300),
  description text check (char_length(description) <= 1000),
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table public.sponsored_challenges (
  id                uuid primary key default gen_random_uuid(),
  group_id          uuid not null references public.groups (id) on delete cascade,
  sponsor_id        uuid not null references public.sponsors (id) on delete cascade,
  headline          text not null check (char_length(headline) between 1 and 120),
  description       text check (char_length(description) <= 1000),
  coupon_code       text check (char_length(coupon_code) <= 40),
  coupon_url        text check (char_length(coupon_url) <= 300),
  starts_on         date,
  ends_on           date,
  is_active         boolean not null default true,
  display_order     integer not null default 0,
  featured_group_id uuid references public.group_featured (group_id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint sponsored_challenges_window_check
    check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

create table public.reward_grants (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  reward_type    text not null check (reward_type in ('streak_mercy','group_slot','saint_theme')),
  source         text not null check (source in ('admob_ssv','admin_grant','sponsored','achievement')),
  ad_network     text check (char_length(ad_network) <= 40),
  transaction_id text check (char_length(transaction_id) <= 200),
  status         text not null default 'granted' check (status in ('granted','consumed','expired','revoked')),
  granted_at     timestamptz not null default now(),
  expires_at     timestamptz,
  consumed_at    timestamptz,
  metadata       jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create unique index reward_grants_txn_uk
  on public.reward_grants (source, transaction_id)
  where transaction_id is not null;

create table public.ad_view_tokens (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  transaction_id text not null unique check (char_length(transaction_id) between 8 and 200),
  reward_type    text not null check (reward_type in ('streak_mercy','group_slot','saint_theme')),
  created_at     timestamptz not null default now(),
  expires_at     timestamptz not null,
  consumed_at    timestamptz,
  updated_at     timestamptz not null default now(),
  constraint ad_view_tokens_window_check check (expires_at > created_at)
);

create table public.ssv_receipts (
  id             uuid primary key default gen_random_uuid(),
  transaction_id text check (char_length(transaction_id) <= 200),
  reward_type    text check (reward_type in ('streak_mercy','group_slot','saint_theme')),
  user_id        uuid references public.profiles (id) on delete set null,
  ad_type        text check (char_length(ad_type) <= 40),
  ad_value       numeric(12, 2),
  currency       text check (char_length(currency) <= 8),
  package_name   text check (char_length(package_name) <= 120),
  outcome        text not null check (outcome in ('granted','duplicate','rejected')),
  reason         text check (char_length(reason) <= 200),
  received_at    timestamptz not null default now(),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
```

> `public.sponsors.logo_path` points at the **existing `group-covers` bucket**
> (A6). No new bucket is created: the sponsor artwork is public and one bucket
> is enough.

### 17.2 RLS summary

| Table | SELECT | INSERT/UPDATE/DELETE |
|---|---|---|
| `liturgical_days`, `daily_readings`, `saints`, `saint_icons` | `anon`, `authenticated` (public content) | **none** — `service_role` only |
| `user_saint_unlocks` | `authenticated`, own rows only | **none** — written by `grant_reward` |
| `sponsors`, `sponsored_challenges` | `anon`, `authenticated` | **none** — `service_role` only |
| `reward_grants` | `authenticated`, own rows only | **none** — `service_role` + `grant_reward` |
| `ad_view_tokens` | `authenticated`, own rows only | **none** — written by `begin_ad_reward_impl` |
| `ssv_receipts` | `service_role` only | `service_role` only |

RLS is **enabled and forced** on every one of them, and the platform's default
`INSERT/UPDATE/DELETE/TRUNCATE/TRIGGER/REFERENCES` grants to
`anon`/`authenticated` are **revoked explicitly**.

### 17.3 RPC signatures (verbatim)

```sql
public.get_today_liturgy ()                                   -> jsonb   -- anon, authenticated, service_role
public.get_liturgical_calendar (p_year integer)               -> jsonb   -- anon, authenticated, service_role
public.my_rewards ()                                          -> jsonb   -- authenticated, service_role
public.begin_ad_reward (p_reward_type text)                   -> jsonb   -- authenticated, service_role
public.consume_reward (p_grant_id uuid)                       -> jsonb   -- authenticated, service_role
public.grant_reward (
  p_user_id        uuid,
  p_reward_type    text,
  p_source         text,
  p_transaction_id text    default null,
  p_expires_days   integer default null,
  p_metadata       jsonb   default '{}'::jsonb
)                                                             -> jsonb   -- service_role ONLY
```

Private (non-exposed) helpers:

```sql
private.easter_sunday (p_year integer)              -> date
private.first_sunday_on_or_after (p_date date)       -> date
private.liturgical_calendar (p_year integer)         -> table (calendar_date, season, liturgical_color, celebration, "rank")
private.caller_role ()                               -> text
private.consume_reward_impl (p_grant_id uuid)        -> jsonb
private.begin_ad_reward_impl (p_reward_type text)    -> jsonb
```

**Security posture.** `public.grant_reward` is `SECURITY DEFINER` with
`set search_path = ''`, owned by `postgres`, and is executable by
**`service_role` only** (`REVOKE EXECUTE FROM PUBLIC, anon, authenticated`) —
so the linter never sees an exposed definer function a client can call. The
two functions a signed-in user may call on its **own** data
(`consume_reward`, `begin_ad_reward`) are thin `SECURITY INVOKER`
wrappers over a `SECURITY DEFINER` implementation in the non-exposed
`private` schema (the pattern A3 uses) — again, no new
`authenticated_security_definer_function_executable` finding. The read-only
RPCs are `SECURITY INVOKER`.

### 17.4 The reward-granting contract

`public.grant_reward` is the **only** write path of the ledger. It is
idempotent on `(source, transaction_id)`:

| `reward_type` | What is granted | Where | Duration |
|---|---|---|---|
| `streak_mercy` | one missed day repaired | A4 `public.streak_mercy_grants` | 30 days |
| `group_slot` | `+1` Group Slot | A3 `public.slot_unlocks` (`kind='group_slot'`, `source='rewarded_video'`) | 30 days |
| `saint_theme` | one app theme / icon | `public.user_saint_unlocks` | 7 days |

* a replayed `(source, transaction_id)` returns
  `{ok:true, granted:false, duplicate:true}` and creates **no** second
  reward (the partial unique index `reward_grants_txn_uk` is the backstop);
* a second `streak_mercy` while one is still active returns
  `{ok:false, reason:'streak_mercy_limit_reached'}` (one mercy per 30 days,
  product plan §4);
* the ledger row and the entitlement row are written in the **same
  transaction**: if the target table is missing, the whole grant fails and no
  orphan ledger row is left behind;
* `public.consume_reward(uuid)` marks the caller's own grant `consumed`
  (`status='consumed'`, `consumed_at=now()`). A caller can never consume
  another user's grant.

### 17.5 The AdMob SSV flow

Edge Function `supabase/functions/admob-ssv/index.ts`, deployed with
**`verify_jwt: false`** (Google cannot present a Supabase JWT) and it
verifies the request itself. It **fails closed**: without the operator's
`ADMOBSIGNING_KEY` secret it refuses every request.

```
app  ──(1) POST /rest/v1/rpc/begin_ad_reward {p_reward_type}  ──▶ creates public.ad_view_tokens row
app  ──(2) shows the rewarded video, passing the token id to AdMob as the
          custom parameter  massmates_txn=<transaction_id>
Google ──(3) SSV ping ─▶  /functions/v1/admob-ssv?ad_type=…&reward_type=…&sig=…&massmates_txn=…
Edge  ──(4) verifies the RSA-SHA256 signature of the canonical query string
          against ADMOBSIGNING_KEY, checks package_name, the reward-type
          allow-list, the pending token, its expiry and the user
Edge  ──(5) POST /rest/v1/rpc/grant_reward (service role)  ──▶ the reward
```

Response contract: `200 {ok:true, granted:true, reward_type, transaction_id}`,
or `200 {ok:true, granted:false, duplicate:true}` for an already-granted
transaction, or a **4xx** with `{ok:false, reason:"…"}` for anything that
fails verification (`missing_parameters`, `package_mismatch`,
`signing_key_not_configured`, `app_signing_key_mismatch`,
`invalid_signature`, `reward_type_not_allowed`, `no_pending_ad_view`,
`ad_view_token_expired`, `ad_view_token_already_used`,
`reward_type_mismatch`, `user_mismatch`).

> The MCP has no `secrets set` tool: the operator must run
> `supabase secrets set ADMOBSIGNING_KEY="-----BEGIN PUBLIC KEY-----\n…\n-----END PUBLIC KEY-----"`
> (or the equivalent base64 SPKI DER) before the function can grant anything.
> Until then it answers `400 signing_key_not_configured` and grants nothing.

### 17.6 The liturgical seeding rules

* The calendar is **computed** from the general Roman calendar rules
  (`private.liturgical_calendar`), never typed out day by day:
  Advent = the four Sundays before Christmas; Christmas = 25 Dec → the
  Baptism of the Lord; Lent = Ash Wednesday (Easter − 46) → Holy Saturday;
  Easter = Easter → Pentecost (Easter + 49); Ordinary Time = the rest.
* Easter itself comes from the anonymous Gregorian algorithm
  (`private.easter_sunday`), so any year from 1583 to 4099 can be seeded.
* Colour: a solemnity or a feast of martyrs carries its own colour; every
  other day takes the colour of its season (advent purple · christmas white ·
  lent purple · easter white · ordinary time green).
* **No Scripture text is ever invented.** The seed writes the structure and
  the celebration names of the fixed-date solemnities we are certain about,
  and nothing else. `first_reading_text` / `psalm_text` / `gospel_text`
  stay `NULL` and `is_complete` stays `false` until an authenticated
  `service_role` pipeline ingests the official **CNBB** text verbatim.
  `saints.biography` stays `NULL` for the same reason.
* Seeded: **2026 and 2027** (730 days). Adding a year = two INSERTs
  (`docs/backend/LITURGICAL_CONTENT.md` §6).

---

## 18. A6 additions — storage, moderation & safety

> **Owner: A6.** Migrations `0501`–`0505`. Policy document:
> [`docs/backend/MODERATION.md`](../docs/backend/MODERATION.md).
> Test suite: `supabase/tests/a6/storage_moderation.sql` (81 assertions, PASS).

### 18.1 Storage buckets

| Bucket | `public` | `file_size_limit` | `allowed_mime_types` | Path convention (inside the bucket) |
|---|---|---|---|---|
| `avatars` | **true** | 5 242 880 (5 MB) | `image/jpeg`, `image/png`, `image/heic`, `image/webp` | `<user_id>/<uuid>.<ext>` |
| `group-covers` | **true** | 8 388 608 (8 MB) | same | `<group_id>/<uuid>.<ext>` |
| `witness-photos` | **false** | 10 485 760 (10 MB) | same | `<group_id>/<user_id>/<uuid>.<ext>` |

`storage.buckets.id` is the bucket name; `storage.objects.name` is the path
**inside** the bucket (it does NOT repeat the bucket name).
`storage.foldername(name)` returns the path segments **without the file name**,
so for `witness-photos/<gid>/<uid>/<file>.jpg` the object name is
`<gid>/<uid>/<file>.jpg` and `foldername` = `['<gid>', '<uid>']`.

> **Sacred privacy:** `witness-photos` is the ONLY private bucket. It holds
> prayer-witness photographs and nothing else — never confession, never
> Spiritual Diary text. `anon` has **no policy at all** on it.

### 18.2 `storage.objects` policies (12 policies)

| Policy | Bucket | Cmd | Roles | Predicate |
|---|---|---|---|---|
| `avatars_select_public` | avatars | SELECT | `anon`, `authenticated` | `bucket_id = 'avatars'` |
| `avatars_insert_own` | avatars | INSERT | `authenticated` | `owner_id = auth.uid()::text` **and** `foldername(name)[1] = auth.uid()::text` |
| `avatars_update_own` | avatars | UPDATE | `authenticated` | own `owner_id`; `WITH CHECK` keeps the own-folder rule |
| `avatars_delete_own` | avatars | DELETE | `authenticated` | own `owner_id` |
| `group_covers_select_public` | group-covers | SELECT | `anon`, `authenticated` | `bucket_id = 'group-covers'` |
| `group_covers_insert_member` | group-covers | INSERT | `authenticated` | `public.is_group_member(private.try_uuid(foldername(name)[1]), auth.uid())` |
| `group_covers_update_admin` | group-covers | UPDATE | `authenticated` | `public.is_group_admin(…)` on the group of the path |
| `group_covers_delete_admin` | group-covers | DELETE | `authenticated` | `public.is_group_admin(…)` on the group of the path |
| `witness_photos_select_members` | witness-photos | SELECT | `authenticated` | `public.is_group_member(group of path, auth.uid())` **and not** `public.is_blocked(auth.uid(), owner of path)` |
| `witness_photos_insert_owner` | witness-photos | INSERT | `authenticated` | `foldername(name)[2] = auth.uid()::text` **and** `public.is_group_member(group of path, auth.uid())` |
| `witness_photos_update_owner` | witness-photos | UPDATE | `authenticated` | own `owner_id`; `WITH CHECK` keeps the own-folder rule |
| `witness_photos_delete_owner_or_admin` | witness-photos | DELETE | `authenticated` | own `owner_id` **or** `public.is_group_admin(group of path, auth.uid())` |

`private.try_uuid(text)` is a NULL-safe uuid cast (a malformed path segment
must never make a policy predicate raise). It lives in the non-exposed
`private` schema; `authenticated` keeps EXECUTE on it because PostgreSQL
evaluates a policy expression with the querying role's privileges.

### 18.3 Signed witness-photo URL

```sql
public.create_signed_witness_url (p_object_path text, p_expires_in integer default 300) → jsonb
```

`SECURITY DEFINER`, `set search_path = ''`, `REVOKE EXECUTE FROM PUBLIC, anon`,
`GRANT EXECUTE TO authenticated, service_role`.

Contract:

* the path must match `^witness-photos/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|jpeg|png|heic|webp)$`
  (the bucket-relative form `<group>/<user>/<file>` is also accepted) —
  otherwise `22023 invalid witness photo path`;
* the caller must be a **member of the group in the path** — otherwise
  `42501 not a member of the group that owns this photo`;
* the caller must **not** be blocked by the photo owner — otherwise
  `42501 blocked by the photo owner`;
* `p_expires_in` is **clamped to 60..3600** seconds;
* it returns
  `{ "signed_url", "expires_in", "bucket_id", "object_path", "group_id", "owner_id", "source", "edge_function" }`.

**This deployment has NO `storage.create_signed_url` helper** (verified against
`pg_proc`: the `storage` schema only ships `foldername`, `search`,
`filename`, `get_object_by_path`-style helpers — there is no signer). The RPC
therefore acts as the **authorisation gate** and returns
`"source": "edge_function"`, `"signed_url": null` and the validated
`object_path`; the **`signed-witness-url` Edge Function** signs it with the
service role (`POST /storage/v1/object/sign/witness-photos/<object_path>`,
`{ "expiresIn": n }`) and returns the absolute URL. If a deployment later
ships the SQL signer, the RPC uses it and returns `"source": "database"`.

Edge Function: `supabase/functions/signed-witness-url/index.ts`
(`verify_jwt: true`). It calls the RPC **with the caller's own JWT** (the
`apikey` header is the project anon key, the `Authorization` header is the
user's token) and only uses the service role for the signing step.
Verified end-to-end: upload → sign → download of a real PNG (HTTP 200).

### 18.4 Moderation tables

```sql
create table public.content_reports (
  id           uuid primary key default gen_random_uuid(),
  reporter_id  uuid not null references public.profiles (id) on delete cascade,
  target_type  text not null check (target_type in
                 ('post','chat_message','prayer_intention','check_in','profile','group')),
  target_id    uuid not null,
  group_id     uuid references public.groups (id) on delete cascade,
  reason       text not null check (reason in
                 ('inappropriate_photo','inappropriate_text','spam','harassment','hate','self_harm','other')),
  details      text check (char_length(details) <= 500),
  status       text not null default 'open' check (status in
                 ('open','reviewing','actioned','dismissed')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  resolved_at  timestamptz,
  resolved_by  uuid            -- deliberately NOT a foreign key
);
```

`resolved_by` is not a FK for the same reason `audit_log.actor_id` is not: the
moderation history must survive the deletion of the moderator.

```sql
create table public.moderation_actions (
  id          uuid primary key default gen_random_uuid(),
  actor_id    uuid not null references public.profiles (id) on delete cascade,
  action_type text not null check (action_type in
                ('hide_post','restore_post','delete_post','hide_chat_message','hide_intention',
                 'remove_member','warn_user','suspend_user','dismiss_report','action_report','auto_hide')),
  target_type text not null,
  target_id   uuid not null,
  group_id    uuid references public.groups (id) on delete set null,
  report_id   uuid references public.content_reports (id) on delete set null,
  reason      text check (char_length(reason) <= 200),
  metadata    jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at  timestamptz not null default now()
);
```

> `action_report` is an **addition** to the ten action types of the A6 spec: a
> report that a moderator *acteded* on has no matching type, so the resolution
> could not be recorded in the trail without it.

```sql
create view public.v_target_report_counts with (security_invoker = true) as
  select target_type, target_id, count(*)::int as report_count
    from public.content_reports
   where status in ('open','reviewing')
   group by 1,2;
```

`security_invoker = true` → the underlying `content_reports` RLS applies to the
reader. `GRANT SELECT TO authenticated, service_role`.

RLS on both tables (enabled **and** forced):

| Table | Cmd | Role | Predicate |
|---|---|---|---|
| `content_reports` | SELECT | `authenticated` | `reporter_id = auth.uid()` **or** `public.is_group_admin(group_id, auth.uid())` |
| `content_reports` | INSERT | `authenticated` | `reporter_id = auth.uid()` |
| `content_reports` | UPDATE | `authenticated` | `public.is_group_admin(group_id, auth.uid())` |
| `content_reports` | SELECT/INSERT/UPDATE | `service_role` | `true` |
| `moderation_actions` | SELECT | `authenticated` | `public.is_group_admin(group_id, auth.uid())` |
| `moderation_actions` | SELECT | `service_role` | `true` |

`moderation_actions` has **no INSERT policy** for `authenticated`: rows are
written only by A6's `security definer` RPCs, so a client can never forge a
moderation action.

Indexes: `idx_content_reports_target (target_type, target_id)`,
`idx_content_reports_status_created (status, created_at desc)`,
`idx_content_reports_reporter`, `idx_content_reports_group`,
`idx_moderation_actions_target (target_type, target_id)`,
`idx_moderation_actions_group_created (group_id, created_at desc)`,
`idx_moderation_actions_actor`, `idx_moderation_actions_report`.
`trg_content_reports_updated_at` keeps `content_reports.updated_at` current.

### 18.5 Auto-hide

`private.auto_hide_threshold()` returns **3**.

`trg_content_reports_auto_hide` — `AFTER INSERT ON public.content_reports FOR
EACH ROW EXECUTE FUNCTION private.auto_hide_after_report()` — counts the
unresolved reports of the target; when the count reaches the threshold it
hides the target and writes one `moderation_actions` row of type `auto_hide`
plus one `audit_log` row (`moderation.auto_hidden`). It never stacks two
`auto_hide` actions for the same target.

Hiding is table-specific and never uses dynamic SQL on a caller-supplied name:

| `target_type` | Hidden by |
|---|---|
| `post` | `public.feed_posts` → `is_hidden = true`, `hidden_reason = 'auto_hidden'` |
| `prayer_intention` | `public.prayer_intentions` → `is_hidden = true` |
| `chat_message` | **not hideable yet** — `chat_messages` has no `is_hidden` column (A5 request) |
| `check_in` | the `feed_posts` rows that carry the check-in (`check_in_id`) |
| `profile` / `group` | not hideable (no visibility flag) — the report is still recorded and shown to the moderator |

### 18.6 A6 public RPCs (verbatim)

All of them are `SECURITY DEFINER`, `set search_path = ''`,
`REVOKE EXECUTE FROM PUBLIC, anon`, `GRANT EXECUTE TO authenticated, service_role`.

```sql
public.block_user (p_blocked_id uuid) → jsonb
public.unblock_user (p_blocked_id uuid) → jsonb
public.list_blocked_users () → jsonb
public.report_content (p_target_type text, p_target_id uuid, p_reason text,
                       p_details text default null, p_group_id uuid default null) → jsonb
public.admin_delete_post (p_post_id uuid) → jsonb
public.hide_content (p_target_type text, p_target_id uuid, p_reason text) → jsonb
public.get_moderation_queue (p_group_id uuid) → jsonb
public.resolve_report (p_report_id uuid, p_status text, p_note text default null) → jsonb
public.get_moderation_actions (p_group_id uuid) → jsonb
public.create_signed_witness_url (p_object_path text, p_expires_in integer default 300) → jsonb
```

Behaviour highlights:

* `block_user` → `{ "blocked": true, "blocked_id", "created" }`; idempotent
  (`ON CONFLICT DO NOTHING`), rejects a self block (`22023`), rejects an
  unknown user (`P0002`); writes `audit_log` (`moderation.user_blocked`).
* `unblock_user` → `{ "blocked": false, "blocked_id", "removed" }`; idempotent.
* `list_blocked_users` → `{ "blocked_users": [ { user_id, display_name,
  avatar_path, blocked_at } ], "count" }` — **only the caller's own blocks**.
* `report_content` → `{ "report_id", "auto_hidden", "report_count", "status",
  "group_id", "duplicate" }`. It is **idempotent per (reporter, target)**: a
  retry returns the existing report (`"duplicate": true`) instead of creating
  a second one, so a single member can never trip the auto-hide threshold
  alone. It refuses a **private check-in** (`22023 this check-in is private
  and cannot be reported`) and refuses content in a group the caller is not a
  member of (`42501`).
* `admin_delete_post` → group-admin only; **delegates to A5's
  `public.soft_delete_feed_post(p_post_id uuid)`** (verified present) and adds
  a `moderation_actions` row (`delete_post`) + an `audit_log` row
  (`moderation.post_deleted`). If A5's function is ever removed, the RPC falls
  back to hiding the post itself (`hidden_reason = 'admin_removed'`).
* `hide_content` → group-admin only; hides a post / chat message / intention,
  writes `moderation_actions` (`hide_post` / `hide_chat_message` /
  `hide_intention`) + `audit_log` (`moderation.content_hidden`).
* `get_moderation_queue` → the open + reviewing reports of the group with a
  short preview of the reported content and the report counter.
* `resolve_report` → `status` ∈ `open` / `reviewing` / `actioned` /
  `dismissed`; writes `moderation_actions` (`dismiss_report` for a dismissal,
  `action_report` for an action) + `audit_log` (`moderation.report_resolved`).
* `get_moderation_actions` → the group's moderation trail, newest first.

### 18.7 A6 private helpers (never exposed through PostgREST)

`private.auto_hide_threshold()`, `private.has_column(regclass, text)`,
`private.resolve_report_group(text, uuid, uuid)`,
`private.report_target_exists(text, uuid)`,
`private.target_preview(text, uuid)`,
`private.auto_hide_content(text, uuid, text)`,
`private.auto_hide_after_report()` (trigger),
`private.try_uuid(text)`.

`revoke all … from public, anon, authenticated` on all of them **except**
`private.try_uuid`, which `authenticated` needs for the storage policies.

### 18.8 A6 privilege note (important for A10)

The project carries a **default privilege** that grants `EXECUTE` on every new
function of schema `public` to `anon` / `authenticated` / `service_role`:

```sql
select defaclacl from pg_default_acl d
  join pg_namespace n on n.oid = d.defaclnamespace
 where n.nspname = 'public' and d.defaclobjtype = 'f';
-- {postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,…}
```

`revoke execute … from public` is therefore **not enough** — the explicit
`anon` grant survives and PostgREST would expose the function as an
unauthenticated RPC. Every A6 function is revoked from `anon` explicitly
(migration `0505`). A2/A3/A4/A5 avoid the residual
`authenticated_security_definer_function_executable` finding by keeping the
implementation in `private` (`*_impl`) behind a thin public wrapper; A6's RPCs
follow the A6 spec and are `security definer` in `public` — the finding is
therefore **open by design** and is A10's decision (same as A1's §3.2).

---

## A2 additions — auth & account lifecycle

> **Owner: A2.** Migrations `0101`–`0105`. Prefix range `0100`–`0199`.
> Objects: `public.handle_new_user`, the `on_auth_user_created` trigger,
> `public.account_deletion_requests`, the profile/deletion RPCs below and the
> Edge Function `delete-account`.

### A2.1 The `private` schema pattern

| Schema | Exposed by PostgREST | Holds |
|---|---|---|
| `public` | yes | the **narrow public wrappers** A9 calls |
| `private` | **no** (not in the dashboard's exposed-schema list) | the `SECURITY DEFINER` implementations (`*_impl`) |

* `private` is created by migration `0101`; `REVOKE ALL ON SCHEMA private FROM PUBLIC`
  + `GRANT USAGE ON SCHEMA private TO authenticated, service_role`.
* Every `private` function is `SECURITY DEFINER`, `SET search_path = ''`,
  fully qualified, and `EXECUTE` is revoked from `PUBLIC` **and from `anon`**
  (the platform's default ACL grants `anon` a direct grant that survives a
  `REVOKE … FROM PUBLIC` — migration `0105`).
* The public wrappers are `SECURITY INVOKER` and simply delegate:
  `public.get_my_profile()` → `private.get_my_profile_impl()`. The effective
  privilege is the owner's, but **`authenticated_security_definer_function_executable`
  does not increase** (verified: the count is unchanged by A2).
* A2 adds **zero** findings to `get_advisors({type:"security"})`. The only new
  performance finding is `unused_index` on
  `idx_account_deletion_requests_user_id` — the same accepted category as
  A1's baseline: the table is empty, and the index backs the foreign key
  (removing it would trip `unindexed_foreign_keys`).

### A2.2 `public.handle_new_user()` + the `auth.users` trigger

```sql
public.handle_new_user() → trigger   -- SECURITY DEFINER, SET search_path = ''
trigger on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW
```

* `EXECUTE` is revoked from `PUBLIC, anon, authenticated` and granted to
  `supabase_auth_admin` (the role GoTrue inserts with) + `service_role`.
* Inserts into `public.profiles` with `ON CONFLICT (id) DO NOTHING`
  (idempotent). `public.profiles` has FORCEd RLS and no client INSERT policy,
  so this definer function is the **only** writer of a profile.
* Derivation (`private.derive_*`): `display_name` ← `full_name` → `name` →
  `user_name` → email local part → `Irmão`/`Irmã` (trimmed, truncated to 60);
  `locale` ← `pt-BR`/`en` else `pt-BR`; `timezone` ← a real IANA name (checked
  against `pg_catalog.pg_timezone_names`) else `America/Sao_Paulo`;
  `avatar_path` ← `avatar_url` **only when it is an `avatars/…` storage path**
  (the column is a path, not a URL — provider URLs are dropped);
  `ad_consent_analytics` / `ad_personalization` **always `false`**;
  `rule_of_life` = `'[]'`.
* Migration `0102` backfills the profiles of the auth users that predate the
  trigger (idempotent).

### A2.3 `public.account_deletion_requests`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK, `gen_random_uuid()` |
| `user_id` | `uuid` | FK → `public.profiles(id)` `ON DELETE CASCADE` |
| `confirmation_token` | `uuid` | `UNIQUE` — second tap of the deletion |
| `requested_at` | `timestamptz` | `now()` |
| `confirmed_at` | `timestamptz` | set by the second tap |
| `completed_at` | `timestamptz` | set by the Edge Function |
| `status` | `text` | `pending` \| `confirmed` \| `completed` \| `expired` \| `cancelled` |
| `expires_at` | `timestamptz` | `now() + interval '15 minutes'` |
| `updated_at` | `timestamptz` | `trg_account_deletion_requests_updated_at` |

* RLS enabled **and** forced. Policies: `…_select_own`, `…_insert_own`,
  `…_update_own` (own rows only; a client may only move a row to `confirmed`
  — with a `confirmed_at` — or cancel it). **No DELETE policy.**
* Partial unique index `idx_account_deletion_requests_live_user (user_id) where
  status in ('pending','confirmed')` — the database-level guarantee behind the
  idempotency of `request_account_deletion()`.
* Holds **no** confession, **no** spiritual-diary text and **no** private
  check-in content — only ids, timestamps and a status.

### A2.4 The RPC surface (A9 — verbatim signatures)

```
public.get_my_profile()                                            → jsonb
public.update_my_profile(p_display_name text DEFAULT NULL,
                          p_avatar_path text DEFAULT NULL,
                          p_parish text DEFAULT NULL,
                          p_city text DEFAULT NULL,
                          p_timezone text DEFAULT NULL,
                          p_locale text DEFAULT NULL,
                          p_ad_consent_analytics boolean DEFAULT NULL,
                          p_ad_personalization boolean DEFAULT NULL,
                          p_rule_of_life jsonb DEFAULT NULL)         → jsonb
public.update_ad_consent(p_analytics boolean, p_personalization boolean) → jsonb
public.request_account_deletion()                                  → jsonb
public.delete_my_account_request()                                 → jsonb   (alias of request_account_deletion)
public.confirm_account_deletion(p_token uuid)                      → jsonb
```

* `update_my_profile` applies **only the non-NULL arguments** and returns the
  updated row. `update_ad_consent` requires **both** flags and writes an
  `account.ad_consent_updated` row to `public.audit_log`; `update_my_profile`
  does the same when it changes a consent flag.
* Validations: `display_name` 1–60 chars after trim · `locale in ('pt-BR','en')`
  · `timezone` must exist in `pg_catalog.pg_timezone_names` · `avatar_path`
  must match `^avatars/[A-Za-z0-9][A-Za-z0-9._/-]*$` and contain no `..` ·
  `rule_of_life` must be a jsonb array of ≤ 10 objects with **exactly** the
  keys `kind` (a `public.practice_kind` value) and `label` (1–60 chars).

### A2.5 Error contract

`RAISE EXCEPTION '<key>' USING ERRCODE = '22023'` (invalid_parameter_value),
with the detail in `HINT`. A9 maps the key to the pt-BR / en string.

| key | 22023 | meaning |
|---|---|---|
| `invalid_display_name` | ✓ | not 1–60 chars after trim |
| `invalid_avatar_path` | ✓ | not an `avatars/…` path |
| `invalid_locale` | ✓ | not `pt-BR`/`en` |
| `invalid_timezone` | ✓ | not a known IANA zone |
| `invalid_parish` / `invalid_city` | ✓ | longer than 120 chars |
| `invalid_rule_of_life` | ✓ | not an array / bad entry shape / extra key |
| `invalid_rule_of_life_kind` | ✓ | `kind` is not a `public.practice_kind` |
| `invalid_rule_of_life_label` | ✓ | `label` not a 1–60 char string |
| `rule_of_life_too_long` | ✓ | more than 10 commitments |
| `invalid_ad_consent` | ✓ | a consent flag was NULL |
| `invalid_deletion_token` | ✓ | unknown / already used token |
| `deletion_token_expired` | ✓ | the 15-minute window closed |
| `not_authenticated` | 42501 | no JWT on the call |
| `profile_not_found` | P0002 | the caller has no profile row |

### A2.6 New trigger on `public.profiles`

`trg_profiles_a2_validate` — `BEFORE UPDATE … FOR EACH ROW EXECUTE FUNCTION
private.validate_profile_update()`. It re-runs the A2 validations, so a direct
PostgREST `PATCH /profiles` cannot bypass the rules that
`public.update_my_profile()` enforces. **A2 does not ALTER the table** — it
only adds the trigger.

### A2.7 Edge Function `delete-account`

`supabase/functions/delete-account/index.ts` (`deno.json` with the import map
for `npm:@supabase/supabase-js@2`), deployed with `verify_jwt: true`.

1. verifies the caller's JWT itself (`auth.getUser(token)` with the service
   client) and takes the user id from the **verified** claims;
2. requires a row of `public.account_deletion_requests` with
   `user_id = <caller>`, `status in ('confirmed','completed')` and
   `expires_at > now()`;
3. deletes the caller's **own** storage objects only (buckets `avatars`,
   `group-covers`, `witness-photos` — an object belongs to the user when its
   path contains the user's uuid as a segment);
4. deletes the caller's `group_members` rows; a group the caller created is
   **deleted** when no member remains, otherwise the ownership is
   **transferred** to the longest-standing admin (or, when there is no admin
   left, to the longest-standing member, who is promoted to admin);
5. marks the request `completed` (before the delete — the row is cascade
   deleted with the profile);
6. deletes the auth user (`auth.admin.deleteUser`), which cascades to
   `public.profiles` and to every row that references it;
7. inserts the `account.deleted` row into `public.audit_log`
   (`actor_id` has no FK on purpose — it survives the deletion).

`{ ok: true, deleted: true }` on success; `{ ok: false, error: '<key>' }` with
400/401/405/409/500 otherwise.

---

## 19. A8 additions — Guardian Angel & push notifications

> **Owner: A8** (migration prefix range `0700`–`0799`). Applied migrations:
> `create_guardian_angel_tables` (0701), `create_guardian_angel_rpcs` (0702),
> `schedule_guardian_angel_cron` (0703),
> `create_notification_outbox_triggers` (0704),
> `fix_eligible_members_alias` (0705),
> `index_guardian_angel_foreign_keys` (0706).
> Tests: `supabase/tests/a8/guardian_angel.sql` — **89 assertions, PASS**;
> `supabase/tests/a8/push.sql` — **55 assertions, PASS**.
> Full documentation: [`docs/backend/PUSH.md`](../docs/backend/PUSH.md).
>
> **SACRED PRIVACY.** Nothing in this section can hold Confession records,
> Spiritual Diary text or the content of a private check-in. The Guardian
> Angel reveals **only a display name** to the guardian, and the nudge is
> **anonymous**.

### 19.1 Tables

#### `public.guardian_angel_opt_ins` — the per-group opt-in

```sql
create table public.guardian_angel_opt_ins (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  group_id   uuid not null references public.groups (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint guardian_angel_opt_ins_user_group_key unique (user_id, group_id)
);
```

* No `updated_at` — an opt-in row is immutable (it is created / deleted).
* `profiles.guardian_angel_opt_in` is the **master switch**; it is kept in
  sync by `public.opt_in_to_guardian_angel()` and is **true whenever the
  user opted into ANY group**.

#### `public.guardian_angel_pairings` — the (secret) draw

```sql
create table public.guardian_angel_pairings (
  id               uuid primary key default gen_random_uuid(),
  group_id         uuid not null references public.groups (id) on delete cascade,
  cycle_key        text not null check (char_length (cycle_key) between 1 and 120),
  guardian_id      uuid not null references public.profiles (id) on delete cascade,
  protected_id     uuid not null references public.profiles (id) on delete cascade,
  cycle_starts_on  date not null,
  cycle_ends_on    date not null,
  is_active        boolean not null default true,
  revealed_at      timestamptz,
  created_at       timestamptz not null default now(),
  constraint guardian_angel_pairings_no_self check (guardian_id <> protected_id),
  constraint guardian_angel_pairings_cycle_window check (cycle_ends_on >= cycle_starts_on),
  constraint guardian_angel_pairings_cycle_guardian_key unique (cycle_key, guardian_id),
  constraint guardian_angel_pairings_cycle_protected_key unique (cycle_key, protected_id)
);
```

* Indexes: `(group_id, cycle_key)`, `(protected_id)`, `(guardian_id)`.
* **There is NO client SELECT policy and the table privilege is REVOKED for
  `anon`/`authenticated`.** A client can never read `guardian_id`
  directly; every read goes through the redacting RPCs. This is the
  mechanism that keeps the Guardian identity secret.
* `revealed_at` is set at the end of the cycle (by
  `public.reveal_guardian_identities()` or the daily cron job).

#### `public.guardian_nudges` — the anonymous "I prayed for my protected soul"

```sql
create table public.guardian_nudges (
  id           uuid primary key default gen_random_uuid(),
  group_id     uuid not null references public.groups (id) on delete cascade,
  pairing_id   uuid not null references public.guardian_angel_pairings (id) on delete cascade,
  sender_id    uuid not null references public.profiles (id) on delete cascade,
  protected_id uuid not null references public.profiles (id) on delete cascade,
  cycle_key    text not null check (char_length (cycle_key) between 1 and 120),
  local_date   date not null,
  created_at   timestamptz not null default now(),
  constraint guardian_nudges_sender_local_date_key unique (sender_id, local_date)
);
```

* `UNIQUE (sender_id, local_date)` = **at most one nudge per Guardian per
  local day**. The client supplies `local_date` (same pattern as
  `check_ins.local_date`); the server validates it against ±1 day of today.
* Indexes: `(protected_id, created_at DESC)`, `(pairing_id)`, `(group_id)`.
* The client grant **omits `sender_id`** and the RLS policy only exposes the
  sender's own rows — the recipient reads **zero** rows and cannot even
  reference the column.

#### `public.device_tokens`

```sql
create table public.device_tokens (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  platform     text not null default 'ios' check (platform in ('ios', 'android')),
  apns_token   text not null check (char_length (apns_token) between 8 and 512),
  environment  text not null default 'production' check (environment in ('sandbox', 'production')),
  app_version  text check (char_length (app_version) <= 40),
  is_active    boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  constraint device_tokens_platform_token_key unique (platform, apns_token)
);
```

* Index: `(user_id, is_active)`.
* `UNIQUE (platform, apns_token)`: the same token is never stored twice.
  Re-registering it **moves** the row to the new user.

#### `public.notification_outbox` — the transactional outbox

```sql
create table public.notification_outbox (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles (id) on delete cascade,
  channel           text not null default 'push' check (channel in ('push')),
  notification_type text not null check (notification_type in (
                    'prayed_for_you', 'amen', 'guardian_nudge',
                    'pinned_notice', 'streak_milestone')),
  title             text not null check (char_length (title) between 1 and 120),
  body              text not null check (char_length (body) between 1 and 500),
  payload           jsonb not null default '{}'::jsonb check (jsonb_typeof (payload) = 'object'),
  group_id          uuid references public.groups (id) on delete cascade,
  dedupe_key        text not null check (char_length (dedupe_key) between 1 and 200),
  status            text not null default 'pending' check (status in (
                    'pending', 'processing', 'sent', 'failed', 'cancelled')),
  attempts          integer not null default 0 check (attempts >= 0),
  scheduled_at      timestamptz not null default now(),
  sent_at           timestamptz,
  last_error        text check (char_length (last_error) <= 1000),
  created_at        timestamptz not null default now(),
  constraint notification_outbox_dedupe_key_key unique (dedupe_key)
);
```

* Indexes: `(status, scheduled_at)`, `(user_id, created_at DESC)`, `(group_id)`.
* **No client INSERT/UPDATE/DELETE** — only a SELECT policy for the user's
  own rows. The client grant omits `dedupe_key` and `last_error`.
* **LITURGICAL REMINDERS ARE LOCAL-ONLY.** The `notification_type` CHECK
  does not accept a liturgical value, so no liturgical row can ever be
  queued. Liturgical prompts are scheduled on the device.

#### `private.app_settings` — operational settings

```sql
create table private.app_settings (
  key        text primary key check (char_length (key) between 1 and 100),
  value      text check (char_length (value) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

* Keys: `push_dispatch_url`, `push_dispatch_secret`.
* No policy and no privilege for `anon`/`authenticated`.

### 19.2 The cycle key

| Group type | Cycle | `cycle_key` |
|---|---|---|
| `fraternity` | the current **ISO week**, Monday..Sunday | `fraternity:<group_id>:<YYYY>-W<ww>` |
| `challenge` | the **whole challenge window** (`starts_on`..`ends_on`) | `challenge:<group_id>:<starts_on>` |

> The fraternity key is **group scoped on purpose**: a member may belong to
> several fraternities in the same week, and the table has
> `UNIQUE (cycle_key, guardian_id)` / `UNIQUE (cycle_key, protected_id)` — a
> global `YYYY-Www` key would collide across groups.

### 19.3 The derangement

The draw is a **deterministic rotation by 1** over the eligible members
sorted by `user_id`:

```
members = [m1, m2, ..., mn]      -- sorted by user_id
m1 guards m2, m2 guards m3, ..., mn guards m1
```

* A rotation by 1 over a sorted list of `n >= 2` elements is a derangement:
  nobody keeps its own position, so `guardian_id <> protected_id` always
  holds, and every member appears exactly once as guardian and once as
  protected.
* **`random()` is never used** — a retry reproduces exactly the same draw.
* The **eligible set** = master opt-in ON **and** a per-group
  `guardian_angel_opt_ins` row **and** an active `group_members` row
  **and** not blocked (either direction) with any other candidate.
* Fewer than 2 eligible members → `{ "paired": 0, "reason":
  "insufficient_opt_ins" }` and **no row is created**. A member who did not
  opt in is never paired and never learns they were excluded.
* The rotation offset is recorded in the `audit_log` metadata
  (`rotation_offset`) and returned by the RPC.

### 19.4 RPC signatures (verbatim — A9 uses these)

```sql
-- client facing (SECURITY INVOKER → private implementation)
public.opt_in_to_guardian_angel (p_group_id uuid, p_opt_in boolean) returns jsonb
public.my_guardian_assignment (p_group_id uuid) returns jsonb
public.guardian_angel_state (p_group_id uuid) returns jsonb
public.send_guardian_nudge (p_group_id uuid, p_local_date date default null) returns jsonb
public.register_device_token (p_apns_token text, p_platform text default 'ios',
                               p_environment text default 'production',
                               p_app_version text default null) returns jsonb

-- server only (SECURITY DEFINER, service_role only)
public.run_guardian_angel_pairing (p_group_id uuid, p_cycle_key text default null,
                                    p_cycle_starts_on date default null) returns jsonb
public.sweep_guardian_angel_pairings (p_scope text default 'all') returns jsonb
public.reveal_guardian_identities (p_group_id uuid) returns jsonb
public.sweep_reveal_guardian_identities () returns jsonb
public.claim_notification_outbox (p_limit integer default 50) returns setof jsonb
public.complete_notification_outbox (p_outbox_id uuid, p_status text,
                                      p_error text default null,
                                      p_retry_at timestamptz default null) returns jsonb
public.deactivate_device_token (p_token_id uuid) returns jsonb
public.dispatch_push_notifications () returns jsonb

-- A5's seam — the body was REPLACED by A8 in migration 0704
public.emit_prayer_notification (p_intention_id uuid, p_prayer_id uuid) returns jsonb
```

Return shapes:

| RPC | Returns |
|---|---|
| `opt_in_to_guardian_angel` | `{group_id, opted_in, group_opt_in, master_opt_in}` |
| `my_guardian_assignment` | `{is_guardian, is_protected, protected_display_name, protected_intentions, guardian_display_name, revealed, cycle_key, cycle_starts_on, cycle_ends_on, can_nudge, nudges_today}` |
| `guardian_angel_state` | `{group_id, opted_in, is_guardian, is_protected, cycle_ends_on, can_nudge, nudges_today}` |
| `send_guardian_nudge` | `{sent, nudges_today, remaining, nudge_id, local_date}` |
| `run_guardian_angel_pairing` | `{group_id, cycle_key, cycle_starts_on, cycle_ends_on, paired, inserted, updated, skipped, member_count, rotation_offset, reason}` |
| `sweep_guardian_angel_pairings` | `{scope, groups, paired}` |
| `reveal_guardian_identities` | `{group_id, revealed, revealed_at}` |
| `claim_notification_outbox` | one jsonb per claimed row: `{id, user_id, notification_type, title, body, payload, group_id, attempts, scheduled_at}` |
| `complete_notification_outbox` | `{id, status, attempts, scheduled_at}` |
| `dispatch_push_notifications` | `{dispatched, request_id}` or `{dispatched:false, reason:"not_configured"}` |

Error keys (the message IS the key):

| SQLSTATE | message |
|---|---|
| `42501` | `authentication required` · `not_a_group_member` · `not_a_guardian` |
| `22023` | `invalid_local_date` · `invalid_platform` · `invalid_environment` · `invalid_push_token` · `invalid_scope` · `invalid_status` · `challenge has no date window` |
| `P0001` | `nudge_already_sent_today` · `cycle_ended` |
| `P0002` | `group not found` · `outbox row not found` · `device token not found` |

### 19.5 The cron jobs

| Job name | Schedule | Command |
|---|---|---|
| `a8_pairing_weekly_fraternities` | `0 5 * * 1` | `select public.sweep_guardian_angel_pairings('fraternity');` |
| `a8_pairing_daily_challenges` | `0 6 * * *` | `select public.sweep_guardian_angel_pairings('challenge');` |
| `a8_reveal_ended_cycles` | `15 6 * * *` | `select public.sweep_reveal_guardian_identities();` |
| `a8_push_dispatch` | `*/5 * * * *` | `select public.dispatch_push_notifications();` |

Migration 0703 unschedules each name before scheduling it, so it is
idempotent: **exactly one row per job name** in `cron.job`.

### 19.6 The outbox notification types and dedupe keys

| `notification_type` | Dedupe key | Emitted by |
|---|---|---|
| `prayed_for_you` | `prayed:<intention_prayer_id>` | `trg_intention_prayers_notify` → `public.emit_prayer_notification()` |
| `amen` | `amen:<amen_reaction_id>` | `trg_amen_reactions_notify` |
| `guardian_nudge` | `nudge:<nudge_id>` | `public.send_guardian_nudge()` |
| `pinned_notice` | `pinned:<notice_id>:<member_id>` | `trg_pinned_notices_notify` |
| `streak_milestone` | — | reserved (A4/A9 follow-up) |

> **A5's seam.** `public.emit_prayer_notification()` was a safe no-op while
> the outbox did not exist. Migration **0704 replaced its body** (same
> signature, same `service_role`-only privilege, same
> `{"emitted":bool,"reason":text}` return shape) and added the trigger
> `trg_intention_prayers_notify` on `public.intention_prayers`. A5's
> `toggle_prayed_for()` calls the seam **and** the trigger fires — both
> resolve to the same dedupe key, so **exactly one** row is created.

### 19.7 The anonymity guarantees

* The **protected** member never receives the guardian's name or id before
  `revealed_at` is set. `public.my_guardian_assignment()` returns
  `guardian_display_name: null` and `revealed: false` until then, and the
  `guardian_id` column is not reachable by any client at all.
* The **guardian** receives the protected member's **display name** and up to
  three of their **group prayer intentions** — never a private check-in, a
  Confession or a Spiritual Diary text.
* The **nudge is anonymous**: the pushed title/body is
  *"Alguém rezou por você."* / *"Alguém rezou por você hoje."*, the payload
  carries only `{group_id, cycle_key}`, and `sender_id` is not granted to
  the client.
* A **blocked pair never produces a notification** (checked with
  `public.is_blocked()`, which is symmetric) — for the prayed-for, amen and
  pinned-notice triggers and for the nudge.

### 19.8 A8's own implementation notes

* Every client-facing RPC is a **SECURITY INVOKER** wrapper in `public`
  that forwards to a `private` implementation (SECURITY DEFINER, `set
  search_path = ''`, fully qualified). A8 therefore contributes **0** to the
  `authenticated_security_definer_function_executable` finding.
* Every server-only RPC is a `public` SECURITY DEFINER function with
  `EXECUTE` revoked from `PUBLIC`/`anon`/`authenticated` and granted to
  `service_role` only.
* The Edge Function `push-dispatch` (`supabase/functions/push-dispatch/`)
  is deployed with `verify_jwt: false` and authenticates itself with the
  service-role key **or** the `x-push-secret` shared secret. See
  [`docs/backend/PUSH.md`](../docs/backend/PUSH.md) for the APNs token
  generation, the HTTP/2 caveat and the production alternatives.

---

## 21. A10 audit — final state

> **Owner:** A10 (security & QA audit) · migration prefix range `0900`–`0999`.
> **Date:** 2026-10-22 · **Project:** `khovpljkitslmjmonuzu` (PostgreSQL 17.11).
> A10 is the last agent of the backend wave: its job is to make the
> backend *provably* secure, correct and documented.

### 21.1 The final advisor counts

| Type | Lint | Level | Before A10 | After A10 |
|---|---|---|---|---|
| security | `authenticated_security_definer_function_executable` | WARN | **33** | **0** |
| security | `anon_security_definer_function_executable` | WARN | 0 | **0** (never regressed) |
| security | `function_search_path_mutable` | WARN | 0 | **0** (never regressed) |
| performance | `unindexed_foreign_keys` | INFO | 2 | **0** (A8 fixed them in `0706`; A10 verified) |
| performance | `unused_index` | INFO | 27 | **18 – 27, accepted baseline**, see §21.6 |

**The security advisor now reports ZERO findings of any kind.**

### 21.2 The security fixes A10 applied

| Migration | What it does |
|---|---|
| `0900_harden_rls_helpers` | The 5 RLS helpers become **self-scoped**; their bodies move to `private.is_*_impl` (`SECURITY DEFINER`); every policy that called the two-argument form is re-issued with the one-argument form. |
| `0901_harden_domain_rpcs` | The 28 flagged domain RPCs move to `private.<name>_impl` (`SECURITY DEFINER`); their public counterparts become `SECURITY INVOKER` wrappers with the **exact** original signature, defaults, return type and error behaviour. |
| `0902_residual_rpc_hardening` | `public.current_user_id()` is revoked from `anon`; `public.probe_wrapper()` is restricted to `service_role`. `anon` can now execute **exactly four** public functions. |
| `0903_fix_a3_preview_usage` | **Bug fix.** `grant usage on schema a3_preview to authenticated, service_role` (+ the matching `grant execute`): the `preview_group_by_code` / `list_featured_challenges` wrappers are `SECURITY INVOKER`, so every SIGNED-IN user got `42501 permission denied for schema a3_preview`. Pre-existing since A3's migration 0208. |
| `0904_fix_join_group_by_code` | **Bug fix.** `private.join_group_impl` captured `FOUND` into `v_has_invite`: the `INSERT INTO group_members` in between reset `FOUND` to `true`, so the invite-usage branch always ran and a code without a `group_invites` row failed with the misleading *"this invite code has reached its usage limit"*. Reachable through the `groups_update_admin` policy. |

### 21.3 The helper signature change (before → after)

| Before | After | The two-user logic now lives in |
|---|---|---|
| `public.is_group_member(p_group_id uuid, p_user_id uuid DEFAULT auth.uid())` | `public.is_group_member(p_group_id uuid)` | `private.is_group_member_impl(p_group_id uuid, p_user_id uuid)` |
| `public.is_group_admin(p_group_id uuid, p_user_id uuid DEFAULT auth.uid())` | `public.is_group_admin(p_group_id uuid)` | `private.is_group_admin_impl(p_group_id uuid, p_user_id uuid)` |
| `public.is_blocked(p_user_id uuid, p_other_id uuid)` | `public.is_blocked(p_other_id uuid)` | `private.is_blocked_impl(p_user_id uuid, p_other_id uuid)` |
| `public.is_group_member_of_any(p_user_id uuid DEFAULT auth.uid())` | `public.is_group_member_of_any()` | `private.is_group_member_of_any_impl(p_user_id uuid)` |
| `public.is_any_group_admin(p_user_id uuid DEFAULT auth.uid())` | `public.is_any_group_admin()` | `private.is_any_group_admin_impl(p_user_id uuid)` |

**Why this is safe.** Every one of the ~40 policies that call a helper
already passed the **caller's own** id as the second argument (A10 measured
this against the live database before changing anything), so the two-user
form was never needed by a policy. The rewrite is a pure textual collapse
of that second argument; the semantics are unchanged and the block relation
stays **symmetric**.

**Why it is necessary.** `authenticated` must keep `EXECUTE` on the helpers
(PostgreSQL evaluates a policy expression with the *querying role's*
privileges), so a `SECURITY DEFINER` helper in the exposed `public` schema is
reachable as an RPC: a signed-in user could learn whether an **arbitrary**
user belonged to an **arbitrary** group, and `is_blocked` leaked the whole
block graph. The signature change removes the capability, not just the
endpoint.

**The public wrappers are `SECURITY INVOKER`** and supply `auth.uid()`
themselves. The privileged bodies live in the **non-exposed** `private`
schema, where PostgREST never routes and the Supabase linter never looks.

### 21.4 The 28 RPCs converted to `private.<name>_impl` + INVOKER wrapper

| Owner | Functions |
|---|---|
| **A4** | `get_consistency_heatmap`, `get_group_progress`, `get_rule_of_life_ring`, `get_streak_summary`, `set_practice_points`, `submit_check_in`, `use_streak_mercy` |
| **A5** | `clear_pinned_notice`, `create_chat_message`, `create_prayer_intention`, `get_chat_messages`, `get_feed_posts`, `get_prayer_intentions`, `set_pinned_notice`, `soft_delete_chat_message`, `soft_delete_feed_post`, `toggle_amen`, `toggle_prayed_for` |
| **A6** | `admin_delete_post`, `block_user`, `create_signed_witness_url`, `get_moderation_actions`, `get_moderation_queue`, `hide_content`, `list_blocked_users`, `report_content`, `resolve_report`, `unblock_user` |

The body was moved **verbatim** by reading it back with
`pg_get_functiondef()`, so no body was ever re-typed. The public wrapper
keeps the original volatility, the original argument names, the original
defaults, the original return type and the original error behaviour.

**Cross-references are safe.** A `SECURITY DEFINER` implementation that
calls `public.other(...)` now calls the thin `INVOKER` wrapper, which
forwards to `private.other_impl(...)`; the effective privilege is still the
owner's (`postgres`), so the behaviour is unchanged. The one dynamic-SQL
reference (`public.admin_delete_post` → `public.soft_delete_feed_post`)
resolves the same way.

### 21.5 The A10 test suites

| File | Assertions | Verdict |
|---|---|---|
| `supabase/tests/a10/rls_matrix.sql` | **647** | PASS |
| `supabase/tests/a10/rpc_matrix.sql` | **96** | PASS |
| `supabase/tests/a10/privacy.sql` | **65** | PASS |

* **rls_matrix** — for EVERY one of the 39 public tables and for EACH of
  the five personas (`anon`, outsider, member, admin, blocked) the number of
  rows reachable with SELECT / UPDATE / DELETE is asserted against a
  hand-written expectation. The probe helpers raise a deliberate exception
  so the probe runs in a sub-transaction and the fixture survives for the
  next persona.
* **rpc_matrix** — the whole privilege matrix, the exact SQLSTATE + message
  of the non-member error contract of 23 RPCs, and the JSON shape of 50+
  happy paths.
* **privacy** — the sacred-privacy invariants end to end (see CONVENTIONS
  §8): the catalog scan, the enforced CHECK constraints, the full
  create-group → join → group check-in → private check-in → confession
  flow, the fan-out counts, the streak / Rule of Life maths, the outbox and
  audit-log silence, the Guardian Angel anonymity, and the moderation path.

### 21.6 The accepted `unused_index` baseline (18 – 27 findings — INFO)

The tables are **empty**, so the planner cannot prove an index unused. The
exact count therefore MOVES with the usage statistics: it was **27** when
A10 started, **26** after the first audit runs and **18** after the full
A10 suite had exercised the real query paths. **The invariant is not the
number but the rule: no index may be dropped.** Every one of them backs a
foreign key, a unique constraint or a documented lookup path, and dropping
one would immediately re-open `unindexed_foreign_keys`.

| Table | Index | Why it stays |
|---|---|---|
| `group_featured` | `idx_group_featured_display_order` | the discovery-list ordering |
| `audit_log` | `idx_audit_log_created_at` | the admin trail pagination |
| `content_reports` | `idx_content_reports_status_created` | the moderation queue |
| `moderation_actions` | `idx_moderation_actions_report` | the trail of one report |
| `ssv_receipts` | `idx_ssv_receipts_received_at`, `idx_ssv_receipts_transaction_id` | the SSV replay lookup |
| `prayer_intentions` | `idx_prayer_intentions_group_created_at` | the Prayer Wall pagination |
| `chat_messages` | `idx_chat_messages_group_created_at`, `idx_chat_messages_user_id`, `chat_messages_hidden_idx` | the chat pagination / the hidden filter |
| `amen_reactions` | `idx_amen_reactions_user_id` | the "my reactions" lookup |
| `intention_prayers` | `idx_intention_prayers_intention_id` | the "who prayed" counter |
| `feed_posts` | `idx_feed_posts_user_created_at`, `idx_feed_posts_visible_group_created_at` | the feed pagination |
| `guardian_nudges` | `idx_guardian_nudges_protected_created`, `idx_guardian_nudges_pairing_id` | the nudge history |
| `device_tokens` | `idx_device_tokens_user_active` | the push fan-out |
| `liturgical_days` | `idx_liturgical_days_season` | the seasonal calendar |
| `saints` | `idx_saints_lower_name` | the saints search |
| `saint_icons` | `idx_saint_icons_saint_id` | the icon → saint link |
| `user_saint_unlocks` | `idx_user_saint_unlocks_saint_icon_id` | the unlocked-themes lookup |
| `notification_outbox` | `idx_notification_outbox_status_scheduled` | the dispatcher's claim query |
| `sponsored_challenges` | `idx_sponsored_challenges_sponsor_id`, `idx_sponsored_challenges_featured_group_id`, `idx_sponsored_challenges_active` | the sponsor / featured / active filters |
| `reward_grants` | `idx_reward_grants_user_id`, `idx_reward_grants_user_status` | the reward ledger |
| `account_deletion_requests` | `idx_account_deletion_requests_user_id` | backs the FK |
| `check_ins` | `idx_check_ins_user_local_date`, `idx_check_ins_user_created_at`, `idx_check_ins_group_shared_user_local_date` | the streak / heatmap / feed paths |
| `check_in_destinations` | `idx_check_in_destinations_group_id` | backs the FK |
| `group_invites` | `idx_group_invites_code`, `idx_group_invites_group_id`, `idx_group_invites_created_by` | the code lookup |
| `group_members` | `idx_group_members_group_role`, `idx_group_members_user_id` | the roster / "my groups" |
| `groups` | `idx_groups_created_by` | backs the FK |
| `user_blocks` | `idx_user_blocks_blocker_id`, `idx_user_blocks_blocked_id` | the block lookups |
| `practice_points` | `idx_practice_points_group_id` | backs the FK |
| `pinned_notices` | `idx_pinned_notices_group_id`, `idx_pinned_notices_author_id` | backs the FKs |
| `slot_unlocks` | `idx_slot_unlocks_user_kind` | the active-slot lookup |
| `streak_events` | `idx_streak_events_user_id`, `idx_streak_events_user_local_date` | the streak audit trail |
| `streak_mercy_grants` | `idx_streak_mercy_grants_user_id` | backs the FK |
| `guardian_angel_opt_ins` | `idx_guardian_angel_opt_ins_group_id` | backs the FK |
| `guardian_angel_pairings` | `idx_guardian_angel_pairings_group_cycle`, `idx_guardian_angel_pairings_guardian_id`, `idx_guardian_angel_pairings_protected_id` | the draw / the lookups |
| `moderation_actions` | `idx_moderation_actions_actor`, `idx_moderation_actions_group_created`, `idx_moderation_actions_target` | the trail |
| `content_reports` | `idx_content_reports_target`, `idx_content_reports_reporter`, `idx_content_reports_group` | the queue |
| `feed_posts` | `idx_feed_posts_check_in_id` | backs the FK |
| `ad_view_tokens` | `idx_ad_view_tokens_user_id`, `idx_ad_view_tokens_open` | the pending-token lookup |
| `reward_grants` | `idx_reward_grants_user_reward_type` | the reward ledger |
| `sponsored_challenges` | `idx_sponsored_challenges_group_id` | backs the FK |
| `saint_icons` | `idx_saint_icons_active` | the active-themes filter |
| `saints` | `idx_saints_calendar_date` | the day lookup |
| `daily_readings` | `daily_readings_calendar_date_key` | the unique date |
| `feed_post_comments` | `idx_feed_post_comments_group_created_at`, `idx_feed_post_comments_hidden`, `idx_feed_post_comments_user_id` | the group-scoped comment list · the moderation query of a group admin · the `feed_post_comments_user_id_fkey` FK (added by migration 1004) — see §22.2 |

> `idx_user_blocks_blocker_id` is technically **redundant** — the
> `user_blocks_blocker_id_blocked_id_key` unique index already has
> `blocker_id` as its leading column. A1 kept it because the spec asked for
> an index on `blocker_id`; it costs nothing on a table this small. It is
> the only index in the project that is not strictly necessary.

### 21.7 The final ownership map

| Object | Table owner | Policies / RPCs | Notes |
|---|---|---|---|
| `public.profiles` | A1 (columns) | A1 (policies), A2 (trigger + profile RPCs), A9 (client) | The `handle_new_user` trigger is the only INSERT path. |
| `public.groups`, `public.group_members`, `public.user_blocks` | A1 | A1 (policies), A3 (groups), A6 (blocks) | A10 rewrote the helper calls in every policy. |
| `public.practice_points` | A1 (table) | A1 (baseline), A4 (data + RPC) | |
| `public.audit_log` | A1 | A2 / A3 / A6 write through their own RPCs | Append-only, no FK on `actor_id`. |
| `public.group_invites`, `public.slot_unlocks`, `public.group_featured` | A3 | A3 | A7 FKs `sponsored_challenges` to `group_featured`. |
| `public.check_ins`, `public.check_in_destinations`, `public.streaks`, `public.streak_events`, `public.streak_mercy_uses`, `public.streak_mercy_grants` | A4 | A4 | `streak_mercy_grants` is written by A7's `grant_reward`. |
| `public.feed_posts`, `public.amen_reactions`, `public.prayer_intentions`, `public.intention_prayers`, `public.chat_messages`, `public.pinned_notices` | A5 | A5 | `feed_posts` is written by A4's fan-out trigger. |
| `public.content_reports`, `public.moderation_actions`, `public.v_target_report_counts` | A6 | A6 | |
| `public.liturgical_days`, `public.daily_readings`, `public.saints`, `public.saint_icons`, `public.user_saint_unlocks`, `public.sponsors`, `public.sponsored_challenges`, `public.reward_grants`, `public.ad_view_tokens`, `public.ssv_receipts` | A7 | A7 | |
| `public.guardian_angel_opt_ins`, `public.guardian_angel_pairings`, `public.guardian_nudges`, `public.device_tokens`, `public.notification_outbox` | A8 | A8 | |
| `public.account_deletion_requests` | A2 | A2 | |
| `private` (the non-exposed implementation schema) | A2 (created) | every agent | `USAGE` for `authenticated` + `service_role`; **never** for `anon`. |
| `a3_preview` (the two public preview implementations) | A3 | A3 | `USAGE` for `anon`, `authenticated`, `service_role` since migration 0903. |
| `public.is_*` helpers | A1 (created) | **A10** (moved to `private`, signatures simplified) | Self-scoped since 0900. |
| `public.<name>` / `private.<name>_impl` (the 28 domain RPCs) | A4 / A5 / A6 | **A10** (the private/INVOKER split) | The signatures are unchanged. |
| `public.pgtap_*` helpers | A1 | — | Test-only, not reachable by a client. |
| `cron.job` (4 A8 jobs) | A8 | — | See §21.8. |
| `storage.buckets` (3) | A6 | A6 | `witness-photos` is the only private one. |
| `auth.instances` (1 row) | — | — | **Do not delete.** GoTrue requires it. |

### 21.8 The cron jobs (final)

| Job | Schedule | Command |
|---|---|---|
| `a8_pairing_weekly_fraternities` | `0 5 * * 1` | `select public.sweep_guardian_angel_pairings('fraternity')` |
| `a8_pairing_daily_challenges` | `0 6 * * *` | `select public.sweep_guardian_angel_pairings('challenge')` |
| `a8_reveal_ended_cycles` | `15 6 * * *` | `select public.sweep_reveal_guardian_identities()` |
| `a8_push_dispatch` | `*/5 * * * *` | `select public.dispatch_push_notifications()` |

### 21.9 What is still missing (operator actions)

| Item | State |
|---|---|
| `ADMOBSIGNING_KEY` (Edge Function secret) | ❌ **NOT SET** — `admob-ssv` answers `400 signing_key_not_configured` and grants nothing. |
| `PUSH_DISPATCH_SECRET` (Edge Function secret **and** `private.app_settings.push_dispatch_secret`) | ❌ **NOT SET** — `push-dispatch` answers `401 unauthorized`. |
| `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY`, `APNS_TOPIC` | ❌ **NOT SET** — the operator must create the APNs auth key. |
| The Auth providers (Apple / Google) and the SMTP relay | ❌ **not configured** — the runbook is `docs/backend/AUTH_SETUP.md`; the MCP exposes no provider/SMTP tool. |
| `private.app_settings.push_dispatch_url` | ❌ **not set** — the dispatcher is a deliberate no-op until it is. |

The full API reference is [`docs/backend/API.md`](../docs/backend/API.md) and
the generated TypeScript types are
[`supabase/types/database.ts`](types/database.ts).

---

## 22. Gap-closure additions

> **Owner:** gap-closure agent (A9 follow-up) · migration prefix range
> `1000`–`1099` · **Date:** 2026-10-22.
> Applied migrations: `create_feed_post_comments` (1000), `create_my_groups`
> (1001), `create_feed_comment_rpcs` (1002),
> `create_signed_witness_urls_batch` (1003),
> `index_feed_post_comments_user_id` (1004).
> Tests: `supabase/tests/a10/my_groups.sql` (26 assertions),
> `supabase/tests/a10/feed_comments.sql` (83),
> `supabase/tests/a10/signed_urls_batch.sql` (37) — **all PASS**.

This section closes the three gaps the iOS agent (A9) reported. Every new
function follows A10's **private + INVOKER** pattern (§21.4): the privileged
body lives in `private.<name>_impl` (`SECURITY DEFINER SET search_path = ''`,
fully qualified) and the exposed function is a thin `SECURITY INVOKER SET
search_path = ''` wrapper. `REVOKE ALL … FROM PUBLIC, anon` + `GRANT EXECUTE
TO authenticated, service_role` (the **explicit `anon` revoke is mandatory**,
§18.8).

### 22.1 `public.my_groups()` — A3's domain

```sql
public.my_groups() returns jsonb
```

Returns the caller's **ACTIVE** groups in ONE call (the "Meus Grupos" screen
needed four round trips before: `group_members` → `groups` → the member count
→ `group_featured`).

**Shape**

```json
{ "items": [ {
    "id": "…", "name": "…", "description": "…",
    "group_type": "fraternity|challenge",
    "scoring_mode": "faithful_days|collective_treasure|custom_points",
    "sharing_requirement": "open|written_fruit|photo_witness",
    "cover_path": "…|null", "starts_on": "2026-10-01|null", "ends_on": "2026-10-31|null",
    "goal_target": 100|null, "member_count": 12,
    "role": "admin|member", "is_featured": true,
    "invite_code": "123456|null", "archived_at": null
} ] }
```

| Rule | Value |
|---|---|
| **`invite_code`** | Returned **only for the group admin**. A plain member always gets `null` — the code is a CAPABILITY (§14.3). |
| `member_count` | The number of `public.group_members` rows of the group (the same count as A3's `preview_group_by_code` and A4's `get_group_progress`). |
| `is_featured` | `true` when the group has a row in `public.group_featured` with `is_featured = true` (A3's rule). |
| **Excluded** | An **archived** group (`archived_at is not null`). |
| **Excluded** | A **challenge whose season has ended** — A3's ACTIVE-membership rule (§14.2): `ends_on IS NULL OR ends_on >= current_date`. A fraternity is never excluded by its end date. |
| **Excluded** | A group whose **creator blocks the caller** — the same rule as A4's `blocked_by_group_creator` (`private.is_blocked_impl`, symmetric). |
| Ordering | A **running challenge first**, then the **most recently joined** (`group_members.joined_at DESC`), then `groups.id` — stable and meaningful. |
| `archived_at` | Always `null` in the answer (archived groups are excluded); it is kept in the shape for a stable contract. |

Error contract: `42501 authentication required` when the caller has no
identity. `anon` may **not** execute it.

Implementation: `private.my_groups_impl()` (uses
`private.is_blocked_impl(v_uid, g.created_by)`).

### 22.2 `public.feed_post_comments` — A5's domain (the missing product feature)

The product plan (`docs/plan/plan.md`, Flow 4 Tab A) requires that members can
*"react with 'Amen' or 'United in Prayer' **and leave encouraging comments**"*.
`addComment` was a **silent no-op** because no table existed.

```sql
create table public.feed_post_comments (
  id            uuid primary key default gen_random_uuid(),
  post_id       uuid not null references public.feed_posts (id) on delete cascade,
  group_id      uuid not null references public.groups (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  body          text not null check (char_length (body) between 1 and 500),
  is_hidden     boolean not null default false,
  hidden_reason text,
  hidden_at     timestamptz,
  created_at    timestamptz not null default now()
);
```

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK, `gen_random_uuid()`. |
| `post_id` | `uuid` | FK → `public.feed_posts(id)` `ON DELETE CASCADE`. |
| `group_id` | `uuid` | FK → `public.groups(id)` `ON DELETE CASCADE`. Denormalised from the post so the policies never have to join `feed_posts`. |
| `user_id` | `uuid` | FK → `public.profiles(id)` `ON DELETE CASCADE`. |
| `body` | `text` | CHECK `char_length(body) between 1 and 500`. |
| `is_hidden` | `boolean` | Server-owned moderation flag. |
| `hidden_reason` | `text` | `'admin_removed'`. |
| `hidden_at` | `timestamptz` | Stamped only by the moderation RPC. |
| `created_at` | `timestamptz` | `now()`. |

**No `updated_at`** → `public.attach_updated_at` is **not** attached: a comment
is effectively append-only (mirrors `public.moderation_actions`).

**Indexes**

| Index | Definition | Why |
|---|---|---|
| `idx_feed_post_comments_post_created_at` | `(post_id, created_at desc, id desc)` | The comment pagination of `get_feed_post_comments` (cursor order `created_at DESC, id DESC`). |
| `idx_feed_post_comments_group_created_at` | `(group_id, created_at desc)` | The group-scoped comment list. |
| `idx_feed_post_comments_hidden` | `(group_id, created_at desc) where is_hidden` | The moderation query of a group admin. |
| `idx_feed_post_comments_user_id` | `(user_id)` | Backs the `feed_post_comments_user_id_fkey` FK (the `unindexed_foreign_keys` lint must stay at **0**) and the "my comments" lookup. |

**RLS** — enabled **and forced**; the policies use the **single-argument**
helpers (§3):

| Command | Role | Predicate |
|---|---|---|
| SELECT | `authenticated` | `public.is_group_member(group_id) and not public.is_blocked(user_id) and (not is_hidden or public.is_group_admin(group_id))` |
| INSERT | `authenticated` | `user_id = (select auth.uid()) and public.is_group_member(group_id)` |
| UPDATE | `authenticated` | `USING (user_id = (select auth.uid()))` · `WITH CHECK (same)` |
| DELETE | `authenticated` | `USING (user_id = (select auth.uid()) or public.is_group_admin(group_id))` |

Table privileges: `anon` → nothing. `authenticated` → `SELECT`, `INSERT
(post_id, group_id, user_id, body)`, `UPDATE (body)` **only**, `DELETE`.
The **column-level** UPDATE grant is what makes the moderation columns
server-owned: a client may edit the body of its own comment, never
`is_hidden` / `hidden_reason` / `hidden_at`.

> ### ⚠️ Sacred privacy
> A comment is **PUBLIC GROUP CONTENT by design**. It is readable by every
> member of the post's group (unless a block applies). It must **never** hold
> a Spiritual Diary text, a Confession record or a "private" check-in
> reflection — those never leave the device (`feed_posts_no_confession` and
> `check_ins_private_has_no_content_ck` enforce that upstream). The
> `comment on table` says so explicitly.

#### The four RPCs (verbatim signatures)

```sql
public.create_feed_post_comment(p_post_id uuid, p_body text) returns jsonb
public.get_feed_post_comments(p_post_id uuid, p_before text default null, p_limit integer default 20) returns jsonb
public.delete_feed_post_comment(p_comment_id uuid) returns jsonb
public.soft_delete_feed_post_comment(p_comment_id uuid) returns jsonb
```

| RPC | Returns |
|---|---|
| `create_feed_post_comment` | `{ id, post_id, group_id, user_id, body, is_hidden, created_at }` |
| `get_feed_post_comments` | `{ items: [ { id, post_id, group_id, user_id, body, is_hidden, created_at } ], next_cursor }` |
| `delete_feed_post_comment` | `{ comment_id, group_id, deleted }` |
| `soft_delete_feed_post_comment` | `{ comment_id, group_id, hidden, hidden_reason, hidden_at, changed }` |

**Rules**

* `create_feed_post_comment` **trims** the body; a blank body is rejected
  (`22023 comment body cannot be empty`) and a body longer than 500 characters
  is rejected (`22023 comment body must be at most 500 characters`). The
  caller must be a member of the post's group and the post must be visible
  (not hidden, not blocked) — otherwise `42501 post not available`. The
  **database** enforces the length a second time with a CHECK constraint.
* `get_feed_post_comments` uses **A5's composite cursor** (§15.3) exactly:
  `next_cursor = "<created_at ISO-8601 UTC>|<row uuid>"`, ordering
  `created_at DESC, id DESC`, `p_before` is a **`text`** parameter, and
  `p_limit` is clamped to **1..50**. A hidden comment is returned to a **group
  admin only**.
* `delete_feed_post_comment` (hard delete) is allowed to the **author** or a
  **group admin** of the comment's group; otherwise
  `42501 only the author or a group admin can delete a comment`.
* `soft_delete_feed_post_comment` is **group-admin only** (mirrors A5's
  `soft_delete_feed_post`): it sets `is_hidden = true`,
  `hidden_reason = 'admin_removed'`, `hidden_at = now()` and appends **one**
  `public.audit_log` row — `action = 'feed.comment_removed'`,
  `target_type = 'feed_post_comment'`, `target_id = <comment id>`,
  `metadata = { group_id, comment_author_id, reason }`. It is **idempotent**:
  a second call returns `changed = 0` and writes no second audit row.

### 22.3 `public.create_signed_witness_urls()` — A6's domain

```sql
public.create_signed_witness_urls(p_paths text[], p_expires_in integer default 300) returns jsonb
```

Authorises **many** witness-photo paths in ONE call. The client used to pay
one request per photo.

**Shape**

```json
{ "items": [ {
    "path": "witness-photos/<gid>/<uid>/<uuid>.jpg",
    "signed_url": "https://…|null",
    "reason": "…|null",
    "authorized": true,
    "source": "edge_function|null",
    "object_path": "<gid>/<uid>/<uuid>.jpg|null",
    "group_id": "…|null",
    "owner_id": "…|null",
    "expires_in": 300
} ],
  "count": 3, "requested": 3, "truncated": false, "expires_in": 300 }
```

| Rule | Value |
|---|---|
| **The checks are A6's own** | The batch calls `private.create_signed_witness_url_impl()` — A6's existing implementation — **once per path**. There is **no second copy of the path regex**: the path shape, the group-membership check and the block check are literally the same code as `public.create_signed_witness_url`. |
| A path that fails its check | Comes back with `signed_url = null`, `authorized = false` and a `reason` — the **same message** the single-URL RPC raises: `invalid witness photo path` (22023), `not a member of the group that owns this photo` (42501) or `blocked by the photo owner` (42501). |
| **The batch never fails** | One bad path never aborts the batch. |
| **No existence leak** | The reasons describe the **caller's own authorisation**, never whether the object exists. |
| `p_expires_in` | Clamped to **60..3600** seconds (identical to the single-URL RPC). `null` → 300. |
| `p_paths` | At most **50** paths; the extra ones are dropped and the answer carries `truncated = true`. A `null` or empty array returns `items: []`. |

#### How it signs

This deployment has **no** `storage.create_signed_url` helper (§18.3), so the
RPC is the **authorisation gate** and returns `signed_url = null` with
`source = 'edge_function'` for an **authorised** path (exactly like the
single-URL RPC). The actual signing is done by the **`signed-witness-url`
Edge Function**, which now also accepts a **batch**:

```
POST /functions/v1/signed-witness-url
{ "object_paths": ["witness-photos/<gid>/<uid>/<uuid>.jpg", …], "expires_in": 300 }
→ { "items": [ { path, signed_url, reason, authorized, source, object_path, group_id, owner_id, expires_in } ], "count": n, "expires_in": 300 }
```

The Edge Function calls `public.create_signed_witness_urls` with the **caller's
own JWT** (the authorisation gate) and then signs every authorised path with
the service role. The **singular** form (`{ "object_path": … }` → `{ signed_url,
expires_in, object_path, source }`) is **unchanged**.

→ The client needs **one** Edge Function call for N photos, not N calls.

### 22.4 The advisor status after the gap closure

| Type | Lint | Level | Count |
|---|---|---|---|
| security | — | — | **0** (no finding of any kind) |
| performance | `unindexed_foreign_keys` | INFO | **0** (the `user_id` FK is indexed by migration 1004) |
| performance | `unused_index` | INFO | **21** (the accepted empty-table baseline of §21.6; the three new indexes back the pagination, the moderation query and the `user_id` FK) |

### 22.5 The `rls_matrix.sql` extension (a necessary, non-weakening change)

`supabase/tests/a10/rls_matrix.sql` asserts that its expectation table covers
**EXACTLY** the public tables and that the set of tables granting
INSERT/UPDATE/DELETE to `authenticated` is **EXACTLY** the documented one.
Adding `public.feed_post_comments` therefore required **extending** that
matrix (not weakening it): the new table got its own row in `a10_expect`
(the five personas × SELECT/INSERT/UPDATE/DELETE) and was added to the three
policy-set assertions. The plan went from **647** to **667** assertions
(+15 matrix cells, +5 INSERT probes). No assertion was removed, skipped or
relaxed — the matrix is now complete again.


