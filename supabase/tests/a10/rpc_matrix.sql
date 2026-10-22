-- =============================================================================
-- A10 · rpc_matrix.sql · the RPC surface matrix
-- =============================================================================
-- Remote invocation procedure: supabase/tests/README.md
--
-- The file MUST end with:
--   select * from finish ();
--   select public.pgtap_summary () as result;   -- always the last result set
--   rollback;
--
-- WHAT IT PROVES
--   A. the privilege matrix of the WHOLE public RPC surface
--        * `anon` may execute EXACTLY the four documented public endpoints
--        * `authenticated` may execute the documented client RPCs
--        * the server-only RPCs are reachable by `service_role` alone
--        * NO public function is SECURITY DEFINER + executable by
--          `authenticated` (the lint that migration 0901 closed)
--   B. the non-member error contract: the exact SQLSTATE and message
--   C. the happy-path shape of every RPC the client calls, cross-checked
--      against supabase/SCHEMA.md
--
--   Fixture
--     u1 Ana    c1000000-0000-0000-0000-000000000001  admin  of G1
--     u2 Bruno  c1000000-0000-0000-0000-000000000002  member of G1
--     u3 Carla  c1000000-0000-0000-0000-000000000003  outsider (no group)
--     G1       c1000000-0000-0000-0000-000000000101  'A10 RPC Main'
-- =============================================================================

begin;
set local search_path = extensions, public;

select plan(96);

-- -----------------------------------------------------------------------------
-- A. The privilege matrix
-- -----------------------------------------------------------------------------

select is ((select string_agg (p.proname || '(' || pg_get_function_identity_arguments (p.oid) || ')', ',' order by p.proname)
            from pg_catalog.pg_proc p
            join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public'
              and p.prorettype <> 'trigger'::regtype
              and p.proname not like 'pgtap\_%'
              and has_function_privilege ('anon', p.oid, 'execute')),
           'get_liturgical_calendar(p_year integer),get_today_liturgy(),list_featured_challenges(),preview_group_by_code(p_code text)',
           'anon may execute EXACTLY the four documented public endpoints');

select ok (not exists (
         select 1 from pg_catalog.pg_proc p
         join pg_catalog.pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public'
           and p.prorettype <> 'trigger'::regtype
           and p.prosecdef
           and has_function_privilege ('authenticated', p.oid, 'execute')),
       'NO public function is SECURITY DEFINER and executable by authenticated');

select is ((select string_agg (p.proname || '(' || pg_get_function_identity_arguments (p.oid) || ')', ',' order by p.proname)
            from pg_catalog.pg_proc p
            join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public'
              and p.prorettype <> 'trigger'::regtype
              and p.proname not like 'pgtap\_%'
              and not has_function_privilege ('authenticated', p.oid, 'execute')
              and not has_function_privilege ('anon', p.oid, 'execute')),
           'attach_updated_at(p_table regclass),claim_notification_outbox(p_limit integer),complete_notification_outbox(p_outbox_id uuid, p_status text, p_error text, p_retry_at timestamp with time zone),deactivate_device_token(p_token_id uuid),dispatch_push_notifications(),emit_prayer_notification(p_intention_id uuid, p_prayer_id uuid),grant_reward(p_user_id uuid, p_reward_type text, p_source text, p_transaction_id text, p_expires_days integer, p_metadata jsonb),grant_slot_unlock(p_user_id uuid, p_kind text, p_source text, p_days integer, p_notes text),grant_streak_mercy(p_user_id uuid, p_expires_at timestamp with time zone),insert_feed_post(p_check_in_id uuid, p_group_id uuid, p_user_id uuid, p_practice_kind practice_kind, p_reflection_text text, p_photo_path text, p_points integer),probe_wrapper(p_a text),reveal_guardian_identities(p_group_id uuid),run_guardian_angel_pairing(p_group_id uuid, p_cycle_key text, p_cycle_starts_on date),set_featured_group(p_group_id uuid, p_is_featured boolean, p_starts_on date, p_ends_on date, p_display_order integer),sweep_guardian_angel_pairings(p_scope text),sweep_reveal_guardian_identities()',
           'the server-only RPCs are reachable by service_role alone');

