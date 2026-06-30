// Cloud Functions entry point. Callables authenticate the caller, then do work with
// the Admin SDK (which bypasses security rules — so functions are the only writer of
// authoritative `server/*` state). Replace these examples with your own.
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";

initializeApp();
const db = getFirestore();

function requireUid(req: CallableRequest): string {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  return uid;
}

/** Example: a trivial authenticated callable. */
export const ping = onCall((req) => {
  const uid = requireUid(req);
  return { pong: true, uid };
});

/** Example: write authoritative, client-unwritable state via the Admin SDK. */
export const recordVisit = onCall(async (req) => {
  const uid = requireUid(req);
  await db
    .collection("server")
    .doc("visits")
    .set({ count: FieldValue.increment(1), lastUid: uid }, { merge: true });
  return { ok: true };
});
