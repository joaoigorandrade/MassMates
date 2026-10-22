-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025010  ("create_storage_buckets")
-- The backend agents ran CONCURRENTLY, so the applied order does NOT follow
-- the prefix order (the prefix only records the author's ownership range).
-- The file is therefore NOT renamed -- it is already applied.
--
-- A clean replay in FILENAME order is safe: the only two forward references
-- in the whole chain are `to_regclass`-guarded on purpose
-- (0305 -> public.feed_posts, 0402 -> public.notification_outbox), so they
-- no-op until the table exists.
-- =============================================================================

-- =============================================================================
-- A6 · 0501 · storage buckets + storage.objects policies
-- =============================================================================
-- Owner: A6 (storage, moderation & safety).
--
-- Three buckets:
--   avatars        PUBLIC  5 MB  images only
--   group-covers   PUBLIC  8 MB  images only
--   witness-photos PRIVATE 10 MB images only  <-- sacred-adjacent, never public
--
-- Path conventions (the bucket id is NOT part of storage.objects.name):
--   avatars        <user_id>/<uuid>.jpg
--   group-covers   <group_id>/<uuid>.jpg
--   witness-photos <group_id>/<user_id>/<uuid>.jpg
--
-- CONVENTIONS §8 (sacred privacy): no bucket may hold Confession or Spiritual
-- Diary content. witness-photos holds prayer-witness photographs only and is
-- the ONLY private bucket; `anon` gets NO policy on it at all.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- private schema: helpers that must not be reachable as PostgREST RPCs.
-- -----------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;

-- Safe uuid cast: returns NULL instead of raising, so a malformed storage path
-- can never make a policy predicate blow up.
create or replace function private.try_uuid (p_text text)
  returns uuid
  language plpgsql
  immutable
as $$
begin
  return p_text::uuid;
exception
  when others then
    return null;
end;
$$;

revoke all on function private.try_uuid (text) from public;
grant execute on function private.try_uuid (text) to authenticated, service_role;

comment on function private.try_uuid (text) is
  'NULL-safe uuid cast used by storage policies: a malformed path segment must not raise.';

-- -----------------------------------------------------------------------------
-- Buckets
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars',        'avatars',        true,  5242880,  array['image/jpeg','image/png','image/heic','image/webp']),
  ('group-covers',   'group-covers',   true,  8388608,  array['image/jpeg','image/png','image/heic','image/webp']),
  ('witness-photos', 'witness-photos', false, 10485760, array['image/jpeg','image/png','image/heic','image/webp'])
on conflict (id) do update
   set public             = excluded.public,
       file_size_limit    = excluded.file_size_limit,
       allowed_mime_types = excluded.allowed_mime_types,
       updated_at         = now();

-- -----------------------------------------------------------------------------
-- avatars — public read, own-folder write
-- -----------------------------------------------------------------------------
create policy avatars_select_public
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'avatars');

create policy avatars_insert_own
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and owner_id = (select auth.uid())::text
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy avatars_update_own
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and owner_id = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and owner_id = (select auth.uid())::text
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy avatars_delete_own
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and owner_id = (select auth.uid())::text
  );

-- -----------------------------------------------------------------------------
-- group-covers — public read, group members write, group admins manage
-- -----------------------------------------------------------------------------
create policy group_covers_select_public
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'group-covers');

create policy group_covers_insert_member
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'group-covers'
    and public.is_group_member (
          private.try_uuid ((storage.foldername(name))[1]),
          (select auth.uid())
        )
  );

create policy group_covers_update_admin
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'group-covers'
    and public.is_group_admin (
          private.try_uuid ((storage.foldername(name))[1]),
          (select auth.uid())
        )
  )
  with check (
    bucket_id = 'group-covers'
    and public.is_group_admin (
          private.try_uuid ((storage.foldername(name))[1]),
          (select auth.uid())
        )
  );

create policy group_covers_delete_admin
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'group-covers'
    and public.is_group_admin (
          private.try_uuid ((storage.foldername(name))[1]),
          (select auth.uid())
        )
  );

-- -----------------------------------------------------------------------------
-- witness-photos — PRIVATE.
--   * NO anon policy at all (neither select nor insert nor update nor delete).
--   * read   : members of the group in the path, minus anyone blocked by the
--              photo owner (a block hides both directions).
--   * insert : the path's own user segment must be the caller AND the caller
--              must be a member of the path's group.
--   * delete : the owner of the object or an admin of the group.
-- -----------------------------------------------------------------------------
create policy witness_photos_select_members
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'witness-photos'
    and public.is_group_member (
          private.try_uuid ((storage.foldername(name))[1]),
          (select auth.uid())
        )
    and not public.is_blocked (
          (select auth.uid()),
          private.try_uuid ((storage.foldername(name))[2])
        )
  );

create policy witness_photos_insert_owner
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'witness-photos'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and public.is_group_member (
          private.try_uuid ((storage.foldername(name))[1]),
          (select auth.uid())
        )
  );

create policy witness_photos_update_owner
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'witness-photos'
    and owner_id = (select auth.uid())::text
  )
  with check (
    bucket_id = 'witness-photos'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

create policy witness_photos_delete_owner_or_admin
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'witness-photos'
    and (
      owner_id = (select auth.uid())::text
      or public.is_group_admin (
            private.try_uuid ((storage.foldername(name))[1]),
            (select auth.uid())
          )
    )
  );
