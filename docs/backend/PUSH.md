# MassMates — Push notifications

> **Owner: A8 (Guardian Angel & push notifications).** Migration prefix range `0700`–`0799`.
> Schema contract: [`supabase/SCHEMA.md`](../../supabase/SCHEMA.md) → *A8 additions*.
> Shared conventions: [`docs/backend/CONVENTIONS.md`](../../docs/backend/CONVENTIONS.md).

---

## 1. The shape of the system

```
       ┌──────────────────────┐   trigger / RPC    ┌──────────────────────────┐
       │  app tables          │ ─────────────────▶ │ public.notification_outbox│
       │  intention_prayers   │                    │  (transactional outbox)   │
       │  amen_reactions      │                    │  UNIQUE (dedupe_key)      │
       │  pinned_notices      │                    └───────────┬──────────────┘
       │  send_guardian_nudge │                                │ claim (SKIP LOCKED)
       └──────────────────────┘                                ▼
                                                        ┌──────────────────┐
   pg_cron (*/5 * * * *) ──pg_net──▶ Edge Function ────▶ │ APNs (HTTP/2)   │
                                     push-dispatch        └──────────────────┘
```

1. A **trigger** (or the `send_guardian_nudge` RPC) writes one row into
   `public.notification_outbox` **inside the same transaction** as the write
   that caused it. If the transaction rolls back, the notification is never
   queued. There is no dual-write and no lost notification.
2. `UNIQUE (dedupe_key)` makes the emission **idempotent**: the same event
   can never queue the same notification twice, no matter how many code paths
   reach it.
3. The **push-dispatch Edge Function** claims a batch of `pending` rows with
   `FOR UPDATE SKIP LOCKED` (so two dispatchers never claim the same row),
   resolves the recipient's active device tokens, signs an APNs provider
   token and POSTs to APNs.
4. Each row ends as `sent`, `failed` (permanent) or `pending` again with an
   exponential backoff.

**No client ever writes to the outbox.** There is no INSERT/UPDATE/DELETE
policy and no table privilege for `anon`/`authenticated`. A client may only
*read its own* rows.

---

## 2. Notification types and their pt-BR copy

