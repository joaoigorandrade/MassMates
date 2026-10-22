# MassMates — Backend API reference

> **Owner:** A10 (security & QA audit) · **Project ref:** `khovpljkitslmjmonuzu`
> **Live project URL:** `https://khovpljkitslmjmonuzu.supabase.co`
> **PostgreSQL:** 17.11 · **Supabase:** managed
> **Schema contract:** [`supabase/SCHEMA.md`](../../supabase/SCHEMA.md) ·
> **Types:** [`supabase/types/database.ts`](../../supabase/types/database.ts)
> **Conventions:** [`docs/backend/CONVENTIONS.md`](CONVENTIONS.md)
>
> This file is the **client-facing contract**. Every signature below was
> cross-checked against the live database and against `supabase/SCHEMA.md`
> by the A10 audit on 2026-10-22; the A10 RPC matrix
> ([`supabase/tests/a10/rpc_matrix.sql`](../../supabase/tests/a10/rpc_matrix.sql))
> asserts every shape and every error key listed here.

---

## 0. TL;DR

| Concern | Answer |
|---|---|
| Base URL | `https://khovpljkitslmjmonuzu.supabase.co` |
| REST | `/rest/v1/<table>` · RPC `POST /rest/v1/rpc/<fn>` |
| Auth | `/auth/v1/*` (GoTrue) — Apple, Google, e-mail OTP |
| Storage | `/storage/v1/object/<bucket>/<path>` |
| Realtime | `wss://khovpljkitslmjmonuzu.supabase.co/realtime/v1` (Phoenix v2) |
| Functions | `/functions/v1/<slug>` |
| Headers | `apikey: <publishable key>` + `Authorization: Bearer <user JWT>` |
| Typed schema | `supabase/types/database.ts` (`Database` type) |

---

## 1. Authentication

### 1.1 The endpoints the client uses

| Endpoint | Method | Body | Notes |
|---|---|---|---|
| `/auth/v1/otp` | POST | `{ email }` | e-mail magic link / OTP. The **only** password-less path. |
| `/auth/v1/token` | POST | `{ email, otp }` or `{ email, password }` | Exchanges the OTP for a session. |
| `/auth/v1/token?grant_type=apple` | POST | `{ provider: 'apple', id_token }` | Sign in with Apple. |
| `/auth/v1/token?grant_type=google` | POST | `{ provider: 'google', id_token }` | Sign in with Google. |
| `/auth/v1/user` | GET | — | The current user (requires the user JWT). |
| `/auth/v1/logout` | POST | — | Revokes the refresh token. |

### 1.2 Deep links

| Link | Where it lands |
|---|---|
| `massmates://auth/callback` | The OAuth / magic-link redirect. The app exchanges the credentials and dismisses back in. |
| `massmates://join/:code` | The 6-digit fraternity invite code. Use `public.preview_group_by_code(code)` (works **signed out**) and then `public.join_group_by_code(code)`. |

Both are registered in `supabase/config.toml`
(`[auth] additional_redirect_urls`) and in the iOS `CFBundleURLTypes`.

### 1.3 The profile is created by the server

`public.handle_new_user()` (a `SECURITY DEFINER` trigger on `auth.users`)
inserts the `public.profiles` row. **The client never inserts a profile.**
The trigger derives `display_name` (from `full_name` → `name` → `user_name` →
the e-mail local part → `Irmão`/`Irmã`), `locale` (`pt-BR` | `en`),
`timezone` (a real IANA name) and `rule_of_life` (`[]`). The consent flags
are **always** `false` at creation.

---

## 2. The RPC surface

### 2.1 Who may execute what

| Role | May execute |
|---|---|
| `anon` (signed out) | **exactly 4** functions: `preview_group_by_code`, `list_featured_challenges`, `get_today_liturgy`, `get_liturgical_calendar` |
| `authenticated` (signed in) | every client RPC listed in §2.2 – §2.9 |
| `service_role` | everything, including the server-only RPCs of §2.10 |

> The five RLS helpers (`is_group_member`, `is_group_admin`, `is_blocked`,
> `is_group_member_of_any`, `is_any_group_admin`) are **self-scoped**: they
> always evaluate against `auth.uid()`. They take no user id, so they cannot
> be used to enumerate the group roster or the block graph.

### 2.2 Profile & account (A2)

```sql
public.get_my_profile()                                   -> jsonb
public.update_my_profile(
  p_display_name         text    default null,
  p_avatar_path          text    default null,
  p_parish               text    default null,
  p_city                 text    default null,
  p_timezone             text    default null,
  p_locale               text    default null,
  p_ad_consent_analytics boolean default null,
  p_ad_personalization   boolean default null,
  p_rule_of_life         jsonb   default null)             -> jsonb
public.update_ad_consent(p_analytics boolean, p_personalization boolean) -> jsonb
public.request_account_deletion()                         -> jsonb
public.delete_my_account_request()                        -> jsonb  -- alias of the above
public.confirm_account_deletion(p_token uuid)             -> jsonb
```

