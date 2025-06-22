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