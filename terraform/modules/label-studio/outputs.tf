# Label Studio Module Outputs

output "service_url" {
  description = "The URL of the Label Studio Cloud Run service"
  value       = google_cloud_run_service.label_studio.status[0].url
}

output "label_studio_host" {
  description = "The full URL for LABEL_STUDIO_HOST environment variable"
  value       = "https://${google_cloud_run_service.label_studio.status[0].url}"
}

output "service_account_email" {
  description = "The email of the Label Studio service account"
  value       = google_service_account.label_studio.email
}

output "database_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.label_studio_db.name
}

output "database_name" {
  description = "The name of the Label Studio database"
  value       = google_sql_database.label_studio.name
}

output "redis_instance_name" {
  description = "The name of the Redis instance"
  value       = google_redis_instance.label_studio.name
}

output "data_bucket_name" {
  description = "The name of the GCS bucket used for Label Studio data"
  value       = var.create_data_bucket ? google_storage_bucket.label_studio_data[0].name : var.gcs_bucket_name
} 