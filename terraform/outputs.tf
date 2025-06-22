output "bucket_name" {
  description = "The name of the created GCS bucket"
  value       = module.dvc_gcs.bucket_name
}

output "bucket_url" {
  description = "The URL of the created GCS bucket"
  value       = module.dvc_gcs.bucket_url
}

output "service_account_email" {
  description = "The email of the service account for DVC access"
  value       = module.dvc_gcs.service_account_email
}

output "service_account_key" {
  description = "The private key for the service account (base64 encoded)"
  value       = module.dvc_gcs.service_account_key
  sensitive   = true
}

output "dvc_remote_config" {
  description = "DVC remote configuration for Google Cloud Storage"
  value       = module.dvc_gcs.dvc_remote_config
} 