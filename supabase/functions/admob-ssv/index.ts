// AdMob Server-Side Verification (SSV) endpoint.
//
// Deployed with `verify_jwt: false` — Google's servers cannot present a
// Supabase JWT — so the function verifies the request ITSELF and fails CLOSED.
//
// The grant only happens when ALL of the following hold:
//   1. every mandatory SSV parameter is present;
//   2. `package_name` is exactly the MassMates bundle id;
//   3. `app_signing_key` is byte-identical to the key configured in the
//      `ADMOBSIGNING_KEY` secret;
//   4. `sig` is a valid RSA-SHA256 signature of the canonical query string
//      made with that key;
//   5. `reward_type` is in the allow-list;
//   6. a PENDING ad-view token (public.ad_view_tokens) exists for the
//      transaction id carried by the callback, it has not expired, it has not
//      been consumed, and it matches the reward type and the user.
//
// Anything else is a 4xx and NOTHING is granted.
//
// The `ADMOBSIGNING_KEY` secret MUST be set before the function can grant
// anything:
//   supabase secrets set ADMOBSIGNING_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"

import { createClient } from "@supabase/supabase-js";
import {
  base64ToBytes,
  canonicalQueryCandidates,
  derFromKeyMaterial,
  sameBytes,
  verifyAdMobSignature,
} from "./ssv_crypto.ts";

const EXPECTED_PACKAGE = "joaoigor.MassMates";

const ALLOWED_REWARD_TYPES = ["streak_mercy", "group_slot", "saint_theme"];

const REQUIRED_PARAMS = [
  "ad_type",
  "ad_value",
  "currency",
  "reward_type",
  "reward_amount",
  "package_name",
  "app_signing_key",
  "sig",
];

// Where the ad-view token (public.ad_view_tokens.transaction_id) may be
// carried. The recommended name is `massmates_txn`.
const TOKEN_PARAMS = [
  "massmates_txn",
  "custom_parameter",
  "custom_parameters",
  "transaction_id",
];

