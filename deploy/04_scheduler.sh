#!/usr/bin/env bash
# Cloud Scheduler executes the daily-kpis job every night at 02:00 (Madrid time).
set -euo pipefail
source "$(dirname "$0")/../setup/00_env.sh"

gcloud run jobs add-iam-policy-binding "$JOB_NAME" --region="$REGION" \
  --member="serviceAccount:${SCHED_SA}" --role=roles/run.invoker --quiet >/dev/null

gcloud scheduler jobs create http "$SCHEDULER_NAME" \
  --location="$REGION" \
  --schedule="0 2 * * *" \
  --time-zone="Europe/Madrid" \
  --uri="https://run.googleapis.com/v2/projects/${PROJECT_ID}/locations/${REGION}/jobs/${JOB_NAME}:run" \
  --http-method=POST \
  --oauth-service-account-email="$SCHED_SA"

echo
echo "Scheduled. To test it now instead of waiting until 02:00:"
echo "  gcloud scheduler jobs run ${SCHEDULER_NAME} --location=${REGION}"
