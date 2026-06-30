import { describe, it, expect } from "vitest";
import { isConfigured } from "./firebaseConfig";

describe("isConfigured", () => {
  it("is false when the VITE_FIREBASE_* env vars are unset", () => {
    // No real config in the test environment, so this should report unconfigured.
    expect(isConfigured()).toBe(false);
  });
});
