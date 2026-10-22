// push-dispatch — drains `public.notification_outbox` and delivers the
// notifications to APNs.
//
// Deployed with `verify_jwt: false`: the caller is pg_cron (through pg_net)
// or the platform itself, and neither can present a Supabase user JWT.
// The function therefore verifies the caller ITSELF and fails closed:
//
//   * `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>`  (platform / admin)
//   * or `x-push-secret: <PUSH_DISPATCH_SECRET>`            (pg_cron)
//
// The shared secret lives in `private.app_settings.push_dispatch_secret` and
// in the `PUSH_DISPATCH_SECRET` Edge Function secret. It is NOT the Supabase
// service-role key, so the database never has to store a service-role key.
//
// OPERATOR CONFIGURATION (all secrets, never hard-coded):
//   APNS_KEY_ID       the key id of the APNs auth key (.p8)
//   APNS_TEAM_ID      the Apple developer team id
//   APNS_PRIVATE_KEY  the contents of the .p8 file (PKCS#8 PEM)
//   APNS_TOPIC        the app bundle id (apns-topic header)
//   PUSH_DISPATCH_SECRET  optional shared secret for the pg_cron path
//
// HTTP/2 CAVEAT — READ THIS
// -----------------------
// APNs only speaks HTTP/2. The Supabase Edge Runtime's `fetch` negotiates
// HTTP/1.1 in most deployments, so the request below can fail with a
// transport error even when the credentials are perfect. The function does
// NOT fake a success: a transport failure marks the row `failed` with the
// real error and schedules a retry. See docs/backend/PUSH.md for the
// recommended production alternative (a dedicated APNs sender service).

import { createClient } from "@supabase/supabase-js";
import {
  apnsHost,
  createApnsProviderToken,
  type ApnsEnvironment,
} from "./apns_crypto.ts";

const DEFAULT_BATCH = 50;
const MAX_BATCH = 500;
/** APNs rejects payloads above 4 KB. */
const MAX_PAYLOAD_BYTES = 3800;

interface OutboxRow {
  id: string;
  user_id: string;
  notification_type: string;
  title: string;
  body: string;
  payload: Record<string, unknown>;
  group_id: string | null;
  attempts: number;
  scheduled_at: string;
}

interface DeviceToken {
  id: string;
  apns_token: string;
  environment: string;
  platform: string;
}

interface Summary {
  processed: number;
  sent: number;
  failed: number;
  skipped_no_tokens: number;
}

