-- =============================================================================
-- A2 · 0104 · account deletion (two-tap) — table, RLS, RPCs
-- =============================================================================
-- Owner: A2 (auth & account lifecycle).
--
-- FLOW
--   tap 1: public.request_account_deletion()  -> pending row + confirmation_token
--   tap 2: public.confirm_account_deletion(token) -> status = 'confirmed'
--   erase: Edge Function `delete-account` (service role) performs the hard delete.
--
-- The request row is the server-side proof that the user asked for the
-- deletion; the Edge Function refuses to delete anything without a confirmed,
-- unexpired row owned by the caller.
--
-- PRIVACY: this table holds NO confession, NO spiritual-diary text and NO
-- private check-in content. It holds only ids, timestamps and a status.
-- =============================================================================

create table public.account_deletion_requests (
  id                 uuid primary key default gen_random_uuid (),
  user_id            uuid not null references public.profiles (id) on delete cascade,
  confirmation_token uuid not null unique,
  requested_at       timestamptz not null default now (),
  confirmed_at       timestamptz,
  completed_at       timestamptz,
  status             text not null default 'pending'
                     check (status in ('pending', 'confirmed', 'completed', 'expired', 'cancelled')),
  expires_at         timestamptz not null default (now () + interval '15 minutes'),
  updated_at         timestamptz not null default now ()
);

comment on table public.account_deletion_requests is
  'Two-tap account deletion intents. A row proves that its owner asked for the deletion; the `delete-account` Edge Function performs the erasure. Holds ONLY ids, timestamps and a status — never Confession records, Spiritual Diary text or private check-in content (CONVENTIONS §8).';

comment on column public.account_deletion_requests.confirmation_token is
  'Random uuid handed to the owner only. Second tap of the two-tap deletion.';

comment on column public.account_deletion_requests.expires_at is
  'End of the 15-minute window in which the request can be confirmed and executed.';

-- Indexes: every foreign key needs one.
create index idx_account_deletion_requests_user_id
  on public.account_deletion_requests (user_id);

-- At most ONE live (pending or confirmed) request per user: the database-level
-- guarantee behind the idempotency of public.request_account_deletion().
create unique index idx_account_deletion_requests_live_user
  on public.account_deletion_requests (user_id)
  where status in ('pending', 'confirmed');

-- RLS: enabled AND forced.
alter table public.account_deletion_requests enable row level security;
alter table public.account_deletion_requests force  row level security;

create policy account_deletion_requests_select_own
  on public.account_deletion_requests
  for select
  to authenticated
  using (user_id = (select auth.uid ()));

create policy account_deletion_requests_insert_own
  on public.account_deletion_requests
  for insert
  to authenticated
  with check (user_id = (select auth.uid ()));

-- The owner may only move a request to 'confirmed' (with a confirmed_at) or
-- cancel it. 'completed' and 'expired' are server-side states.
create policy account_deletion_requests_update_own
  on public.account_deletion_requests
  for update
  to authenticated
  using (user_id = (select auth.uid ()))
  with check (
    user_id = (select auth.uid ())
    and status in ('confirmed', 'cancelled')
    and (status = 'cancelled' or confirmed_at is not null)
  );

-- No DELETE policy: requests are never deleted by a client.

select public.attach_updated_at ('public.account_deletion_requests'::regclass);

-- -----------------------------------------------------------------------------
-- private.request_account_deletion_impl()
-- -----------------------------------------------------------------------------
create or replace function private.request_account_deletion_impl ()
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := public.current_user_id ();
  v_row public.account_deletion_requests;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using
      errcode = '42501',
      hint = 'a signed-in user is required';
  end if;

  -- Expire the stale requests of this user first, so the partial unique index
  -- idx_account_deletion_requests_live_user cannot be violated below.
  update public.account_deletion_requests
     set status = 'expired'
   where user_id = v_uid
     and status in ('pending', 'confirmed')
     and expires_at <= now ();

  select * into v_row
    from public.account_deletion_requests
   where user_id = v_uid
     and status in ('pending', 'confirmed')
     and expires_at > now ()
   order by requested_at desc
   limit 1;

  if found then
    return jsonb_build_object (
      'id',                 v_row.id,
      'confirmation_token', v_row.confirmation_token,
      'requested_at',       v_row.requested_at,
      'expires_at',         v_row.expires_at,
      'status',             v_row.status,
      'created',            false
    );
  end if;

  begin
    insert into public.account_deletion_requests (user_id, confirmation_token)
    values (v_uid, pg_catalog.gen_random_uuid ())
    returning * into v_row;
  exception
    when unique_violation then
      -- Concurrent request: reuse the winner's row instead of failing.
      select * into v_row
        from public.account_deletion_requests
       where user_id = v_uid
         and status in ('pending', 'confirmed')
         and expires_at > now ()
       order by requested_at desc
       limit 1;
  end;

  if v_row.id is null then
    raise exception 'deletion_request_failed' using
      errcode = 'P0001',
      hint = 'could not create a deletion request';
  end if;

  insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
  values (
    v_uid,
    'account.delete_requested',
    'profile',
    v_uid,
    jsonb_build_object ('request_id', v_row.id)
  );

  return jsonb_build_object (
    'id',                 v_row.id,
    'confirmation_token', v_row.confirmation_token,
    'requested_at',       v_row.requested_at,
    'expires_at',         v_row.expires_at,
    'status',             v_row.status,
    'created',            true
  );
