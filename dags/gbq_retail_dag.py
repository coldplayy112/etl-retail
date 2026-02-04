import os
import pendulum
from datetime import datetime
from airflow import DAG
from airflow.providers.google.cloud.transfers.postgres_to_gcs import PostgresToGCSOperator
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator

# 1. Handle the Jakarta Timezone
local_tz = pendulum.timezone("Asia/Jakarta")

# 2. Environment Variables
# Pulls from the 'GCS_BUCKET' line we added to your docker-compose.yaml
GCS_BUCKET = os.getenv("GCS_BUCKET", "retail-data-bucket-unique-id")
BQ_DATASET = "a"
BQ_TABLE = "retail_transactions"

with DAG(
    dag_id="retail_transactions_sync_jakarta",
    start_date=datetime(2026, 1, 3, tzinfo=local_tz),
    schedule="@hourly",
    catchup=False,
    tags=['retail', 'jakarta'],
) as dag:

    # Task 1: Extract from Postgres to GCS
    # Uses 'postgres_default' and 'google_cloud_default' from your YAML
    extract_to_gcs = PostgresToGCSOperator(
        task_id="extract_postgres_to_gcs",
        postgres_conn_id="postgres_default",
        sql="SELECT * FROM public.retail_transactions;",
        bucket=GCS_BUCKET,
        filename="retail_transactions/export.json",
        export_format="json",
        google_cloud_storage_conn_id="google_cloud_default",
    )

    # Task 2: Load from GCS to BigQuery
    load_to_bq = GCSToBigQueryOperator(
        task_id="load_gcs_to_bigquery",
        bucket=GCS_BUCKET,
        source_objects=["retail_transactions/export.json"],
        # Note: Project ID is automatically pulled from the 
        # AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT connection in your YAML
        destination_project_dataset_table=f"{BQ_DATASET}.{BQ_TABLE}",
        source_format="NEWLINE_DELIMITED_JSON",
        write_disposition="WRITE_TRUNCATE", 
        autodetect=True,
        location="asia-southeast2", 
        google_cloud_storage_conn_id="google_cloud_default",
    )

    extract_to_gcs >> load_to_bq