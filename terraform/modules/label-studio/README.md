# Label Studio Module

This Terraform module deploys Label Studio on Google Cloud Platform using Compute Engine. Label Studio is an open-source data labeling tool for machine learning projects.

## Features

- **Compute Engine Instance**: Deploys Label Studio on a GCP Compute Engine instance
- **VPC & Networking**: Creates dedicated VPC and subnet with proper firewall rules
- **GCS Integration**: Configures Google Cloud Storage for data persistence
- **Service Account**: Creates and configures service account with necessary permissions
- **Auto-startup**: Includes startup script for automatic installation and configuration
- **Health Monitoring**: Built-in health checks and status monitoring

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Label Studio Module                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Compute       │  │   VPC &         │  │   GCS        │ │
│  │   Engine        │  │   Networking    │  │   Storage    │ │
│  │                 │  │                 │  │              │ │
│  │ • Instance      │  │ • VPC           │  │ • Data       │ │
│  │ • Startup       │  │ • Subnet        │  │   Bucket     │ │
│  │   Script        │  │ • Firewall      │  │ • Versioning │ │
│  │ • Service       │  │ • IAM           │  │ • Lifecycle  │ │
│  │   Account       │  │                 │  │   Rules      │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "label_studio" {
  source = "./modules/label-studio"

  project_id = "your-gcp-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
  
  # Required: Admin password
  admin_password = "your-secure-password"
  
  # Optional: Customize instance
  machine_type = "e2-standard-4"
  environment  = "dev"
}
```

### Advanced Usage

```hcl
module "label_studio" {
  source = "./modules/label-studio"

  project_id = "your-gcp-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
  
  # Label Studio Configuration
  label_studio_version = "1.9.2"
  admin_user          = "admin"
  admin_password      = "your-secure-password"
  
  # Compute Configuration
  machine_type        = "e2-standard-8"
  boot_disk_size_gb   = 100
  enable_static_ip    = true
  
  # Network Configuration
  subnet_cidr         = "10.0.1.0/24"
  allowed_source_ranges = ["YOUR_IP_RANGE/32"]
  
  # Storage Configuration
  bucket_location     = "US"
  lifecycle_age_days  = 365
  
  # Environment
  environment = "prod"
  
