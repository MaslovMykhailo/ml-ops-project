# Label Studio Module Variables

variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "The Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "network" {
  description = "The VPC network for the database"
  type        = string
  default     = "default"
}

variable "db_password" {
  description = "Password for the Label Studio database user"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Label Studio admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Label Studio admin password"
  type        = string
  sensitive   = true
}

variable "gcs_bucket_name" {
  description = "Name of the GCS bucket for Label Studio data (can be the same as DVC bucket)"
  type        = string
}

variable "create_data_bucket" {
  description = "Whether to create a new GCS bucket for Label Studio data"
  type        = bool
  default     = false
}

variable "bucket_location" {
  description = "Location for the GCS bucket"
  type        = string
  default     = "US"
}

variable "force_destroy" {
  description = "Whether to force destroy the bucket"
  type        = bool
  default     = false
}

variable "lifecycle_age_days" {
  description = "Age in days for lifecycle rule"
  type        = number
  default     = 365
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    project     = "ml-ops"
    team        = "data-science"
    managed_by  = "terraform"
    environment = "dev"
  }
} 