end;
$$;

comment on function private.request_account_deletion_impl () is
  'Implementation of public.request_account_deletion(): first tap of the two-tap deletion. Idempotent — an unexpired pending/confirmed request is returned as-is instead of creating a duplicate.';

-- -----------------------------------------------------------------------------
-- private.confirm_account_deletion_impl()
-- -----------------------------------------------------------------------------
create or replace function private.confirm_account_deletion_impl (p_token uuid)
  returns jsonb
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_uid uuid := public.current_user_id ();
  v_row public.account_deletion_requests;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using
      errcode = '42501',
      hint = 'a signed-in user is required';
  end if;

  if p_token is null then
    raise exception 'invalid_deletion_token' using
      errcode = '22023',
      hint = 'the confirmation token is required';
  end if;

  select * into v_row
    from public.account_deletion_requests
   where user_id = v_uid
     and confirmation_token = p_token;

  if not found then
    raise exception 'invalid_deletion_token' using
      errcode = '22023',
      hint = 'unknown confirmation token';
  end if;

  if v_row.status = 'expired' or (v_row.status in ('pending', 'confirmed') and v_row.expires_at <= now ()) then
    update public.account_deletion_requests
       set status = 'expired'
     where id = v_row.id;

    raise exception 'deletion_token_expired' using
      errcode = '22023',
      hint = 'the confirmation token has expired';
  end if;

  if v_row.status = 'confirmed' then
    -- Idempotent: the second tap already happened.
    return jsonb_build_object (
      'id',                 v_row.id,
      'confirmation_token', v_row.confirmation_token,
      'requested_at',       v_row.requested_at,
      'confirmed_at',       v_row.confirmed_at,
      'expires_at',         v_row.expires_at,
      'status',             v_row.status
    );
  end if;

  if v_row.status <> 'pending' then
    raise exception 'invalid_deletion_token' using
      errcode = '22023',
      hint = 'the confirmation token cannot be used';
  end if;

  update public.account_deletion_requests
     set status       = 'confirmed',
         confirmed_at = now ()
   where id = v_row.id
  returning * into v_row;

  insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
  values (
    v_uid,
    'account.delete_confirmed',
    'profile',
    v_uid,
    jsonb_build_object ('request_id', v_row.id)
  );

  return jsonb_build_object (
    'id',                 v_row.id,
    'confirmation_token', v_row.confirmation_token,
    'requested_at',       v_row.requested_at,
    'confirmed_at',       v_row.confirmed_at,
    'expires_at',         v_row.expires_at,
    'status',             v_row.status
  );
end;
$$;

comment on function private.confirm_account_deletion_impl (uuid) is
  'Implementation of public.confirm_account_deletion(): second tap of the two-tap deletion. The token must belong to the caller, be unexpired and still be pending.';

-- -----------------------------------------------------------------------------
-- Public wrappers — the only client-reachable surface
-- -----------------------------------------------------------------------------
create or replace function public.request_account_deletion ()
  returns jsonb
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  return private.request_account_deletion_impl ();
end;
$$;

comment on function public.request_account_deletion () is
  'First tap of the account deletion. Creates (or reuses) a pending deletion request and returns {id, confirmation_token, requested_at, expires_at, status, created}. The caller must then confirm the token and call the `delete-account` Edge Function.';

create or replace function public.confirm_account_deletion (p_token uuid)
  returns jsonb
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  return private.confirm_account_deletion_impl (p_token);
end;
$$;

comment on function public.confirm_account_deletion (uuid) is
  'Second tap of the account deletion. Confirms the request identified by p_token (the token must belong to the caller and be unexpired) and returns the confirmed request.';

-- Alias kept because the A2 brief names the intent `delete_my_account_request`.
-- It is the very same call as public.request_account_deletion().
create or replace function public.delete_my_account_request ()
  returns jsonb
  language plpgsql
  security invoker
  set search_path = ''
as $$
begin
  return private.request_account_deletion_impl ();
end;
$$;

comment on function public.delete_my_account_request () is
  'Alias of public.request_account_deletion() — first tap of the two-tap account deletion.';

-- -----------------------------------------------------------------------------
-- Privileges
-- -----------------------------------------------------------------------------
revoke execute on function public.request_account_deletion () from public, anon;
grant execute on function public.request_account_deletion () to authenticated, service_role;

revoke execute on function public.confirm_account_deletion (uuid) from public, anon;
grant execute on function public.confirm_account_deletion (uuid) to authenticated, service_role;

revoke execute on function public.delete_my_account_request () from public, anon;
grant execute on function public.delete_my_account_request () to authenticated, service_role;

grant execute on function private.request_account_deletion_impl () to authenticated, service_role;
grant execute on function private.confirm_account_deletion_impl (uuid) to authenticated, service_role;