function json (body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function fail (reason: string, status: number, extra: Record<string, unknown> = {}): Response {
  return json({ ok: false, reason, ...extra }, status);
}

/** Extracts a MassMates token id out of a custom-parameter blob. */
function tokenCandidates (params: URLSearchParams): string[] {
  const found: string[] = [];
  for (const name of TOKEN_PARAMS) {
    const value = params.get(name);
    if (!value) continue;
    const embedded = value.match(/massmates_txn=([A-Za-z0-9-]+)/);
    if (embedded) found.push(embedded[1]);
    found.push(value);
  }
  return [...new Set(found)];
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "GET" && req.method !== "POST") {
    return fail("method_not_allowed", 405);
  }

  const url = new URL(req.url);
  const params = url.searchParams;
  const rawQuery = url.search.slice(1);

  // 1. mandatory parameters -------------------------------------------------
  const missing = REQUIRED_PARAMS.filter((name) => !params.get(name));
  if (missing.length > 0) {
    return fail("missing_parameters", 400, { missing });
  }

  // 2. the app's own integrity ---------------------------------------------
  if (params.get("package_name") !== EXPECTED_PACKAGE) {
    return fail("package_mismatch", 400, { expected: EXPECTED_PACKAGE });
  }

  // 3. the configured public key -------------------------------------------
  const configuredDer = derFromKeyMaterial(Deno.env.get("ADMOBSIGNING_KEY"));
  if (!configuredDer) {
    // FAIL CLOSED: without the operator-configured key nothing can be
    // verified, therefore nothing is granted.
    return fail("signing_key_not_configured", 400);
  }

  const requestDer = derFromKeyMaterial(params.get("app_signing_key"));
  if (!requestDer) {
    return fail("app_signing_key_invalid", 400);
  }
  if (!sameBytes(configuredDer, requestDer)) {
    return fail("app_signing_key_mismatch", 400);
  }

  // 4. the signature --------------------------------------------------------
  let signature: Uint8Array;
  try {
    signature = base64ToBytes(params.get("sig") as string);
  } catch {
    return fail("signature_not_base64", 400);
  }
  if (signature.length === 0) {
    return fail("signature_missing", 400);
  }
  if (!(await verifyAdMobSignature(configuredDer, signature, rawQuery))) {
    return fail("invalid_signature", 400);
  }

  // 5. the reward type ------------------------------------------------------
  const rewardType = params.get("reward_type") as string;
  if (!ALLOWED_REWARD_TYPES.includes(rewardType)) {
    return fail("reward_type_not_allowed", 400, { reward_type: rewardType });
  }

  // 6. the pending ad view --------------------------------------------------
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return fail("server_not_configured", 400);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const candidates = tokenCandidates(params);
  if (candidates.length === 0) {
    return fail("no_ad_view_token", 400);
  }

  const { data: tokens, error: tokenError } = await admin
    .from("ad_view_tokens")
    .select("id, user_id, transaction_id, reward_type, expires_at, consumed_at")
    .in("transaction_id", candidates)
    .limit(1);

  if (tokenError) {
    return fail("token_lookup_failed", 400, { detail: tokenError.message });
  }

  const token = (tokens ?? [])[0];
  if (!token) {
    return fail("no_pending_ad_view", 400);
  }
  if (token.consumed_at) {
    return fail("ad_view_token_already_used", 400);
  }
  if (new Date(token.expires_at).getTime() < Date.now()) {
    return fail("ad_view_token_expired", 400);
  }
  if (token.reward_type !== rewardType) {
    return fail("reward_type_mismatch", 400, {
      expected: token.reward_type,
      received: rewardType,
    });
  }

  const userIdParam = params.get("user_id");
  if (userIdParam && userIdParam !== token.user_id) {
    return fail("user_mismatch", 400);
  }

  // 7. idempotency ----------------------------------------------------------
  const admobTransactionId = params.get("transaction_id");
  const ledgerTransactionId = admobTransactionId ?? token.transaction_id;

  const { data: existing, error: existingError } = await admin
    .from("reward_grants")
    .select("id, status, expires_at")
    .eq("source", "admob_ssv")
    .eq("transaction_id", ledgerTransactionId)
    .limit(1);

  if (existingError) {
    return fail("ledger_lookup_failed", 400, { detail: existingError.message });
  }
  if ((existing ?? []).length > 0) {
    await admin
      .from("ad_view_tokens")
      .update({ consumed_at: new Date().toISOString() })
      .eq("id", token.id)
      .is("consumed_at", null);
    return json({
      ok: true,
      granted: false,
      duplicate: true,
      reward_type: rewardType,
      transaction_id: ledgerTransactionId,
    });
  }

  // 8. the grant ------------------------------------------------------------
  const { data: granted, error: grantError } = await admin.rpc("grant_reward", {
    p_user_id: token.user_id,
    p_reward_type: rewardType,
    p_source: "admob_ssv",
    p_transaction_id: ledgerTransactionId,
    p_expires_days: null,
    p_metadata: {
      ad_network: "admob",
      ad_type: params.get("ad_type"),
      ad_value: params.get("ad_value"),
      currency: params.get("currency"),
      reward_amount: params.get("reward_amount"),
      admob_transaction_id: admobTransactionId,
      ad_view_token_id: token.id,
    },
  });

  if (grantError) {
    await recordReceipt(admin, {
      transactionId: ledgerTransactionId,
      rewardType,
      userId: token.user_id,
      outcome: "rejected",
      reason: `grant_error: ${grantError.message}`,
      params,
    });
    return fail("grant_failed", 400, { detail: grantError.message });
  }

  const result = (granted ?? {}) as Record<string, unknown>;
  if (result.ok === false) {
    await recordReceipt(admin, {
      transactionId: ledgerTransactionId,
      rewardType,
      userId: token.user_id,
      outcome: "rejected",
      reason: String(result.reason ?? "not_granted"),
      params,
    });
    const reason = String(result.reason ?? "not_granted");
    return fail(reason, reason === "streak_mercy_limit_reached" ? 409 : 400);
  }

  await admin
    .from("ad_view_tokens")
    .update({ consumed_at: new Date().toISOString() })
    .eq("id", token.id)
    .is("consumed_at", null);

  await recordReceipt(admin, {
    transactionId: ledgerTransactionId,
    rewardType,
    userId: token.user_id,
    outcome: result.duplicate === true ? "duplicate" : "granted",
    reason: null,
    params,
  });

  return json({
    ok: true,
    granted: result.granted !== false,
    duplicate: result.duplicate === true,
    reward_type: rewardType,
    transaction_id: ledgerTransactionId,
  });
});

async function recordReceipt (
  admin: ReturnType<typeof createClient>,
  input: {
    transactionId: string | null;
    rewardType: string | null;
    userId: string | null;
    outcome: string;
    reason: string | null;
    params: URLSearchParams;
  }
): Promise<void> {
  try {
    await admin.from("ssv_receipts").insert({
      transaction_id: input.transactionId,
      reward_type: input.rewardType,
      user_id: input.userId,
      ad_type: input.params.get("ad_type"),
      ad_value: input.params.get("ad_value"),
      currency: input.params.get("currency"),
      package_name: input.params.get("package_name"),
      outcome: input.outcome,
      reason: input.reason,
    });
  } catch {
    // a receipt is best effort: it must never break the grant
  }
}
