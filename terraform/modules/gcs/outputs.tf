output "bucket_name" {
  description = "The name of the created GCS bucket"
  value       = google_storage_bucket.dvc_datasets.name
}

output "bucket_url" {
  description = "The URL of the created GCS bucket"
  value       = "gs://${google_storage_bucket.dvc_datasets.name}"
}

output "service_account_email" {
  description = "The email of the service account for DVC access"
  value       = google_service_account.dvc_service_account.email
}

output "service_account_key" {
  description = "The private key for the service account (base64 encoded)"
  value       = var.create_service_account_key ? base64decode(google_service_account_key.dvc_key[0].private_key) : null
  sensitive   = true
}

output "dvc_remote_config" {
  description = "DVC remote configuration for Google Cloud Storage"
  value = {
    url = "gs://${google_storage_bucket.dvc_datasets.name}"
    service_account_email = google_service_account.dvc_service_account.email
  }
} 