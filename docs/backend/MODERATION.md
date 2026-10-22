# MassMates — Moderation & Community Safety Policy

> **Owner:** A6 (storage, moderation & safety) · **Migration range:** `0500`–`0599`
> **Audience:** the App Store reviewer, the product owner, the trust & safety team.
> **Schema contract:** [`supabase/SCHEMA.md`](../supabase/SCHEMA.md) · **Conventions:** [`docs/backend/CONVENTIONS.md`](CONVENTIONS.md)

MassMates is a private, invite-based community of Catholic fraternities. Every
group has a **group administrator** (a real person, usually a parish leader)
and a **small member roster**. The app therefore does not run a public feed:
it runs *small rooms with a named adult in charge of them*. This document
describes the reporting, blocking and moderation machinery that backs the
App Store User-Generated Content requirements (Guideline 1.2).

---

## 1. The three safety actions a member can take

Every actionable surface of the app (a feed post, a chat message, a prayer
intention, a member's profile) offers the same three-entry safety menu, from
the **group detail screen** (`10_GroupDetail`, top-right menu) and from the item
itself (long-press / swipe):

| Action | Who | Server RPC | What it does |
|---|---|---|---|
| **Report** | any member of the group | `public.report_content(...)` | opens a moderation report for the group administrator |
| **Block** | any signed-in user | `public.block_user(p_blocked_id)` | hides both users' content from each other, everywhere |
| **Unblock** | any signed-in user | `public.unblock_user(p_blocked_id)` | lifts the block |

`public.list_blocked_users()` returns the caller's own block list so the
client can render a "Blocked members" screen.

### 1.1 What can be reported

`target_type` ∈ `post`, `chat_message`, `prayer_intention`, `check_in`,
`profile`, `group`.

`reason` ∈ `inappropriate_photo`, `inappropriate_text`, `spam`, `harassment`,
`hate`, `self_harm`, `other`, plus an optional free-text note of **at most 500
characters**.

A report is **idempotent**: if the same member reports the same item twice,
the second call returns the first report instead of creating a duplicate. A
single member can therefore never trip the auto-hide threshold alone.

### 1.2 What can never be reported

* **Private check-ins** ("Only in My Private Diary"). They carry no content at
  all — `check_ins.reflection_text` and `check_ins.photo_path` are `NULL` for
  a private check-in — and they are never shared. `report_content` refuses them
  explicitly. This is the sacred-privacy gate (CONVENTIONS §8).
* **Confession records and Spiritual Diary entries.** These never reach the
  server: they live on the device, behind the optional Face ID lock. No table,
  no column and no storage bucket of MassMates can hold them.

---

## 2. What happens after N reports — the auto-hide

```
private.auto_hide_threshold()  =  3
```

When the number of **unresolved** reports (`status in ('open','reviewing')`) for
one target reaches **three**, an `AFTER INSERT` trigger on
`public.content_reports` (`trg_content_reports_auto_hide`) automatically:

1. hides the target (`feed_posts.is_hidden = true`,
   `hidden_reason = 'auto_hidden'`; `prayer_intentions.is_hidden = true`),
2. writes a `public.moderation_actions` row with `action_type = 'auto_hide'`,
3. writes a `public.audit_log` row (`moderation.auto_hidden`).

The post is **not deleted** — it is hidden. The group administrator still sees
it (hidden items remain visible to administrators) and can restore it.

**Three independent members** are therefore required before anything is hidden
automatically. Two members — or one member reporting repeatedly — never hide
content. A single report is never enough.

The counter that drives this is exposed as the view
`public.v_target_report_counts` (`security_invoker = true`, so a member only
sees counters for reports they are allowed to see).

---

## 3. What a group administrator can do

Administrators act from the **group detail screen → Safety & Moderation**
(`public.get_moderation_queue(p_group_id)` lists the open reports of their
group with a short preview of the reported content).

| Action | RPC | Effect |
|---|---|---|
| **Hide a post** | `public.hide_content('post', …, reason)` | `is_hidden = true`, `hidden_reason = 'hidden_by_admin'` |
| **Hide a chat message** | `public.hide_content('chat_message', …, reason)` | hides the message (see the caveat in §3.2) |
| **Hide a prayer intention** | `public.hide_content('prayer_intention', …, reason)` | `is_hidden = true` |
| **Delete a post** | `public.admin_delete_post(p_post_id)` | delegates to A5's `soft_delete_feed_post` → `is_hidden = true, hidden_reason = 'admin_removed'` |
| **Remove a member** | A3's `public.remove_member(group_id, member_id)` | leaves the group |
| **Warn a member** | recorded in `moderation_actions` (`action_type = 'warn_user'`) | the warning is part of the audit trail |
| **Resolve a report** | `public.resolve_report(p_report_id, p_status, p_note)` | `status` ∈ `open`, `reviewing`, `actioned`, `dismissed` |
| **Review the trail** | `public.get_moderation_actions(p_group_id)` | every moderation action of the group, newest first |

Every action is written twice: once to `public.moderation_actions` (the
group-facing trail) and once to `public.audit_log` (the platform-wide,
append-only log). The two are complementary: `audit_log` survives the deletion
of the actor, `moderation_actions` is scoped to the group and carries the
report it answered.

### 3.1 "Hide" vs "Delete" — the difference

This distinction is deliberate and is the one the App Store reviewer cares
about.

| | **Hide** | **Delete** |
|---|---|---|
| What changes | the item disappears from every member's feed, chat and prayer wall | the item is soft-deleted: `is_hidden = true, hidden_reason = 'admin_removed'` |
| Is the row destroyed? | **No** | **No** — MassMates never hard-deletes user content |
| Who can still see it | the group administrators | the group administrators |
| Can it be restored? | Yes (`moderation_actions.action_type = 'restore_post'`) | Yes, by the administrator |
| Audit trail | `moderation_actions` + `audit_log` | `moderation_actions` + `audit_log` |
| When to use it | the content is inappropriate but the member may still be in good standing | the content is so harmful that the member must be removed as well |

"Delete" in the app is always a **soft delete** (`is_hidden = true`). No
administrator action in MassMates destroys a row: an audit trail that can be
erased is not an audit trail, and the account-deletion flow of A2 is the only
path that hard-deletes anything.

### 3.2 Caveat: chat messages

`public.chat_messages` (owned by A5) has **no `is_hidden` column**. The
`hide_content('chat_message', …)` RPC therefore records the moderation action
and the audit row, but the message itself cannot be hidden until A5 adds the
column (or a `soft_delete_chat_message` RPC). This is an open cross-domain
request, tracked by A6. Posts and prayer intentions are fully covered today.

---

## 4. Blocking

`public.block_user(p_blocked_id)` inserts a row in `public.user_blocks`
(A1's table, A6's RPCs). The block is:

* **symmetric** — `public.is_blocked(a, b)` is true in *both* directions, so the
  blocker also stops seeing the blocked user's content (no unilateral
  "watching" of someone you blocked);
