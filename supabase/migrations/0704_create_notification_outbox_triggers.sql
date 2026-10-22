-- =============================================================================
-- A10 NOTE (2026-10-22) -- the APPLIED version of this file
-- =============================================================================
-- This file was applied to the remote project `khovpljkitslmjmonuzu` as
--   migration version 20261022031852  ("create_notification_outbox_triggers")
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
-- A8 · 0704 · Notification outbox emission triggers
-- =============================================================================
-- Owner: A8.
--
-- Every trigger function lives in `private` and is SECURITY DEFINER with
-- `set search_path = ''` and fully qualified names, so it can write into
-- `public.notification_outbox` (which has NO client INSERT policy).
--
-- SACRED PRIVACY
--   * A push never carries private check-in content, Confession content or
--     Spiritual Diary text. The only free text that ever reaches a push is
--     the display name of a reacting member and the body of a PINNED NOTICE
--     (a group announcement written by a group admin).
--   * A blocked pair never produces a notification (checked with
--     public.is_blocked, which is symmetric).
--   * LITURGICAL REMINDERS ARE LOCAL-ONLY. This backend NEVER creates an
--     outbox row for a liturgical day, a reading, a saint or a reminder.
--     Those notifications are scheduled on the device.
-- -----------------------------------------------------------------------------

-- =============================================================================
-- 1 · "Someone prayed for you"  (public.intention_prayers AFTER INSERT)
-- =============================================================================
-- A5's seam: public.emit_prayer_notification(intention_id, prayer_id).
-- A5's toggle_prayed_for() already calls it on every new prayer, so the
-- trigger below only adds the direct-INSERT path. The UNIQUE (dedupe_key)
-- on the outbox makes the two paths idempotent: both resolve to
-- 'prayed:<intention_prayer_id>' and only ONE row is ever created.
create or replace function public.emit_prayer_notification (
  p_intention_id uuid,
  p_prayer_id uuid
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_recipient uuid;
  v_group     uuid;
  v_ip_id     uuid;
  v_dedupe    text;
  v_id        uuid;
begin
  if to_regclass ('public.notification_outbox') is null then
    return jsonb_build_object (
      'emitted', false,
      'reason', 'notification_outbox_not_available');
  end if;

  select i.user_id, i.group_id into v_recipient, v_group
    from public.prayer_intentions i
   where i.id = p_intention_id;

  if v_recipient is null then
    return jsonb_build_object ('emitted', false, 'reason', 'intention_not_found');
  end if;

  if v_recipient = p_prayer_id then
    return jsonb_build_object ('emitted', false, 'reason', 'self_prayer');
  end if;

  if public.is_blocked (v_recipient, p_prayer_id) then
    return jsonb_build_object ('emitted', false, 'reason', 'blocked');
  end if;

  select ip.id into v_ip_id
    from public.intention_prayers ip
   where ip.intention_id = p_intention_id
     and ip.prayer_id = p_prayer_id;

  v_dedupe := case
                when v_ip_id is not null then 'prayed:' || v_ip_id::text
                else 'prayed:' || p_intention_id::text || ':' || p_prayer_id::text
              end;

  insert into public.notification_outbox (
    user_id, channel, notification_type, title, body, payload, group_id, dedupe_key)
  values (
    v_recipient, 'push', 'prayed_for_you',
    'Alguém rezou por você',
    'Alguém rezou pela sua intenção de hoje.',
    jsonb_build_object ('intention_id', p_intention_id, 'group_id', v_group),
    v_group,
    v_dedupe)
  on conflict (dedupe_key) do nothing
  returning id into v_id;

  return jsonb_build_object (
    'emitted', v_id is not null,
    'reason', case when v_id is null then 'duplicate' else null end,
    'dedupe_key', v_dedupe);
end;
$$;

comment on function public.emit_prayer_notification (uuid, uuid) is
  'A8 seam (body replaced by A8 in migration 0704). Writes the "someone prayed for you" notification into public.notification_outbox. Dedupe key: prayed:<intention_prayer_id>. Never raises; returns {"emitted":bool,"reason":text}. Not callable by clients.';

create or replace function private.a8_notify_prayer_notification ()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public.emit_prayer_notification (new.intention_id, new.prayer_id);
  return new;
end;
$$;

comment on function private.a8_notify_prayer_notification () is
  'AFTER INSERT trigger on public.intention_prayers: notifies the intention author that somebody prayed for them.';

drop trigger if exists trg_intention_prayers_notify on public.intention_prayers;
create trigger trg_intention_prayers_notify
  after insert on public.intention_prayers
  for each row execute function private.a8_notify_prayer_notification ();

-- =============================================================================
-- 2 · "Amen" / "United in Prayer"  (public.amen_reactions AFTER INSERT)
-- =============================================================================
-- The post author is notified. The reactor's DISPLAY NAME is included (the
-- feed already shows it) but NEVER the content of the post — a private
-- check-in never produces a feed post in the first place.
create or replace function private.a8_notify_amen ()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_author uuid;
  v_group  uuid;
  v_name   text;
