locals {
  base_services = [
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com",
    "firestore.googleapis.com",
    "identitytoolkit.googleapis.com",
  ]
  functions_services = [
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
  ]
  services = concat(local.base_services, var.enable_functions ? local.functions_services : [])
  repo     = "${var.github_owner}/${var.github_repository}"
}

# ── GCP project (optional) ─────────────────────────────────────────────────────
resource "google_project" "this" {
  count           = var.create_project ? 1 : 0
  name            = coalesce(var.project_name, var.project_id)
  project_id      = var.project_id
  billing_account = var.billing_account != "" ? var.billing_account : null
  org_id          = var.org_id != "" ? var.org_id : null
}

locals {
  project_id = var.create_project ? google_project.this[0].project_id : var.project_id
}

resource "google_project_service" "svc" {
  for_each           = toset(local.services)
  project            = local.project_id
  service            = each.value
  disable_on_destroy = false
}

# ── Firebase + Firestore + Auth ───────────────────────────────────────────────
resource "google_firebase_project" "this" {
  provider   = google-beta
  project    = local.project_id
  depends_on = [google_project_service.svc]
}

resource "google_firestore_database" "this" {
  project     = local.project_id
  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"
  depends_on  = [google_firebase_project.this]
}

resource "google_identity_platform_config" "auth" {
  provider   = google-beta
  project    = local.project_id
  depends_on = [google_project_service.svc]
  sign_in {
    anonymous {
      enabled = true
    }
  }
}

# ── Web app + its public config ───────────────────────────────────────────────
resource "google_firebase_web_app" "this" {
  provider     = google-beta
  project      = local.project_id
  display_name = "Web app"
  depends_on   = [google_firebase_project.this]
}

data "google_firebase_web_app_config" "this" {
  provider   = google-beta
  project    = local.project_id
  web_app_id = google_firebase_web_app.this.app_id
}

# ── Least-privilege deploy service account (impersonated via WIF; NO key) ───────
resource "google_service_account" "deploy" {
  project      = local.project_id
  account_id   = "ci-deploy"
  display_name = "CI deploy (GitHub Actions, keyless)"
}

locals {
  deploy_roles = concat(
    ["roles/firebasehosting.admin", "roles/firebaserules.admin", "roles/datastore.user"],
    var.enable_functions ? [
      "roles/cloudfunctions.developer",
      "roles/iam.serviceAccountUser",
      "roles/cloudbuild.builds.editor",
      "roles/artifactregistry.writer",
      "roles/run.admin",
    ] : [],
  )
}

resource "google_project_iam_member" "deploy" {
  for_each = toset(local.deploy_roles)
  project  = local.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.deploy.email}"
}

# ── Workload Identity Federation: GitHub OIDC -> impersonate the deploy SA ──────
resource "google_iam_workload_identity_pool" "github" {
  project                   = local.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  depends_on                = [google_project_service.svc]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = local.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "assertion.repository == \"${local.repo}\""
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Only this repo may impersonate the deploy account.
resource "google_service_account_iam_member" "wif" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.repo}"
}

# ── GitHub: repo VARIABLES (no secrets — everything here is non-sensitive) ──────
resource "github_actions_variable" "config" {
  for_each = {
    WIF_PROVIDER                      = google_iam_workload_identity_pool_provider.github.name
    WIF_SERVICE_ACCOUNT               = google_service_account.deploy.email
    FIREBASE_PROJECT_ID               = local.project_id
    VITE_FIREBASE_API_KEY             = data.google_firebase_web_app_config.this.api_key
    VITE_FIREBASE_AUTH_DOMAIN         = data.google_firebase_web_app_config.this.auth_domain
    VITE_FIREBASE_PROJECT_ID          = local.project_id
    VITE_FIREBASE_STORAGE_BUCKET      = data.google_firebase_web_app_config.this.storage_bucket
    VITE_FIREBASE_MESSAGING_SENDER_ID = data.google_firebase_web_app_config.this.messaging_sender_id
    VITE_FIREBASE_APP_ID              = google_firebase_web_app.this.app_id
  }
  repository    = var.github_repository
  variable_name = each.key
  value         = each.value
}

resource "github_branch_protection" "main" {
  repository_id  = var.github_repository
  pattern        = "main"
  enforce_admins = false

  required_status_checks {
    strict   = true
    contexts = var.required_status_checks
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }
}
