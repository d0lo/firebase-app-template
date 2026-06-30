import { defineConfig } from "vitest/config";

// Emulator integration tests — run via `npm run test:integration`, which boots the
// Firebase emulators first. Kept separate from the unit suite so `npm test` stays fast.
export default defineConfig({
  test: {
    include: ["firebase/test/**/*.test.ts"],
    testTimeout: 20000,
    hookTimeout: 40000,
    fileParallelism: false,
  },
});