| RPC | Response keys |
|---|---|
| `get_my_profile` | `id, display_name, avatar_path, parish, city, timezone, locale, ad_consent_analytics, ad_personalization, rule_of_life, guardian_angel_opt_in, created_at, updated_at, deleted_at` |
| `update_my_profile` | the same profile row (only the non-`NULL` arguments are applied) |
| `update_ad_consent` | `id, ad_consent_analytics, ad_personalization, updated_at` |
| `request_account_deletion` / `delete_my_account_request` | `id, confirmation_token, status, requested_at, expires_at, created` |
| `confirm_account_deletion` | `{ deleted: true, … }` |

**Rules.** `display_name` 1–60 chars after trim · `locale ∈ {pt-BR, en}` ·
`timezone` must exist in `pg_timezone_names` · `avatar_path` must match
`^avatars/[A-Za-z0-9][A-Za-z0-9._/-]*$` and contain no `..` ·
`rule_of_life` is a jsonb array of ≤ 10 objects with **exactly** the keys
`kind` (a `practice_kind` value) and `label` (1–60 chars).
`request_account_deletion` starts a **15-minute** two-tap window; the
`delete-account` Edge Function performs the erasure.

**Error keys** (all `22023`): `invalid_display_name`, `invalid_avatar_path`,
`invalid_locale`, `invalid_timezone`, `invalid_parish`, `invalid_city`,
`invalid_rule_of_life`, `invalid_rule_of_life_kind`, `invalid_rule_of_life_label`,
`rule_of_life_too_long`, `invalid_ad_consent`, `invalid_deletion_token`,
`deletion_token_expired` · `42501` `not_authenticated` · `P0002`
`profile_not_found`.

### 2.3 Groups, invites & slots (A3)

```sql
public.create_group(
  p_name                text,
  p_description         text                       default null,
  p_group_type          public.group_type          default 'fraternity',
  p_scoring_mode        public.scoring_mode        default 'faithful_days',
  p_sharing_requirement public.sharing_requirement default 'open',
  p_starts_on           date                       default null,
  p_ends_on             date                       default null,
  p_goal_target         integer                    default null)          -> jsonb
public.join_group_by_code(p_code text)                                   -> jsonb
public.join_featured_challenge(p_group_id uuid)                           -> jsonb
public.reset_invite_code(p_group_id uuid)                                -> jsonb
public.leave_group(p_group_id uuid)                                       -> jsonb
public.remove_member(p_group_id uuid, p_member_id uuid)                   -> jsonb
public.transfer_admin(p_group_id uuid, p_new_admin_id uuid)               -> jsonb
public.preview_group_by_code(p_code text)                                 -> jsonb  -- anon too
public.list_featured_challenges()                                         -> jsonb  -- anon too
public.my_group_slots()                                                  -> jsonb
public.my_groups()                                                       -> jsonb
```

| RPC | Response keys |
|---|---|
| `create_group` | `group, invite_code` |
| `join_group_by_code` | `group, invite_code, member_role, already_member` |
| `join_featured_challenge` | `group, member_role, already_member` |
| `reset_invite_code` | `group_id, invite_code` |
| `leave_group` | `group_id, left, archived` |
| `remove_member` | `group_id, removed_user, removed_self` |
| `transfer_admin` | `group_id, new_admin, previous_admin` |
| `preview_group_by_code` | `id, name, group_type, scoring_mode, sharing_requirement, cover_path, member_count, is_featured, starts_on, ends_on, goal_target, description_preview` — **never** `invite_code` / `created_by` |
| `list_featured_challenges` | an **array** of the same preview shape |
| `my_group_slots` | `personal_used, personal_max, seasonal_used, seasonal_max, bonus_active, bonus_expires_at, personal_available, seasonal_available` |
| `my_groups` | `items[]` — item: `id, name, description, group_type, scoring_mode, sharing_requirement, cover_path, starts_on, ends_on, goal_target, member_count, role, is_featured, invite_code, archived_at` |

**`my_groups`** — the caller's **active** groups in **one** call (the "Meus
Grupos" screen used to need four round trips). An **archived** group and a
**challenge whose season has ended** (`ends_on` in the past) are **excluded**,
and so is a group whose **creator blocks the caller**. Ordering: a running
challenge first, then the most recently joined, then the group id.

> **`invite_code` is returned ONLY to the group admin.** A plain member always
> receives `invite_code: null` — the code is a capability, not a label.
> `role` is `"admin"` or `"member"`.

**Slot rules.** Free tier = **2 personal fraternities + 1 seasonal challenge**.
A rewarded video adds **+1 personal slot for 30 days**. The server enforces
this — a client cannot buy a slot.

**Admin rules.** One admin per group · the **last** admin cannot leave or be
removed (transfer first) · `transfer_admin` demotes every other admin · the
last member leaving **archives** the group.

**Error keys.** `42501` `only a group admin can …`, `not a member of this
group`, `only a group administrator can …` · `22023` `invalid invite code:
expected 6 digits`, `a challenge requires both starts_on and ends_on` ·
`P0001` `this invite code has reached its usage limit`, `slot limit: …`,
`you are the last admin …`, `you cannot join this group` · `P0002`
`invite code not found`, `group not found`.

