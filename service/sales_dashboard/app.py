"""
sales-dashboard - Cloud Run service (Streamlit)

Reads the latest KPIs written by the daily-kpis job (lab.daily_kpis)
and shows them as charts. The "Refresh" button executes the job.
"""
import os

import streamlit as st
from google.cloud import bigquery, run_v2

PROJECT_ID = os.environ.get("PROJECT_ID", "")
REGION = os.environ.get("REGION", "europe-west1")
JOB_NAME = os.environ.get("JOB_NAME", "daily-kpis")
APP_VERSION = os.environ.get("APP_VERSION", "v1")

LATEST_KPIS = """
SELECT order_date, country, product, orders, units, revenue, computed_at
FROM `lab.daily_kpis`
WHERE execution = (
  SELECT execution FROM `lab.daily_kpis` ORDER BY computed_at DESC LIMIT 1
)
"""

st.set_page_config(page_title="Sales dashboard", layout="wide")
st.title("Sales dashboard")
st.caption(f"Data from BigQuery · lab.daily_kpis · app {APP_VERSION}")


@st.cache_data(ttl=60)
def load_kpis():
    return bigquery.Client().query(LATEST_KPIS).to_dataframe()


# --- Refresh button: executes the Cloud Run job -------------------------
if st.button("↻ Refresh (run the daily-kpis job)"):
    job = f"projects/{PROJECT_ID}/locations/{REGION}/jobs/{JOB_NAME}"
    run_v2.JobsClient().run_job(name=job)
    st.cache_data.clear()
    st.success("Job started. New data will be ready in about a minute: reload the page.")

df = load_kpis()
if df.empty:
    st.warning("No KPIs yet. Upload a CSV to the landing bucket and run the job.")
    st.stop()

st.caption(f"Last computed: {df['computed_at'].max():%Y-%m-%d %H:%M} UTC")

# --- Headline numbers ---------------------------------------------------
c1, c2, c3 = st.columns(3)
c1.metric("Revenue", f"{df['revenue'].sum():,.2f} €")
c2.metric("Orders", f"{df['orders'].sum():,}")
c3.metric("Units sold", f"{df['units'].sum():,}")

# --- Charts -------------------------------------------------------------
left, right = st.columns(2)
with left:
    st.subheader("Revenue per day")
    st.line_chart(df.groupby("order_date")["revenue"].sum())
with right:
    st.subheader("Revenue per country")
    st.bar_chart(df.groupby("country")["revenue"].sum().sort_values(ascending=False))

# ------------------------------------------------------------------------
# TODO (Challenge 3): add a third chart, "Top 5 products by revenue".
#   - Group df by "product", sum "revenue", keep the 5 largest
#     (hint: .nlargest(5))
#   - Show it with st.bar_chart under a st.subheader
# ------------------------------------------------------------------------

with st.expander("Raw KPI rows"):
    st.dataframe(df.sort_values(["order_date", "country", "product"]))
