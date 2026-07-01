output "project_id" {
  value = local.project_id
}

output "wif_provider" {
  description = "Workload Identity provider resource name (set as the WIF_PROVIDER repo variable — Terraform already did)."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "deploy_service_account" {
  value = google_service_account.deploy.email
}

output "web_app_id" {
  value = google_firebase_web_app.this.app_id
}