### 2.4 Check-ins, streaks & scoring (A4)

```sql
public.submit_check_in(
  p_practice   public.practice_kind,
  p_sharing    text,
  p_group_ids  uuid[] default '{}',
  p_reflection text    default null,
  p_photo_path text    default null,
  p_local_date date    default null,
  p_timezone   text    default null)                                -> jsonb
public.get_rule_of_life_ring(p_local_date date default null)      -> jsonb
public.get_streak_summary()                                       -> jsonb
public.get_consistency_heatmap(p_from date, p_to date)            -> jsonb
public.get_group_progress(p_group_id uuid)                        -> jsonb
public.use_streak_mercy(p_repairs_date date)                      -> jsonb
public.set_practice_points(p_group_id uuid, p_practice public.practice_kind, p_points integer) -> jsonb
```

| RPC | Response keys |
|---|---|
| `submit_check_in` | `check_in_id, streak{current, longest, last_practice_date}, ring{completed, total, percentage, items}, destinations[]` |
| `get_rule_of_life_ring` | `completed, total, percentage, items[{kind, label, done}], local_date` |
| `get_streak_summary` | `current_streak, longest_streak, last_practice_date, total_practices, mercy_available, mercy_used_this_month` |
| `get_consistency_heatmap` | a **plain map** `{"2026-10-21": 2, "2026-10-22": 1}` (the key is the local date) |
| `get_group_progress` | `group_id, goal_current, goal_target, percentage, active_today_count, member_count, scoring_mode, per_member[{user_id, display_name, points, days_active}]` |
| `use_streak_mercy` | `applied, repairs_date, current_streak, longest_streak, last_practice_date, mercy_used_this_month` |
| `set_practice_points` | `id, group_id, practice_kind, points` |

> ### ⚠️ Sacred privacy (the hard rule)
> A check-in with `p_sharing = 'private'` **MUST** send
> `p_reflection = null` **and** `p_photo_path = null`. The server rejects
> it with `private_check_in_cannot_hold_content`, and the database rejects
> it a second time with a CHECK constraint. A `confession` check-in is
> always private. The client keeps the Spiritual Diary **on the device**.

**Error keys.** `22023` `invalid_sharing`, `confession_is_private_only`,
`private_check_in_cannot_hold_content`, `reflection_text_too_long`,
`invalid_photo_path`, `invalid_timezone`, `local_date_in_future`,
`local_date_too_old`, `group_sharing_requires_destination`, `group_archived`,
`group_sharing_requirement_not_met`, `no_streak_mercy_grant`,
`no_streak_to_repair`, `repairs_date_not_missed`,
`repairs_date_not_adjacent_to_streak`, `repairs_date_in_future`,
`repairs_date_too_old`, `invalid_range`, `range_too_large`, `group_not_found`,
`invalid_points` · `23505` `already_checked_in_today`,
`streak_mercy_already_used_this_month` · `42501` `not_a_group_member`,
`blocked_by_group_creator`, `not_a_group_admin`, `service_role_required`,
`authentication required` · `28000` `profile_not_found`.

### 2.5 Feed, prayer wall & chat (A5)

```sql
public.get_feed_posts(p_group_id uuid, p_before text default null, p_limit integer default 20)      -> jsonb
public.get_prayer_intentions(p_group_id uuid, p_before text default null, p_limit integer default 20) -> jsonb
public.get_chat_messages(p_group_id uuid, p_before text default null, p_limit integer default 30)   -> jsonb
public.toggle_amen(p_post_id uuid, p_reaction_type text default 'amen')                             -> jsonb
public.toggle_prayed_for(p_intention_id uuid)                                                      -> jsonb
public.create_prayer_intention(p_group_id uuid, p_body text)                                       -> jsonb
public.create_chat_message(p_group_id uuid, p_body text, p_reply_to_id uuid default null)           -> jsonb
public.set_pinned_notice(p_group_id uuid, p_body text)                                              -> jsonb
public.clear_pinned_notice(p_group_id uuid)                                                        -> jsonb
public.soft_delete_feed_post(p_post_id uuid)                                                       -> jsonb
public.soft_delete_chat_message(p_message_id uuid)                                                 -> jsonb
public.create_feed_post_comment(p_post_id uuid, p_body text)                                       -> jsonb
public.get_feed_post_comments(p_post_id uuid, p_before text default null,
                              p_limit integer default 20)                                          -> jsonb
public.delete_feed_post_comment(p_comment_id uuid)                                                 -> jsonb
public.soft_delete_feed_post_comment(p_comment_id uuid)                                           -> jsonb
```