  # Labels
  labels = {
    project = "ml-ops"
    team    = "data-science"
    service = "label-studio"
    cost_center = "ai-research"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The ID of the Google Cloud project | `string` | n/a | yes |
| region | The default region for Google Cloud resources | `string` | `"us-central1"` | no |
| zone | The default zone for Google Cloud resources | `string` | `"us-central1-a"` | no |
| environment | The environment (dev, staging, prod) | `string` | `"dev"` | no |
| subnet_cidr | CIDR range for the Label Studio subnet | `string` | `"10.0.1.0/24"` | no |
| allowed_source_ranges | List of IP ranges allowed to access Label Studio | `list(string)` | `["0.0.0.0/0"]` | no |
| machine_type | The machine type for the Label Studio instance | `string` | `"e2-standard-4"` | no |
| boot_disk_image | The boot disk image for the Label Studio instance | `string` | `"debian-cloud/debian-11"` | no |
| boot_disk_size_gb | The size of the boot disk in GB | `number` | `50` | no |
| boot_disk_type | The type of the boot disk | `string` | `"pd-standard"` | no |
| enable_external_ip | Whether to enable external IP for the Label Studio instance | `bool` | `true` | no |
| enable_static_ip | Whether to assign a static IP to the Label Studio instance | `bool` | `false` | no |
| ssh_user | The SSH user for the Label Studio instance | `string` | `"label-studio"` | no |
| ssh_public_key_path | Path to the SSH public key file | `string` | `"~/.ssh/id_rsa.pub"` | no |
| label_studio_version | The version of Label Studio to install | `string` | `"1.9.2"` | no |
| admin_user | The admin username for Label Studio | `string` | `"admin"` | no |
| admin_password | The admin password for Label Studio | `string` | n/a | yes |
| bucket_location | The location of the Label Studio data bucket | `string` | `"US"` | no |
| force_destroy | Whether to force destroy the bucket even if it contains objects | `bool` | `false` | no |
| lifecycle_age_days | Number of days after which objects should be deleted (0 to disable) | `number` | `0` | no |
| labels | Labels to apply to all resources | `map(string)` | `{"project": "ml-ops", "service": "label-studio", "team": "data-science"}` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_name | The name of the Label Studio instance |
| instance_external_ip | The external IP address of the Label Studio instance |
| instance_internal_ip | The internal IP address of the Label Studio instance |
| static_ip_address | The static IP address assigned to Label Studio (if enabled) |
| label_studio_url | The URL to access Label Studio web interface |
| service_account_email | The email of the service account used by Label Studio |
| data_bucket_name | The name of the GCS bucket for Label Studio data |
| vpc_name | The name of the VPC created for Label Studio |
| subnet_name | The name of the subnet created for Label Studio |
| firewall_rule_name | The name of the firewall rule for Label Studio |
| ssh_command | SSH command to connect to the Label Studio instance |
| admin_credentials | Label Studio admin credentials (sensitive) |

## Security Considerations

### Network Security
- **Firewall Rules**: Only port 8080 (Label Studio) and 22 (SSH) are open
- **Source Ranges**: Restrict `allowed_source_ranges` to your IP ranges in production
- **VPC**: Dedicated VPC with isolated subnet

### Access Control
- **Service Account**: Least privilege principle with specific IAM roles
- **SSH Keys**: Use SSH keys for secure access
- **Admin Password**: Strong password required (minimum 8 characters)

### Data Security
- **GCS Bucket**: Uniform bucket-level access enabled
- **Versioning**: Enabled for data protection
- **Lifecycle Rules**: Configurable data retention policies

## Monitoring and Maintenance

### Health Checks
The module includes built-in health checks:
- Service status monitoring
- Web interface availability
- Resource usage tracking

### Logs
- System logs: `/var/log/syslog`
- Label Studio logs: `/home/label-studio/.local/share/label-studio/logs/`
- Startup script logs: Available in instance metadata

### Backup and Recovery
- **GCS Bucket**: Automatic versioning for data protection
- **Database**: SQLite database backed up to GCS
- **Configuration**: Stored in instance metadata

## Troubleshooting

### Common Issues

1. **Instance won't start**
   - Check startup script logs
   - Verify service account permissions
   - Ensure required APIs are enabled

2. **Can't access web interface**
   - Verify firewall rules
   - Check if Label Studio service is running
   - Confirm external IP is assigned

3. **GCS integration issues**
   - Verify service account has storage permissions
   - Check bucket exists and is accessible
   - Review IAM role assignments

### Debug Commands

```bash
# Check service status
sudo systemctl status label-studio

# View logs
sudo journalctl -u label-studio -f

# Check Label Studio process
ps aux | grep label-studio

# Test web interface
curl http://localhost:8080/health/

# Check GCS connectivity
gcloud auth list
gsutil ls gs://your-bucket-name
```

## Cost Optimization

### Resource Sizing
- **Development**: `e2-standard-2` (2 vCPUs, 8 GB RAM)
- **Production**: `e2-standard-4` or higher based on workload
- **Storage**: Start with 50GB, scale as needed

### Cost Monitoring
- Use GCP Cost Management tools
- Set up billing alerts
- Monitor resource usage with Cloud Monitoring

### Lifecycle Management
- Configure lifecycle rules for old data
- Use preemptible instances for non-critical workloads
- Implement auto-shutdown for development environments

## Examples

See the main Terraform configuration for complete examples of how to use this module in your ML Ops project.

## Contributing

When contributing to this module:
1. Follow Terraform best practices
2. Add comprehensive tests
3. Update documentation
4. Ensure backward compatibility 