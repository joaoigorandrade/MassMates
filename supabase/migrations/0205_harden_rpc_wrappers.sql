-- =============================================================================
-- A3 · 0205 · harden the exposed RPC wrappers
-- =============================================================================
-- The public RPCs created in 0202-0204 were first written as SECURITY DEFINER
-- pass-throughs. A `SECURITY DEFINER` function that lives in the exposed
-- `public` schema and is executable by `authenticated` is reported by the
-- Supabase security advisor (`authenticated_security_definer_function_executable`).
-- A1 left 5 such findings open on purpose (SCHEMA.md §3.2) and recommended the
-- fix: keep the privileged implementation in a schema PostgREST does not
-- expose and leave a thin, SECURITY INVOKER entry point in `public`.
--
-- This migration applies that pattern to every A3 RPC:
--   * `private.*_impl`  stays SECURITY DEFINER (the privileged work);
--   * `public.*`         becomes SECURITY INVOKER and only forwards to it;
--   * `authenticated` gets USAGE on `private` + EXECUTE on the impls, so the
--     wrapper can reach them; nothing else in `private` is executable.
--
-- The behaviour of every RPC is unchanged.
-- -----------------------------------------------------------------------------

drop function if exists private.probe (text);

grant usage on schema private to authenticated;

alter function public.create_group (text, text, public.group_type, public.scoring_mode, public.sharing_requirement, date, date, integer) security invoker;
alter function public.join_group_by_code (text) security invoker;
alter function public.join_featured_challenge (uuid) security invoker;
alter function public.reset_invite_code (uuid) security invoker;
alter function public.leave_group (uuid) security invoker;
alter function public.remove_member (uuid, uuid) security invoker;
alter function public.transfer_admin (uuid, uuid) security invoker;

grant execute on function private.create_group_impl (text, text, public.group_type, public.scoring_mode, public.sharing_requirement, date, date, integer) to authenticated;
grant execute on function private.join_group_impl (text) to authenticated;
grant execute on function private.join_featured_impl (uuid) to authenticated;
grant execute on function private.reset_invite_code_impl (uuid) to authenticated;
grant execute on function private.leave_group_impl (uuid) to authenticated;
grant execute on function private.remove_member_impl (uuid, uuid) to authenticated;
grant execute on function private.transfer_admin_impl (uuid, uuid) to authenticated;

-- the internal helpers stay owner-only
revoke execute on function private.generate_invite_code (integer) from public, anon, authenticated;
revoke execute on function private.slot_state (uuid) from public, anon, authenticated;
revoke execute on function private.assert_slot_available (uuid, public.group_type) from public, anon, authenticated;

comment on function public.create_group (text, text, public.group_type, public.scoring_mode, public.sharing_requirement, date, date, integer) is
  'Creates a group. Returns {"group": {...}, "invite_code": "123456"}. The creator becomes the admin and holds one slot (personal for a fraternity, seasonal for a challenge). SECURITY INVOKER pass-through to private.create_group_impl().';
