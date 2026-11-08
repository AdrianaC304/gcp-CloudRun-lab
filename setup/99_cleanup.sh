#!/usr/bin/env bash
# Deletes everything created by the lab, so nothing keeps costing money.
set -uo pipefail
source "$(dirname "$0")/00_env.sh"

read -r -p "This deletes all lab resources in ${PROJECT_ID}. Continue? (y/N) " ok
[[ "$ok" == "y" ]] || exit 0

gcloud scheduler jobs delete "$SCHEDULER_NAME" --location="$REGION" --quiet
gcloud run services delete "$SERVICE_NAME" --region="$REGION" --quiet
gcloud run jobs delete "$JOB_NAME" --region="$REGION" --quiet
gcloud functions delete "$FUNCTION_NAME" --gen2 --region="$REGION" --quiet
gcloud storage rm --recursive "gs://${LANDING_BUCKET}"
bq rm -r -f --dataset "${PROJECT_ID}:${DATASET}"
gcloud artifacts repositories delete "$AR_REPO" --location="$REGION" --quiet
for sa in "$FN_SA" "$JOB_SA" "$DASH_SA" "$SCHED_SA"; do
  gcloud iam service-accounts delete "$sa" --quiet
done
echo "Clean-up finished."
