# GCS Module for DVC Datasets

This Terraform module creates a Google Cloud Storage bucket and service account specifically designed for DVC dataset storage.

## Features

- **Google Cloud Storage Bucket** with versioning enabled
- **Service Account** with appropriate permissions for DVC access
- **Security configurations** including uniform bucket-level access
- **Cost optimization** with configurable lifecycle rules
- **Flexible labeling** for resource organization

## Usage

```hcl
module "dvc_gcs" {
  source = "./modules/gcs"

  bucket_name = "my-ml-datasets"
  environment = "dev"
  
  # Optional configurations
  bucket_location      = "US"
  lifecycle_age_days   = 90
  force_destroy        = false
  service_account_id   = "dvc-datasets-sa"
  create_service_account_key = true
  
  labels = {
    team = "ml-ops"
    cost-center = "ai-research"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | The name of the GCS bucket | `string` | n/a | yes |
| bucket_location | The location of the bucket | `string` | `"US"` | no |
| force_destroy | Whether to force destroy the bucket | `bool` | `false` | no |
| lifecycle_age_days | Days before objects are deleted (0 to disable) | `number` | `0` | no |
| environment | The environment name | `string` | `"dev"` | no |
| service_account_id | The ID for the service account | `string` | `"dvc-datasets-sa"` | no |
| create_service_account_key | Whether to create a service account key | `bool` | `true` | no |
| labels | Additional labels to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | The name of the created GCS bucket |
| bucket_url | The URL of the created GCS bucket |
| service_account_email | The email of the service account |
| service_account_key | The private key for the service account (sensitive) |
| dvc_remote_config | DVC remote configuration object |

## Examples

### Basic Usage
```hcl
module "dvc_gcs" {
  source = "./modules/gcs"
  
  bucket_name = "my-ml-datasets"
  environment = "dev"
}
```

### With Lifecycle Rules
```hcl
module "dvc_gcs" {
  source = "./modules/gcs"
  
  bucket_name        = "my-ml-datasets"
  environment        = "prod"
  lifecycle_age_days = 365  # Delete objects after 1 year
}
```

### Without Service Account Key (for CI/CD with Workload Identity)
```hcl
module "dvc_gcs" {
  source = "./modules/gcs"
  
  bucket_name                = "my-ml-datasets"
  environment                = "prod"
  create_service_account_key = false
}
``` 