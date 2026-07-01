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
- [ ] 🔴 **Actions policy** — Settings → Actions → General → "Allow all actions" (workflows use
      third-party actions: `w9jds/*`, `FirebaseExtended/*`, `google-github-actions/*`).
- [ ] 🔴 **Repo secrets** — `FIREBASE_SERVICE_ACCOUNT` and 6× `VITE_FIREBASE_*`.
- [ ] 🔴 **Template repository toggle** *(template repo itself only)* — Settings → General →
      ✅ Template repository.

> 💡 Most of the deploy-time + GCP items below (and the repo secrets + branch protection above)
> can be provisioned in one `terraform apply` — see [`../terraform/`](../terraform/). The only
> parts Terraform can't do are creating the billing account and the GitHub repo itself.

## Firebase Console (deploy-time)

- [ ] 🔴 Firebase **project** + Firestore (location) + **Anonymous Auth**.
- [ ] 🔴 **Blaze billing** — only if using Cloud Functions (everything else is free).
- [ ] 🔴 **Auth → Authorized domains** — add any **custom domain**; sign-in silently fails on
      unlisted domains (`*.web.app`/`*.firebaseapp.com` are auto-added).

## Google Cloud / IAM (deploy-time)

- [ ] 🔴 Service-account **key** = the `FIREBASE_SERVICE_ACCOUNT` secret. **Keep it** — it's the
      ongoing CI deploy credential; do **not** delete it after setup.
- [ ] 🤖/🔴 **APIs** — Firestore + Identity Toolkit (the bootstrap workflow enables these).
      Functions v2 also needs Cloud Functions, Cloud Build, Artifact Registry, Cloud Run,
      Eventarc, Pub/Sub (usually auto-enabled on first deploy).

## Hardening (before public launch)

- [ ] **Scope the SA role down** from `Owner` to least-privilege (hosting.admin,
      cloudfunctions.developer, firebaserules.admin, datastore.user, + serviceAccountUser /
      cloudbuild / artifactregistry for Functions). Verify against a real deploy first.
- [ ] **Budget + alerts** (Cloud Billing) once on Blaze.
- [ ] **App Check** — block non-app clients from Firestore/Functions.
- [ ] **Firestore backups / PITR**.
