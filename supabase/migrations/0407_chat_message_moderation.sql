-- =============================================================================
-- A5 · 0407 · Chat message moderation (is_hidden) + soft_delete_chat_message
-- =============================================================================
-- Owner: A5 (public.chat_messages is A5's table).
--
-- A6 reported the gap: public.chat_messages had no `is_hidden` column, so
-- A6's public.hide_content('chat_message', …) could record the
-- moderation_actions + audit_log trail but could not actually hide the
-- message. Chat moderation is IN SCOPE (group admins must be able to remove
-- inappropriate content; App Store UGC compliance needs a working
-- report -> hide path).
--
-- This migration mirrors EXACTLY what public.feed_posts already does:
--   * is_hidden / hidden_reason / hidden_at columns,
--   * a partial index for the moderation query,
--   * a SELECT policy where a hidden message is invisible to ordinary
--     members but still visible to the group admins,
--   * a soft_delete_chat_message() RPC that mirrors soft_delete_feed_post()
--     (same privilege pattern, same audit_log shape, same jsonb shape).
--
-- `hidden_at` has NO default and is NOT set automatically on UPDATE: only the
-- moderation RPC sets it. The `updated_at` trigger convention is unchanged
-- (trg_chat_messages_updated_at still refreshes updated_at only).
--
-- A6's public.hide_content() needs NO change: private.auto_hide_content()
-- already contains
--     update public.chat_messages set is_hidden = true where id = …
-- guarded by private.has_column (v_tbl, 'is_hidden'). The guard now passes,
-- so A6's report -> hide path works as soon as this migration lands.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 1. Columns
-- -----------------------------------------------------------------------------
alter table public.chat_messages
  add column if not exists is_hidden     boolean not null default false;
alter table public.chat_messages
  add column if not exists hidden_reason text;
alter table public.chat_messages
  add column if not exists hidden_at     timestamptz;

comment on column public.chat_messages.is_hidden is
  'True when the message is hidden from ordinary group members (moderation — A6 hide_content, or a group admin via public.soft_delete_chat_message). A group admin still sees it. Set only by the server; clients have no UPDATE policy on this table.';
comment on column public.chat_messages.hidden_reason is
  'Why the message is hidden. ''admin_removed'' is written by public.soft_delete_chat_message. A6''s hide_content path sets only is_hidden, so this can be NULL for an A6-hidden message.';
comment on column public.chat_messages.hidden_at is
  'When the message was hidden. Set ONLY by public.soft_delete_chat_message (no default, never set automatically on UPDATE).';

-- -----------------------------------------------------------------------------
-- 2. Index for the moderation query
-- -----------------------------------------------------------------------------
create index if not exists chat_messages_hidden_idx
  on public.chat_messages (group_id, created_at desc) where is_hidden;

-- -----------------------------------------------------------------------------
-- 3. SELECT policy — hidden messages are invisible to ordinary members
-- -----------------------------------------------------------------------------
drop policy if exists chat_messages_select_members on public.chat_messages;

create policy chat_messages_select_members
  on public.chat_messages
  for select
  to authenticated
  using (
    public.is_group_member (group_id, (select auth.uid ()))
    and not public.is_blocked ((select auth.uid ()), user_id)
    and (not is_hidden or public.is_group_admin (group_id, (select auth.uid ())))
  );

-- The DELETE policy is unchanged (own messages or group admin). The INSERT
-- policy is unchanged (own messages, in a group you belong to).

-- -----------------------------------------------------------------------------
-- 4. public.soft_delete_chat_message — mirrors public.soft_delete_feed_post
-- -----------------------------------------------------------------------------
create or replace function public.soft_delete_chat_message (p_message_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid ();
  v_gid     uuid;
  v_author  uuid;
  v_changed integer;
  v_hidden_at timestamptz := now ();
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select m.group_id, m.user_id
    into v_gid, v_author
    from public.chat_messages m
   where m.id = p_message_id;

  if v_gid is null then
    raise exception 'message not found' using errcode = 'P0002';
  end if;

  if not public.is_group_admin (v_gid, v_uid) then
    raise exception 'only a group admin can remove a message' using errcode = '42501';
  end if;

  update public.chat_messages
     set is_hidden = true,
         hidden_reason = 'admin_removed',
         hidden_at = v_hidden_at
   where id = p_message_id
     and not is_hidden;
  get diagnostics v_changed = row_count;

  if v_changed > 0 then
    insert into public.audit_log (actor_id, action, target_type, target_id, metadata)
    values (
      v_uid,
      'chat.message_removed',
      'chat_message',
      p_message_id,
      jsonb_build_object (
        'group_id', v_gid,
        'message_author_id', v_author,
        'reason', 'admin_removed'
      )
    );
  end if;

  return jsonb_build_object (
    'message_id', p_message_id,
    'group_id', v_gid,
    'hidden', true,
    'hidden_reason', 'admin_removed',
    'hidden_at', private.a5_iso (v_hidden_at),
    'changed', v_changed
  );
end;
$$;

comment on function public.soft_delete_chat_message (uuid) is
  'GROUP-ADMIN removal of a chat message (mirrors public.soft_delete_feed_post). Sets is_hidden = true, hidden_reason = ''admin_removed'' and hidden_at = now(), and appends one row to public.audit_log (action ''chat.message_removed'', target_type ''chat_message''). The row is kept (soft delete) and stays visible to the group admins. The caller MUST be an admin of the message''s group. Idempotent: calling it twice writes no second audit row.';

-- -----------------------------------------------------------------------------
-- 5. Privileges — explicit revoke from anon (the project grants EXECUTE on
--    new public functions to anon by default, so "from public" alone is NOT
--    enough — A6 found this).
-- -----------------------------------------------------------------------------
revoke execute on function public.soft_delete_chat_message (uuid) from public, anon;
grant  execute on function public.soft_delete_chat_message (uuid) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 6. The pagination RPC must not leak hidden messages
--    public.get_chat_messages is SECURITY DEFINER, so it bypasses RLS and has
--    to apply the visibility rules itself — exactly like get_feed_posts.
-- -----------------------------------------------------------------------------
create or replace function public.get_chat_messages (
  p_group_id uuid,
  p_before   text    default null,
  p_limit    integer default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid ();
  v_limit  integer := least (greatest (coalesce (p_limit, 30), 1), 100);
  v_ts     timestamptz;
  v_id     uuid;
  v_items  jsonb;
  v_cursor text;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not public.is_group_member (p_group_id, v_uid) then
    raise exception 'not a member of this group' using errcode = '42501';
  end if;

  v_ts := private.a5_cursor_ts (p_before);
  v_id := private.a5_cursor_id (p_before);

  with page as (
    select m.id,
           m.group_id,
           m.user_id,
           m.body,
           m.reply_to_id,
           m.created_at
      from public.chat_messages m
     where m.group_id = p_group_id
       and not public.is_blocked (v_uid, m.user_id)
       and (not m.is_hidden or public.is_group_admin (p_group_id, v_uid))
       and (
             v_ts is null
             or (v_id is null and m.created_at < v_ts)
             or (v_id is not null and (m.created_at, m.id) < (v_ts, v_id))
           )
     order by m.created_at desc, m.id desc
     limit v_limit
  )
  select coalesce (
           jsonb_agg (
             jsonb_build_object (
               'id', pg.id,
               'group_id', pg.group_id,
               'user_id', pg.user_id,
               'body', pg.body,
               'reply_to_id', pg.reply_to_id,
               'created_at', private.a5_iso (pg.created_at)
             )
             order by pg.created_at desc, pg.id desc
           ),
           '[]'::jsonb
         ),
         (select private.a5_cursor_text (pg.created_at, pg.id)
            from page pg
           order by pg.created_at asc, pg.id asc
           limit 1)
    into v_items, v_cursor
  from page pg;

  return jsonb_build_object (
    'items', v_items,
    'next_cursor', v_cursor
  );
end;
$$;

comment on function public.get_chat_messages (uuid, text, integer) is
  'Cursor-paginated group chat. Returns {"items":[...],"next_cursor":"<iso>|<uuid>"|null}. NEWEST FIRST (a chat is read from the bottom up, so the client reverses the array when it renders). p_limit is clamped to 1..100. Messages from a blocked user are never returned. HIDDEN messages are returned to a group admin only — same rule as the feed. Pass next_cursor back as p_before for the next (older) page.';

revoke execute on function public.get_chat_messages (uuid, text, integer) from public, anon;
grant  execute on function public.get_chat_messages (uuid, text, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 7. A reply to a hidden message must not reveal that it exists
-- -----------------------------------------------------------------------------
create or replace function public.create_chat_message (
  p_group_id    uuid,
  p_body        text,
  p_reply_to_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid ();
  v_body       text;
  v_id         uuid;
  v_created_at timestamptz;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  v_body := btrim (coalesce (p_body, ''));

  if char_length (v_body) < 1 then
    raise exception 'message body cannot be empty' using errcode = '22023';
  end if;

  if char_length (v_body) > 2000 then
    raise exception 'message body must be at most 2000 characters' using errcode = '22023';
  end if;

  if not public.is_group_member (p_group_id, v_uid) then
    raise exception 'not a member of this group' using errcode = '42501';
  end if;

  if p_reply_to_id is not null then
    if not exists (
      select 1
        from public.chat_messages m
       where m.id = p_reply_to_id
         and m.group_id = p_group_id
         and (not m.is_hidden or public.is_group_admin (p_group_id, v_uid))
    ) then
      raise exception 'the message being replied to does not exist in this group' using errcode = '22023';
    end if;
  end if;

  insert into public.chat_messages (group_id, user_id, body, reply_to_id)
  values (p_group_id, v_uid, v_body, p_reply_to_id)
  returning id, created_at into v_id, v_created_at;

  return jsonb_build_object (
    'id', v_id,
    'group_id', p_group_id,
    'user_id', v_uid,
    'body', v_body,
    'reply_to_id', p_reply_to_id,
    'created_at', private.a5_iso (v_created_at)
  );
end;
$$;

comment on function public.create_chat_message (uuid, text, uuid) is
  'Posts a message to the group chat. The caller must be a member of p_group_id. Body is trimmed and must be 1..2000 characters. p_reply_to_id must reference a VISIBLE message of the SAME group (a hidden message reads as non-existent). Chat messages are immutable — there is no edit path.';

revoke execute on function public.create_chat_message (uuid, text, uuid) from public, anon;
grant  execute on function public.create_chat_message (uuid, text, uuid) to authenticated;
