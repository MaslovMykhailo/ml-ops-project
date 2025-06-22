# Label Studio Module Variables

variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
}

variable "region" {
  description = "The default region for Google Cloud resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The default zone for Google Cloud resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Network Configuration
variable "subnet_cidr" {
  description = "CIDR range for the Label Studio subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_source_ranges" {
  description = "List of IP ranges allowed to access Label Studio"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Warning: This allows all IPs - restrict in production
}

# Compute Configuration
variable "machine_type" {
  description = "The machine type for the Label Studio instance"
  type        = string
  default     = "e2-standard-4"  # 4 vCPUs, 16 GB RAM
}

variable "boot_disk_image" {
  description = "The boot disk image for the Label Studio instance"
  type        = string
  default     = "debian-cloud/debian-11"  # Debian 11 (Bullseye)
}

variable "boot_disk_size_gb" {
  description = "The size of the boot disk in GB"
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "The type of the boot disk"
  type        = string
  default     = "pd-standard"
}

variable "enable_external_ip" {
  description = "Whether to enable external IP for the Label Studio instance"
  type        = bool
  default     = true
}

variable "enable_static_ip" {
  description = "Whether to assign a static IP to the Label Studio instance"
  type        = bool
  default     = false
}

# SSH Configuration
variable "ssh_user" {
  description = "The SSH user for the Label Studio instance"
  type        = string
  default     = "label-studio"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Label Studio Configuration
variable "label_studio_version" {
  description = "The version of Label Studio to install"
  type        = string
  default     = "1.9.2"
}

variable "admin_user" {
  description = "The admin username for Label Studio"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "The admin password for Label Studio"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long."
  }
}

# Storage Configuration
variable "bucket_location" {
  description = "The location of the Label Studio data bucket"
  type        = string
  default     = "US"
}

variable "force_destroy" {
  description = "Whether to force destroy the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "lifecycle_age_days" {
  description = "Number of days after which objects should be deleted (0 to disable)"
  type        = number
  default     = 0
  
  validation {
    condition     = var.lifecycle_age_days >= 0
    error_message = "Lifecycle age must be 0 or greater."
  }
}

# Labels
variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    project = "ml-ops"
    team    = "data-science"
    service = "label-studio"
  }
} 