# Configure the Google Cloud Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  
  # Optional: Configure backend for state management
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "ml-ops-project"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Use the GCS module for DVC datasets
module "dvc_gcs" {
  source = "./modules/gcs"

  bucket_name = var.bucket_name
  environment = var.environment
  
  # Optional configurations
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

# Deploy Label Studio (conditional)
module "label_studio" {
  count  = var.enable_label_studio ? 1 : 0
  source = "./modules/label-studio"

  project_id = var.project_id
  region     = var.region
  zone       = var.zone
  environment = var.environment
  
  # Label Studio Configuration
  admin_password = var.label_studio_admin_password
  machine_type   = var.label_studio_machine_type
  enable_static_ip = var.label_studio_enable_static_ip
  allowed_source_ranges = var.label_studio_allowed_source_ranges
  
  # Storage Configuration
  bucket_location = var.bucket_location
  force_destroy   = var.force_destroy
  lifecycle_age_days = var.lifecycle_age_days
  
  # Labels
  labels = {
    project = "ml-ops"
    team    = "data-science"
    service = "label-studio"
  }
} 