// Local unit test of the AdMob SSV signature verification.
//
//   node --test supabase/functions/admob-ssv/ssv_crypto.test.ts
//
// It proves the three properties the Edge Function depends on:
//   1. a signature made with the app's private key over the canonical query
//      string IS accepted;
//   2. a tampered query string is REJECTED;
//   3. a signature made with another key is REJECTED.

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  base64ToBytes,
  canonicalQueryCandidates,
  derFromKeyMaterial,
  sameBytes,
  verifyAdMobSignature,
} from "./ssv_crypto.ts";

const toBase64 = (bytes: Uint8Array): string => Buffer.from(bytes).toString("base64");

async function makeKeyPair (): Promise<{ privateKey: CryptoKey; publicDer: Uint8Array }> {
  const pair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"]
  );
  const spki = await crypto.subtle.exportKey("spki", pair.publicKey);
  return { privateKey: pair.privateKey, publicDer: new Uint8Array(spki) };
}

async function sign (privateKey: CryptoKey, message: Uint8Array): Promise<Uint8Array> {
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    message as unknown as BufferSource
  );
  return new Uint8Array(signature);
}

test("a valid AdMob SSV signature is accepted", async () => {
  const { privateKey, publicDer } = await makeKeyPair();
  const query = [
    "ad_type=rewarded",
    "ad_value=0.01",
    "currency=USD",
    "reward_type=streak_mercy",
    "reward_amount=1",
    "package_name=joaoigor.MassMates",
    `app_signing_key=${toBase64(publicDer)}`,
    "massmates_txn=11111111-2222-3333-4444-555555555555",
  ].join("&");

  const signature = await sign(privateKey, canonicalQueryCandidates(query)[0]);
  const valid = await verifyAdMobSignature(publicDer, signature, query);
  assert.equal(valid, true);
});

test("a tampered query string is rejected", async () => {
  const { privateKey, publicDer } = await makeKeyPair();
  const query = [
    "ad_type=rewarded",
    "ad_value=0.01",
    "currency=USD",
    "reward_type=streak_mercy",
    "reward_amount=1",
    "package_name=joaoigor.MassMates",
    `app_signing_key=${toBase64(publicDer)}`,
  ].join("&");

  const signature = await sign(privateKey, canonicalQueryCandidates(query)[0]);
  const tampered = `${query}&reward_amount=100`;
  const valid = await verifyAdMobSignature(publicDer, signature, tampered);
  assert.equal(valid, false);
});

test("a signature made with another key is rejected", async () => {
  const { privateKey } = await makeKeyPair();
  const other = await makeKeyPair();
  const query = "ad_type=rewarded&ad_value=0.01&currency=USD&reward_type=group_slot&reward_amount=1&package_name=joaoigor.MassMates";

  const signature = await sign(privateKey, canonicalQueryCandidates(query)[0]);
  const valid = await verifyAdMobSignature(other.publicDer, signature, query);
  assert.equal(valid, false);
});

test("the canonical string excludes sig and is sorted by name", () => {
  const candidates = canonicalQueryCandidates("b=2&a=1&sig=zzz");
  const decoded = new TextDecoder().decode(candidates[0]);
  assert.equal(decoded, "a=1&b=2");
});

test("the configured key is compared byte for byte", () => {
  const der = new Uint8Array([1, 2, 3, 4]);
  const pem = "-----BEGIN PUBLIC KEY-----\n" + toBase64(der) + "\n-----END PUBLIC KEY-----";
  const fromPem = derFromKeyMaterial(pem);
  assert.ok(fromPem);
  assert.equal(sameBytes(fromPem, der), true);
  assert.equal(sameBytes(fromPem, new Uint8Array([1, 2, 3, 5])), false);
  assert.equal(derFromKeyMaterial(""), null);
  assert.equal(derFromKeyMaterial(null), null);
});

test("base64 is decoded to the exact bytes", () => {
  assert.deepEqual([...base64ToBytes(toBase64(new Uint8Array([0, 1, 254, 255])))], [0, 1, 254, 255]);
});
