from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import os

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2026, 2, 4), 
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def extract_and_stage():
    # 1. Extract from Postgres
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    # Using your specific source table
    df = pg_hook.get_pandas_df(sql="SELECT * FROM public.retail_transactions;")
    
    # 2. Save to local temp file (in Docker worker)
    local_path = '/tmp/retail_data.csv'
    df.to_csv(local_path, index=False, header=False)
    
    # 3. Put to Snowflake Stage
    sf_hook = SnowflakeHook(snowflake_conn_id='snowflake')
    sf_hook.run(f"PUT file://{local_path} @retail_stage OVERWRITE=TRUE")
    
    # Clean up local file
    if os.path.exists(local_path):
        os.remove(local_path)

with DAG(
    'postgres_to_snowflake_hourly',
    default_args=default_args,
    description='Idempotent Sync from public.retail_transactions to Snowflake',
    schedule='@hourly',
    catchup=False
) as dag:

    extract_task = PythonOperator(
        task_id='extract_and_upload_to_stage',
        python_callable=extract_and_stage,
    )

    # This task ensures idempotency by clearing the target before loading
    truncate_and_insert = SQLExecuteQueryOperator(
        task_id='truncate_and_insert_to_table',
        conn_id='snowflake',
        sql="""
            TRUNCATE TABLE RETAIL_DB.RETAIL_STAGING.RETAIL_TRANSACTIONS;
            
            COPY INTO RETAIL_DB.RETAIL_STAGING.RETAIL_TRANSACTIONS
            FROM @retail_stage
            FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 0);
        """
    )

    extract_task >> truncate_and_insert