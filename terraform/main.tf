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

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "servicenetworking.googleapis.com",  # Required for Cloud SQL private networking
    "redis.googleapis.com",              # Required for Memorystore Redis
    "sqladmin.googleapis.com",           # Required for Cloud SQL
    "run.googleapis.com",                # Required for Cloud Run
    "compute.googleapis.com",            # Required for networking
    "storage.googleapis.com"             # Required for Cloud Storage
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Configure Service Networking for VPC
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "projects/${var.project_id}/global/networks/${var.network}"
  
  depends_on = [google_project_service.required_apis]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = "projects/${var.project_id}/global/networks/${var.network}"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  
  depends_on = [google_project_service.required_apis]
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

  project_id        = var.project_id
  region            = var.region
  environment       = var.environment
  network           = var.network
  
  # Database configuration
  db_password       = var.label_studio_db_password
  
  # Admin credentials
  admin_username    = var.label_studio_admin_username
  admin_password    = var.label_studio_admin_password
  
  # Storage configuration - use the same bucket as DVC
  gcs_bucket_name   = module.dvc_gcs.bucket_name
  create_data_bucket = false  # Use existing DVC bucket
  
  # Common labels
  common_labels = {
    project     = "ml-ops"
    team        = "data-science"
    managed_by  = "terraform"
    environment = var.environment
  }
  
  depends_on = [google_service_networking_connection.private_vpc_connection]
} 