* **idempotent** — a retry returns `{ "blocked": true, "created": false }` and
  does not create a second row;
* **rejecting of self-blocks** — the RPC raises `22023`;
* **immediate** — every read path in the app filters through `is_blocked`
  (feed, chat, prayer wall, witness photos, the blocked list).

`public.unblock_user(p_blocked_id)` removes the row and is idempotent too.

**Blocks are private.** A member sees only the blocks *they* placed
(`user_blocks_select_own`); they never learn that somebody blocked them.

---

## 5. Witness photos — the private bucket

The `witness-photos` bucket is the **only private bucket** in MassMates, and
the only place where a user-generated photo can be seen by a restricted group.

* **Path convention:** `witness-photos/<group_id>/<user_id>/<uuid>.<ext>`.
  The storage policies enforce the structure: the second segment must be the
  uploader and the caller must be a member of the group in the first segment.
* **Read:** only the members of that group, minus anyone blocked by the photo
  owner. **`anon` has no policy on this bucket at all** — not for read, not for
  write.
* **Access:** the client asks
  `public.create_signed_witness_url(p_object_path, p_expires_in)` (or the
  `signed-witness-url` Edge Function) for a **short-lived signed URL**. The TTL
  is clamped to **60–3600 seconds**; the request is rejected with `42501` when
  the caller is not a member of the group, and with `42501` when the caller is
  blocked by the photo owner.
