import { test, expect } from "@playwright/test";

// Smoke test: the app builds, serves, and its JS runs (the placeholder swaps out).
// Replace with real user-flow assertions for your app.
test("app loads and runs", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("#app")).toContainText("Firebase");
});
