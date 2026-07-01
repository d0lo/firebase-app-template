# Agent Setup Runbook

**You are an agent standing up a new Firebase project from this template. Read this top to
bottom and execute it.** It encodes every step. Steps are tagged:

- 🤖 **AGENT** — you do this yourself (git, GitHub API/MCP, workflow runs, reading logs).
- 🔴 **HUMAN** — the user must do this; it needs their Google identity, a payment method, or a
  GitHub setting you can't change via API. Tell them the exact click-path and wait.

**This template is keyless.** GitHub Actions authenticates to Google via **Workload Identity
Federation** (short-lived OIDC tokens) — **no service-account key is ever created or stored.**
The user runs one script, adds a few repo *variables* (not secrets), and you do the rest.

> Full settings list: [`docs/SETTINGS.md`](docs/SETTINGS.md) (these do **not** copy when a repo is
> made from this template — re-apply each time).
>
> **Fast path:** [`terraform/`](terraform/) provisions everything — project, Firestore, auth, the
> WIF pool/provider, a least-privilege deploy SA, **and** sets the GitHub repo variables + branch
> protection — in one `terraform apply`, keyless. Prefer it when the user can run Terraform; the
> phases below are the click-through equivalent.

---

## Phase 0 — Decide scope

**Does this project need Cloud Functions?** No → free **Spark** plan, no billing. Yes → **Blaze**
(pay-as-you-go) billing, a 🔴 step. Everything else is identical.

---

## Phase 1 — Create the repo from this template

🔴 **HUMAN:** GitHub → this template → **Use this template → Create a new repository** → name it.

🤖 **AGENT:** Bring it into your session (`add_repo(owner, repo)` in Claude Code on the web), then
create `dev` and adopt `feature/* → PR → dev → main`: `git branch dev && git push -u origin dev`.

---

## Phase 2 — Human-only Google setup (one script, no key)

🔴 **HUMAN — create the project:** console.firebase.google.com → **Add project** → name it.
Enable **Hosting** (Build → Hosting → Get started → click through). If using Functions, also
enable **Blaze billing** (⚙ → Usage and billing → Modify plan).

🔴 **HUMAN — run the setup script in Cloud Shell:**
1. **console.cloud.google.com** → select the project → tap the **`>_`** (Cloud Shell) icon.
2. Open [`scripts/setup.sh`](scripts/setup.sh), edit the `PROJECT_ID`, `REPO`, and
   `ENABLE_FUNCTIONS` lines at the top, paste the whole thing into Cloud Shell, run it.
3. It sets up Workload Identity Federation + a least-privilege deploy account + Firestore + anon
   auth, and prints three `WIF_*`/`FIREBASE_PROJECT_ID` values. **No key is created.**

---

## Phase 3 — Wire the repo variables

🔴 **HUMAN — add repo VARIABLES** (Settings → Secrets and variables → Actions → **Variables** tab
→ New repository variable). Agents can't set these via typical toolkits, so hand the user the
values from the script output:

- `WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID` (from the script)
- If the app calls Firebase at runtime, also the six `VITE_FIREBASE_*` (Firebase console →
  Project settings → your Web app config). These are public, so variables (not secrets) are right.

🤖 **AGENT — trigger + verify deploys.** Push to `main` (Hosting live) or open a PR (Hosting
preview channel); for rules/functions, the relevant workflow runs on the matching push or via
`workflow_dispatch`. Read the run logs, extract the URL, fix and re-run on failure.

---

## Phase 4 — Verify

🤖 **AGENT:** confirm CI is green (`check` + `integration`); confirm Hosting deployed and post the
live/preview URL; if Functions, confirm the callables deployed.

🔴 **HUMAN (recommended):** Settings → Branches → add a ruleset for `main` requiring a PR + the
`check`/`integration` checks (Terraform sets this automatically).

---

## Reference

### Repo variables this template uses (no secrets!)

| Variable | Required | Purpose |
|---|---|---|
| `WIF_PROVIDER` | always | Workload Identity provider resource name (keyless auth) |
| `WIF_SERVICE_ACCOUNT` | always | The deploy service account to impersonate |
| `FIREBASE_PROJECT_ID` | always | Project to deploy to |
| `VITE_FIREBASE_*` (×6) | if the app uses Firebase | Public web config injected at build |

### Workflows

| Workflow | Trigger | Does |
|---|---|---|
| `ci.yml` | push/PR | lint, format, typecheck, unit + emulator tests, terraform validate |
| `firebase-deploy.yml` | push to rules / manual | deploy Firestore rules (keyless) |
| `firebase-functions-deploy.yml` | push to functions / manual | bundle + deploy Functions (keyless, Blaze) |
| `firebase-hosting.yml` | push main / PR | live on merge, preview channel on PR (keyless) |

Deploy workflows **no-op gracefully** until the `WIF_*` variables exist, so early pushes stay green.

### What the agent genuinely cannot do (so these stay 🔴)

- Create the Google/Firebase **project** and enable **billing**.
- Run the **Cloud Shell setup script** (it runs as the user's Google identity).
- Set **GitHub Actions variables** / toggle **branch protection** / "**Use this template**".

Everything else — configuration, deploys, log-reading, fixes, verification — is 🤖. (The Terraform
fast path collapses even the 🔴 script + variables into one `apply`.)
