output "project_id" {
  value = local.project_id
}

output "web_app_id" {
  value = google_firebase_web_app.this.app_id
}

output "deploy_service_account" {
  value = google_service_account.deploy.email
}

output "firebase_config" {
  description = "The public web config that was pushed to the VITE_FIREBASE_* secrets."
  value = {
    apiKey            = data.google_firebase_web_app_config.this.api_key
    authDomain        = data.google_firebase_web_app_config.this.auth_domain
    projectId         = local.project_id
    storageBucket     = data.google_firebase_web_app_config.this.storage_bucket
    messagingSenderId = data.google_firebase_web_app_config.this.messaging_sender_id
    appId             = google_firebase_web_app.this.app_id
  }
}
