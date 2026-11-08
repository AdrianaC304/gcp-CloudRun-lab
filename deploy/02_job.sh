#!/usr/bin/env bash
# Builds and deploys the daily-kpis Cloud Run job (3 tasks in parallel).
set -euo pipefail
source "$(dirname "$0")/../setup/00_env.sh"
SRC="${1:-job/daily_kpis}"   # pass solutions/job/daily_kpis to deploy the solution

gcloud run jobs deploy "$JOB_NAME" \
  --source="$SRC" \
  --region="$REGION" \
  --tasks=3 \
  --parallelism=3 \
  --max-retries=1 \
  --task-timeout=10m \
  --service-account="$JOB_SA"

echo
echo "Job ready. Run it with:"
echo "  gcloud run jobs execute ${JOB_NAME} --region=${REGION} --wait"
