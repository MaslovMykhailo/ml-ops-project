# Label Studio Module

This Terraform module deploys Label Studio on Google Cloud Platform using Cloud Run, Cloud SQL, and Redis.

## Architecture

- **Cloud Run**: Hosts the Label Studio web application
- **Cloud SQL**: PostgreSQL database for Label Studio metadata
- **Redis**: Caching and session management
- **Cloud Storage**: Data storage (can use existing DVC bucket)

## Usage

```hcl
module "label_studio" {
  source = "./modules/label-studio"

  project_id        = "your-project-id"
  region            = "us-central1"
  environment       = "dev"
  
  # Database configuration
  db_password       = "your-secure-password"
  
  # Admin credentials
  admin_username    = "admin"
  admin_password    = "your-admin-password"
  
  # Storage configuration
  gcs_bucket_name   = "your-dvc-bucket-name"  # Can use existing DVC bucket
  create_data_bucket = false  # Set to true if you want a separate bucket
  
  # Network configuration
  network           = "default"
  
  # Common labels
  common_labels = {
    project     = "ml-ops"
    team        = "data-science"
    managed_by  = "terraform"
    environment = "dev"
  }
}
```

## Features

- **Auto-scaling**: Cloud Run automatically scales based on demand
- **Cost-effective**: Pay only for what you use
- **Secure**: Uses service accounts and private networking
- **Persistent storage**: Data stored in Cloud SQL and Cloud Storage
- **Easy access**: Public URL for web interface

## Outputs

- `service_url`: URL to access Label Studio web interface
- `service_account_email`: Service account email for API access
- `database_instance_name`: Cloud SQL instance name
- `database_name`: Database name
- `redis_instance_name`: Redis instance name
- `data_bucket_name`: GCS bucket name for data storage

## Security Considerations

- Database is in private network
- Uses service accounts with minimal permissions
- Admin credentials should be stored securely (use Terraform Cloud or similar)
- Consider enabling IAP for additional security

## Cost Optimization

- Uses `db-f1-micro` for development (upgrade for production)
- Redis Basic tier for development
- Cloud Run scales to zero when not in use
- Lifecycle rules for data cleanup

## Integration with DVC

This module can use your existing DVC GCS bucket by setting:
- `gcs_bucket_name = module.dvc_gcs.bucket_name`
- `create_data_bucket = false`

This allows Label Studio to access the same images that DVC manages. 