| `notification_type` | Title | Body | Emitted by | Dedupe key |
|---|---|---|---|---|
| `prayed_for_you` | *Alguém rezou por você* | *Alguém rezou pela sua intenção de hoje.* | `trg_intention_prayers_notify` (A5's `emit_prayer_notification`) | `prayed:<intention_prayer_id>` |
| `amen` | *Alguém rezou contigo* / *Alguém rezou junto com você* | *«Nome» reagiu à sua partilha com um Amen.* / *«Nome» rezou junto com a sua partilha.* | `trg_amen_reactions_notify` | `amen:<amen_reaction_id>` |
| `guardian_nudge` | *Alguém rezou por você* | *Alguém rezou por você hoje.* | `public.send_guardian_nudge` | `nudge:<nudge_id>` |
| `pinned_notice` | *Novo aviso no grupo* | the notice body (max 300 chars) | `trg_pinned_notices_notify` | `pinned:<notice_id>:<member_id>` |
| `streak_milestone` | *reserved* | *reserved* | — (A4/A9 follow-up) | — |

> ### 🚫 Liturgical reminders are LOCAL-ONLY
> **This backend never pushes a liturgical reminder.** The Angelus, the
> Morning Offering, the Evening Examination of Conscience, the Rosary reminder
> and every other liturgical prompt are scheduled **on the device** (UNUser
> NotificationCenter), because they are a personal rhythm, not a social
> event — and because a sacred screen must never be interrupted by a server.
>
> The guarantee is enforced in the schema, not just in the code: the
> `notification_type` CHECK constraint of `public.notification_outbox` does
> **not** accept a liturgical value, so no outbox row for a liturgical day,
> a reading, a saint or a reminder can ever be created. The pgTAP suite
> asserts this (`supabase/tests/a8/push.sql`).
>
> The only things this backend pushes are **social** events between people:
> somebody prayed for you, somebody reacted to your post, somebody nudged
> you, the group posted a notice.

---

## 3. What a push may and may not contain (the privacy gate)

| Allowed in a push | Forbidden in a push |
|---|---|
| A display name of another **member** (the feed already shows it) | The content of a **private** check-in (`sharing = 'private'`) |
| The body of a **pinned notice** (a group announcement, admin authored) | A **Confession** record (date, confessor notes, penance) |
| The **group id** and the notification type | Any **Spiritual Diary** text |
| — | The **identity of a Guardian Angel** (see §6) |
| — | The **identity of the sender of a nudge** (see §6) |

Every trigger checks `public.is_blocked(recipient, sender)` first: **a blocked
pair never produces a notification** — in either direction, because
`is_blocked` is symmetric.

---

## 4. The cron schedule

| Job name | Schedule | What it does |
|---|---|---|
| `a8_pairing_weekly_fraternities` | `0 5 * * 1` | Monday 05:00 UTC — draws the Guardian Angel for every fraternity (the ISO week) |
| `a8_pairing_daily_challenges` | `0 6 * * *` | every day 06:00 UTC — draws the Guardian Angel for every **active** challenge |
| `a8_reveal_ended_cycles` | `15 6 * * *` | every day 06:15 UTC — reveals the Guardian identities of the cycles that have ended |
| `a8_push_dispatch` | `*/5 * * * *` | every 5 minutes — calls the `push-dispatch` Edge Function through `pg_net` |

The jobs live in `cron.job` and are **idempotent**: migration `0703`
unschedules each name before scheduling it, so re-running it never produces a
duplicate row.

`a8_push_dispatch` is a **no-op** until it is configured:

```sql
select public.dispatch_push_notifications ();
-- {"dispatched":false,"reason":"not_configured","hint":"set private.app_settings.push_dispatch_url"}
```

---

## 5. Operator configuration

### 5.1 The Edge Function secrets

```bash
supabase secrets set \
  APNS_KEY_ID=XXXXXXXXXX \
  APNS_TEAM_ID=YYYYYYYYYY \
  APNS_PRIVATE_KEY="$(cat AuthKey_XXXXXXXXXX.p8)" \
  APNS_TOPIC=joaoigor.MassMates \
  PUSH_DISPATCH_SECRET="$(openssl rand -hex 32)"
```

| Secret | Meaning |
|---|---|
| `APNS_KEY_ID` | the key id of the APNs auth key (the `.p8` file issued by Apple) |
| `APNS_TEAM_ID` | the Apple developer **team id** (the `iss` claim) |
| `APNS_PRIVATE_KEY` | the contents of the `.p8` file — a **PKCS#8 PEM** |
| `APNS_TOPIC` | the app bundle id, sent as the `apns-topic` header |
| `PUSH_DISPATCH_SECRET` | optional shared secret; lets `pg_cron` authenticate without the service-role key |

Optional sandbox overrides: `APNS_SANDBOX_KEY_ID`, `APNS_SANDBOX_TEAM_ID`,
`APNS_SANDBOX_PRIVATE_KEY` (a sandbox token is sent to
`api.sandbox.push.apple.com`).

> **Never** hard-code a secret: everything is read from `Deno.env`.

### 5.2 The database settings

The database never stores the service-role key. It stores the **URL** of the
Edge Function and the **shared secret** in `private.app_settings`:

```sql
insert into private.app_settings (key, value) values
  ('push_dispatch_url',
   'https://khovpljkitslmjmonizu.supabase.co/functions/v1/push-dispatch'),
  ('push_dispatch_secret', '<the same value as the PUSH_DISPATCH_SECRET secret>')
on conflict (key) do update set value = excluded.value, updated_at = now ();
```

`private.app_settings` has **no** policy for `anon`/`authenticated` and no
table privilege for them.

### 5.3 Who may call the Edge Function

`push-dispatch` is deployed with **`verify_jwt: false`** because its caller
is `pg_cron` (through `pg_net`) and the platform itself — neither can present
a Supabase user JWT. The function therefore **fails closed** and accepts
exactly one of:

* `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>` — the platform/admin;
* `x-push-secret: <PUSH_DISPATCH_SECRET>` — the `pg_cron` path.

Anything else gets `401 {"ok":false,"reason":"unauthorized"}`. The comparison
is length-checked and constant-time-ish; the secret is never logged.

> **Decision:** the app never triggers the dispatcher directly. The app only
> *queues* notifications (through the triggers and the RPCs); the server
> delivers them. This keeps the service-role key out of the mobile binary.

---

## 6. The anonymity guarantees

### The Guardian Angel identity

* The **guardian** sees the display name and the prayer intentions of the
  member it guards.
* The **protected** member sees that *somebody* is guarding it — **never** the
  guardian's name and **never** the guardian's id, until the cycle ends.
* There is **no client `SELECT` policy** on `public.guardian_angel_pairings`
  and the table privilege is revoked for `anon`/`authenticated`: no client
  can read `guardian_id` directly, at all. Every read goes through
  `public.my_guardian_assignment` / `public.guardian_angel_state`, which
  redact.
* `public.reveal_guardian_identities` (service_role only) sets `revealed_at`
  at the end of the cycle; the daily `a8_reveal_ended_cycles` job does it
  automatically for every cycle whose `cycle_ends_on` is in the past.

### The nudge

* The pushed body is *«Alguém rezou por você hoje.»* — it contains **no**
  name, **no** id and **no** hint about who sent it.
* The outbox payload carries only `{group_id, cycle_key}`.
* The `sender_id` column of `public.guardian_nudges` is **not** granted to
  `authenticated` at all, and the RLS policy only exposes the sender's own
  rows — the recipient reads **zero** rows.

---

## 7. The APNs provider token

The provider token is a JWS signed with **ES256** (ECDSA P-256 + SHA-256)
using the `.p8` key:

```
header  = { "alg": "ES256", "kid": "<APNS_KEY_ID>", "typ": "JWT" }
claims  = { "iss": "<APNS_TEAM_ID>", "iat": <unix seconds> }
signing = base64url(header) + "." + base64url(claims)
token   = signing + "." + base64url(signature)
```

The signature is produced with WebCrypto:

```ts
const key = await crypto.subtle.importKey(
  "pkcs8", pemToDer(pem),
  { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);

const raw = new Uint8Array(await crypto.subtle.sign(
  { name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(signing)));
```

`crypto.subtle.sign` returns the **raw** signature: `R || S`, 32 bytes each.

> ### ⚠️ Raw vs DER — the A8 brief was inverted, and this is why it matters
> The A8 brief asked for a "raw r||s → DER" conversion "because JWS ES256
> requires the DER form". **That premise is wrong.** RFC 7515 §3.4 and
> RFC 7518 §3.4 say the opposite: a JWS ECDSA signature is *the raw
> concatenation R || S*. DER (`SEQUENCE { INTEGER r, INTEGER s }`) is the
> OpenSSL / PKCS#1 encoding and is **not** what a JWS carries.
>
> Shipping the DER form would make **every** provider token invalid — APNs
> answers `InvalidProviderToken` and no push would ever be delivered.
>
> The conversion is nevertheless implemented and exported
> (`rawSignatureToDer` / `derSignatureToRaw` in
> `supabase/functions/push-dispatch/apns_crypto.ts`) and the encoding is a
> single switch, `JWS_SIGNATURE_ENCODING`, so a provider that ever demanded
> the OpenSSL form could be supported without touching the rest of the
> function. The default is `"raw"`, which is what APNs accepts.

The token is cached for **50 minutes** (APNs tokens are valid for one hour).

---

## 8. The HTTP/2 caveat — read this before trusting a green run

**APNs only speaks HTTP/2.** The Supabase Edge Runtime's `fetch` is built on
a client that negotiates **HTTP/1.1** in most deployments, so a request to
`api.push.apple.com` can fail at the transport layer even when the
credentials, the topic and the payload are perfect.

The function **does not fake a success**:

* a transport error is caught and reported as
  `apns_0:transport_error:<message>`;
* the outbox row is marked `failed` (or rescheduled with a backoff) with
  that real error;
* nothing is ever marked `sent` without a `200` from APNs.

**Recommendation for production.** In order of preference:

1. **A dedicated APNs sender service** (a small container or a managed
   queue consumer) that speaks HTTP/2 natively. The database keeps queueing
   into the outbox; the service drains it. This is the cleanest option: the
   Edge Runtime is then only a trigger, not a transport.
2. **An APNs provider that supports HTTP/1.1** (or a proxy that terminates
   HTTP/2 for the Edge Runtime).
3. Keep the Edge Function and accept that some notifications fail and are
   retried — acceptable only while the retry budget (5 attempts) lasts.

Whatever the option, the outbox makes the switch safe: rows that were not
delivered stay `pending`/`failed` and are retried by the next tick.

### APNs responses that the function handles

| APNs answer | What the function does |
|---|---|
| `200` | the row becomes `sent` (`sent_at = now()`) |
| `400 BadDeviceToken` | the `device_tokens` row is deactivated, the row fails |
| `410 Unregistered` | the `device_tokens` row is deactivated, the row fails |
| `429 TooManyRequests` | the row is rescheduled with the exponential backoff |
| `403` (auth) | the row fails loudly with the real reason; the batch stops |
| transport error | the row fails with `apns_0:transport_error:…` and is retried |

---

## 9. The retry budget

`public.complete_notification_outbox` owns the retry policy:

* `sent` → `status = 'sent'`, `sent_at = now()`;
* `failed` and `attempts < 5` → `status = 'pending'`,
  `scheduled_at = now() + 2^attempts minutes` (2, 4, 8, 16 minutes);
* `failed` and `attempts >= 5` → `status = 'failed'` (permanent), the real
  `last_error` is kept.

A user with **no active device token** gets `status = 'cancelled'`: nothing
to deliver to is not an error.

---

## 10. The server-side RPCs (service_role only)

```sql
public.claim_notification_outbox (p_limit integer default 50) returns setof jsonb
public.complete_notification_outbox (p_outbox_id uuid, p_status text,
                                     p_error text default null,
                                     p_retry_at timestamptz default null) returns jsonb
public.deactivate_device_token (p_token_id uuid) returns jsonb
public.dispatch_push_notifications () returns jsonb
```

`claim_notification_outbox` is the only correct way to claim a batch:

```sql
with claimed as (
  select o.id from public.notification_outbox o
   where o.status = 'pending' and o.scheduled_at <= now()
   order by o.scheduled_at, o.id
   limit greatest (1, least (coalesce (p_limit, 50), 500))
     for update skip locked
)
update public.notification_outbox o
   set status = 'processing', attempts = o.attempts + 1
  from claimed c where o.id = c.id
returning ...
```

`FOR UPDATE SKIP LOCKED` is what makes two concurrent dispatchers safe.
**Do not** claim with ad-hoc PostgREST filters — there is no row lock
there.

---

## 11. Client-facing RPCs

```sql
public.register_device_token (p_apns_token text, p_platform text default 'ios',
                               p_environment text default 'production',
                               p_app_version text default null) returns jsonb
```

* `UNIQUE (platform, apns_token)`: the same token is never stored twice.
  Re-registering it **moves** the row to the new user (a device that changed
  hands does not keep notifying the old owner).
* A client may also read/insert/update/delete its own `device_tokens` rows
  directly, but the RPC is the recommended path (it is the only one that can
  move a token to another user).

`public.notification_outbox` is **read-only** for clients, and only for the
user's own rows. The client grant omits `dedupe_key` and `last_error`.

---

## 12. Tests

| File | Assertions |
|---|---|
| `supabase/tests/a8/guardian_angel.sql` | 89 — the draw, the derangement, the anonymity, the nudge, the cron |
| `supabase/tests/a8/push.sql` | 55 — the device tokens, the outbox, the three triggers, the blocked-pair gate, the dispatch RPCs, the cron |

Both files are wrapped in `begin; … rollback;` and end with
`select public.pgtap_summary () as result;` — the verdict is
`{"verdict":"PASS","plan":N,"ran":N,"failed":0}`.
