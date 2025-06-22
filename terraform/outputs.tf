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

# Label Studio Outputs
output "label_studio_url" {
  description = "The URL of the Label Studio web interface"
  value       = var.enable_label_studio ? module.label_studio[0].service_url : null
}

output "label_studio_service_account" {
  description = "The email of the Label Studio service account"
  value       = var.enable_label_studio ? module.label_studio[0].service_account_email : null
}

output "label_studio_database" {
  description = "The name of the Label Studio database"
  value       = var.enable_label_studio ? module.label_studio[0].database_name : null
}

output "label_studio_redis" {
  description = "The name of the Redis instance for Label Studio"
  value       = var.enable_label_studio ? module.label_studio[0].redis_instance_name : null
} 