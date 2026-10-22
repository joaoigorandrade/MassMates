// AdMob Server-Side Verification — pure crypto helpers.
//
// Kept in its own module so the verification can be unit-tested locally
// (node --test) with the exact same code that runs on Deno Edge Runtime.
//
// AdMob signs the SSV query string with the app's private RSA key and sends
// the matching public key (base64, X.509 SubjectPublicKeyInfo DER) in the
// `app_signing_key` parameter. The signature (`sig`) is base64 RSA-SHA256
// (RSASSA-PKCS1-v1_5) over the canonical query string: every parameter
// except `sig`, sorted alphabetically by name, joined with `&`.

export function base64ToBytes (b64: string): Uint8Array {
  const clean = b64.replace(/\s+/g, "").replace(/-/g, "+").replace(/_/g, "/");
  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/**
 * Accepts a PEM ("-----BEGIN PUBLIC KEY-----") or a bare base64 blob and
 * returns the DER (SubjectPublicKeyInfo) bytes, or null when the material is
 * not usable.
 */
export function derFromKeyMaterial (material: string | null | undefined): Uint8Array | null {
  if (!material) return null;
  const trimmed = material.trim();
  if (trimmed.length === 0) return null;
  const pem = trimmed.match(/-----BEGIN [^-]+-----([\s\S]*?)-----END [^-]+-----/);
  const body = pem ? pem[1] : trimmed;
  const base64 = body.replace(/[^A-Za-z0-9+/=]/g, "");
  if (base64.length === 0) return null;
  try {
    return base64ToBytes(base64);
  } catch {
    return null;
  }
}

export function sameBytes (a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i += 1) diff |= a[i] ^ b[i];
  return diff === 0;
}

interface QueryPair {
  rawKey: string;
  rawValue: string;
  key: string;
}

function splitQuery (rawQuery: string): QueryPair[] {
  return rawQuery
    .replace(/^\?/, "")
    .split("&")
    .filter((part) => part.length > 0)
    .map((part) => {
      const index = part.indexOf("=");
      const rawKey = index === -1 ? part : part.slice(0, index);
      const rawValue = index === -1 ? "" : part.slice(index + 1);
      return {
        rawKey,
        rawValue,
        key: decodeURIComponent(rawKey.replace(/\+/g, " ")),
      };
    });
}

/**
 * The candidate canonical strings of an SSV query. Google documents the
 * canonical form as "the query parameters, excluding `sig`, sorted
 * alphabetically and joined with &". Implementations differ on whether the
 * values are compared raw (as received, still percent-encoded) or decoded,
 * so every reasonable encoding is offered to the verifier: a signature that
 * matches NONE of them is rejected.
 */
export function canonicalQueryCandidates (rawQuery: string): Uint8Array[] {
  const pairs = splitQuery(rawQuery).filter((pair) => pair.key !== "sig");
  pairs.sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0));

  const raw = pairs.map((p) => `${p.rawKey}=${p.rawValue}`).join("&");
  const encoded = pairs
    .map((p) => `${encodeURIComponent(p.key)}=${encodeURIComponent(decodeURIComponent(p.rawValue.replace(/\+/g, " ")))}`)
    .join("&");
  const plain = pairs
    .map((p) => `${p.key}=${decodeURIComponent(p.rawValue.replace(/\+/g, " "))}`)
    .join("&");

  const encoder = new TextEncoder();
  return [raw, encoded, plain].map((value) => encoder.encode(value));
}

/**
 * Verifies an AdMob SSV signature. Returns false (never throws) when the key
 * cannot be imported or the signature does not match.
 */
export async function verifyAdMobSignature (
  derPublicKey: Uint8Array,
  signature: Uint8Array,
  rawQuery: string
): Promise<boolean> {
  let key: CryptoKey;
  try {
    key = await crypto.subtle.importKey(
      "spki",
      derPublicKey as unknown as BufferSource,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["verify"]
    );
  } catch {
    return false;
  }

  for (const message of canonicalQueryCandidates(rawQuery)) {
    try {
      const valid = await crypto.subtle.verify(
        "RSASSA-PKCS1-v1_5",
        key,
        signature as unknown as BufferSource,
        message as unknown as BufferSource
      );
      if (valid) return true;
    } catch {
      // try the next candidate
    }
  }
  return false;
}
