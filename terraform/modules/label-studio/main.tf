# Label Studio Module - Deploy Label Studio on Cloud Run
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Service account for Label Studio
resource "google_service_account" "label_studio" {
  account_id   = "label-studio-${var.environment}"
  display_name = "Label Studio Service Account"
  description  = "Service account for Label Studio application"
}

# IAM binding for Label Studio to access GCS
resource "google_project_iam_member" "label_studio_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.label_studio.email}"
}

# IAM binding to allow Cloud Run to access Cloud SQL
resource "google_project_iam_member" "label_studio_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.label_studio.email}"
}

# IAM binding to allow Cloud Run to access Redis
resource "google_project_iam_member" "label_studio_redis" {
  project = var.project_id
  role    = "roles/redis.viewer"
  member  = "serviceAccount:${google_service_account.label_studio.email}"
}

# Create Cloud SQL instance for Label Studio database
resource "google_sql_database_instance" "label_studio_db" {
  name             = "label-studio-db-${var.environment}"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier = "db-f1-micro"  # Small instance for development

    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = "projects/${var.project_id}/global/networks/${var.network}"
      require_ssl     = false  # For development, set to true for production
    }
  }

  deletion_protection = false  # Set to true for production
}

# Create database for Label Studio
resource "google_sql_database" "label_studio" {
  name     = "label_studio"
  instance = google_sql_database_instance.label_studio_db.name
}

# Create user for Label Studio
resource "google_sql_user" "label_studio" {
  name     = "label_studio"
  instance = google_sql_database_instance.label_studio_db.name
  password = var.db_password
}

# Create Redis instance for Label Studio
resource "google_redis_instance" "label_studio" {
  name           = "label-studio-redis-${var.environment}"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region

  authorized_network = "projects/${var.project_id}/global/networks/${var.network}"

  labels = var.common_labels
}

# Create Cloud Run service for Label Studio
resource "google_cloud_run_service" "label_studio" {
  name     = "label-studio-${var.environment}"
  location = var.region

  template {
    spec {
      containers {
        image = "heartexlabs/label-studio:latest"
        
        ports {
          container_port = 8080
        }

        env {
          name  = "LABEL_STUDIO_BASE_DATA_DIR"
          value = "/label-studio/data"
        }

        env {
          name  = "LABEL_STUDIO_DB"
          value = "postgresql://${google_sql_user.label_studio.name}:${var.db_password}@${google_sql_database_instance.label_studio_db.private_ip_address}:5432/${google_sql_database.label_studio.name}"
        }

        env {
          name  = "LABEL_STUDIO_REDIS_URL"
          value = "redis://${google_redis_instance.label_studio.host}:${google_redis_instance.label_studio.port}/0"
        }

        env {
          name  = "LABEL_STUDIO_USERNAME"
          value = var.admin_username
        }

        env {
          name  = "LABEL_STUDIO_PASSWORD"
          value = var.admin_password
        }

        env {
          name  = "LABEL_STUDIO_GCS_BUCKET"
          value = var.gcs_bucket_name
        }
      }

      service_account_name = google_service_account.label_studio.email
    }

    metadata {
      annotations = {
        "run.googleapis.com/execution-environment" = "gen2"
        "run.googleapis.com/cpu-throttling"        = "false"
        "run.googleapis.com/startup-cpu-boost"     = "true"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  
  depends_on = [
    google_sql_database_instance.label_studio_db,
    google_redis_instance.label_studio
  ]
}

# Make Cloud Run service publicly accessible
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_service.label_studio.location
  service  = google_cloud_run_service.label_studio.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Create Cloud Storage bucket for Label Studio data (if not using existing DVC bucket)
resource "google_storage_bucket" "label_studio_data" {
  count         = var.create_data_bucket ? 1 : 0
  name          = "${var.project_id}-label-studio-data-${var.environment}"
  location      = var.bucket_location
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(var.common_labels, {
    purpose = "label-studio-data"
  })
}

# IAM binding for Label Studio to access data bucket
resource "google_storage_bucket_iam_member" "label_studio_data_access" {
  count  = var.create_data_bucket ? 1 : 0
  bucket = google_storage_bucket.label_studio_data[0].name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.label_studio.email}"
} 