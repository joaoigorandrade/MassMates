// supabase/functions/signed-witness-url/index.ts
// =============================================================================
// A6 · signed-witness-url  (+ the gap-closure BATCH mode)
// =============================================================================
// Issues a short-lived signed URL for an object in the PRIVATE
// `witness-photos` bucket.
//
// The `witness-photos` bucket is the only private bucket in the app: a prayer
// witness photo must only ever be visible to the members of the group it was
// shared in. This function is the single place where that bucket is signed.
//
// Flow
//   1. The caller (authenticated) sends { object_path, expires_in? }.
//   2. The AUTHORIZATION GATE is `public.create_signed_witness_url(...)`,
//      called over PostgREST with the CALLER's own JWT, so `auth.uid()` is the
//      real user. The RPC validates the path shape, checks group membership,
//      checks that the caller is not blocked by the photo owner, and clamps the
//      TTL to 60..3600 seconds.
//   3. Only the SIGNING step uses the service role key.
//
// BATCH MODE (gap closure)
//   The caller may send { object_paths: ["...", "..."], expires_in? }.
//   The AUTHORIZATION GATE is then `public.create_signed_witness_urls(...)`,
//   which runs the SAME checks for every path (A6's own single-path
//   implementation, one call per path) and NEVER fails because of one bad
//   path. Every authorised path is signed and the answer is
//   `{ items: [{ path, signed_url, reason, ... }] }`.
//
//   The singular form is UNCHANGED: `{ object_path }` still answers
//   `{ signed_url, expires_in, object_path, source }`.
//
// NOTE: no regular expressions are used on purpose — the bearer token is
// split on spaces so the parsing cannot be tripped up by escaping.
// =============================================================================

const BUCKET = 'witness-photos';
const MIN_TTL = 60;
const MAX_TTL = 3600;
const DEFAULT_TTL = 300;
const MAX_PATHS = 50;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store',
    },
  });
}

function bearerToken(req: Request): string {
  const raw = req.headers.get('Authorization') ?? '';
  const parts = raw.split(' ').filter((p) => p.length > 0);
  if (parts.length === 0) return '';
  if (parts.length === 1) return parts[0].trim();
  if (parts[0].toLowerCase() === 'bearer') return parts.slice(1).join(' ').trim();
  return raw.trim();
}

function clampTtl(raw: unknown): number {
  const parsed = Number(raw);
  if (!Number.isFinite(parsed)) return DEFAULT_TTL;
  return Math.min(MAX_TTL, Math.max(MIN_TTL, Math.trunc(parsed)));
}

