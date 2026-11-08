"""
daily-kpis - Cloud Run job

Reads lab.orders_raw and writes aggregated KPIs (sales per day, country
and product) into lab.daily_kpis.

The job runs with several tasks in parallel. Each task processes only
its share of the countries, using the environment variables that Cloud
Run sets automatically:

  CLOUD_RUN_TASK_INDEX   which task am I? (0, 1, 2, ...)
  CLOUD_RUN_TASK_COUNT   how many tasks are there in total?
  CLOUD_RUN_EXECUTION    name of this execution (same for all tasks)
"""
import os
import pathlib

from google.cloud import bigquery

TASK_INDEX = int(os.environ.get("CLOUD_RUN_TASK_INDEX", 0))
TASK_COUNT = int(os.environ.get("CLOUD_RUN_TASK_COUNT", 1))
EXECUTION = os.environ.get("CLOUD_RUN_EXECUTION", "local-run")

SQL = (pathlib.Path(__file__).parent / "kpis.sql").read_text()


def main():
    print(f"Task {TASK_INDEX + 1}/{TASK_COUNT} of execution {EXECUTION} starting")
    client = bigquery.Client()
    job = client.query(
        SQL,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("task_index", "INT64", TASK_INDEX),
                bigquery.ScalarQueryParameter("task_count", "INT64", TASK_COUNT),
                bigquery.ScalarQueryParameter("execution", "STRING", EXECUTION),
            ]
        ),
    )
    job.result()
    print(f"Task {TASK_INDEX + 1}/{TASK_COUNT}: {job.num_dml_affected_rows} KPI rows written")


if __name__ == "__main__":
    main()
