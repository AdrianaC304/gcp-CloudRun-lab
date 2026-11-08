#!/usr/bin/env bash
# Shared variables. Load them in every new terminal with:
#   source setup/00_env.sh

export PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
export REGION="europe-west1"

export LANDING_BUCKET="${PROJECT_ID}-landing"
export DATASET="lab"
export AR_REPO="cloud-run-source-deploy"

export FUNCTION_NAME="on-upload"
export JOB_NAME="daily-kpis"
export SERVICE_NAME="sales-dashboard"
export SCHEDULER_NAME="daily-kpis-nightly"

# One service account per component: least privilege.
export FN_SA="fn-on-upload@${PROJECT_ID}.iam.gserviceaccount.com"
export JOB_SA="job-daily-kpis@${PROJECT_ID}.iam.gserviceaccount.com"
export DASH_SA="run-dashboard@${PROJECT_ID}.iam.gserviceaccount.com"
export SCHED_SA="scheduler-kpis@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud config set run/region "$REGION" --quiet >/dev/null 2>&1
echo "Project: $PROJECT_ID ($PROJECT_NUMBER) · region: $REGION"