* **Bucket limits:** 10 MB, `image/jpeg`, `image/png`, `image/heic`,
  `image/webp`.

The other two buckets, `avatars` (5 MB) and `group-covers` (8 MB), are public:
an avatar appears in a feed, and a group cover appears in a group card. They
accept the same four image types.

---

## 6. Retention policy for reports

| Data | Retained for | Why |
|---|---|---|
| `content_reports` (the report itself) | **24 months** after it is resolved (`resolved_at`), then purged by the platform's retention job | the group needs a record of what was reported; the details text is a free-text note about somebody else's content and must not be kept forever |
| `content_reports` (still `open` / `reviewing`) | indefinitely, until a moderator resolves it | an open report is a live case |
| `moderation_actions` | indefinitely (append-only) | the audit trail; a moderate amount of data, one row per action |
| `audit_log` | indefinitely (append-only) | the platform-wide trail; `actor_id` is deliberately **not** a foreign key so the trail survives the deletion of the actor |
| `user_blocks` | until the member unblocks, or until either account is deleted | a block is a live setting, not a record |
| `witness-photos` objects | until the owning member deletes them, or the group is deleted | the photo belongs to the member |

`content_reports.details` is the only free-text field in the moderation
tables and is capped at **500 characters**. The tables are deliberately
**not** used for analytics: no report text, no report reason and no moderation
note is ever used to personalise advertising (`profiles.ad_consent_analytics`
and `ad_personalization` are never derived from moderation data).

The automatic purge of resolved reports older than 24 months is **not yet
implemented** — it is a `pg_cron` job owned by A8/A10 (cron is installed and
verified working, see SCHEMA.md §6). Until that job exists, the tables grow
slowly and the cap can also be enforced manually.

---

## 7. Response times and escalation

* A group administrator is notified in-app of a new report in their group
  (notification delivery is A8's domain).
* MassMates does not operate a content moderation team for private, small
  groups: **the group administrator is the moderator of record**. The
  escalation path to the platform is the `service_role`, which can read every
  report (`content_reports_select_service`), resolve it and act on a user.
* `self_harm` is a report reason, not an automated feature. A report of
  `self_harm` is handled by the group administrator, who is a pastoral
  contact in a parish context; the platform does not attempt automated
  intervention.

---

## 8. Server-side summary

| Object | Kind | Purpose |
|---|---|---|
| `storage.buckets` · `avatars` | public bucket | profile pictures |
| `storage.buckets` · `group-covers` | public bucket | group cards |
| `storage.buckets` · `witness-photos` | **private** bucket | prayer witness photos |
| `public.content_reports` | table | the reports |
| `public.moderation_actions` | table | the moderation trail |
| `public.v_target_report_counts` | view | unresolved-report counter per target |
| `public.report_content(...)` | RPC | file a report (idempotent) |
| `public.hide_content(...)` | RPC | admin hides a post / chat message / intention |
| `public.admin_delete_post(...)` | RPC | admin soft-deletes a post |
| `public.resolve_report(...)` | RPC | admin closes a report |
| `public.get_moderation_queue(...)` | RPC | the admin's open-report list |
| `public.get_moderation_actions(...)` | RPC | the admin's audit trail |
| `public.block_user(...)` / `public.unblock_user(...)` / `public.list_blocked_users()` | RPCs | blocking |
| `public.create_signed_witness_url(...)` | RPC | authorises + returns the signed URL request for a private photo |
| `signed-witness-url` | Edge Function | signs the private photo with the service role (60–3600 s) |
