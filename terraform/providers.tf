# Google: authenticate with Application Default Credentials once, up front:
#   gcloud auth application-default login
# GitHub: set a Personal Access Token (repo + admin:repo scopes) in the environment:
#   export GITHUB_TOKEN=ghp_...
provider "google" {}

provider "google-beta" {}

provider "github" {
  owner = var.github_owner
}
