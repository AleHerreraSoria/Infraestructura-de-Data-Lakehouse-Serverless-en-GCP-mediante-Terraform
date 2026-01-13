provider "google" {
  project = var.project_id
  region  = var.region
}

# --- 1. Cloud Storage (Data Lake) ---
resource "google_storage_bucket" "data_lake" {
  name          = "datastream-lite-ale_herrera-v1"
  location      = "US-CENTRAL1"
  force_destroy = true
  uniform_bucket_level_access = true
}

# Subida automática de archivos
resource "google_storage_bucket_object" "usuarios" {
  name   = "raw-data/usuarios.csv"
  source = "./data/usuarios.csv"
  bucket = google_storage_bucket.data_lake.name
}
resource "google_storage_bucket_object" "visualizaciones" {
  name   = "raw-data/visualizaciones.csv"
  source = "./data/visualizaciones.csv"
  bucket = google_storage_bucket.data_lake.name
}
resource "google_storage_bucket_object" "videos" {
  name   = "raw-data/videos.csv"
  source = "./data/videos.csv"
  bucket = google_storage_bucket.data_lake.name
}
resource "google_storage_bucket_object" "eventos" {
  name   = "raw-data/eventos_serverless.csv"
  source = "./data/eventos_serverless.csv"
  bucket = google_storage_bucket.data_lake.name
}

# --- 2. BigQuery Dataset ---
resource "google_bigquery_dataset" "analytics_lite" {
  dataset_id    = "analytics_lite"
  friendly_name = "Analytics Lite Lakehouse"
  location      = "US"
}

# --- 3. Tablas Externas (Lakehouse) ---

resource "google_bigquery_table" "usuarios" {
  dataset_id = google_bigquery_dataset.analytics_lite.dataset_id
  table_id   = "usuarios"
  deletion_protection = false
  
  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.data_lake.name}/raw-data/usuarios.csv"]
    
    csv_options { 
      quote             = "\""
      skip_leading_rows = 1 
    }
    
    schema = <<EOF
[
  {"name": "user_id", "type": "STRING"},
  {"name": "nombre", "type": "STRING"},
  {"name": "email", "type": "STRING"},
  {"name": "pais", "type": "STRING"},
  {"name": "plan", "type": "STRING"},
  {"name": "fecha_registro", "type": "DATE"}
]
EOF
  }
}

resource "google_bigquery_table" "visualizaciones" {
  dataset_id = google_bigquery_dataset.analytics_lite.dataset_id
  table_id   = "visualizaciones"
  deletion_protection = false
  
  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.data_lake.name}/raw-data/visualizaciones.csv"]
    
    csv_options { 
      quote             = "\""
      skip_leading_rows = 1 
    }

    schema = <<EOF
[
  {"name": "log_id", "type": "STRING"},
  {"name": "user_id", "type": "STRING"},
  {"name": "video_id", "type": "STRING"},
  {"name": "timestamp", "type": "TIMESTAMP"},
  {"name": "minutos_vistos", "type": "INTEGER"},
  {"name": "dispositivo", "type": "STRING"}
]
EOF
  }
}

resource "google_bigquery_table" "videos" {
  dataset_id = google_bigquery_dataset.analytics_lite.dataset_id
  table_id   = "videos"
  deletion_protection = false
  
  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.data_lake.name}/raw-data/videos.csv"]
    
    csv_options { 
      quote             = "\""
      skip_leading_rows = 1 
    }

    schema = <<EOF
[
  {"name": "video_id", "type": "STRING"},
  {"name": "titulo", "type": "STRING"},
  {"name": "categoria", "type": "STRING"},
  {"name": "duracion_min", "type": "INTEGER"},
  {"name": "formato", "type": "STRING"},
  {"name": "fecha_subida", "type": "TIMESTAMP"},
  {"name": "url_s3", "type": "STRING"}
]
EOF
  }
}

resource "google_bigquery_table" "eventos" {
  dataset_id = google_bigquery_dataset.analytics_lite.dataset_id
  table_id   = "eventos_serverless"
  deletion_protection = false
  
  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.data_lake.name}/raw-data/eventos_serverless.csv"]
    
    csv_options { 
      quote             = "\""
      skip_leading_rows = 1 
    }

    schema = <<EOF
[
  {"name": "event_id", "type": "STRING"},
  {"name": "video_id", "type": "STRING"},
  {"name": "accion", "type": "STRING"},
  {"name": "timestamp", "type": "TIMESTAMP"},
  {"name": "resultado", "type": "STRING"}
]
EOF
  }
}