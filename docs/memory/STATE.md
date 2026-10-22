Current Focus: MassMates backend is complete and shipped — a Supabase schema with 40 RLS-forged tables, 71 migrations, 1948 passing pgTAP assertions, a zero-finding security advisor, and an iOS client wired to it over the first-party `Networking` package.
Completed:
- Schema `0001`–`1004`: auth, profiles, groups, 6-digit invites, slot rules, check-in engine, streaks/ring, feed, prayer wall, chat, moderation, storage, liturgical calendar, AdMob rewards, Guardian Angel, push outbox, security hardening, gap closure.
- Security: 0 advisor findings; every `SECURITY DEFINER` implementation lives in the non-exposed `private` schema behind `SECURITY INVOKER` wrappers; the 5 RLS helpers are caller-scoped (`is_group_member(uuid)`, `is_blocked(uuid)`), so no user can enumerate another user's memberships.
- Privacy: `check_ins` CHECK constraints reject any private check-in carrying reflection/photo and any confession shared to a group; a private check-in fans out nowhere; `witness-photos` is private with zero `anon` policies. Verified by `supabase/tests/a10/privacy.sql` (65 assertions) and the iOS `CheckInPrivacyTests`.
- iOS: `Core/Backend/` (20 files) over `Networking` only; all community protocols are `async throws`; the iOS test suite is 96 tests in 25 suites, green.
- Docs: `docs/backend/{API,AUTH_SETUP,MODERATION,LITURGICAL_CONTENT,PUSH}.md`, `supabase/SCHEMA.md` (3115 lines), `supabase/types/database.ts`, merged `docs/memory/DECISIONS.md`.
- `Networking` package extended with a WebSocket adapter (`98b7c52`) so Supabase Realtime works without `supabase-swift`.
Next Step: operator secrets and provider configuration (below); then wire the Today dashboard to `public.get_today_liturgy()` (still reading the local calendar) and add the AdMob SDK for the rewarded video.
Blockers/Quirks:
- NOT SET: `ADMOBSIGNING_KEY`, `PUSH_DISPATCH_SECRET`, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY`, `APNS_TOPIC`, and `private.app_settings.push_dispatch_url`. `admob-ssv` answers `signing_key_not_configured` and `push-dispatch` answers 401 — both fail closed, granting nothing.
- Apple/Google auth providers and the SMTP relay are unconfigured (dashboard-only; runbook `docs/backend/AUTH_SETUP.md`). No user JWT can be minted yet, so the Edge Function happy paths are unverified.
- APNs requires HTTP/2, which the Supabase Edge Runtime does not negotiate outbound; `push-dispatch` reports the real transport error and retries. A dedicated HTTP/2 sender is the production path (`docs/backend/PUSH.md`).
- `is_featured` is the only signal for the "Desafio em destaque" split, so a user-created challenge appears under "Fraternidades" — a product decision, not a bug.
- The AdMob SDK is not linked, so `RewardedAdCoordinator` uses `UnavailableRewardedAdPresenter`; the seam is unit-tested and swaps in once the SDK and app ID exist.