function json (body: unknown, status = 200): Response {
  return new Response (JSON.stringify (body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

/** Constant-time-ish string comparison (no secret is ever logged). */
function safeEqual (a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt (i) ^ b.charCodeAt (i);
  return diff === 0;
}

function isAuthorized (req: Request): boolean {
  const serviceRoleKey = Deno.env.get ("SUPABASE_SERVICE_ROLE_KEY");
  const sharedSecret = Deno.env.get ("PUSH_DISPATCH_SECRET");

  const authorization = req.headers.get ("authorization") ?? "";
  if (serviceRoleKey && safeEqual (authorization, `Bearer ${serviceRoleKey}`)) return true;

  const provided = req.headers.get ("x-push-secret") ?? "";
  if (sharedSecret && provided.length > 0 && safeEqual (provided, sharedSecret)) return true;

  return false;
}

// ---------------------------------------------------------------------------
// provider token cache (APNs tokens are valid for one hour)
// ---------------------------------------------------------------------------
const tokenCache = new Map<string, { token: string; expiresAt: number }>();
const TOKEN_TTL_MS = 50 * 60 * 1000;

function apnsConfig (environment: ApnsEnvironment) {
  const suffix = environment === "sandbox" ? "SANDBOX_" : "";
  const keyId = Deno.env.get (`APNS_${suffix}KEY_ID`) ?? Deno.env.get ("APNS_KEY_ID");
  const teamId = Deno.env.get (`APNS_${suffix}TEAM_ID`) ?? Deno.env.get ("APNS_TEAM_ID");
  const privateKey = Deno.env.get (`APNS_${suffix}PRIVATE_KEY`) ??
    Deno.env.get ("APNS_PRIVATE_KEY");
  return { keyId, teamId, privateKey };
}

async function providerToken (environment: ApnsEnvironment): Promise<string> {
  const cached = tokenCache.get (environment);
  if (cached && cached.expiresAt > Date.now ()) return cached.token;

  const { keyId, teamId, privateKey } = apnsConfig (environment);
  if (!keyId || !teamId || !privateKey) {
    throw new Error (
      `apns_not_configured:${environment}:set APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY`,
    );
  }

  const token = await createApnsProviderToken ({ keyId, teamId, privateKeyPem: privateKey });
  tokenCache.set (environment, { token, expiresAt: Date.now () + TOKEN_TTL_MS });
  return token;
}

// ---------------------------------------------------------------------------
// APNs delivery
// ---------------------------------------------------------------------------
interface ApnsOutcome {
  ok: boolean;
  status: number;
  reason: string;
  permanent: boolean;
}

async function deliver (
  deviceToken: string,
  environment: ApnsEnvironment,
  topic: string,
  payload: Record<string, unknown>,
): Promise<ApnsOutcome> {
  let token: string;
  try {
    token = await providerToken (environment);
  } catch (error) {
    return {
      ok: false,
      status: 0,
      reason: error instanceof Error ? error.message : "provider_token_failed",
      permanent: true,
    };
  }

  let response: Response;
  try {
    response = await fetch (`${apnsHost (environment)}/3/device/${deviceToken}`, {
      method: "POST",
      headers: {
        "authorization": `bearer ${token}`,
        "apns-topic": topic,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-expiration": "0",
        "content-type": "application/json",
      },
      body: JSON.stringify (payload),
    });
  } catch (error) {
    // TRANSPORT FAILURE (very often: APNs requires HTTP/2 and the Edge
    // Runtime negotiated HTTP/1.1). Never reported as a success.
    return {
      ok: false,
      status: 0,
      reason: `transport_error:${
        error instanceof Error ? error.message : String (error)
      }`,
      permanent: false,
    };
  }

  if (response.status === 200) return { ok: true, status: 200, reason: "ok", permanent: false };

  let reason = response.statusText || "unknown";
  try {
    const body = await response.json ();
    if (body && typeof body.reason === "string") reason = body.reason;
  } catch {
    // keep the status text
  }

  return {
    ok: false,
    status: response.status,
    reason,
    permanent: response.status === 403 || response.status === 400 ||
      response.status === 410,
  };
}

function buildPayload (row: OutboxRow): Record<string, unknown> {
  const payload: Record<string, unknown> = {
    aps: {
      alert: { title: row.title, body: row.body },
      sound: "default",
    },
    type: row.notification_type,
    group_id: row.group_id,
    data: row.payload ?? {},
  };

  // APNs hard limit: 4 KB. Trim the custom data rather than the alert.
  if (JSON.stringify (payload).length > MAX_PAYLOAD_BYTES) {
    delete payload.data;
    if (JSON.stringify (payload).length > MAX_PAYLOAD_BYTES) {
      (payload.aps.alert as { body: string }).body =
        (payload.aps.alert as { body: string }).body.slice (0, 200);
    }
  }
  return payload;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST" && req.method !== "GET") {
    return json ({ ok: false, reason: "method_not_allowed" }, 405);
  }

  if (!isAuthorized (req)) {
    return json ({ ok: false, reason: "unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get ("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get ("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json ({ ok: false, reason: "server_not_configured" }, 500);
  }

  const topic = Deno.env.get ("APNS_TOPIC");
  if (!topic) {
    return json ({ ok: false, reason: "apns_topic_not_configured" }, 500);
  }

  const admin = createClient (supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let limit = DEFAULT_BATCH;
  try {
    const raw = await req.text ();
    if (raw) {
      const parsed = JSON.parse (raw) as { limit?: number };
      if (typeof parsed.limit === "number" && Number.isFinite (parsed.limit)) {
        limit = Math.max (1, Math.min (Math.trunc (parsed.limit), MAX_BATCH));
      }
    }
  } catch {
    // an empty / non-JSON body simply means "use the default batch size"
  }

  // 1 · claim a batch (FOR UPDATE SKIP LOCKED — safe with concurrent dispatchers)
  const { data: claimed, error: claimError } = await admin.rpc ("claim_notification_outbox", {
    p_limit: limit,
  });
  if (claimError) {
    return json ({ ok: false, reason: "claim_failed", detail: claimError.message }, 500);
  }

  const rows = (claimed ?? []) as OutboxRow[];
  const summary: Summary = { processed: 0, sent: 0, failed: 0, skipped_no_tokens: 0 };

  for (const row of rows) {
    summary.processed++;

    const { data: tokens, error: tokenError } = await admin
      .from ("device_tokens")
      .select ("id, apns_token, environment, platform")
      .eq ("user_id", row.user_id)
      .eq ("is_active", true);

    if (tokenError) {
      await admin.rpc ("complete_notification_outbox", {
        p_outbox_id: row.id,
        p_status: "failed",
        p_error: `device_token_lookup_failed:${tokenError.message}`,
      });
      summary.failed++;
      continue;
    }

    const devices = (tokens ?? []) as DeviceToken[];
    if (devices.length === 0) {
      // Nothing to deliver to: this is not an error, the row is retired.
      await admin.rpc ("complete_notification_outbox", {
        p_outbox_id: row.id,
        p_status: "cancelled",
        p_error: "no_active_device_token",
      });
      summary.skipped_no_tokens++;
      continue;
    }

    const payload = buildPayload (row);
    let delivered = false;
    let lastReason = "unknown";
    let lastStatus = 0;
    let badTokenIds: string[] = [];

    for (const device of devices) {
      const environment: ApnsEnvironment = device.environment === "sandbox"
        ? "sandbox"
        : "production";
      const outcome = await deliver (device.apns_token, environment, topic, payload);
      if (outcome.ok) {
        delivered = true;
        continue;
      }
      lastReason = outcome.reason;
      lastStatus = outcome.status;
      if (outcome.status === 400 || outcome.status === 410) {
        badTokenIds.push (device.id);
      }
      if (outcome.status === 403) {
        // Auth failure: fail the batch loudly.
        break;
      }
    }

    for (const tokenId of badTokenIds) {
      await admin.rpc ("deactivate_device_token", { p_token_id: tokenId });
    }

    if (delivered) {
      await admin.rpc ("complete_notification_outbox", {
        p_outbox_id: row.id,
        p_status: "sent",
        p_error: null,
      });
      summary.sent++;
    } else {
      await admin.rpc ("complete_notification_outbox", {
        p_outbox_id: row.id,
        p_status: "failed",
        p_error: `apns_${lastStatus}:${lastReason}`,
      });
      summary.failed++;
    }
  }

  return json ({ ok: true, ...summary });
});
