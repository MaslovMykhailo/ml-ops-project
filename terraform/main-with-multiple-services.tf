# Example: Main configuration with multiple services
# This file demonstrates how to organize multiple services using modules

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 1. GCS Module for DVC datasets
module "dvc_gcs" {
  source = "./modules/gcs"

  bucket_name = var.bucket_name
  environment = var.environment
  
  bucket_location      = var.bucket_location
  lifecycle_age_days   = var.lifecycle_age_days
  force_destroy        = var.force_destroy
  service_account_id   = "dvc-datasets-sa"
  create_service_account_key = true
  
  labels = {
    project = "ml-ops"
    team    = "data-science"
  }
}

# 2. Compute Module for ML Training (example)
module "ml_training" {
  source = "./modules/compute"
  
  instance_count = var.training_instance_count
  instance_name  = "ml-training"
  machine_type   = var.training_machine_type
  zone           = var.zone
  
  environment = var.environment
  enable_external_ip = var.enable_external_ip
  
  service_account_email = module.dvc_gcs.service_account_email
  
  labels = {
    project = "ml-ops"
    team    = "ml-engineering"
  }
  
  # Only create if training is enabled
  count = var.enable_ml_training ? 1 : 0
}

# 3. Example: Add more services as needed
# module "ml_serving" {
#   source = "./modules/serving"
#   
#   environment = var.environment
#   service_account_email = module.dvc_gcs.service_account_email
#   
#   depends_on = [module.dvc_gcs]
# }

# module "monitoring" {
#   source = "./modules/monitoring"
#   
#   environment = var.environment
#   project_id = var.project_id
# }

# module "networking" {
#   source = "./modules/networking"
#   
#   environment = var.environment
#   project_id = var.project_id
# } 