# Label Studio Module - Main Configuration
# This module deploys Label Studio on Google Cloud Platform

# Create a VPC for Label Studio
resource "google_compute_network" "label_studio_vpc" {
  name                    = "label-studio-vpc-${var.environment}"
  auto_create_subnetworks = false
  description            = "VPC for Label Studio deployment"
}

# Create subnet for Label Studio
resource "google_compute_subnetwork" "label_studio_subnet" {
  name          = "label-studio-subnet-${var.environment}"
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.label_studio_vpc.id
  region        = var.region
  
  # Enable flow logs for network monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata           = "INCLUDE_ALL_METADATA"
  }
}

# Create firewall rule for Label Studio web interface
resource "google_compute_firewall" "label_studio_web" {
  name    = "label-studio-web-${var.environment}"
  network = google_compute_network.label_studio_vpc.id
  
  allow {
    protocol = "tcp"
    ports    = ["8080"]  # Default Label Studio port
  }
  
  allow {
    protocol = "tcp"
    ports    = ["22"]    # SSH access
  }
  
  source_ranges = var.allowed_source_ranges
  target_tags   = ["label-studio"]
}

# Create service account for Label Studio
resource "google_service_account" "label_studio_sa" {
  account_id   = "label-studio-sa-${var.environment}"
  display_name = "Label Studio Service Account"
  description  = "Service account for Label Studio deployment"
}

# Grant necessary roles to the service account
resource "google_project_iam_member" "label_studio_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.label_studio_sa.email}"
}

resource "google_project_iam_member" "label_studio_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.label_studio_sa.email}"
}

# Create GCS bucket for Label Studio data
resource "google_storage_bucket" "label_studio_data" {
  name          = "${var.project_id}-label-studio-data-${var.environment}"
  location      = var.bucket_location
  force_destroy = var.force_destroy
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(var.labels, {
    purpose = "label-studio-data"
  })
}

# Create startup script for Label Studio using templatefile function
locals {
  startup_script = templatefile("${path.module}/startup-script.sh", {
    label_studio_version = var.label_studio_version
    admin_user          = var.admin_user
    admin_password      = var.admin_password
    gcs_bucket_name     = google_storage_bucket.label_studio_data.name
    project_id          = var.project_id
    environment         = var.environment
  })
}

# Create a static IP for the Label Studio instance (optional)
resource "google_compute_address" "label_studio_ip" {
  count   = var.enable_static_ip ? 1 : 0
  name    = "label-studio-ip-${var.environment}"
  region  = var.region
  project = var.project_id
}

# Create Compute Engine instance for Label Studio
resource "google_compute_instance" "label_studio" {
  name         = "label-studio-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone
  
  allow_stopping_for_update = true
  
  tags = ["label-studio", "http-server", "https-server"]
  
  boot_disk {
    initialize_params {
      image  = var.boot_disk_image
      size   = var.boot_disk_size_gb
      type   = var.boot_disk_type
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.label_studio_subnet.id
    
    # Enable external IP if specified
    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {
        nat_ip = var.enable_static_ip ? google_compute_address.label_studio_ip[0].address : null
      }
    }
  }
  
  metadata = {
    startup-script = local.startup_script
    ssh-keys       = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }
  
  service_account {
    email  = google_service_account.label_studio_sa.email
    scopes = ["cloud-platform"]
  }
  
  labels = merge(var.labels, {
    purpose = "label-studio"
  })
} 