select is ((select string_agg (p.proname || '(' || pg_get_function_identity_arguments (p.oid) || ')', ',' order by p.proname)
            from pg_catalog.pg_proc p
            join pg_catalog.pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public'
              and p.prorettype <> 'trigger'::regtype
              and p.proname not like 'pgtap\_%'
              and has_function_privilege ('service_role', p.oid, 'execute')
              and not has_function_privilege ('authenticated', p.oid, 'execute')
              and not has_function_privilege ('anon', p.oid, 'execute')),
           'claim_notification_outbox(p_limit integer),complete_notification_outbox(p_outbox_id uuid, p_status text, p_error text, p_retry_at timestamp with time zone),deactivate_device_token(p_token_id uuid),dispatch_push_notifications(),emit_prayer_notification(p_intention_id uuid, p_prayer_id uuid),grant_reward(p_user_id uuid, p_reward_type text, p_source text, p_transaction_id text, p_expires_days integer, p_metadata jsonb),grant_slot_unlock(p_user_id uuid, p_kind text, p_source text, p_days integer, p_notes text),grant_streak_mercy(p_user_id uuid, p_expires_at timestamp with time zone),insert_feed_post(p_check_in_id uuid, p_group_id uuid, p_user_id uuid, p_practice_kind practice_kind, p_reflection_text text, p_photo_path text, p_points integer),probe_wrapper(p_a text),reveal_guardian_identities(p_group_id uuid),run_guardian_angel_pairing(p_group_id uuid, p_cycle_key text, p_cycle_starts_on date),set_featured_group(p_group_id uuid, p_is_featured boolean, p_starts_on date, p_ends_on date, p_display_order integer),sweep_guardian_angel_pairings(p_scope text),sweep_reveal_guardian_identities()',
           'service_role keeps EXECUTE on every server-only RPC');

select ok (not exists (
         select 1 from pg_catalog.pg_proc p
         join pg_catalog.pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'private'
           and has_function_privilege ('anon', p.oid, 'execute')),
       'anon may not execute any function of the private schema');

select ok (not has_schema_privilege ('anon', 'private', 'usage'),
           'anon has no USAGE on the private schema');