| RPC | Response keys |
|---|---|
| `get_feed_posts` | `items[], next_cursor` — item: `id, check_in_id, group_id, user_id, practice_kind, reflection_text, photo_path, points, created_at, amens, united_in_prayer, my_reactions[]` |
| `get_prayer_intentions` | `items[], next_cursor` — item: `id, group_id, user_id, body, prayer_count, prayed, created_at` |
| `get_chat_messages` | `items[], next_cursor` — item: `id, group_id, user_id, body, reply_to_id, created_at` |
| `toggle_amen` | `amens, united_in_prayer, reacted` |
| `toggle_prayed_for` | `prayer_count, prayed` |
| `create_prayer_intention` | `id, group_id, user_id, body, prayer_count, created_at` |
| `create_chat_message` | `id, group_id, user_id, body, reply_to_id, created_at` |
| `set_pinned_notice` | `id, group_id, author_id, body, is_active, replaced, created_at` |
| `clear_pinned_notice` | `group_id, cleared` |
| `soft_delete_feed_post` | `post_id, group_id, hidden, hidden_reason, changed` |
| `soft_delete_chat_message` | `message_id, group_id, hidden, hidden_reason, hidden_at, changed` |
| `create_feed_post_comment` | `id, post_id, group_id, user_id, body, is_hidden, created_at` |
| `get_feed_post_comments` | `items[], next_cursor` — item: `id, post_id, group_id, user_id, body, is_hidden, created_at` |
| `delete_feed_post_comment` | `comment_id, group_id, deleted` |
| `soft_delete_feed_post_comment` | `comment_id, group_id, hidden, hidden_reason, hidden_at, changed` |

**Comments on a feed post** (the "encouraging comments" of the product plan).
A comment is **public group content**: readable by every member of the post's
group, hidden from a blocked pair, and moderated by the group admins.

* `create_feed_post_comment` **trims** the body. A blank body → `22023
  comment body cannot be empty`; more than 500 characters → `22023 comment
  body must be at most 500 characters`. The caller must be a member of the
  post's group and the post must be visible, otherwise `42501 post not
  available`. The database enforces the length a second time (CHECK).
* `get_feed_post_comments` uses the **same composite cursor** as
  `get_feed_posts` (§2.5 "Pagination cursor") and the same `p_limit` clamp
  (**1..50**). A hidden comment is returned to a **group admin only**.
* `delete_feed_post_comment` (hard delete) — the **author** or a **group
  admin** of the comment's group; otherwise `42501 only the author or a group
  admin can delete a comment`.
* `soft_delete_feed_post_comment` — **group admin only** (`42501 only a group
  admin can remove a comment`). It hides the comment (the row is kept) and
  writes **exactly one** `audit_log` row (`action = feed.comment_removed`,
  `target_type = feed_post_comment`). It is idempotent: a second call returns
  `changed = 0` and writes no second audit row.

**Pagination cursor.** `next_cursor` is the composite keyset
`"<created_at ISO-8601 UTC>|<row uuid>"`. **Pass it back unchanged** as
`p_before`. A bare ISO timestamp is accepted but compares strictly and
therefore skips rows that share a `created_at`. Ordering is
`created_at DESC, id DESC` for every list; the chat is read bottom-up, so
the client reverses `items`. `p_limit` is clamped (feed/prayer wall `1..50`,
chat `1..100`, **comments `1..50`**). `next_cursor` is `null` when the page is
empty.

**Error keys.** `42501` `not a member of this group`, `post not available`,
`intention not available`, `only a group admin can pin a notice`,
`only a group admin can clear a notice`, `only a group admin can remove a post`,
`only a group admin can remove a message`, `only a group admin can remove a comment`,
`only the author or a group admin can delete a comment` · `22023`
`body_too_long`, `invalid_reaction_type`, `comment body cannot be empty`,
`comment body must be at most 500 characters` · `P0002` `post not found`,
`intention not found`, `comment not found`.

### 2.6 Moderation & safety (A6)

```sql
public.block_user(p_blocked_id uuid)                                        -> jsonb
public.unblock_user(p_blocked_id uuid)                                      -> jsonb
public.list_blocked_users()                                                 -> jsonb
public.report_content(p_target_type text, p_target_id uuid, p_reason text,
                       p_details text default null, p_group_id uuid default null) -> jsonb
