# ETL with Airflow and Snowflake And Google Big Query







**Repo ini merupakan sebuah container untuk proses ETL dari PostgreSQL ke GBQ (Google Big Query).** 



✅**Berikut setup:**
1. Install Docker Desktop, dan pastikan WSL menyala secara otomatis saat docker desktop menyala.

2. Git clone <repo>. Pastikan untuk mengingat path tempat anda meng-clone repo.

3. Cd ke file path, dan lakukan: docker compose up -d --build

4. Buka browser, dan akses http://localhost:8080 dengan kredensial (User: admin | Password: admin) 



✅**Untuk meng-akses DB, dan melihat table:**
1. host: postgres (jika di dalam docker) atau localhost (jika di local)

2. port: 5432

3. user: airflow

4. password: airflow

5. database: airflow

✅**Untuk cek warehouse Snowflake**

1. Masukkan kredensial ke airflow ui.
   
3. Buat table yang memiliki DDL logic yang sama dengan yang berada di file init.sql (Untuk create table)
   
4. Buat stage di snowflake (karena data dari Postgre akan ke stage terlebih dahulu)
   
5. Tes untuk trigger.

6. Cek hasil di Snowflake. 
   
   
✅**Untuk cek warehouse (BigQuery): (Tidak disarankan)**

1. Masuk ke docker-compose.yaml
   
3. Pergi ke line 18 dan ubah variable 'your\_gcs\_bucket\_id' menjadi bucket\_id anda.
   
5. Pergi ke line 20 dan ubah variable 'your\_gcp\_project\_id' menjadi project\_id anda.
   
7. Masukan GCP Service Account JSON ke file google\_keys.json
   
9. Save.
