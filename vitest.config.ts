import { defineConfig } from "vitest/config";

// Unit tests only. Emulator integration tests live in firebase/test and run via
// `npm run test:integration` (which boots the emulators first).
export default defineConfig({
  test: {
    include: ["app/**/*.test.ts"],
    coverage: {
      provider: "v8",
      // Tune the include/thresholds to your real code. The example app has almost no
      // unit-testable logic; firebase.ts/main.ts are runtime glue covered by e2e instead.
      include: ["app/src/lib/firebaseConfig.ts"],
      thresholds: { lines: 80, functions: 80, statements: 80, branches: 50 },
    },
  },
});
