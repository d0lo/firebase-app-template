// Firestore security-rules integration tests (run against the emulator).
// Validates the default ruleset: users own their own doc; the server collection
// is read-only to clients. Run via `npm run test:integration`.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { beforeAll, afterAll, beforeEach, describe, it } from "vitest";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-template",
    firestore: {
      rules: readFileSync(fileURLToPath(new URL("../firestore.rules", import.meta.url)), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

describe("users/{uid}", () => {
  it("a user can write their own doc", async () => {
    const alice = env.authenticatedContext("alice");
    await assertSucceeds(setDoc(doc(alice.firestore(), "users/alice"), { name: "Alice" }));
  });

  it("a user cannot write someone else's doc", async () => {
    const alice = env.authenticatedContext("alice");
    await assertFails(setDoc(doc(alice.firestore(), "users/bob"), { name: "hax" }));
  });

  it("an unauthenticated client cannot write a user doc", async () => {
    const anon = env.unauthenticatedContext();
    await assertFails(setDoc(doc(anon.firestore(), "users/alice"), { name: "anon" }));
  });
});

describe("server/{doc}", () => {
  it("is world-readable but not client-writable", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "server/state"), { ok: true });
    });
    const anon = env.unauthenticatedContext();
    await assertSucceeds(getDoc(doc(anon.firestore(), "server/state")));

    const alice = env.authenticatedContext("alice");
    await assertFails(setDoc(doc(alice.firestore(), "server/state"), { ok: false }));
  });
});
