-- =============================================================================
-- A2 · 0102 · backfill profiles for auth users that predate the trigger
-- =============================================================================
-- Owner: A2. Idempotent: only auth.users rows without a profile are touched
-- and the insert is guarded with ON CONFLICT (id) DO NOTHING.
--
-- Privacy: this migration copies ONLY the profile columns that exist on
-- public.profiles. It never reads, copies or stores Confession records,
-- Spiritual Diary text or private check-in content (CONVENTIONS §8).
-- =============================================================================

insert into public.profiles (
  id, display_name, avatar_path, locale, timezone,
  ad_consent_analytics, ad_personalization, rule_of_life
)
select
  u.id,
  private.derive_display_name (coalesce(u.raw_user_meta_data, '{}'::jsonb), u.email),
  private.derive_avatar_path (coalesce(u.raw_user_meta_data, '{}'::jsonb)),
  private.derive_locale (coalesce(u.raw_user_meta_data, '{}'::jsonb)),
  private.derive_timezone (coalesce(u.raw_user_meta_data, '{}'::jsonb)),
  false,
  false,
  '[]'::jsonb
from auth.users u
where not exists (
  select 1 from public.profiles p where p.id = u.id
)
on conflict (id) do nothing;
