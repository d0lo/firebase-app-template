variable "project_id" {
  description = "Globally-unique GCP/Firebase project id."
  type        = string
}

variable "project_name" {
  description = "Display name for the project (defaults to project_id)."
  type        = string
  default     = null
}

variable "create_project" {
  description = "Create the GCP project (true), or manage an existing one (false)."
  type        = bool
  default     = true
}

variable "billing_account" {
  description = "Billing account id (XXXXXX-XXXXXX-XXXXXX). Required to create a project and to use Cloud Functions (Blaze)."
  type        = string
  default     = ""
}

variable "org_id" {
  description = "Optional GCP organization id. Leave empty for a personal (no-org) account."
  type        = string
  default     = ""
}

variable "firestore_location" {
  description = "Firestore location — permanent once set (e.g. nam5, eur3, asia-east1)."
  type        = string
  default     = "nam5"
}

variable "enable_functions" {
  description = "Enable the APIs + IAM roles Cloud Functions v2 needs (requires Blaze billing)."
  type        = bool
  default     = false
}

variable "github_owner" {
  description = "GitHub org/user that owns the repository."
  type        = string
}

variable "github_repository" {
  description = "Existing GitHub repo (created from this template) to configure with secrets + branch protection."
  type        = string
}

variable "required_status_checks" {
  description = "CI job names that must pass before merging to main."
  type        = list(string)
  default     = ["check", "integration"]
}
