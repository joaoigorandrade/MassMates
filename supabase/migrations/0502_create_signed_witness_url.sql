-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022025220  ("create_signed_witness_url")
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
-- A6 · 0502 · signed witness-photo URL
-- =============================================================================
-- Owner: A6 (storage, moderation & safety).
--
-- `witness-photos` is a PRIVATE bucket (CONVENTIONS §8 — sacred-adjacent):
-- only the members of the group the photo was shared in may ever see it.
-- Reading it therefore requires a short-lived signed URL.
--
-- This project has NO `storage.create_signed_url` helper in the database
-- (verified against pg_proc — the storage schema only exposes helpers such as
-- storage.foldername / storage.search). The signer therefore lives in the
-- `signed-witness-url` Edge Function, which signs with the service role.
--
-- The RPC below is the AUTHORIZATION GATE:
--   1. the path must match the witness-photo path convention,
--   2. the caller must be a member of the group in the path,
--   3. the caller must not be blocked by the photo owner,
--   4. the TTL is clamped to 60..3600 seconds.
-- It returns the validated, clamped request. When a database-side signer is
-- available it also returns `signed_url`; otherwise `signed_url` is null and
-- `edge_function` names the function that must be called.
-- =============================================================================

create or replace function public.create_signed_witness_url (
  p_object_path text,
  p_expires_in  integer default 300
)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_raw     text;
  v_parts   text[];
  v_group   uuid;
  v_owner   uuid;
  v_file    text;
  v_caller  uuid := auth.uid();
  v_expires integer;
  v_signed  text;
  v_full    text;
  v_rel     text;
begin
  -- ---------------------------------------------------------------------------
  -- 0. caller + payload
  -- ---------------------------------------------------------------------------
  if v_caller is null then
    raise exception 'authentication required'
      using errcode = '42501';
  end if;

  if p_object_path is null or btrim(p_object_path) = '' then
    raise exception 'invalid witness photo path'
      using errcode = '22023';
  end if;

  v_expires := greatest(60, least(3600, coalesce(p_expires_in, 300)));

  v_raw   := btrim(p_object_path, '/');
  v_parts := string_to_array(v_raw, '/');

  -- ---------------------------------------------------------------------------
  -- 1. path shape. Both the bucket-qualified form
  --    (witness-photos/<group>/<user>/<file>, the public URL form) and the
  --    bucket-relative form (<group>/<user>/<file>, the storage.objects.name
  --    form) are accepted; nothing else is.
  -- ---------------------------------------------------------------------------
  if array_length(v_parts, 1) = 4 and v_parts[1] = 'witness-photos' then
    if v_raw !~ '^witness-photos/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|jpeg|png|heic|webp)$' then
      raise exception 'invalid witness photo path'
        using errcode = '22023';
    end if;
    v_group := private.try_uuid (v_parts[2]);
    v_owner := private.try_uuid (v_parts[3]);
    v_file  := v_parts[4];
  elsif array_length(v_parts, 1) = 3 then
    if v_raw !~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|jpeg|png|heic|webp)$' then
      raise exception 'invalid witness photo path'
        using errcode = '22023';
    end if;
    v_group := private.try_uuid (v_parts[1]);
    v_owner := private.try_uuid (v_parts[2]);
    v_file  := v_parts[3];
  else
    raise exception 'invalid witness photo path'
      using errcode = '22023';
  end if;

  if v_group is null or v_owner is null then
    raise exception 'invalid witness photo path'
      using errcode = '22023';
  end if;

  v_rel  := v_group::text || '/' || v_owner::text || '/' || v_file;
  v_full := 'witness-photos/' || v_rel;

  -- ---------------------------------------------------------------------------
  -- 2. the caller must be a member of the group the photo was shared in.
  -- ---------------------------------------------------------------------------
  if not public.is_group_member (v_group, v_caller) then
    raise exception 'not a member of the group that owns this photo'
      using errcode = '42501';
  end if;

  -- ---------------------------------------------------------------------------
  -- 3. a block (in either direction) hides the photo.
  -- ---------------------------------------------------------------------------
  if public.is_blocked (v_caller, v_owner) then
    raise exception 'blocked by the photo owner'
      using errcode = '42501';
  end if;

  -- ---------------------------------------------------------------------------
  -- 4. sign server-side when the deployment ships the SQL signer.
  -- ---------------------------------------------------------------------------
  if to_regprocedure ('storage.create_signed_url(text,integer)') is not null then
    begin
      execute format ('select (storage.create_signed_url(%L, %s)).signed_url', v_full, v_expires)
        into v_signed;
    exception
      when others then
        v_signed := null;
    end;

    if v_signed is null then
      begin
        execute format ('select (storage.create_signed_url(%L, %s)).signed_url', v_rel, v_expires)
          into v_signed;
      exception
        when others then
          v_signed := null;
      end;
    end;

    if v_signed is not null then
      return jsonb_build_object (
        'signed_url',  v_signed,
        'expires_in',  v_expires,
        'bucket_id',   'witness-photos',
        'object_path', v_rel,
        'group_id',    v_group,
        'owner_id',    v_owner,
        'source',      'database'
      );
    end if;
  end if;

  -- ---------------------------------------------------------------------------
  -- 5. fallback: the Edge Function signs with the service role.
  -- ---------------------------------------------------------------------------
  return jsonb_build_object (
    'signed_url',    null,
    'expires_in',    v_expires,
    'bucket_id',     'witness-photos',
    'object_path',   v_rel,
    'group_id',      v_group,
    'owner_id',      v_owner,
    'source',        'edge_function',
    'edge_function', 'signed-witness-url',
    'message',       'No database-side signer on this deployment: call the signed-witness-url Edge Function with the returned object_path and expires_in.'
  );
end;
$$;

revoke execute on function public.create_signed_witness_url (text, integer) from public, anon;
grant  execute on function public.create_signed_witness_url (text, integer) to authenticated, service_role;

comment on function public.create_signed_witness_url (text, integer) is
  'Authorizes the caller for a witness-photo path and returns a short-lived signed URL (TTL clamped to 60..3600s). Returns object_path/expires_in and edge_function=''signed-witness-url'' when the deployment has no database-side signer.';
