import { defineConfig } from "vitest/config";

// Unit tests only. Emulator integration tests live in firebase/test and run via
// `npm run test:integration` (which boots the emulators first).
export default defineConfig({
  test: {
    include: ["app/**/*.test.ts"],
  },
});
