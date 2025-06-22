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