begin
  select p.user_id, p.group_id into v_author, v_group
    from public.feed_posts p
   where p.id = new.post_id;

  if v_author is null or v_author = new.user_id then
    return new;
  end if;

  if public.is_blocked (v_author, new.user_id) then
    return new;
  end if;

  select pr.display_name into v_name
    from public.profiles pr
   where pr.id = new.user_id;

  if v_name is null or btrim (v_name) = '' then
    v_name := 'Alguém';
  end if;

  insert into public.notification_outbox (
    user_id, channel, notification_type, title, body, payload, group_id, dedupe_key)
  values (
    v_author, 'push', 'amen',
    case when new.reaction_type = 'united_in_prayer'
         then 'Alguém rezou junto com você'
         else 'Alguém rezou contigo' end,
    case when new.reaction_type = 'united_in_prayer'
         then v_name || ' rezou junto com a sua partilha.'
         else v_name || ' reagiu à sua partilha com um Amen.' end,
    jsonb_build_object (
      'post_id', new.post_id,
      'group_id', v_group,
      'reaction_type', new.reaction_type),
    v_group,
    'amen:' || new.id::text)
  on conflict (dedupe_key) do nothing;

  return new;
end;
$$;

comment on function private.a8_notify_amen () is
  'AFTER INSERT trigger on public.amen_reactions: notifies the post author. Dedupe key: amen:<amen_reaction_id>. The pushed body carries the reactor''s display name only — never the post content.';

drop trigger if exists trg_amen_reactions_notify on public.amen_reactions;
create trigger trg_amen_reactions_notify
  after insert on public.amen_reactions
  for each row execute function private.a8_notify_amen ();

-- =============================================================================
-- 3 · Pinned notice  (public.pinned_notices AFTER INSERT)
-- =============================================================================
-- Every active member of the group except the author is notified. The body of
-- the notice is a group announcement (admin authored, group visible) — it is
-- NOT private check-in content.
create or replace function private.a8_notify_pinned_notice ()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.is_active is not true then
    return new;
  end if;

  insert into public.notification_outbox (
    user_id, channel, notification_type, title, body, payload, group_id, dedupe_key)
  select gm.user_id,
         'push',
         'pinned_notice',
         'Novo aviso no grupo',
         left (new.body, 300),
         jsonb_build_object ('group_id', new.group_id, 'notice_id', new.id),
         new.group_id,
         'pinned:' || new.id::text || ':' || gm.user_id::text
    from public.group_members gm
   where gm.group_id = new.group_id
     and gm.user_id <> new.author_id
     and not public.is_blocked (gm.user_id, new.author_id)
  on conflict (dedupe_key) do nothing;

  return new;
end;
$$;

comment on function private.a8_notify_pinned_notice () is
  'AFTER INSERT trigger on public.pinned_notices: notifies every active member of the group except the author. Dedupe key: pinned:<notice_id>:<member_id>.';

drop trigger if exists trg_pinned_notices_notify on public.pinned_notices;
create trigger trg_pinned_notices_notify
  after insert on public.pinned_notices
  for each row execute function private.a8_notify_pinned_notice ();

-- =============================================================================
-- Privileges (the A5 seam stays service_role only)
-- =============================================================================
revoke execute on function public.emit_prayer_notification (uuid, uuid) from public, anon, authenticated;
grant  execute on function public.emit_prayer_notification (uuid, uuid) to service_role;

revoke execute on function private.a8_notify_prayer_notification () from public, anon, authenticated, service_role;
revoke execute on function private.a8_notify_amen ()             from public, anon, authenticated, service_role;
revoke execute on function private.a8_notify_pinned_notice ()    from public, anon, authenticated, service_role;
