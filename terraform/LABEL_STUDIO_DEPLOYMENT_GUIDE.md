# Label Studio Deployment Guide

This guide walks you through deploying Label Studio on Google Cloud Platform using Terraform.

## 🎯 Overview

Label Studio is an open-source data labeling tool that helps you create high-quality training data for machine learning models. This deployment includes:

- **Compute Engine Instance**: Hosts Label Studio application
- **VPC & Networking**: Secure network configuration with firewall rules
- **GCS Integration**: Google Cloud Storage for data persistence
- **Service Account**: Secure access with least privilege permissions
- **Auto-startup**: Automatic installation and configuration

## 🚀 Quick Start

### Prerequisites

1. **Google Cloud Project**: You need a GCP project with billing enabled
2. **Terraform**: Install Terraform (version >= 1.0)
3. **Google Cloud CLI**: Install and authenticate with `gcloud auth login`
4. **SSH Key**: Generate SSH key pair for instance access

### Step 1: Configure Variables

Copy the example configuration and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# Required: Your GCP project ID
project_id = "your-gcp-project-id"

# Required: Label Studio admin password (minimum 8 characters)
label_studio_admin_password = "your-secure-password-here"

# Enable Label Studio deployment
enable_label_studio = true

# Optional: Customize instance type
label_studio_machine_type = "e2-standard-4"

# Optional: Enable static IP for production
label_studio_enable_static_ip = false

# Security: Restrict access to your IP range
label_studio_allowed_source_ranges = ["YOUR_IP_ADDRESS/32"]
```

### Step 2: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### Step 3: Access Label Studio

After deployment completes, you'll see output like:

```
label_studio_url = "http://34.123.45.67:8080"
label_studio_admin_credentials = {
  username = "admin"
  password = "your-secure-password-here"
}
```

1. Open the URL in your browser
2. Log in with the admin credentials
3. Start creating your labeling projects!

## 🔧 Configuration Options

### Instance Configuration

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `label_studio_machine_type` | Compute Engine machine type | `e2-standard-4` | `e2-standard-2`, `e2-standard-4`, `e2-standard-8`, etc. |
| `label_studio_enable_static_ip` | Assign static IP address | `false` | `true`, `false` |
| `label_studio_version` | Label Studio version | `1.9.2` | Latest version from PyPI |

### Network Configuration

| Variable | Description | Default | Security |
|----------|-------------|---------|----------|
| `label_studio_allowed_source_ranges` | IP ranges allowed to access | `["0.0.0.0/0"]` | **Restrict in production!** |

**Security Recommendation**: Replace `0.0.0.0/0` with your specific IP range:
```hcl
label_studio_allowed_source_ranges = ["203.0.113.0/24", "198.51.100.0/24"]
```

### Storage Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `bucket_location` | GCS bucket location | `"US"` |
| `lifecycle_age_days` | Data retention period | `0` (no deletion) |
| `force_destroy` | Delete bucket on destroy | `false` |

## 🔐 Security Best Practices

### 1. Network Security

```hcl
# Production configuration
label_studio_allowed_source_ranges = [
  "YOUR_OFFICE_IP/32",
  "YOUR_VPN_RANGE/24"
]
```

### 2. Strong Passwords

```hcl
# Use a strong, unique password
label_studio_admin_password = "ComplexPassword123!@#"
```

### 3. Service Account Permissions

The module creates a service account with minimal required permissions:
- `roles/storage.admin` - For GCS access
- `roles/compute.admin` - For instance management

### 4. SSH Access

Generate and use SSH keys for secure access:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/label_studio_key

# Update terraform.tfvars
ssh_public_key_path = "~/.ssh/label_studio_key.pub"
```

## 📊 Monitoring and Maintenance

### Health Checks

Check if Label Studio is running:

```bash
# SSH into the instance
gcloud compute ssh label-studio@label-studio-dev --zone=us-central1-a

# Check service status
sudo systemctl status label-studio

# Check logs
sudo journalctl -u label-studio -f
```

### Backup Strategy

1. **GCS Bucket**: Automatic versioning enabled
2. **Database**: SQLite database in `/home/label-studio/.local/share/label-studio/`
3. **Configuration**: Stored in instance metadata

### Scaling Considerations

- **Development**: `e2-standard-2` (2 vCPUs, 8 GB RAM)
- **Production**: `e2-standard-4` or higher based on workload
- **High Availability**: Consider multiple instances with load balancer

## 🛠️ Troubleshooting

### Common Issues

#### 1. Instance Won't Start

```bash
# Check startup script logs
gcloud compute instances get-serial-port-output label-studio-dev --zone=us-central1-a

# Verify service account permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID
```

#### 2. Can't Access Web Interface

```bash
# Check firewall rules
gcloud compute firewall-rules list --filter="name~label-studio"

# Verify external IP
gcloud compute instances describe label-studio-dev --zone=us-central1-a --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
```

#### 3. GCS Integration Issues

```bash
# Check service account authentication
gcloud auth list

# Test GCS access
gsutil ls gs://YOUR_PROJECT_ID-label-studio-data-dev/
```

### Debug Commands

```bash
# SSH into instance
gcloud compute ssh label-studio@label-studio-dev --zone=us-central1-a

# Check Label Studio process
ps aux | grep label-studio

# Test web interface locally
curl http://localhost:8080/health/

# Check disk space
df -h

# Check memory usage
free -h
```

## 💰 Cost Optimization

### Resource Sizing

| Environment | Machine Type | Monthly Cost (approx.) |
|-------------|--------------|------------------------|
| Development | `e2-standard-2` | $25-30 |
| Production | `e2-standard-4` | $50-60 |
| Large Scale | `e2-standard-8` | $100-120 |

### Cost Monitoring

1. **Set up billing alerts** in Google Cloud Console
2. **Monitor resource usage** with Cloud Monitoring
3. **Use preemptible instances** for non-critical workloads
4. **Implement auto-shutdown** for development environments

### Lifecycle Management

```hcl
# Configure data retention
lifecycle_age_days = 365  # Delete data older than 1 year

# Use cheaper storage classes
bucket_location = "US"  # Standard storage
```

## 🔄 Updates and Maintenance

### Updating Label Studio

1. **Update version in terraform.tfvars**:
   ```hcl
   label_studio_version = "1.9.3"
   ```

2. **Apply changes**:
   ```bash
   terraform plan
   terraform apply
   ```

### Infrastructure Updates

```bash
# Update Terraform modules
terraform init -upgrade

# Plan and apply updates
terraform plan
terraform apply
```

## 🗑️ Cleanup

To destroy the Label Studio infrastructure:

```bash
# Destroy Label Studio only
terraform destroy -target=module.label_studio

# Destroy all infrastructure
terraform destroy
```

**Warning**: This will delete all data in the GCS bucket if `force_destroy = true`.

## 📚 Additional Resources

- [Label Studio Documentation](https://labelstud.io/guide/)
- [Google Cloud Compute Engine](https://cloud.google.com/compute/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCS Best Practices](https://cloud.google.com/storage/docs/best-practices)

## 🤝 Support

For issues with this deployment:

1. Check the troubleshooting section above
2. Review Label Studio logs: `/home/label-studio/.local/share/label-studio/logs/`
3. Check Terraform state: `terraform show`
4. Verify GCP resources in the Cloud Console 