public.admin_delete_post(p_post_id uuid)                                    -> jsonb
public.hide_content(p_target_type text, p_target_id uuid, p_reason text)    -> jsonb
public.get_moderation_queue(p_group_id uuid)                                -> jsonb
public.resolve_report(p_report_id uuid, p_status text, p_note text default null) -> jsonb
public.get_moderation_actions(p_group_id uuid)                              -> jsonb
public.create_signed_witness_url(p_object_path text, p_expires_in integer default 300) -> jsonb
public.create_signed_witness_urls(p_paths text[], p_expires_in integer default 300)  -> jsonb
```

| RPC | Response keys |
|---|---|
| `block_user` | `blocked, blocked_id, created` |
| `unblock_user` | `blocked, blocked_id, removed` |
| `list_blocked_users` | `blocked_users[{user_id, display_name, avatar_path, blocked_at}], count` |
| `report_content` | `report_id, auto_hidden, report_count, status, group_id, duplicate` |
| `admin_delete_post` | `post_id, group_id, deleted, hidden, detail` |
| `hide_content` | `target_id, target_type, group_id, hidden, action_type` |
| `get_moderation_queue` | `count, group_id, reports[]` |
| `resolve_report` | `report_id, status, action_type` |
| `get_moderation_actions` | `count, group_id, actions[]` |
| `create_signed_witness_url` | `signed_url, expires_in, bucket_id, object_path, group_id, owner_id, source, edge_function, message` |
| `create_signed_witness_urls` | `items[{path, signed_url, reason, authorized, source, object_path, group_id, owner_id, expires_in}], count, requested, truncated, expires_in` |

**Rules.** `report_content` is **idempotent per (reporter, target)** — a
retry returns the existing report (`duplicate: true`). **3 independent
reports** auto-hide the target (`auto_hidden: true`). A block hides content
**in both directions**. `create_signed_witness_url` is the **authorisation
gate**: it validates the path, checks the caller's group membership and the
block, clamps the TTL to `60..3600` s and returns the validated
`object_path`; the **`signed-witness-url` Edge Function** then signs it
(`source: "edge_function"`). A private check-in can never be reported.

**The batch** (`create_signed_witness_urls`) runs **the same checks** for
**many** paths in one call: every path goes through A6's own single-path
implementation, so the path shape, the group membership and the block are the
same rules. A path that fails its check comes back with `signed_url = null`,
`authorized = false` and a `reason` (the same message the single-URL RPC
raises); **the batch never fails because of one bad path** and the reason
never reveals whether the object exists. `p_expires_in` is clamped to
`60..3600` s and at most **50** paths are processed (`truncated: true` when
there were more). On this deployment there is **no SQL signer**, so
`signed_url` is `null` for an authorised path (`source: "edge_function"`) and
the **`signed-witness-url` Edge Function** does the signing — it now also
accepts `{ "object_paths": [...] }` and returns
`{ "items": [{ path, signed_url, reason, … }], "count": n }`, so the client
needs **one** call for N photos.

**Error keys.** `42501` `you can only report content inside your own groups`,
`only a group administrator can delete a post`,
`only a group administrator can hide content`,
`only a group administrator can read the moderation queue`,
`only a group administrator can read the moderation trail`,
`not a member of the group that owns this photo`,
`blocked by the photo owner` · `22023` `invalid target type`, `invalid reason`,
`target is required`, `this check-in is private and cannot be reported`,
`invalid witness photo path` · `P0002` `reported content not found`,
`user not found` · `P0001` `you cannot block yourself`.

### 2.7 Liturgical content & monetization (A7)

```sql
public.get_today_liturgy()                            -> jsonb  -- anon too
public.get_liturgical_calendar(p_year integer)         -> jsonb  -- anon too
public.my_rewards()                                    -> jsonb
public.begin_ad_reward(p_reward_type text)             -> jsonb
public.consume_reward(p_grant_id uuid)                -> jsonb
```

| RPC | Response keys |
|---|---|
| `get_today_liturgy` | `date, day, readings, saints` |
| `get_liturgical_calendar` | `year, count, days[{date, season, liturgical_color, celebration, rank, saints[]}]` |
| `my_rewards` | `grants[]` |
| `begin_ad_reward` | `ok, reward_type, transaction_id, expires_at, expires_in_seconds, saint_icon_id` |
| `consume_reward` | `ok, grant_id, reward_type, status, consumed_at` |

**The rewarded-video flow.** `begin_ad_reward` mints a single-use
`transaction_id`; the app shows the ad and passes it to the ad network as
the custom parameter `massmates_txn`; Google calls the `admob-ssv` Edge
Function, which verifies the RSA-SHA256 signature and calls
`public.grant_reward` (server side). A replayed callback never grants twice.

**Error keys.** `22023` `unsupported reward type`, `reward not found`,
`reward already consumed` · `42501` `not_authenticated` · `P0002`
`grant not found`.

### 2.8 Guardian Angel & push (A8)

```sql
public.guardian_angel_state(p_group_id uuid)                       -> jsonb
public.my_guardian_assignment(p_group_id uuid)                     -> jsonb
public.opt_in_to_guardian_angel(p_group_id uuid, p_opt_in boolean)  -> jsonb
public.send_guardian_nudge(p_group_id uuid, p_local_date date)      -> jsonb
public.register_device_token(p_apns_token text, p_platform text,
                              p_environment text, p_app_version text) -> jsonb
