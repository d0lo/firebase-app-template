# Terraform — one-command project provisioning

Provisions an entire new project from `terraform apply`, **keyless**: the GCP/Firebase project,
Firestore, anonymous auth, a web app, a least-privilege deploy service account, **Workload
Identity Federation** (so GitHub authenticates with no stored key), and it sets the GitHub repo
**variables** (`WIF_*`, `FIREBASE_PROJECT_ID`, `VITE_FIREBASE_*`) + **branch protection**. No
service-account key is ever created — there are no secrets.

Free: Terraform (or OpenTofu) and the providers cost nothing; you only pay for the Firebase/GCP
resources you'd pay for anyway.

## The irreducible floor (do once)

Terraform automates everything **except** the things that need your identity/payment:

1. 🔴 A **Google billing account** (add a payment method once at console.cloud.google.com/billing).
   Needed to create a project and for Cloud Functions. Grab its id (`XXXXXX-XXXXXX-XXXXXX`).
2. 🔴 **Authenticate Google** locally: `gcloud auth application-default login`.
3. 🔴 A **GitHub token**: a PAT (classic) with `repo` + `admin:repo_hook`/`admin:org` as needed,
   or a fine-grained token with Administration + Secrets write on the repo. `export GITHUB_TOKEN=…`.
4. 🔴 The **GitHub repo must already exist** (create it from this template first).

Everything else is Terraform's job.

## Run it

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit: project_id, billing_account, github_*
terraform init
terraform plan       # review
terraform apply      # provisions everything
```

After apply: `terraform output firebase_config` shows the web config (also already in your
repo secrets). Push to `main` and the deploy workflows run against the new project.

## Important notes

- **State is sensitive.** The state file contains the service-account key and secret values. Do
  **not** commit `terraform.tfstate` (it's gitignored). For real use, switch to a remote backend
  (a GCS bucket) so state is encrypted and shared — add a `backend "gcs"` block to `versions.tf`.
- **Personal (no-org) accounts:** creating a project works but is subject to your project quota
  and requires the billing account. If project creation is denied, create the project by hand (or
  `gcloud projects create`) and set `create_project = false`.
- **Provider drift:** the Firebase resources live in `google-beta` and occasionally change between
  provider majors. If `apply` errors on a resource, run `terraform plan` and adjust — this is
  normal for any IaC bootstrap and is not a bug in the module.
- **IAM is scoped, not Owner:** the deploy SA gets `firebase.admin` (+ Functions roles when
  enabled), which is narrower than the Owner key the manual path uses.

## What this does NOT do

- Create the GitHub **repo** (make it from the template first) or the **billing account**.
- Enable the org-wide security defaults — that's a GitHub Organization feature (see `docs/SETTINGS.md`).
