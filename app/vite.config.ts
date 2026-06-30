import { defineConfig } from "vite";

export default defineConfig({
  // Built output is copied into firebase/public by the hosting workflow before deploy.
  build: { outDir: "dist" },
});