```

| RPC | Response keys |
|---|---|
| `guardian_angel_state` | `group_id, opted_in, is_guardian, is_protected, can_nudge, nudges_today, cycle_ends_on` |
| `my_guardian_assignment` | `is_guardian, is_protected, guardian_display_name, protected_display_name, protected_intentions, cycle_key, cycle_starts_on, cycle_ends_on, revealed, can_nudge, nudges_today` |
| `opt_in_to_guardian_angel` | `group_id, opted_in, group_opt_in, master_opt_in` |
| `send_guardian_nudge` | `sent, nudges_today, remaining, nudge_id, local_date` |
| `register_device_token` | `id, platform, environment, app_version, is_active, registered` |

> ### ⚠️ The Guardian Angel is anonymous to the recipient
> The nudge the protected member receives carries **neither the sender's
> name nor the sender's id** — the payload is `{group_id, cycle_key}` and the
> body is *"Alguém rezou por você hoje."*. `public.guardian_angel_pairings`
> has **no client-readable policy at all**; the identities are revealed only
> when the cycle ends (a server action).

**Error keys.** `42501` `not_a_guardian`, `not_a_protected`,
`authentication required` · `P0001` `nudge_already_sent_today`,
`guardian_angel_not_enabled` · `22023` `invalid_group_id`.

### 2.9 The self-scoped RLS helpers

```sql
public.is_group_member(p_group_id uuid)     -> boolean
public.is_group_admin(p_group_id uuid)      -> boolean
public.is_blocked(p_other_id uuid)          -> boolean
public.is_group_member_of_any()             -> boolean
public.is_any_group_admin()                 -> boolean
```

All five evaluate against `auth.uid()`. `is_blocked` is **symmetric**: it is
`true` when a block exists in either direction.

### 2.10 The server-only RPCs (`service_role` only)

```sql
public.claim_notification_outbox(p_limit integer)                       -> setof jsonb
public.complete_notification_outbox(p_outbox_id uuid, p_status text,
                                     p_error text default null,
                                     p_retry_at timestamptz default null) -> jsonb
public.dispatch_push_notifications()                                    -> jsonb
public.emit_prayer_notification(p_intention_id uuid, p_prayer_id uuid)    -> jsonb
public.deactivate_device_token(p_token_id uuid)                         -> jsonb
public.grant_reward(p_user_id uuid, p_reward_type text, p_source text,
                     p_transaction_id text default null,
                     p_expires_days integer default null,
                     p_metadata jsonb default '{}')                      -> jsonb
public.grant_slot_unlock(p_user_id uuid, p_kind text, p_source text,
                         p_days integer default 30, p_notes text default null) -> jsonb
public.grant_streak_mercy(p_user_id uuid, p_expires_at timestamptz default null) -> jsonb
public.insert_feed_post(p_check_in_id uuid, p_group_id uuid, p_user_id uuid,
                         p_practice_kind public.practice_kind,
                         p_reflection_text text default null,
                         p_photo_path text default null,
                         p_points integer default 0)                     -> jsonb
public.set_featured_group(p_group_id uuid, p_is_featured boolean default true,
                           p_starts_on date default null, p_ends_on date default null,
                           p_display_order integer default 0)            -> jsonb
public.run_guardian_angel_pairing(p_group_id uuid, p_cycle_key text,
                                  p_cycle_starts_on date)                -> jsonb
