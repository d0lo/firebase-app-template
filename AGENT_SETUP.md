# Agent Setup Runbook

**You are an agent standing up a new Firebase project from this template. Read this top to
bottom and execute it.** It encodes every step. Steps are tagged:

- 🤖 **AGENT** — you do this yourself (git, GitHub API/MCP, workflow runs, reading logs).
- 🔴 **HUMAN** — the user must do this; it needs their Google identity, a payment method, or a
  GitHub setting you can't change via API. Tell them the exact click-path and wait.

The design goal: the user provides **one secret** (a service-account key) and does a few
irreducible console clicks; **you do everything else**, including reading deploy logs and
fixing failures. The project id is derived from the key — nothing is hardcoded.

> The full out-of-code settings/permissions list is in [`docs/SETTINGS.md`](docs/SETTINGS.md).
> Note these do **not** copy when a repo is created from this template — re-apply them each time.

---

## Phase 0 — Decide scope

Ask the user one thing if it isn't obvious: **does this project need Cloud Functions?**

- **No Functions** → everything runs on the **free Spark plan**. No billing step.
- **Functions** → requires the **Blaze (pay-as-you-go) plan**, i.e. a 🔴 billing step.

Everything else is identical either way.

---

## Phase 1 — Create the repo from this template

🔴 **HUMAN:** On GitHub, open this template repo → **Use this template → Create a new
repository** → name it → Create. (Agents generally can't create repos via API in restricted
environments; if yours can — `POST /repos/{owner}/{repo}/generate` — do it yourself instead.)

🤖 **AGENT:** Bring the new repo into your session and clone/push to it. In Claude Code on the
web that means: call `add_repo(owner, newRepo)`, then operate via git or the GitHub MCP. Confirm
you can read it before continuing.

🤖 **AGENT:** Create the `dev` branch and adopt `feature/* → PR → dev → main` from here on:
`git branch dev && git push -u origin dev`.

---

## Phase 2 — Human-only Google/Firebase setup

Give the user these exact steps (Safari/console works on mobile):

🔴 **HUMAN — create the project:**
1. **console.firebase.google.com** → **Add project** → name it → (Analytics optional) → Create.

🔴 **HUMAN — enable Firestore & Auth:**
2. Build → **Firestore Database** → Create database → pick a location (permanent) → **Production
   mode** → Create.
3. Build → **Authentication** → Get started → enable the **Anonymous** provider.
   (The bootstrap workflow also enables Anonymous, but doing it here first is harmless.)

🔴 **HUMAN — (only if using Functions) enable billing:**
4. ⚙ → **Usage and billing** → **Modify plan** → **Blaze** → attach a payment method.

🔴 **HUMAN — service-account key:**
5. **console.cloud.google.com** (same project selected) → **IAM & Admin → Service Accounts**.
6. Use the existing `firebase-adminsdk-…` account (or create one), then **IAM → edit that
   principal → add role `Owner`** (the default Admin SDK role can't deploy rules/functions).
7. Service Accounts → that account → **Keys → Add key → Create new key → JSON** → downloads a file.

🔴 **HUMAN — add the secret:**
8. GitHub → the new repo → **Settings → Secrets and variables → Actions → New repository
   secret** → name **`FIREBASE_SERVICE_ACCOUNT`** → paste the entire JSON → Add.

> 🧹 Remind the user they can delete this key (or remove the Owner role) once setup is done.

---

## Phase 3 — Agent-driven configuration

🤖 **AGENT — run the bootstrap workflow.** It enables APIs, creates the Firestore DB, deploys
rules, enables anonymous auth, registers a web app, and prints the web config. Trigger it
(`workflow_dispatch` on `firebase-bootstrap.yml`, input `region` = the user's Firestore
location), then read the run logs.

- If a step fails (e.g. an API not yet enabled, a permission gap), diagnose from the log and
  re-run. Common fixes: wait/re-run after API enablement propagates; confirm the SA has Owner.

🤖 **AGENT — extract the web config.** In the bootstrap log, find the block between
`===FIREBASE_CONFIG_START===` and `===FIREBASE_CONFIG_END===`. It contains the `firebaseConfig`
(apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId).

🔴 **HUMAN — add the client secrets.** You (agent) **cannot set GitHub secrets via API**. Give
the user the six values and have them add each as a repo secret (Settings → Secrets and
variables → Actions):
`VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_AUTH_DOMAIN`, `VITE_FIREBASE_PROJECT_ID`,
`VITE_FIREBASE_STORAGE_BUCKET`, `VITE_FIREBASE_MESSAGING_SENDER_ID`, `VITE_FIREBASE_APP_ID`.

> Alternative (fewer human steps): since the web config is **public**, you may instead commit it
> by replacing `app/src/lib/firebaseConfig.ts` with the literal values. Pick one approach; don't
> do both. The secrets approach keeps config out of git; the commit approach removes six manual
> steps.

🤖 **AGENT — (if using Functions) deploy them.** Trigger `firebase-functions-deploy.yml`
(`workflow_dispatch`). Requires Blaze (Phase 2 step 4). Read logs; fix and re-run on failure.

---

## Phase 4 — Verify

🤖 **AGENT:**
- Confirm **CI is green** on the latest push (the `check` and `integration` jobs).
- Confirm **rules deployed** (bootstrap or the rules workflow succeeded).
- Confirm **Hosting** deployed: push to `main` (or open a PR for a preview) and read the
  `Firebase Hosting` workflow log for the live/preview URL. Post the URL to the user.
- If Functions: confirm the functions deploy succeeded and the callables are listed.

🔴 **HUMAN (recommended):** GitHub → repo → **Settings → Branches → Add ruleset** for `main`:
require a PR and require the `check` + `integration` status checks. (No API for this in most
agent toolkits.)

---

## Reference

### Secrets this template uses

| Secret | Required | Purpose |
|---|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | always | SA JSON; authorizes all deploys. Project id is derived from it. |
| `VITE_FIREBASE_*` (×6) | for Hosting | Public web config injected into the app build. |

### Workflows

| Workflow | Trigger | Does |
|---|---|---|
| `ci.yml` | push/PR | lint, format, typecheck, unit + emulator tests (gates correctness) |
| `firebase-bootstrap.yml` | manual | one-shot: APIs, DB, rules, anon auth, web app, print config |
| `firebase-deploy.yml` | push to rules / manual | deploy Firestore rules |
| `firebase-functions-deploy.yml` | push to functions / manual | bundle + deploy Functions (Blaze) |
| `firebase-hosting.yml` | push main / PR | live release on merge, preview channel on PR |

Deploy workflows **no-op gracefully** until `FIREBASE_SERVICE_ACCOUNT` exists, so early pushes
stay green.

### What the agent genuinely cannot do (so these stay 🔴)

- Create the Google/Firebase **project** (needs the user's Google login).
- Enable **billing** (needs a payment method).
- Generate the **service-account key** (needs console access to that project).
- Set **GitHub Actions secrets** (no API in typical agent toolkits; needs repo admin + encryption).
- Toggle **branch protection** / "**Use this template**" (GitHub settings UI).

Everything else — configuration, deploys, log-reading, fixes, verification — is 🤖.
