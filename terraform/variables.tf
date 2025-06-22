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

variable "bucket_name" {
  description = "The name of the Google Cloud Storage bucket for DVC datasets"
  type        = string
  default     = "ml-ops-datasets"
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be globally unique and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "bucket_location" {
  description = "The location of the Google Cloud Storage bucket"
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

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Label Studio Configuration
variable "enable_label_studio" {
  description = "Whether to deploy Label Studio"
  type        = bool
  default     = false
}

variable "label_studio_admin_password" {
  description = "The admin password for Label Studio"
  type        = string
  sensitive   = true
  default     = ""
  
  validation {
    condition     = var.enable_label_studio ? length(var.label_studio_admin_password) >= 8 : true
    error_message = "Label Studio admin password must be at least 8 characters long when Label Studio is enabled."
  }
}

variable "label_studio_machine_type" {
  description = "The machine type for the Label Studio instance"
  type        = string
  default     = "e2-standard-4"
}

variable "label_studio_enable_static_ip" {
  description = "Whether to assign a static IP to the Label Studio instance"
  type        = bool
  default     = false
}

variable "label_studio_allowed_source_ranges" {
  description = "List of IP ranges allowed to access Label Studio"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Warning: This allows all IPs - restrict in production
} 