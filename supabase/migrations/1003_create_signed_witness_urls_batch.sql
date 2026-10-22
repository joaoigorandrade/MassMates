-- =============================================================================
-- 1003 · create_signed_witness_urls_batch
-- =============================================================================
-- Gap closure (A9 report): `public.create_signed_witness_url()` signs ONE
-- witness photo at a time, so a feed with N photos costs N round trips.
--
-- DESIGN
--   The batch RPC is the AUTHORISATION GATE for many paths at once. It calls
--   A6's EXISTING implementation -- `private.create_signed_witness_url_impl`
--   -- once per path, so the path regex, the group-membership check and the
--   block check are literally the same code as the single-URL RPC. There is
--   NO second copy of the path regex.
--
--   A path that fails its check NEVER fails the batch: it comes back with
--   `signed_url = null` and a `reason` that describes the caller's own
--   authorisation failure. The reason never reveals whether the object
--   exists.
--
--   On this deployment there is NO `storage.create_signed_url` helper, so the
--   RPC returns `signed_url = null` with `source = 'edge_function'` for an
--   AUTHORISED path (exactly like the single-URL RPC) and the
--   `signed-witness-url` Edge Function performs the actual signing.
--
-- CLAMPS
--   p_expires_in : 60..3600 seconds (identical to the single-URL RPC)
--   p_paths      : at most 50 paths; the extra ones are dropped and the
--                  answer carries `truncated: true`.
-- =============================================================================

create or replace function private.create_signed_witness_urls_impl (p_paths text[], p_expires_in integer default 300)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_uid      uuid := auth.uid ();
  v_expires  integer;
  v_max      constant integer := 50;
  v_requested integer;
  v_paths    text[];
  v_items    jsonb := '[]'::jsonb;
  v_one      jsonb;
  v_res      jsonb;
  v_reason   text;
  v_path     text;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  v_expires   := greatest (60, least (3600, coalesce (p_expires_in, 300)));
  v_requested := coalesce (cardinality (p_paths), 0);
  v_paths     := coalesce (p_paths, '{}'::text[]);

  if cardinality (v_paths) > v_max then
    v_paths := v_paths[1:v_max];
  end if;

  foreach v_path in array v_paths loop
    v_res    := null;
    v_reason := null;

    begin
      v_res := private.create_signed_witness_url_impl (v_path, v_expires);
    exception
      when others then
        v_res    := null;
        v_reason := sqlerrm;
    end;

    if v_res is null then
      v_one := jsonb_build_object (
        'path',        v_path,
        'signed_url',  null,
        'reason',      coalesce (v_reason, 'the witness photo path could not be authorised'),
        'authorized',  false,
        'source',      null,
        'object_path', null,
        'group_id',    null,
        'owner_id',    null,
        'expires_in',  v_expires
      );
    else
      v_one := jsonb_build_object (
        'path',        v_path,
        'signed_url',  v_res -> 'signed_url',
        'reason',      null,
        'authorized',  true,
        'source',      v_res -> 'source',
        'object_path', v_res -> 'object_path',
        'group_id',    v_res -> 'group_id',
        'owner_id',    v_res -> 'owner_id',
        'expires_in',  v_expires
      );
    end if;

    v_items := v_items || jsonb_build_array (v_one);
  end loop;

  return jsonb_build_object (
    'items',     v_items,
    'count',     jsonb_array_length (v_items),
    'requested', v_requested,
    'truncated', v_requested > v_max,
    'expires_in', v_expires
  );
end;
$$;

comment on function private.create_signed_witness_urls_impl (text[], integer) is
  'Implementation of public.create_signed_witness_urls(). Authorises MANY witness-photo paths with A6''s own private.create_signed_witness_url_impl(); a path that fails its check never fails the batch.';

create or replace function public.create_signed_witness_urls (p_paths text[], p_expires_in integer default 300)
  returns jsonb
  language plpgsql
  stable
  set search_path = ''
as $$
begin
  return private.create_signed_witness_urls_impl (p_paths, p_expires_in);
end;
$$;

comment on function public.create_signed_witness_urls (p_paths text[], p_expires_in integer) is
  'Authorises MANY witness-photo paths in ONE call. Every path goes through the SAME checks as public.create_signed_witness_url() (path shape, group membership, block). A path that fails comes back with signed_url = null and a reason; the batch never fails because of one bad path and the reason never reveals whether the object exists. p_expires_in is clamped to 60..3600 s; at most 50 paths are processed (the rest are dropped and `truncated` is true). Returns { items: [ { path, signed_url, reason, authorized, source, object_path, group_id, owner_id, expires_in } ], count, requested, truncated, expires_in }. On this deployment signed_url is null for an authorised path: the signed-witness-url Edge Function does the signing.';

revoke all on function private.create_signed_witness_urls_impl (text[], integer) from public, anon;
grant execute on function private.create_signed_witness_urls_impl (text[], integer) to authenticated, service_role;

revoke all on function public.create_signed_witness_urls (text[], integer) from public, anon;
grant execute on function public.create_signed_witness_urls (text[], integer) to authenticated, service_role;
