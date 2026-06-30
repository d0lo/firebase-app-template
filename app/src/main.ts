import { ensureAuth } from "./lib/firebase";
import { isConfigured } from "./lib/firebaseConfig";

const el = document.getElementById("app")!;

async function main(): Promise<void> {
  if (!isConfigured()) {
    el.textContent =
      "Firebase is not configured yet — set the VITE_FIREBASE_* env vars (see app/.env.example).";
    return;
  }
  try {
    const uid = await ensureAuth();
    el.textContent = `Connected to Firebase. Signed in anonymously as ${uid}.`;
  } catch (err) {
    el.textContent = `Firebase error: ${(err as Error).message}`;
  }
}

void main();
