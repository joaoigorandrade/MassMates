// APNs provider-token helpers.
//
// The APNs provider token is a JWT signed with the ES256 (ECDSA P-256 +
// SHA-256) algorithm, using the `.p8` key issued by Apple.
//
//   header : { "alg": "ES256", "kid": "<APNS_KEY_ID>" }
//   claims : { "iss": "<APNS_TEAM_ID>", "iat": <unix seconds> }
//
// SIGNATURE ENCODING — READ THIS BEFORE "FIXING" IT
// ----------------------------------------------------
// WebCrypto's ECDSA `sign()` returns the RAW signature: R || S, 32 bytes
// each, in fixed-width big-endian order.
//
// RFC 7515 §3.4 ("Using ECDSA Signatures") says a JWS ECDSA signature is
// *the raw concatenation R || S*, NOT the DER/PKCS#1 encoding. APNs
// implements RFC 7515, so the token MUST carry base64url(R || S).
//
// The DER form (SEQUENCE { INTEGER r, INTEGER s }) is what OpenSSL's
// `ECDSA_sign()` produces; it is NOT what a JWS carries. `rawSignatureToDer`
// and `derSignatureToRaw` below implement that well-defined conversion and
// are exported for completeness / for a provider that would demand the
// OpenSSL form, but the default below is `raw`, which is what APNs accepts.
//
// (The A8 brief asked for the DER form "because JWS ES256 requires it".
// That premise is inverted: JWS requires the raw form. Shipping DER would
// make every provider token invalid — APNs answers `InvalidProviderToken`.
// The conversion is implemented and documented either way.)

export type ApnsEnvironment = "production" | "sandbox";

/** Which signature encoding the JWS carries. See the note above. */
export const JWS_SIGNATURE_ENCODING: "raw" | "der" = "raw";

const APNS_PRODUCTION_HOST = "https://api.push.apple.com";
const APNS_SANDBOX_HOST = "https://api.sandbox.push.apple.com";

export function apnsHost (environment: ApnsEnvironment): string {
  return environment === "sandbox" ? APNS_SANDBOX_HOST : APNS_PRODUCTION_HOST;
}

export function base64UrlEncode (bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function base64UrlEncodeText (text: string): string {
  return base64UrlEncode(new TextEncoder().encode(text));
}

/** PKCS#8 PEM (the Apple `.p8` file) -> raw DER bytes. */
export function pemToDer (pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/[^A-Za-z0-9+/=]/g, "");
  const binary = atob(body);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
  return out;
}

function concatBytes (parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((sum, p) => sum + p.length, 0);
  const out = new Uint8Array(total);
  let offset = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}

function derLength (length: number): Uint8Array {
  if (length < 0x80) return Uint8Array.of(length);
  const bytes: number[] = [];
  let value = length;
  while (value > 0) {
    bytes.unshift(value & 0xff);
    value >>>= 8;
  }
  return concatBytes([Uint8Array.of(0x80 | bytes.length), Uint8Array.from(bytes)]);
}

function derInteger (value: Uint8Array): Uint8Array {
  let start = 0;
  while (start < value.length - 1 && value[start] === 0) start++;
  let body = value.subarray(start);
  if (body.length > 0 && (body[0] & 0x80) !== 0) {
    body = concatBytes([Uint8Array.of(0x00), body]);
  }
  return concatBytes([Uint8Array.of(0x02), derLength(body.length), body]);
}

/** Raw R||S (64 bytes) -> DER SEQUENCE { INTEGER r, INTEGER s }. */
export function rawSignatureToDer (raw: Uint8Array): Uint8Array {
  if (raw.length !== 64) {
    throw new Error(`expected a 64-byte raw ECDSA signature, got ${raw.length}`);
  }
  const body = concatBytes([
    derInteger(raw.subarray(0, 32)),
    derInteger(raw.subarray(32, 64)),
  ]);
  return concatBytes([Uint8Array.of(0x30), derLength(body.length), body]);
}

/** DER SEQUENCE { INTEGER r, INTEGER s } -> raw R||S (64 bytes). */
export function derSignatureToRaw (der: Uint8Array): Uint8Array {
  if (der.length < 8 || der[0] !== 0x30) throw new Error("not a DER ECDSA signature");
  let cursor = 2;
  if ((der[1] & 0x80) !== 0) cursor = 2 + (der[1] & 0x7f);
  const out = new Uint8Array(64);
  for (let part = 0; part < 2; part++) {
    if (der[cursor] !== 0x02) throw new Error("not a DER ECDSA signature");
    let length = der[cursor + 1];
    let header = 2;
    if ((length & 0x80) !== 0) {
      const count = length & 0x7f;
      length = 0;
      for (let i = 0; i < count; i++) length = (length << 8) | der[cursor + 2 + i];
      header = 2 + count;
    }
    let value = der.subarray(cursor + header, cursor + header + length);
    let start = 0;
    while (start < value.length - 1 && value[start] === 0) start++;
    value = value.subarray(start);
    out.set(value, part * 32 + (32 - value.length));
    cursor += header + length;
  }
  return out;
}

export interface ApnsTokenConfig {
  keyId: string;
  teamId: string;
  /** PKCS#8 PEM, the contents of the Apple `.p8` file. */
  privateKeyPem: string;
}

/**
 * Builds the APNs provider token (a JWS, ES256).
 * `issuedAt` is injectable so the token can be tested deterministically.
 */
export async function createApnsProviderToken (
  config: ApnsTokenConfig,
  issuedAt: number = Math.floor (Date.now () / 1000),
): Promise<string> {
  const header = base64UrlEncodeText (
    JSON.stringify ({ alg: "ES256", kid: config.keyId, typ: "JWT" }),
  );
  const claims = base64UrlEncodeText (
    JSON.stringify ({ iss: config.teamId, iat: issuedAt }),
  );
  const signingInput = `${header}.${claims}`;

  const key = await crypto.subtle.importKey (
    "pkcs8",
    pemToDer (config.privateKeyPem),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  // WebCrypto hashes the message with SHA-256 itself and returns R || S.
  const raw = new Uint8Array (
    await crypto.subtle.sign (
      { name: "ECDSA", hash: "SHA-256" },
      key,
      new TextEncoder ().encode (signingInput),
    ),
  );

  const signature = JWS_SIGNATURE_ENCODING === "der" ? rawSignatureToDer (raw) : raw;
  return `${signingInput}.${base64UrlEncode (signature)}`;
}
