# GCS Module for DVC Datasets
# This module creates a Google Cloud Storage bucket and service account for DVC

resource "google_storage_bucket" "dvc_datasets" {
  name          = var.bucket_name
  location      = var.bucket_location
  force_destroy = var.force_destroy

  # Enable versioning for dataset versioning
  versioning {
    enabled = true
  }

  # Configure lifecycle rules for cost optimization
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_age_days > 0 ? [1] : []
    content {
      condition {
        age = var.lifecycle_age_days
      }
      action {
        type = "Delete"
      }
    }
  }

  # Optional: Configure uniform bucket-level access
  uniform_bucket_level_access = true

  # Optional: Configure public access prevention
  public_access_prevention = "enforced"

  labels = merge(var.labels, {
    environment = var.environment
    project     = "ml-ops"
    purpose     = "dvc-datasets"
  })
}

# Create a service account for DVC access
resource "google_service_account" "dvc_service_account" {
  account_id   = var.service_account_id
  display_name = "Service Account for DVC Dataset Storage"
  description  = "Service account used by DVC to access Google Cloud Storage"
}

# Grant the service account access to the bucket
resource "google_storage_bucket_iam_member" "dvc_bucket_access" {
  bucket = google_storage_bucket.dvc_datasets.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dvc_service_account.email}"
}

# Create a service account key for DVC authentication
resource "google_service_account_key" "dvc_key" {
  count              = var.create_service_account_key ? 1 : 0
  service_account_id = google_service_account.dvc_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
} 