public.reveal_guardian_identities(p_group_id uuid)                      -> jsonb
public.sweep_guardian_angel_pairings(p_scope text)                     -> jsonb
public.sweep_reveal_guardian_identities()                              -> jsonb
```

> `public.probe_wrapper(text)` is a **legacy debug echo** kept for
> compatibility; it is restricted to `service_role` and is not part of the
> client contract.

---

## 3. The PostgREST tables the client may read

Direct table access is allowed **behind RLS**. The client must never write
to a table that has no client write policy.

| Table | The client may | Notes |
|---|---|---|
| `profiles` | SELECT own + groupmates, UPDATE own | The `handle_new_user` trigger is the only INSERT path. |
| `groups` | SELECT non-archived groups + own groups, INSERT own, UPDATE/DELETE as group admin | A group admin may write `invite_code` directly — **do not**: the join flow needs a matching `group_invites` row. |
| `group_members` | SELECT the roster of own groups, INSERT self, UPDATE as group admin, DELETE self or as group admin | |
| `user_blocks` | SELECT / INSERT / DELETE **own** rows only | You never see the blocks others placed on you. |
| `check_ins` | SELECT **own** rows, DELETE own | No client INSERT: a check-in goes through `submit_check_in`. |
| `check_in_destinations` | SELECT the rows of own groups | Read-only. |
| `streaks`, `streak_events`, `streak_mercy_uses`, `streak_mercy_grants` | SELECT own | Read-only for the client. |
| `feed_posts` | SELECT visible posts | **No client write** — the fan-out trigger owns the table. |
| `feed_post_comments` | SELECT visible, INSERT own, UPDATE own (`body` only), DELETE own or as group admin | The encouraging comments of a post. **Public group content** — never a Spiritual Diary text, a Confession record or a private check-in reflection. |
| `amen_reactions` | SELECT visible, INSERT own, DELETE own | |
| `prayer_intentions` | SELECT visible, INSERT own, UPDATE own (`body` only), DELETE own or as group admin | `prayer_count` is server-owned. |
| `intention_prayers` | SELECT visible, INSERT own, DELETE own | |
| `chat_messages` | SELECT visible, INSERT own, DELETE own or as group admin | |
| `pinned_notices` | SELECT visible, INSERT/UPDATE/DELETE as group admin | |
| `content_reports` | SELECT own or as group admin, INSERT own, UPDATE as group admin | |
| `moderation_actions` | SELECT as group admin | Read-only. |
| `audit_log` | SELECT as a group admin of **any** group | Append-only, server-written. |
| `group_invites` | SELECT as group admin | The invite audit trail. |
| `slot_unlocks`, `reward_grants`, `ad_view_tokens`, `device_tokens`, `notification_outbox`, `account_deletion_requests`, `user_saint_unlocks` | SELECT **own** rows | Read-only for the client. |
| `guardian_angel_opt_ins` | SELECT own + the opt-ins of own groups, INSERT/DELETE own | |
| `guardian_angel_pairings` | **NOTHING** | No client policy and no client privilege. Read through `my_guardian_assignment`. |
| `guardian_nudges` | SELECT **own** rows (the ones you sent) | The recipient never sees the sender. |
| `liturgical_days`, `daily_readings`, `saints`, `saint_icons`, `sponsors`, `sponsored_challenges`, `group_featured` | SELECT (public content, `anon` included) | Read-only for the client. |
| `practice_points` | SELECT global + own groups, INSERT/UPDATE/DELETE as group admin | |
| `ssv_receipts` | **NOTHING** | Server-only. |

---

## 4. Storage

Three buckets. `storage.objects.name` is the path **inside** the bucket
(it does not repeat the bucket name).

| Bucket | `public` | Size | MIME | Path convention |
|---|---|---|---|---|
| `avatars` | **true** | 5 MiB | jpeg / png / heic / webp | `<user_id>/<uuid>.<ext>` |
| `group-covers` | **true** | 8 MiB | jpeg / png / heic / webp | `<group_id>/<uuid>.<ext>` |
| `witness-photos` | **false** | 10 MiB | jpeg / png / heic / webp | `<group_id>/<user_id>/<uuid>.<ext>` |

### 4.1 Upload an avatar

```
POST /storage/v1/object/avatars/<user_id>/<uuid>.jpg
Headers: apikey, Authorization: Bearer <user JWT>, Content-Type: image/jpeg
```
The `avatars_insert_own` policy requires `owner_id = auth.uid()` **and**
`foldername(name)[1] = auth.uid()`. Then write the path to
`profiles.avatar_path` (`public.update_my_profile(p_avatar_path => …)`).

### 4.2 Upload a group cover

```
POST /storage/v1/object/group-covers/<group_id>/<uuid>.jpg
```
The `group_covers_insert_member` policy requires the caller to be a **member**
of the group in the path. Then `groups.cover_path`.

### 4.3 Upload a witness photo (the private one)

```
POST /storage/v1/object/witness-photos/<group_id>/<user_id>/<uuid>.jpg
```
The `witness_photos_insert_owner` policy requires
`foldername(name)[2] = auth.uid()` **and** group membership. The bucket is
**private**: an `anon` client cannot read it and a member of another group
cannot either.

Then ask the server for a signed URL:

```
POST /rest/v1/rpc/create_signed_witness_url
{ "p_object_path": "witness-photos/<group_id>/<user_id>/<uuid>.jpg", "p_expires_in": 300 }
```
→ `{ signed_url, expires_in, bucket_id, object_path, group_id, owner_id, source, edge_function, message }`.
`source` is `"edge_function"` on this deployment (there is no SQL signer
here); the app then calls the `signed-witness-url` Edge Function with its
**user JWT** to obtain the absolute URL.

### 4.4 Sign MANY witness photos in one round trip

```
POST /functions/v1/signed-witness-url
{ "object_paths": ["witness-photos/<gid>/<uid>/<uuid>.jpg", …], "expires_in": 300 }
→ { "items": [ { path, signed_url, reason, authorized, source, object_path, group_id, owner_id, expires_in } ], "count": n, "expires_in": 300 }
```

The Edge Function calls `public.create_signed_witness_urls` with the
**caller's own JWT** (the authorisation gate — the same checks as the single
URL) and then signs every **authorised** path with the service role. A path
that fails its check comes back with `signed_url = null` and a `reason`; the
batch never fails because of one bad path. The singular
`{ "object_path": … }` form is unchanged.

---

## 5. Realtime

The `supabase_realtime` publication contains exactly three tables:

| Table | Channel | Note |
|---|---|---|
| `chat_messages` | `postgres_changes` | `REPLICA IDENTITY FULL` — the payload is the whole row. |
| `amen_reactions` | `postgres_changes` | |
| `intention_prayers` | `postgres_changes` | |

The server applies the table's RLS to the channel, so a subscriber only
receives the rows it is allowed to `SELECT`.

---

## 6. Edge Functions

| Slug | `verify_jwt` | Who calls it | Required secrets |
|---|---|---|---|
| `delete-account` | **true** | The user (its own JWT) | `SUPABASE_SERVICE_ROLE_KEY` (platform) |
| `signed-witness-url` | **true** | The user (its own JWT) | `SUPABASE_SERVICE_ROLE_KEY` (platform) |
| `admob-ssv` | **false** | Google AdMob | `ADMOBSIGNING_KEY` — **operator action, NOT set** |
| `push-dispatch` | **false** | `pg_cron` via `pg_net` | `PUSH_DISPATCH_SECRET` — **operator action, NOT set**; `APNS_*` — **operator action, NOT set** |

The two `verify_jwt: false` functions **verify the caller themselves** and
**fail closed**:

* `admob-ssv` refuses every request with `400 signing_key_not_configured`
  until `ADMOBSIGNING_KEY` is set; it also refuses a wrong
  `package_name`, a wrong reward type, an unknown `transaction_id` and a bad
  signature. **It grants nothing.**
* `push-dispatch` refuses every request with `401 {"ok":false,"reason":"unauthorized"}`
  unless it receives the service-role bearer **or** the matching
  `x-push-secret`.

### 6.1 The operator secrets

| Secret | Used by | State |
|---|---|---|
| `ADMOBSIGNING_KEY` | `admob-ssv` | ❌ **NOT SET** (verified: the function answers `signing_key_not_configured`) |
| `PUSH_DISPATCH_SECRET` | `push-dispatch` + `private.app_settings.push_dispatch_secret` | ❌ **NOT SET** (verified: `private.app_settings` is empty and the function answers 401) |
| `APNS_KEY_ID` | `push-dispatch` | ❌ **NOT SET** (operator action) |
| `APNS_TEAM_ID` | `push-dispatch` | ❌ **NOT SET** (operator action) |
| `APNS_PRIVATE_KEY` | `push-dispatch` (the `.p8` PKCS#8 PEM) | ❌ **NOT SET** (operator action) |
| `APNS_TOPIC` | `push-dispatch` (the bundle id) | ❌ **NOT SET** (operator action) |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` | all | ✅ provided by the platform |

