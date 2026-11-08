#!/usr/bin/env bash
# Deploys the on-upload Cloud Run function with a Cloud Storage trigger (Eventarc).
# Re-run it every time you change function/on_upload/main.py.
set -euo pipefail
source "$(dirname "$0")/../setup/00_env.sh"
SRC="${1:-function/on_upload}"   # pass solutions/function/on_upload to deploy the solution

gcloud functions deploy "$FUNCTION_NAME" \
  --gen2 \
  --region="$REGION" \
  --runtime=python312 \
  --source="$SRC" \
  --entry-point=on_upload \
  --trigger-bucket="$LANDING_BUCKET" \
  --service-account="$FN_SA" \
  --trigger-service-account="$FN_SA" \
  --set-env-vars="BQ_TABLE=${DATASET}.orders_raw" \
  --memory=512Mi \
  --timeout=120s

echo
echo "Function ready. Upload a file with:"
echo "  gcloud storage cp data/orders_week1.csv gs://${LANDING_BUCKET}/"
