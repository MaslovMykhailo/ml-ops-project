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

# Outputs for DVC GCS Module
output "dvc_bucket_name" {
  description = "The name of the GCS bucket for DVC datasets"
  value       = module.dvc_gcs.bucket_name
}

output "dvc_bucket_url" {
  description = "The URL of the GCS bucket for DVC datasets"
  value       = module.dvc_gcs.bucket_url
}

output "dvc_service_account_email" {
  description = "The email of the service account for DVC datasets"
  value       = module.dvc_gcs.service_account_email
}

output "dvc_service_account_key_path" {
  description = "The path to the service account key file for DVC datasets"
  value       = module.dvc_gcs.service_account_key_path
  sensitive   = true
}

# Outputs for Label Studio Module (conditional)
output "label_studio_instance_name" {
  description = "The name of the Label Studio instance"
  value       = var.enable_label_studio ? module.label_studio[0].instance_name : null
}

output "label_studio_external_ip" {
  description = "The external IP address of the Label Studio instance"
  value       = var.enable_label_studio ? module.label_studio[0].instance_external_ip : null
}

output "label_studio_url" {
  description = "The URL to access Label Studio web interface"
  value       = var.enable_label_studio ? module.label_studio[0].label_studio_url : null
}

output "label_studio_data_bucket" {
  description = "The name of the GCS bucket for Label Studio data"
  value       = var.enable_label_studio ? module.label_studio[0].data_bucket_name : null
}

output "label_studio_service_account" {
  description = "The email of the service account used by Label Studio"
  value       = var.enable_label_studio ? module.label_studio[0].service_account_email : null
}

output "label_studio_ssh_command" {
  description = "SSH command to connect to the Label Studio instance"
  value       = var.enable_label_studio ? module.label_studio[0].ssh_command : null
}

output "label_studio_admin_credentials" {
  description = "Label Studio admin credentials"
  value       = var.enable_label_studio ? module.label_studio[0].admin_credentials : null
  sensitive   = true
} 