interface SignResult {
  path: string;
  signed_url: string | null;
  reason: string | null;
  authorized: boolean;
  source: string | null;
  object_path: string | null;
  group_id: string | null;
  owner_id: string | null;
  expires_in: number;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return json(405, { error: 'method_not_allowed' });
  }

  const token = bearerToken(req);
  if (!token) {
    return json(401, { error: 'authentication_required' });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!supabaseUrl || !serviceKey || !anonKey) {
    return json(500, { error: 'server_misconfigured' });
  }

  let body: Record<string, unknown>;
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch {
    return json(400, { error: 'invalid_json' });
  }

  const expiresIn = clampTtl(body.expires_in);
  const rawPaths = body.object_paths;

  // ---- BATCH mode ----------------------------------------------------------
  if (Array.isArray(rawPaths)) {
    const paths = rawPaths
      .map((p) => String(p ?? '').trim())
      .filter((p) => p.length > 0)
      .slice(0, MAX_PATHS);

    if (paths.length === 0) {
      return json(400, { error: 'object_paths_required' });
    }

    let decision: { items?: SignResult[] };
    try {
      const authRes = await fetch(supabaseUrl + '/rest/v1/rpc/create_signed_witness_urls', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          apikey: anonKey,
          Authorization: 'Bearer ' + token,
        },
        body: JSON.stringify({ p_paths: paths, p_expires_in: expiresIn }),
      });

      if (!authRes.ok) {
        const raw = await authRes.text();
        console.error('create_signed_witness_urls rejected the request', authRes.status, raw);
        if (authRes.status === 400) return json(400, { error: 'invalid_path' });
        if (authRes.status === 401) return json(401, { error: 'authentication_required' });
        return json(403, { error: 'not_authorized' });
      }

      decision = (await authRes.json()) as { items?: SignResult[] };
    } catch (err) {
      console.error('authorization call failed', err);
      return json(502, { error: 'authorization_unavailable' });
    }

    const items = decision.items ?? [];
    const out: SignResult[] = [];

    for (const item of items) {
      const base: SignResult = {
        path: item.path,
        signed_url: null,
        reason: item.reason ?? null,
        authorized: item.authorized === true,
        source: item.source ?? null,
        object_path: item.object_path ?? null,
        group_id: item.group_id ?? null,
        owner_id: item.owner_id ?? null,
        expires_in: Number(item.expires_in ?? expiresIn),
      };

      if (!base.authorized || !base.object_path) {
        // The path failed its check: the reason explains WHY, and it never
        // reveals whether the object exists.
        out.push(base);
        continue;
      }

      // A deployment that ships `storage.create_signed_url` already signed it.
      if (typeof item.signed_url === 'string' && item.signed_url.length > 0) {
        out.push({ ...base, signed_url: item.signed_url, source: 'database' });
        continue;
      }

      try {
        const signRes = await fetch(
          supabaseUrl + '/storage/v1/object/sign/' + BUCKET + '/' + base.object_path,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              apikey: serviceKey,
              Authorization: 'Bearer ' + serviceKey,
            },
            body: JSON.stringify({ expiresIn: base.expires_in }),
          },
        );

        if (!signRes.ok) {
          const raw = await signRes.text();
          console.error('storage signing failed', signRes.status, raw);
          out.push({ ...base, signed_url: null, reason: 'object_not_found' });
          continue;
        }

        const signed = (await signRes.json()) as { signedURL?: string };
        if (!signed.signedURL) {
          out.push({ ...base, signed_url: null, reason: 'signing_failed' });
          continue;
        }

        out.push({
          ...base,
          signed_url: supabaseUrl + '/storage/v1' + signed.signedURL,
          source: 'edge_function',
        });
      } catch (err) {
        console.error('signing call failed', err);
        out.push({ ...base, signed_url: null, reason: 'signing_unavailable' });
      }
    }

    return json(200, { items: out, count: out.length, expires_in: expiresIn });
  }

  // ---- SINGLE mode (unchanged) --------------------------------------------
  const requestedPath = String(body.object_path ?? body.path ?? '').trim();
  if (!requestedPath) {
    return json(400, { error: 'object_path_required' });
  }

  // ---- 1. authorize as the caller -----------------------------------------
  let decision: Record<string, unknown>;
  try {
    const authRes = await fetch(supabaseUrl + '/rest/v1/rpc/create_signed_witness_url', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // The apikey must be the project API key; the CALLER's JWT goes in
        // Authorization so that auth.uid() is the real user.
        apikey: anonKey,
        Authorization: 'Bearer ' + token,
      },
      body: JSON.stringify({
        p_object_path: requestedPath,
        p_expires_in: expiresIn,
      }),
    });

    if (!authRes.ok) {
      const raw = await authRes.text();
      console.error('create_signed_witness_url rejected the request', authRes.status, raw);
      if (authRes.status === 400) return json(400, { error: 'invalid_path' });
      if (authRes.status === 401) return json(401, { error: 'authentication_required' });
      return json(403, { error: 'not_authorized' });
    }

    decision = (await authRes.json()) as Record<string, unknown>;
  } catch (err) {
    console.error('authorization call failed', err);
    return json(502, { error: 'authorization_unavailable' });
  }

  const objectPath = typeof decision.object_path === 'string' ? decision.object_path : '';
  if (!objectPath) {
    return json(403, { error: 'not_authorized' });
  }

  // The database already signed it (deployments that ship
  // storage.create_signed_url) — hand the URL back untouched.
  if (typeof decision.signed_url === 'string' && decision.signed_url.length > 0) {
    return json(200, {
      signed_url: decision.signed_url,
      expires_in: decision.expires_in,
      object_path: objectPath,
      source: 'database',
    });
  }

  // ---- 2. sign with the service role --------------------------------------
  try {
    const signRes = await fetch(
      supabaseUrl + '/storage/v1/object/sign/' + BUCKET + '/' + objectPath,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          apikey: serviceKey,
          Authorization: 'Bearer ' + serviceKey,
        },
        body: JSON.stringify({ expiresIn: Number(decision.expires_in ?? expiresIn) }),
      },
    );

    if (!signRes.ok) {
      const raw = await signRes.text();
      console.error('storage signing failed', signRes.status, raw);
      return json(404, { error: 'object_not_found' });
    }

    const signed = (await signRes.json()) as { signedURL?: string };
    if (!signed.signedURL) {
      return json(500, { error: 'signing_failed' });
    }

    return json(200, {
      signed_url: supabaseUrl + '/storage/v1' + signed.signedURL,
      expires_in: decision.expires_in,
      object_path: objectPath,
      source: 'edge_function',
    });
  } catch (err) {
    console.error('signing call failed', err);
    return json(502, { error: 'signing_unavailable' });
  }
});
