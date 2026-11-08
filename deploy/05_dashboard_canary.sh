#!/usr/bin/env bash
# Challenge 4: deploy a new version of the dashboard WITHOUT sending traffic to it,
# then give it 10% of the users (canary release).
set -euo pipefail
source "$(dirname "$0")/../setup/00_env.sh"
SRC="${1:-service/sales_dashboard}"

# 1. New revision with 0% traffic and its own test URL (tag "canary").
gcloud run deploy "$SERVICE_NAME" \
  --source="$SRC" \
  --region="$REGION" \
  --service-account="$DASH_SA" \
  --set-env-vars="PROJECT_ID=${PROJECT_ID},REGION=${REGION},JOB_NAME=${JOB_NAME},APP_VERSION=v2" \
  --no-traffic \
  --tag=canary

echo
echo "Test the new version privately at the 'canary---' URL above."
read -r -p "Send 10% of the traffic to it? (y/N) " ok
[[ "$ok" == "y" ]] || exit 0

# 2. Canary: 10% to the new revision, 90% stays on the stable one.
gcloud run services update-traffic "$SERVICE_NAME" --region="$REGION" --to-tags=canary=10

echo
echo "Done. Useful commands:"
echo "  see the split:  gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format='yaml(status.traffic)'"
echo "  promote (100%): gcloud run services update-traffic ${SERVICE_NAME} --region=${REGION} --to-latest"
echo "  rollback:       gcloud run revisions list --service=${SERVICE_NAME} --region=${REGION}"
echo "                  gcloud run services update-traffic ${SERVICE_NAME} --region=${REGION} --to-revisions=<STABLE_REVISION>=100"
