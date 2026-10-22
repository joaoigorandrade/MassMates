// =============================================================================
// A2 · delete-account · Edge Function (Deno)
// =============================================================================
// Executes the hard erasure of an account. It NEVER trusts the caller: the
// destructive work happens with the service role, but only after the caller's
// own JWT has been verified AND the caller owns a `confirmed`, unexpired row in
// public.account_deletion_requests (the second tap of the two-tap deletion).
//
// Nothing belonging to another user is ever deleted: every delete is filtered
// by the caller's uuid.
//
// Environment (never hard-coded):
//   SUPABASE_URL            — project URL
//   SUPABASE_SERVICE_ROLE_KEY — service role key (destructive deletes only)
// =============================================================================

import { createClient } from "@supabase/supabase-js";

// Buckets A6 owns. The list is intersected with the buckets that actually
// exist, so a bucket that is renamed or not yet created is simply skipped.
const CANDIDATE_BUCKETS = ["avatars", "group-covers", "witness-photos", "check-in-proofs"];

type Json = Record<string, unknown>;

function jsonResponse(body: Json, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

/**
 * An object belongs to the user when its path contains the user's uuid as a
 * full segment. witness-photos paths are `group_id/user_id/uuid.jpg`, so the
 * user_id segment is what identifies the owner's objects.
 */
function isOwnedBy(key: string, userId: string): boolean {
  return key.split("/").some((segment) => segment === userId);
}

async function listBucketKeys(
  admin: ReturnType<typeof createClient>,
  bucket: string,
): Promise<string[]> {
  const keys: string[] = [];

  const walk = async (prefix: string): Promise<void> => {
    for (let offset = 0; ; offset += 1000) {
      const { data, error } = await admin.storage
        .from(bucket)
        .list(prefix, { limit: 1000, offset });

      if (error) {
        throw new Error(`storage.list(${bucket}/${prefix}): ${error.message}`);
      }
      if (!data || data.length === 0) break;

      for (const item of data) {
        const path = prefix ? `${prefix}/${item.name}` : item.name;
        // A folder has id === null in the storage API.
        if (item.id === null) {
          await walk(path);
        } else {
          keys.push(path);
        }
      }

      if (data.length < 1000) break;
    }
  };

  await walk("");
  return keys;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "method_not_allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ ok: false, error: "server_misconfigured" }, 500);
  }

  // ---------------------------------------------------------------------------
  // 1. Verify the caller's JWT ourselves (the gateway checks it too).
  // ---------------------------------------------------------------------------
  const authHeader = req.headers.get("Authorization") ?? "";
  const accessToken = authHeader.replace(/^Bearer\s+/i, "").trim();

  if (!accessToken) {
    return jsonResponse({ ok: false, error: "missing_token" }, 401);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await admin.auth.getUser(accessToken);

  if (userError || !userData?.user) {
    return jsonResponse({ ok: false, error: "invalid_token" }, 401);
  }

  const userId = userData.user.id;

  // ---------------------------------------------------------------------------
  // 2. Optional body. When present it must be a JSON object.
  // ---------------------------------------------------------------------------
  const rawBody = await req.text();

  if (rawBody.length > 0) {
    let parsed: unknown;
    try {
      parsed = JSON.parse(rawBody);
    } catch {
      return jsonResponse({ ok: false, error: "invalid_body" }, 400);
    }
    if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
      return jsonResponse({ ok: false, error: "invalid_body" }, 400);
    }
    if ((parsed as Json).confirm === false) {
      return jsonResponse({ ok: false, error: "confirmation_required" }, 400);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. The two-tap proof: a confirmed, unexpired request OWNED by the caller.
  // ---------------------------------------------------------------------------
  const { data: requestRows, error: requestError } = await admin
    .from("account_deletion_requests")
    .select("id, user_id, status, requested_at, confirmed_at, completed_at, expires_at")
    .eq("user_id", userId)
    .in("status", ["confirmed", "completed"])
    .gt("expires_at", new Date().toISOString())
    .order("requested_at", { ascending: false })
    .limit(1);

  if (requestError) {
    return jsonResponse({ ok: false, error: "request_lookup_failed" }, 500);
  }

  const request = (requestRows ?? [])[0];

  if (!request) {
    return jsonResponse(
      { ok: false, error: "deletion_not_confirmed" },
      409,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Storage: delete ONLY the caller's own objects.
  // ---------------------------------------------------------------------------
  const { data: buckets } = await admin.storage.listBuckets();
  const existingBuckets = new Set((buckets ?? []).map((b) => b.name));

  const deletedObjects: string[] = [];

  for (const bucket of CANDIDATE_BUCKETS) {
    if (!existingBuckets.has(bucket)) continue;

    let keys: string[] = [];
    try {
      keys = await listBucketKeys(admin, bucket);
    } catch {
      continue; // a bucket that cannot be listed must not block the erasure
    }

    const owned = keys.filter((key) => isOwnedBy(key, userId));
    if (owned.length === 0) continue;

    const { error: removeError } = await admin.storage.from(bucket).remove(owned);
    if (removeError) {
      return jsonResponse(
        { ok: false, error: `storage_delete_failed:${bucket}` },
        500,
      );
    }

    for (const key of owned) deletedObjects.push(`${bucket}/${key}`);
  }

  // ---------------------------------------------------------------------------
  // 5. Group membership + groups created by the caller.
  //    RULE (documented): a group created by the caller is DELETED when no
  //    member remains; otherwise the ownership is TRANSFERRED to the
  //    longest-standing admin, or — when there is no admin left — to the
  //    longest-standing member, who is promoted to admin.
  // ---------------------------------------------------------------------------
  const { data: ownedGroups } = await admin
    .from("groups")
    .select("id")
    .eq("created_by", userId);

  const deletedGroups: string[] = [];
  const transferredGroups: { group_id: string; new_owner: string }[] = [];

  for (const group of ownedGroups ?? []) {
    const { data: remaining } = await admin
      .from("group_members")
      .select("id, user_id, role, joined_at")
      .eq("group_id", group.id)
      .neq("user_id", userId)
      .order("joined_at", { ascending: true });

    if (!remaining || remaining.length === 0) {
      await admin.from("groups").delete().eq("id", group.id);
      deletedGroups.push(group.id);
      continue;
    }

    const heir = remaining.find((m) => m.role === "admin") ?? remaining[0];

    if (heir.role !== "admin") {
      await admin
        .from("group_members")
        .update({ role: "admin" })
        .eq("id", heir.id)
        .eq("user_id", heir.user_id);
    }

    await admin
      .from("groups")
      .update({ created_by: heir.user_id })
      .eq("id", group.id)
      .eq("created_by", userId);

    transferredGroups.push({ group_id: group.id, new_owner: heir.user_id });
  }

  // The caller's own roster rows (every other member row is untouched).
  await admin.from("group_members").delete().eq("user_id", userId);

  // ---------------------------------------------------------------------------
  // 6. Mark the request completed BEFORE the auth user is deleted: the row is
  //    cascade-deleted together with public.profiles.
  // ---------------------------------------------------------------------------
  await admin
    .from("account_deletion_requests")
    .update({ status: "completed", completed_at: new Date().toISOString() })
    .eq("id", request.id)
    .eq("user_id", userId);

  // ---------------------------------------------------------------------------
  // 7. Delete the auth user. Every row that references public.profiles(id)
  //    with ON DELETE CASCADE goes with it.
  // ---------------------------------------------------------------------------
  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);

  if (deleteError) {
    // Keep the request retryable.
    await admin
      .from("account_deletion_requests")
      .update({ status: "confirmed" })
      .eq("id", request.id)
      .eq("user_id", userId);
    return jsonResponse({ ok: false, error: "auth_user_delete_failed" }, 500);
  }

  // ---------------------------------------------------------------------------
  // 8. Audit trail. audit_log.actor_id has NO foreign key on purpose, so the
  //    row survives the deletion of the actor.
  // ---------------------------------------------------------------------------
  await admin.from("audit_log").insert({
    actor_id: userId,
    action: "account.deleted",
    target_type: "profile",
    target_id: userId,
    metadata: {
      completed_at: new Date().toISOString(),
      groups_deleted: deletedGroups,
      groups_transferred: transferredGroups,
      storage_objects_deleted: deletedObjects.length,
    },
  });

  return jsonResponse(
    {
      ok: true,
      deleted: true,
      groups_deleted: deletedGroups.length,
      groups_transferred: transferredGroups.length,
      storage_objects_deleted: deletedObjects.length,
    },
    200,
  );
});
