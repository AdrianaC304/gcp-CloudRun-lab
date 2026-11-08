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
    """Return a clean row ready for BigQuery, or None to drop it. (SOLUTION)"""
    product = (row.get("product") or "").strip()
    country = (row.get("country") or "").strip().upper()
    try:
        quantity = int(row["quantity"])
        unit_price = float(row["unit_price"])
    except (KeyError, TypeError, ValueError):
        return None  # 4. numbers that can't be converted

    if not product:  # 1. empty product
        return None
    if quantity <= 0 or unit_price <= 0:  # 2. impossible values
        return None
    if len(country) != 2 or not country.isalpha():  # 3. bad country code
        return None

    return {
        "order_id": row["order_id"].strip(),
        "order_date": row["order_date"].strip(),
        "country": country,
        "product": product,
        "quantity": quantity,
        "unit_price": unit_price,
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