-- The A3 preview seam (fixed by migration 0903): it used to fail for every
-- SIGNED-IN user with "permission denied for schema a3_preview".
insert into auth.users (id, email, aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('c1000000-0000-0000-0000-000000000001', 'a10_rpc_ana@example.test',   'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('c1000000-0000-0000-0000-000000000002', 'a10_rpc_bruno@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('c1000000-0000-0000-0000-000000000003', 'a10_rpc_carla@example.test', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('c1000000-0000-0000-0000-000000000004', 'a10_rpc_daniel@example.test','authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('c1000000-0000-0000-0000-000000000005', 'a10_rpc_eva@example.test',  'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.groups (id, name, created_by, invite_code)
values ('c1000000-0000-0000-0000-000000000101', 'A10 RPC Main', 'c1000000-0000-0000-0000-000000000001', '654321');

insert into public.group_invites (group_id, code, created_by)
values ('c1000000-0000-0000-0000-000000000101', '654321', 'c1000000-0000-0000-0000-000000000001');

insert into public.group_members (group_id, user_id, role)
values
  ('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000001', 'admin'),
  ('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000002', 'member'),
  ('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000004', 'member'),
  ('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000005', 'member');

insert into public.check_ins (id, user_id, practice_kind, sharing, local_date, timezone, reflection_text)
values ('c1000000-0000-0000-0000-000000000201', 'c1000000-0000-0000-0000-000000000002',
        'rosary', 'group', current_date, 'America/Sao_Paulo', 'a10 rpc reflection');

insert into public.check_in_destinations (check_in_id, group_id)
values ('c1000000-0000-0000-0000-000000000201', 'c1000000-0000-0000-0000-000000000101');

-- A second post with a KNOWN id: A4's fan-out trigger mints a random id, and
-- the moderation RPCs below need a target that exists for every persona.
insert into public.feed_posts (id, group_id, user_id, practice_kind, reflection_text)
values ('c1000000-0000-0000-0000-000000000202', 'c1000000-0000-0000-0000-000000000101',
        'c1000000-0000-0000-0000-000000000002', 'rosary', 'a10 rpc post');

insert into public.prayer_intentions (id, group_id, user_id, body)
values ('c1000000-0000-0000-0000-000000000203', 'c1000000-0000-0000-0000-000000000101',
        'c1000000-0000-0000-0000-000000000002', 'a10 rpc intention');

insert into public.chat_messages (id, group_id, user_id, body)
values ('c1000000-0000-0000-0000-000000000204', 'c1000000-0000-0000-0000-000000000101',
        'c1000000-0000-0000-0000-000000000002', 'a10 rpc chat');

insert into public.pinned_notices (group_id, author_id, body)
values ('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000001', 'a10 rpc notice');

create function pg_temp.keys (j jsonb)
returns text language sql stable as $$
  select coalesce (string_agg (k, ',' order by k), '') from jsonb_object_keys (j) k;
$$;

-- -----------------------------------------------------------------------------
-- B. The NON-MEMBER error contract (u3 is not in the group)
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000003","role":"authenticated"}';

select throws_ok ($$select public.get_feed_posts('c1000000-0000-0000-0000-000000000101')$$,
                  '42501', 'not a member of this group',
                  'RPC: get_feed_posts rejects a non-member');
select throws_ok ($$select public.get_chat_messages('c1000000-0000-0000-0000-000000000101')$$,
                  '42501', 'not a member of this group',
                  'RPC: get_chat_messages rejects a non-member');
select throws_ok ($$select public.get_prayer_intentions('c1000000-0000-0000-0000-000000000101')$$,
                  '42501', 'not a member of this group',
                  'RPC: get_prayer_intentions rejects a non-member');
select throws_ok ($$select public.create_chat_message('c1000000-0000-0000-0000-000000000101', 'hello')$$,
                  '42501', 'not a member of this group',
                  'RPC: create_chat_message rejects a non-member');
select throws_ok ($$select public.create_prayer_intention('c1000000-0000-0000-0000-000000000101', 'pray')$$,
                  '42501', 'not a member of this group',
                  'RPC: create_prayer_intention rejects a non-member');
select throws_ok ($$select public.get_group_progress('c1000000-0000-0000-0000-000000000101')$$,
                  '42501', 'not_a_group_member',
                  'RPC: get_group_progress rejects a non-member');
select throws_ok ($$select public.submit_check_in('rosary', 'group', array['c1000000-0000-0000-0000-000000000101']::uuid[], null, null, current_date, 'UTC')$$,
                  '42501', 'not_a_group_member',
                  'RPC: submit_check_in rejects a non-member');
select throws_ok ($$select public.set_practice_points('c1000000-0000-0000-0000-000000000101', 'rosary', 5)$$,
                  '42501', 'not_a_group_admin',
                  'RPC: set_practice_points rejects a non-admin');
select throws_ok ($$select public.get_moderation_queue('c1000000-0000-0000-0000-000000000101')$$,
                  '42501', 'only a group administrator can read the moderation queue',
                  'RPC: get_moderation_queue rejects a non-admin');
select throws_ok ($$select public.get_moderation_actions('c1000000-0000-0000-0000-000000000101')$$,
                  '42501', 'only a group administrator can read the moderation trail',
                  'RPC: get_moderation_actions rejects a non-admin');
select throws_ok ($$select public.set_pinned_notice('c1000000-0000-0000-0000-000000000101', 'n')$$,
                  '42501', 'only a group admin can pin a notice',
                  'RPC: set_pinned_notice rejects a non-admin');
select throws_ok ($$select public.clear_pinned_notice('c1000000-0000-0000-0000-000000000101')$$,
                  '42501', 'only a group admin can clear a notice',
                  'RPC: clear_pinned_notice rejects a non-admin');
select throws_ok ($$select public.leave_group('c1000000-0000-0000-0000-000000000101')$$,
                  'P0002', 'you are not a member of this group',
                  'RPC: leave_group rejects a non-member');
select throws_ok ($$select public.remove_member('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000001')$$,
                  '42501', 'only a group admin can remove a member',
                  'RPC: remove_member rejects a non-admin');
select throws_ok ($$select public.transfer_admin('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000001')$$,
                  '42501', 'only a group admin can transfer the admin role',
                  'RPC: transfer_admin rejects a non-admin');
select throws_ok ($$select public.reset_invite_code('c1000000-0000-0000-0000-000000000101')$$,
                  '42501', 'only a group admin can reset the invite code',
                  'RPC: reset_invite_code rejects a non-admin');
select throws_ok ($$select public.admin_delete_post('c1000000-0000-0000-0000-000000000202')$$,
                  '42501', 'only a group administrator can delete a post',
                  'RPC: admin_delete_post rejects a non-admin');
select throws_ok ($$select public.soft_delete_feed_post('c1000000-0000-0000-0000-000000000202')$$,
                  '42501', 'only a group admin can remove a post',
                  'RPC: soft_delete_feed_post rejects a non-admin');
select throws_ok ($$select public.soft_delete_chat_message('c1000000-0000-0000-0000-000000000204')$$,
                  '42501', 'only a group admin can remove a message',
                  'RPC: soft_delete_chat_message rejects a non-admin');
select throws_ok ($$select public.hide_content('post', 'c1000000-0000-0000-0000-000000000202', 'reason')$$,
                  '42501', 'only a group administrator can hide content',
                  'RPC: hide_content rejects a non-admin');
select throws_ok ($$select public.report_content('post', 'c1000000-0000-0000-0000-000000000202', 'spam', null, null)$$,
                  '42501', 'you can only report content inside your own groups',
                  'RPC: report_content rejects a non-member');
select throws_ok ($$select public.toggle_amen('c1000000-0000-0000-0000-000000000202')$$,
                  '42501', 'post not available',
                  'RPC: toggle_amen rejects a non-member');
select throws_ok ($$select public.toggle_prayed_for('c1000000-0000-0000-0000-000000000203')$$,
                  '42501', 'intention not available',
                  'RPC: toggle_prayed_for rejects a non-member');

-- The A3 preview seam must work for a signed-in user (migration 0903).
select is (pg_temp.keys (public.preview_group_by_code ('654321')),
           'cover_path,description_preview,ends_on,goal_target,group_type,id,is_featured,member_count,name,scoring_mode,sharing_requirement,starts_on',
           'RPC: preview_group_by_code works for a signed-in user');
select ok (public.list_featured_challenges () is not null,
           'RPC: list_featured_challenges works for a signed-in user');

-- -----------------------------------------------------------------------------
-- C. The happy path (as the group member u2)
-- -----------------------------------------------------------------------------

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000002","role":"authenticated"}';

select is (pg_temp.keys (public.get_my_profile ()),
           'ad_consent_analytics,ad_personalization,avatar_path,city,created_at,deleted_at,display_name,guardian_angel_opt_in,id,locale,parish,rule_of_life,timezone,updated_at',
           'RPC: get_my_profile shape');
select is ((public.get_my_profile () ->> 'id'), 'c1000000-0000-0000-0000-000000000002',
           'RPC: get_my_profile returns the caller');

select is (pg_temp.keys (public.get_streak_summary ()),
           'current_streak,last_practice_date,longest_streak,mercy_available,mercy_used_this_month,total_practices',
           'RPC: get_streak_summary shape');
select is (pg_temp.keys (public.get_rule_of_life_ring (current_date)),
           'completed,items,local_date,percentage,total',
           'RPC: get_rule_of_life_ring shape');
select is (pg_temp.keys (public.get_group_progress ('c1000000-0000-0000-0000-000000000101')),
           'active_today_count,goal_current,goal_target,group_id,member_count,per_member,percentage,scoring_mode',
           'RPC: get_group_progress shape');

select is (pg_temp.keys (public.get_feed_posts ('c1000000-0000-0000-0000-000000000101')),
           'items,next_cursor',
           'RPC: get_feed_posts shape');
select is (pg_temp.keys ((public.get_feed_posts ('c1000000-0000-0000-0000-000000000101') -> 'items' -> 0)),
           'amens,check_in_id,created_at,group_id,id,my_reactions,photo_path,points,practice_kind,reflection_text,united_in_prayer,user_id',
           'RPC: get_feed_posts item shape');
select is (pg_temp.keys (public.get_prayer_intentions ('c1000000-0000-0000-0000-000000000101')),
           'items,next_cursor',
           'RPC: get_prayer_intentions shape');
select is (pg_temp.keys ((public.get_prayer_intentions ('c1000000-0000-0000-0000-000000000101') -> 'items' -> 0)),
           'body,created_at,group_id,id,prayed,prayer_count,user_id',
           'RPC: get_prayer_intentions item shape');
select is (pg_temp.keys (public.get_chat_messages ('c1000000-0000-0000-0000-000000000101')),
           'items,next_cursor',
           'RPC: get_chat_messages shape');
select is (pg_temp.keys ((public.get_chat_messages ('c1000000-0000-0000-0000-000000000101') -> 'items' -> 0)),
           'body,created_at,group_id,id,reply_to_id,user_id',
           'RPC: get_chat_messages item shape');

select is (pg_temp.keys (public.create_chat_message ('c1000000-0000-0000-0000-000000000101', 'hello')),
           'body,created_at,group_id,id,reply_to_id,user_id',
           'RPC: create_chat_message shape');
select is (pg_temp.keys (public.create_prayer_intention ('c1000000-0000-0000-0000-000000000101', 'pray')),
           'body,created_at,group_id,id,prayer_count,user_id',
           'RPC: create_prayer_intention shape');
select is (pg_temp.keys (public.toggle_amen ('c1000000-0000-0000-0000-000000000202')),
           'amens,reacted,united_in_prayer',
           'RPC: toggle_amen shape');
select is (pg_temp.keys (public.toggle_prayed_for ('c1000000-0000-0000-0000-000000000203')),
           'prayed,prayer_count',
           'RPC: toggle_prayed_for shape');

select is (pg_temp.keys (public.my_group_slots ()),
           'bonus_active,bonus_expires_at,personal_available,personal_max,personal_used,seasonal_available,seasonal_max,seasonal_used',
           'RPC: my_group_slots shape');
select is (pg_temp.keys (public.list_blocked_users ()),
           'blocked_users,count',
           'RPC: list_blocked_users shape');
select is (pg_temp.keys (public.block_user ('c1000000-0000-0000-0000-000000000003')),
           'blocked,blocked_id,created',
           'RPC: block_user shape');
select is (pg_temp.keys (public.unblock_user ('c1000000-0000-0000-0000-000000000003')),
           'blocked,blocked_id,removed',
           'RPC: unblock_user shape');
select is (pg_temp.keys (public.report_content ('post', 'c1000000-0000-0000-0000-000000000202', 'spam', null, null)),
           'auto_hidden,duplicate,group_id,report_count,report_id,status',
           'RPC: report_content shape');
select is (pg_temp.keys (public.get_my_profile ()),
           'ad_consent_analytics,ad_personalization,avatar_path,city,created_at,deleted_at,display_name,guardian_angel_opt_in,id,locale,parish,rule_of_life,timezone,updated_at',
           'RPC: get_my_profile shape is stable');

select is (pg_temp.keys (public.submit_check_in ('rosary', 'private', '{}'::uuid[], null, null, current_date - 1, 'UTC')),
           'check_in_id,destinations,ring,streak',
           'RPC: submit_check_in shape');
select is (pg_temp.keys (public.submit_check_in ('adoration', 'private', '{}'::uuid[], null, null, current_date - 2, 'UTC') -> 'ring'),
           'completed,items,percentage,total',
           'RPC: submit_check_in ring shape');
select is (pg_temp.keys (public.submit_check_in ('daily_gospel', 'private', '{}'::uuid[], null, null, current_date - 3, 'UTC') -> 'streak'),
           'current,last_practice_date,longest',
           'RPC: submit_check_in streak shape');

select ok ((select count(*) from jsonb_object_keys (public.get_consistency_heatmap (current_date - 3, current_date)) k) between 1 and 4,
           'RPC: get_consistency_heatmap returns a plain map keyed by local date');
select ok (not exists (select 1 from jsonb_object_keys (public.get_consistency_heatmap (current_date - 3, current_date)) k where k !~ '^\d{4}-\d{2}-\d{2}$'),
           'RPC: get_consistency_heatmap keys are ISO dates');

select is (pg_temp.keys (public.get_today_liturgy ()),
           'date,day,readings,saints',
           'RPC: get_today_liturgy shape');
select is (pg_temp.keys (public.get_liturgical_calendar (2026)), 'count,days,year',
           'RPC: get_liturgical_calendar shape');
select ok (jsonb_typeof (public.get_liturgical_calendar (2026) -> 'days') = 'array',
           'RPC: get_liturgical_calendar returns a days array');
select is (pg_temp.keys (public.my_rewards ()),
           'grants',
           'RPC: my_rewards shape');
select is (pg_temp.keys (public.guardian_angel_state ('c1000000-0000-0000-0000-000000000101')),
           'can_nudge,cycle_ends_on,group_id,is_guardian,is_protected,nudges_today,opted_in',
           'RPC: guardian_angel_state shape');
select is (pg_temp.keys (public.my_guardian_assignment ('c1000000-0000-0000-0000-000000000101')),
           'can_nudge,cycle_ends_on,cycle_key,cycle_starts_on,guardian_display_name,is_guardian,is_protected,nudges_today,protected_display_name,protected_intentions,revealed',
           'RPC: my_guardian_assignment shape');

-- the self-scoped RLS helpers
select is (public.is_group_member ('c1000000-0000-0000-0000-000000000101'), true,
           'RPC: is_group_member is true for the caller');
select is (public.is_group_member ('c1000000-0000-0000-0000-000000000199'), false,
           'RPC: is_group_member is false for a group the caller is not in');
select is (public.is_group_admin ('c1000000-0000-0000-0000-000000000101'), false,
           'RPC: is_group_admin is false for a plain member');
select is (public.is_blocked ('c1000000-0000-0000-0000-000000000003'), false,
           'RPC: is_blocked is false for an unrelated user');
select is (public.is_group_member_of_any (), true,
           'RPC: is_group_member_of_any is true for a member');
select is (public.is_any_group_admin (), false,
           'RPC: is_any_group_admin is false for a plain member');

reset role;

-- -----------------------------------------------------------------------------
-- D. The admin path (as u1, the group admin)
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is (public.is_group_admin ('c1000000-0000-0000-0000-000000000101'), true,
           'RPC: is_group_admin is true for the group admin');
select is (public.is_any_group_admin (), true,
           'RPC: is_any_group_admin is true for a group admin');

select is (pg_temp.keys (public.set_pinned_notice ('c1000000-0000-0000-0000-000000000101', 'a10 pinned')),
           'author_id,body,created_at,group_id,id,is_active,replaced',
           'RPC: set_pinned_notice shape');
select is (pg_temp.keys (public.clear_pinned_notice ('c1000000-0000-0000-0000-000000000101')),
           'cleared,group_id',
           'RPC: clear_pinned_notice shape');
select is (pg_temp.keys (public.get_moderation_queue ('c1000000-0000-0000-0000-000000000101')),
           'count,group_id,reports',
           'RPC: get_moderation_queue shape');
select is (pg_temp.keys (public.get_moderation_actions ('c1000000-0000-0000-0000-000000000101')),
           'actions,count,group_id',
           'RPC: get_moderation_actions shape');
select is (pg_temp.keys (public.hide_content ('post', 'c1000000-0000-0000-0000-000000000202', 'a10 reason')),
           'action_type,group_id,hidden,target_id',
           'RPC: hide_content shape');
select is (pg_temp.keys (public.soft_delete_feed_post ('c1000000-0000-0000-0000-000000000202')),
           'changed,group_id,hidden,hidden_reason,post_id',
           'RPC: soft_delete_feed_post shape');
select is (pg_temp.keys (public.soft_delete_chat_message ('c1000000-0000-0000-0000-000000000204')),
           'changed,group_id,hidden,hidden_at,hidden_reason,message_id',
           'RPC: soft_delete_chat_message shape');
select is (pg_temp.keys (public.admin_delete_post ('c1000000-0000-0000-0000-000000000202')),
           'deleted,detail,group_id,post_id',
           'RPC: admin_delete_post shape');
select is (pg_temp.keys (public.set_practice_points ('c1000000-0000-0000-0000-000000000101', 'rosary', 5)),
           'group_id,id,points,practice_kind',
           'RPC: set_practice_points shape');
select is (pg_temp.keys (public.join_group_by_code ('654321')),
           'already_member,group,invite_code,member_role',
           'RPC: join_group_by_code shape');
select is (pg_temp.keys (public.create_group ('A10 RPC Second')),
           'group,invite_code',
           'RPC: create_group shape');

reset role;

-- -----------------------------------------------------------------------------
-- E. The account lifecycle (as u2)
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000002","role":"authenticated"}';

select is (pg_temp.keys (public.request_account_deletion ()),
           'confirmation_token,created,expires_at,id,requested_at,status',
           'RPC: request_account_deletion shape');
select is (pg_temp.keys (public.update_ad_consent (false, false)),
           'ad_consent_analytics,ad_personalization,id,updated_at',
           'RPC: update_ad_consent shape');
select is (pg_temp.keys (public.update_my_profile (p_display_name => 'Bruno II')),
           'ad_consent_analytics,ad_personalization,avatar_path,city,created_at,deleted_at,display_name,guardian_angel_opt_in,id,locale,parish,rule_of_life,timezone,updated_at',
           'RPC: update_my_profile shape');
select is (pg_temp.keys (public.delete_my_account_request ()),
           'confirmation_token,created,expires_at,id,requested_at,status',
           'RPC: delete_my_account_request shape');

select is (pg_temp.keys (public.register_device_token ('a10-device-0001', 'ios', 'sandbox', '1.0.0')),
           'app_version,environment,id,is_active,platform,registered',
           'RPC: register_device_token shape');
select is (pg_temp.keys (public.opt_in_to_guardian_angel ('c1000000-0000-0000-0000-000000000101', true)),
           'group_id,group_opt_in,master_opt_in,opted_in',
           'RPC: opt_in_to_guardian_angel shape');
select is (pg_temp.keys (public.begin_ad_reward ('group_slot')),
           'expires_at,expires_in_seconds,ok,reward_type,saint_icon_id,transaction_id',
           'RPC: begin_ad_reward shape');
select is (pg_temp.keys (public.create_signed_witness_url (
             'witness-photos/c1000000-0000-0000-0000-000000000101/c1000000-0000-0000-0000-000000000002/a10a0000-0000-0000-0000-000000000001.jpg')),
           'bucket_id,edge_function,expires_in,group_id,message,object_path,owner_id,signed_url,source',
           'RPC: create_signed_witness_url shape');

-- the report -> resolve path
select is (pg_temp.keys (public.report_content ('post', 'c1000000-0000-0000-0000-000000000202', 'spam', 'a10 detail', null)),
           'auto_hidden,duplicate,group_id,report_count,report_id,status',
           'RPC: report_content shape (with details)');

-- the report id is captured for the admin who resolves it
create temporary table a10_report (id uuid);
grant insert, select on a10_report to authenticated;
grant usage, select on all sequences in schema pg_temp to authenticated;
insert into a10_report
select (public.report_content ('post', 'c1000000-0000-0000-0000-000000000202', 'spam', null, null) ->> 'report_id')::uuid;

reset role;

-- -----------------------------------------------------------------------------
-- E2. The group-admin mutations (run last: they change the membership)
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated"}';

select is (pg_temp.keys (public.reset_invite_code ('c1000000-0000-0000-0000-000000000101')),
           'group_id,invite_code',
           'RPC: reset_invite_code shape');
select is (pg_temp.keys (public.remove_member ('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000005')),
           'group_id,removed_self,removed_user',
           'RPC: remove_member shape');
-- the report is resolved BEFORE the admin role moves
select is (pg_temp.keys (public.resolve_report ((select id from a10_report), 'dismissed', 'a10 note')),
           'action_type,report_id,status',
           'RPC: resolve_report shape');
select is (pg_temp.keys (public.transfer_admin ('c1000000-0000-0000-0000-000000000101', 'c1000000-0000-0000-0000-000000000004')),
           'group_id,new_admin,previous_admin',
           'RPC: transfer_admin shape');

reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000002","role":"authenticated"}';
select is (pg_temp.keys (public.leave_group ('c1000000-0000-0000-0000-000000000101')),
           'archived,group_id,left',
           'RPC: leave_group shape');
reset role;

select * from finish ();
select public.pgtap_summary () as result;

rollback;
