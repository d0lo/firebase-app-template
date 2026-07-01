locals {
  base_services = [
    "serviceusage.googleapis.com",
    "firebase.googleapis.com",
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

# Enable anonymous sign-in.
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

# ── Deploy service account (the GitHub Actions credential) ─────────────────────
resource "google_service_account" "deploy" {
  project      = local.project_id
  account_id   = "ci-deploy"
  display_name = "CI deploy (GitHub Actions)"
}

locals {
  # firebase.admin covers Hosting + rules + Firestore admin + project management
  # (scoped to Firebase, not full Owner). Functions v2 needs the extra roles.
  deploy_roles = concat(
    ["roles/firebase.admin", "roles/datastore.user"],
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

resource "google_service_account_key" "deploy" {
  service_account_id = google_service_account.deploy.name
}

# ── GitHub: secrets + branch protection ───────────────────────────────────────
# The workflows JSON.parse this, so store the DECODED key (not the base64 blob).
resource "github_actions_secret" "sa" {
  repository      = var.github_repository
  secret_name     = "FIREBASE_SERVICE_ACCOUNT"
  plaintext_value = base64decode(google_service_account_key.deploy.private_key)
}

resource "github_actions_secret" "vite" {
  for_each = {
    VITE_FIREBASE_API_KEY             = data.google_firebase_web_app_config.this.api_key
    VITE_FIREBASE_AUTH_DOMAIN         = data.google_firebase_web_app_config.this.auth_domain
    VITE_FIREBASE_PROJECT_ID          = local.project_id
    VITE_FIREBASE_STORAGE_BUCKET      = data.google_firebase_web_app_config.this.storage_bucket
    VITE_FIREBASE_MESSAGING_SENDER_ID = data.google_firebase_web_app_config.this.messaging_sender_id
    VITE_FIREBASE_APP_ID              = google_firebase_web_app.this.app_id
  }
  repository      = var.github_repository
  secret_name     = each.key
  plaintext_value = each.value
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
