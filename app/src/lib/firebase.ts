// Firebase client initialization. Lazy, no side effects on import. Exposes Firestore/
// Auth/Functions handles, anonymous sign-in, and dev-emulator wiring.
import { initializeApp, type FirebaseApp } from "firebase/app";
import { getFirestore, connectFirestoreEmulator, type Firestore } from "firebase/firestore";
import { getAuth, connectAuthEmulator, signInAnonymously, type Auth } from "firebase/auth";
import { getFunctions, connectFunctionsEmulator, type Functions } from "firebase/functions";
import { firebaseConfig } from "./firebaseConfig";

let _app: FirebaseApp | null = null;
let _emulatorsConnected = false;

const useEmulators = Boolean(import.meta.env.DEV && import.meta.env.VITE_USE_EMULATORS);

function app(): FirebaseApp {
  if (!_app) _app = initializeApp(firebaseConfig);
  return _app;
}

export function auth(): Auth {
  return getAuth(app());
}

export function functions(): Functions {
  return getFunctions(app());
}

export function db(): Firestore {
  const d = getFirestore(app());
  if (useEmulators && !_emulatorsConnected) {
    connectFirestoreEmulator(d, "127.0.0.1", 8080);
    connectFunctionsEmulator(functions(), "127.0.0.1", 5001);
    connectAuthEmulator(auth(), "http://127.0.0.1:9099", { disableWarnings: true });
    _emulatorsConnected = true;
  }
  return d;
}

/** Ensure an (anonymous) signed-in user; resolves to the uid. Call before any write. */
export async function ensureAuth(): Promise<string> {
  const cred = await signInAnonymously(auth());
  return cred.user.uid;
}
