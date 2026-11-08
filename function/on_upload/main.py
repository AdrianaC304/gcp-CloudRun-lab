"""
on_upload - Cloud Run function (event-driven)

Triggered by Eventarc every time a file is created in the landing bucket.
It reads the CSV, cleans each row and loads the result into BigQuery
(table lab.orders_raw).
"""
import csv
import datetime
import io
import os

import functions_framework
from google.cloud import bigquery, storage

BQ_TABLE = os.environ.get("BQ_TABLE", "lab.orders_raw")

bq = bigquery.Client()
gcs = storage.Client()


def clean_row(row: dict) -> dict | None:
    """Return a clean row ready for BigQuery, or None to drop it.

    ------------------------------------------------------------------
    TODO (Challenge 1): the data that arrives is dirty. Right now this
    function only converts types, so bad rows reach BigQuery and the
    dashboard shows strange numbers. Improve it so that:

      1. Rows with an empty product are dropped (return None).
      2. Rows with quantity <= 0 or unit_price <= 0 are dropped.
      3. The country is normalised: no spaces and in UPPERCASE
         (" es" -> "ES"). Drop the row if it is not 2 letters long.
      4. Rows whose numbers can't be converted (e.g. "abc") are dropped
         instead of crashing the whole file.

    Test it locally with:  python -m pytest tests/
    ------------------------------------------------------------------
    """
    return {
        "order_id": row["order_id"],
        "order_date": row["order_date"],
        "country": row["country"],
        "product": row["product"],
        "quantity": int(row["quantity"]),
        "unit_price": float(row["unit_price"]),
    }


@functions_framework.cloud_event
def on_upload(cloud_event):
    data = cloud_event.data
    bucket_name, file_name = data["bucket"], data["name"]

    if not file_name.lower().endswith(".csv"):
        print(f"Skipping {file_name}: not a CSV file")
        return

    text = gcs.bucket(bucket_name).blob(file_name).download_as_text()
    rows = list(csv.DictReader(io.StringIO(text)))

    clean = [r for r in (clean_row(row) for row in rows) if r is not None]
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    for r in clean:
        r["source_file"] = file_name
        r["ingested_at"] = now

    if clean:
        job_config = bigquery.LoadJobConfig(
            schema=bq.get_table(BQ_TABLE).schema,
            write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        )
        bq.load_table_from_json(clean, BQ_TABLE, job_config=job_config).result()

    print(
        f"{file_name}: {len(rows)} rows read, {len(clean)} loaded, "
        f"{len(rows) - len(clean)} dropped"
    )
