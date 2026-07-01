# Settings & Permissions Checklist

Out-of-code settings a project from this template depends on — none live in the file tree, so
they're easy to forget. Tags: 🤖 an agent can do it · 🔴 only a human can (login / payment /
admin UI). An agent following `AGENT_SETUP.md` will prompt you for the 🔴 items.

> ⚠️ **"Use this template" copies files, NOT settings.** A new repo gets this checklist and the
> workflows, but **none** of the actual config below — secrets, branch protection, secret
> scanning, the Actions policy, the template toggle, and every Firebase/GCP project setting are
> per-repo/per-project and must be re-applied each time. Re-run this checklist on every new repo.
> (Also: "Use this template" copies only the default branch unless you tick *Include all
> branches* — the agent re-creates `dev` anyway.)

## GitHub (do-now)

- [ ] 🔴 **Secret scanning + push protection** — Settings → Code security. Blocks accidental
      commits of a service-account key.
- [ ] 🔴 **Branch protection on `main`** — require a PR + status checks `check` and `integration`.
- [ ] 🔴 **Auto-delete head branches** + **squash-merge** — Settings → General → Pull Requests.
      *(optional, keeps the `feature/*` flow tidy)*
- [ ] 🔴 **Actions policy** — Settings → Actions → General → "Allow all actions", and enable
      **"Allow GitHub Actions to create and approve pull requests"** (release-please opens PRs).
- [ ] 🔴 **Repo variables** (not secrets!) — `WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT`,
      `FIREBASE_PROJECT_ID` (+ 6× `VITE_FIREBASE_*` if the app uses Firebase). Set via the
      **Variables** tab. This template is **keyless** — there are no secrets to add.
- [ ] 🔴 **Template repository toggle** *(template repo itself only)* — Settings → General →
      ✅ Template repository.

> 💡 Most of the deploy-time + GCP items below (and the repo variables + branch protection above)
> are provisioned in one `terraform apply` — see [`../terraform/`](../terraform/). Terraform can't
> only create the billing account and the GitHub repo itself.

## Firebase Console (deploy-time)

- [ ] 🔴 Firebase **project** + Firestore (location) + **Anonymous Auth**.
- [ ] 🔴 **Blaze billing** — only if using Cloud Functions (everything else is free).
- [ ] 🔴 **Auth → Authorized domains** — add any **custom domain**; sign-in silently fails on
      unlisted domains (`*.web.app`/`*.firebaseapp.com` are auto-added).

## Google Cloud / IAM (deploy-time — done by `scripts/setup.sh` or Terraform)

- [ ] 🔴 **Keyless auth (Workload Identity Federation)** — no service-account key exists. GitHub
      authenticates with short-lived OIDC tokens; the deploy SA has **least-privilege** roles
      (hosting/rules/datastore, + Functions roles only if enabled) and can be impersonated **only
      by this repo**. Set up by `scripts/setup.sh` (Cloud Shell) or `terraform apply`.
- [ ] 🤖/🔴 **APIs** — enabled by the setup script/Terraform (IAM, STS, Firestore, Identity
      Toolkit, Hosting; + Functions/Build/Artifact/Run/Eventarc/PubSub when Functions are on).

## Hardening (before public launch)

- [ ] **Budget + alerts** (Cloud Billing) once on Blaze.
- [ ] **App Check** — block non-app clients from Firestore/Functions.
- [ ] **Firestore backups / PITR**.
