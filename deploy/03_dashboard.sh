#!/usr/bin/env bash
# Builds and deploys the sales-dashboard Cloud Run service (Streamlit).
set -euo pipefail
source "$(dirname "$0")/../setup/00_env.sh"
SRC="${1:-service/sales_dashboard}"   # pass solutions/service/sales_dashboard to deploy the solution
VERSION="${2:-v1}"

# The dashboard may execute the job (Refresh button).
gcloud run jobs add-iam-policy-binding "$JOB_NAME" --region="$REGION" \
  --member="serviceAccount:${DASH_SA}" --role=roles/run.invoker --quiet >/dev/null

gcloud run deploy "$SERVICE_NAME" \
  --source="$SRC" \
  --region="$REGION" \
  --service-account="$DASH_SA" \
  --set-env-vars="PROJECT_ID=${PROJECT_ID},REGION=${REGION},JOB_NAME=${JOB_NAME},APP_VERSION=${VERSION}" \
  --allow-unauthenticated \
  --min-instances=0 \
  --max-instances=2 \
  --memory=1Gi

echo
echo "Dashboard URL:"
gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format='value(status.url)'
