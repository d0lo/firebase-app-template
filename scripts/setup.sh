#!/usr/bin/env bash
# One-shot, KEYLESS project setup. Run in Google Cloud Shell (already logged in as you).
# Creates NO service-account key. Sets up Workload Identity Federation so GitHub Actions
# authenticates to Google with short-lived tokens, plus the project basics + a least-privilege
# deploy account. Prints the repo *variables* to add to GitHub.
set -euo pipefail

# ── EDIT THESE ────────────────────────────────────────────────────────────────
PROJECT_ID="your-project-id"      # Firebase/GCP project id (console -> Project settings)
REPO="your-user/your-repo"        # the GitHub repo made from this template
ENABLE_FUNCTIONS="false"          # "true" if you'll use Cloud Functions (needs Blaze billing)
REGION="nam5"                     # Firestore location (permanent)
# ──────────────────────────────────────────────────────────────────────────────

POOL_ID="github-pool"; PROVIDER_ID="github-provider"; SA_NAME="ci-deploy"
gcloud config set project "$PROJECT_ID"
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "==> Enabling APIs"
APIS="iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com cloudresourcemanager.googleapis.com firebase.googleapis.com firebasehosting.googleapis.com firestore.googleapis.com identitytoolkit.googleapis.com"
[ "$ENABLE_FUNCTIONS" = "true" ] && APIS="$APIS cloudfunctions.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com eventarc.googleapis.com pubsub.googleapis.com"
gcloud services enable $APIS

echo "==> Firestore (default) + anonymous auth"
gcloud firestore databases create --location="$REGION" 2>/dev/null || echo "   (Firestore already exists)"
curl -sS -X PATCH "https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/config?updateMask=signIn.anonymous.enabled" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
  -d '{"signIn":{"anonymous":{"enabled":true}}}' >/dev/null || echo "   (anon auth patch skipped)"

echo "==> Least-privilege deploy service account"
gcloud iam service-accounts create "$SA_NAME" --display-name="CI deploy" 2>/dev/null || echo "   (SA already exists)"
add_role(){ gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:${SA_EMAIL}" --role="$1" --condition=None >/dev/null; }
add_role roles/firebasehosting.admin
add_role roles/firebaserules.admin
add_role roles/datastore.user
if [ "$ENABLE_FUNCTIONS" = "true" ]; then
  for r in roles/cloudfunctions.developer roles/iam.serviceAccountUser roles/cloudbuild.builds.editor roles/artifactregistry.writer roles/run.admin; do add_role "$r"; done
fi

echo "==> Workload Identity Federation (keyless) scoped to ${REPO}"
gcloud iam workload-identity-pools create "$POOL_ID" --location=global --display-name="GitHub Actions" 2>/dev/null || echo "   (pool exists)"
gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
  --location=global --workload-identity-pool="$POOL_ID" --display-name="GitHub OIDC" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='${REPO}'" 2>/dev/null || echo "   (provider exists)"
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${REPO}" >/dev/null

cat <<EOF

======================================================================
 DONE (no key created). Add these GitHub repo VARIABLES:
   Settings -> Secrets and variables -> Actions -> Variables tab
----------------------------------------------------------------------
WIF_PROVIDER        = projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}
WIF_SERVICE_ACCOUNT = ${SA_EMAIL}
FIREBASE_PROJECT_ID = ${PROJECT_ID}
======================================================================
If your web app calls Firebase at runtime, also add the six VITE_FIREBASE_*
variables from: Firebase console -> Project settings -> your Web app config.
EOF
