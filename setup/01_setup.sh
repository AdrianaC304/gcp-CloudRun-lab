#!/usr/bin/env bash
# Creates everything the lab needs BEFORE deploying code:
# APIs, bucket, BigQuery tables, Artifact Registry repo, service accounts and IAM.
# Safe to run twice: existing resources are skipped.
set -euo pipefail
source "$(dirname "$0")/00_env.sh"

echo "== 1. Enabling APIs (takes 1-2 minutes)"
gcloud services enable \
  run.googleapis.com cloudfunctions.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com eventarc.googleapis.com pubsub.googleapis.com \
  bigquery.googleapis.com cloudscheduler.googleapis.com logging.googleapis.com \
  storage.googleapis.com

echo "== 2. Landing bucket"
gcloud storage buckets create "gs://${LANDING_BUCKET}" \
  --location="$REGION" --uniform-bucket-level-access 2>/dev/null || echo "   (already exists)"

echo "== 3. BigQuery dataset and tables"
bq --location="$REGION" mk --dataset "${PROJECT_ID}:${DATASET}" 2>/dev/null || echo "   (dataset already exists)"
bq mk --table "${PROJECT_ID}:${DATASET}.orders_raw" setup/schemas/orders_raw.json 2>/dev/null || echo "   (orders_raw already exists)"
bq mk --table "${PROJECT_ID}:${DATASET}.daily_kpis" setup/schemas/daily_kpis.json 2>/dev/null || echo "   (daily_kpis already exists)"

echo "== 4. Artifact Registry repository for the images"
gcloud artifacts repositories create "$AR_REPO" \
  --repository-format=docker --location="$REGION" \
  --description="Images built by gcloud run deploy --source" 2>/dev/null || echo "   (already exists)"

echo "== 5. Service accounts (one per component)"
for sa in fn-on-upload job-daily-kpis run-dashboard scheduler-kpis; do
  gcloud iam service-accounts create "$sa" --display-name="lab: $sa" 2>/dev/null || echo "   ($sa already exists)"
done
sleep 10  # give IAM a moment to see the new accounts

echo "== 6. IAM roles (least privilege)"
grant_project () {  # $1 member, $2 role
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="$1" --role="$2" \
    --condition=None --quiet >/dev/null
  echo "   $2 -> $1"
}

# Cloud Storage publishes the "file created" events through Pub/Sub.
GCS_AGENT="$(gcloud storage service-agent --project="$PROJECT_ID")"
grant_project "serviceAccount:${GCS_AGENT}" roles/pubsub.publisher

# on-upload function: receive events, read the bucket, write to BigQuery.
grant_project "serviceAccount:${FN_SA}" roles/eventarc.eventReceiver
grant_project "serviceAccount:${FN_SA}" roles/run.invoker
grant_project "serviceAccount:${FN_SA}" roles/bigquery.jobUser
gcloud storage buckets add-iam-policy-binding "gs://${LANDING_BUCKET}" \
  --member="serviceAccount:${FN_SA}" --role=roles/storage.objectViewer --quiet >/dev/null
echo "   roles/storage.objectViewer on the bucket -> ${FN_SA}"

# daily-kpis job and dashboard: run queries.
grant_project "serviceAccount:${JOB_SA}"  roles/bigquery.jobUser
grant_project "serviceAccount:${DASH_SA}" roles/bigquery.jobUser

# Dataset-level permissions, granted with SQL (BigQuery DCL).
bq query --location="$REGION" --nouse_legacy_sql --quiet "
GRANT \`roles/bigquery.dataEditor\` ON SCHEMA \`${PROJECT_ID}.${DATASET}\`
  TO 'serviceAccount:${FN_SA}', 'serviceAccount:${JOB_SA}';
GRANT \`roles/bigquery.dataViewer\` ON SCHEMA \`${PROJECT_ID}.${DATASET}\`
  TO 'serviceAccount:${DASH_SA}';
" >/dev/null
echo "   dataset roles granted with GRANT ... ON SCHEMA"

# Builds from source run as the Compute Engine default service account.
grant_project "serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" roles/cloudbuild.builds.builder

echo
echo "Setup done. Next step: bash deploy/01_function.sh"