Set them with:

```bash
supabase secrets set ADMOBSIGNING_KEY="-----BEGIN PUBLIC KEY-----\n…\n-----END PUBLIC KEY-----"
supabase secrets set PUSH_DISPATCH_SECRET="<random 32+ bytes>"
supabase secrets set APNS_KEY_ID="ABCDE12345" APNS_TEAM_ID="FGHIJ67890" APNS_TOPIC="joaoigor.MassMates"
supabase secrets set APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n…\n-----END PRIVATE KEY-----"
```

> The APNs provider token must be signed with the **raw** `R || S` form
> (RFC 7515 §3.4), not DER — see `docs/backend/PUSH.md`.

---

## 7. Cron jobs

`pg_cron` runs in the database.

| Job | Schedule | Command | Effect |
|---|---|---|---|
| `a8_pairing_weekly_fraternities` | `0 5 * * 1` | `select public.sweep_guardian_angel_pairings('fraternity')` | Draws the weekly Guardian Angel pairs of every fraternity. |
| `a8_pairing_daily_challenges` | `0 6 * * *` | `select public.sweep_guardian_angel_pairings('challenge')` | Draws the pairs of every challenge. |
| `a8_reveal_ended_cycles` | `15 6 * * *` | `select public.sweep_reveal_guardian_identities()` | Reveals the identities of the cycles that ended. |
| `a8_push_dispatch` | `*/5 * * * *` | `select public.dispatch_push_notifications()` | Sends the queued pushes (a **no-op** until `private.app_settings.push_dispatch_url` is set). |

---

## 8. The privacy guarantees

These are enforced by the **database**, not by the client.

1. **No Confession, no Spiritual Diary, ever.** No table, column or storage
   bucket can hold them. The word `confession` exists only as a *value* of
   `public.practice_kind` — a practice that may be **recorded** and never
   **shared**.
2. **A private check-in carries no content.** `check_ins.reflection_text`
   and `check_ins.photo_path` are `NULL` for every `sharing = 'private'` row
   — enforced by `check_ins_private_has_no_content_ck`.
3. **A confession can never be shared.** Enforced by
   `check_ins_confession_is_private_ck` and by
   `feed_posts_no_confession`.
4. **A private check-in never fans out.** It creates **zero**
   `check_in_destinations` and **zero** `feed_posts` rows. The fan-out
   trigger skips it.
5. **The fact is stored, the content is not.** A private check-in counts
   for the Daily Streak and (when the practice kind is a Rule of Life
   commitment) for the Rule of Life Ring. Only the **content** stays on the
   device.
6. **No private content reaches the outbox or the audit log.**
7. **Witness photos are private.** The bucket is `public = false` and `anon`
   has **no** policy on it.
8. **The Guardian Angel nudge is anonymous.** Neither the sender's name nor
   the sender's id is in the payload, the title or the body.

The end-to-end proof lives in
[`supabase/tests/a10/privacy.sql`](../../supabase/tests/a10/privacy.sql)
(65 assertions).

---

## 9. The RLS matrix at a glance

* **40** tables, every one with RLS **enabled and forced**.
* Every table has at least one explicit policy.
* `anon` may **write** to **no** table, and may **read** only the seven
  public-content tables (`daily_readings`, `group_featured`,
  `liturgical_days`, `saint_icons`, `saints`, `sponsored_challenges`,
  `sponsors`).
* The five personas (anon / outsider / member / admin / blocked) are
  asserted table by table in
  [`supabase/tests/a10/rls_matrix.sql`](../../supabase/tests/a10/rls_matrix.sql)
  (667 assertions).
