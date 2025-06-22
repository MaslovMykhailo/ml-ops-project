# Terraform Architecture Guide for Multiple Services

This guide explains how to organize your Terraform configuration when you have multiple services in your ML Ops project.

## 🏗️ Recommended Architecture: Modular Approach

### Directory Structure
```
terraform/
├── modules/                    # Reusable modules
│   ├── gcs/                   # GCS for DVC datasets
│   ├── compute/               # Compute Engine for training
│   ├── serving/               # Model serving infrastructure
│   ├── monitoring/            # Monitoring and logging
│   ├── networking/            # VPC, firewall, load balancers
│   └── shared/                # Shared resources (IAM, etc.)
├── environments/              # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── main.tf                    # Current configuration (GCS only)
├── main-with-multiple-services.tf  # Example with multiple services
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example
```

## 🎯 When to Use Each Approach

### 1. **Single Main File** (Current Setup)
**Best for**: Simple projects, single service, learning
```hcl
# main.tf - Just GCS for DVC
module "dvc_gcs" {
  source = "./modules/gcs"
  # ... configuration
}
```

### 2. **Multiple Modules in Main** (Recommended for Growth)
**Best for**: Multiple services, single environment, team collaboration
```hcl
# main.tf - Multiple services
module "dvc_gcs" { ... }
module "ml_training" { ... }
module "ml_serving" { ... }
module "monitoring" { ... }
```

### 3. **Environment-Based Structure** (Production Ready)
**Best for**: Multiple environments, CI/CD, enterprise
```
environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
├── staging/
└── prod/
```

## 🚀 Migration Path

### Step 1: Start with Modules (Current)
You're already here! Your GCS configuration is modularized.

### Step 2: Add More Services
When you need additional services, add them as modules:

```hcl
# Example: Adding ML Training
module "ml_training" {
  source = "./modules/compute"
  
  instance_count = 2
  machine_type   = "n1-standard-8"
  zone           = var.zone
  
  # Use the service account from GCS module
  service_account_email = module.dvc_gcs.service_account_email
}
```

### Step 3: Environment Separation (Future)
When you need multiple environments:

```bash
# Create environment directories
mkdir -p environments/{dev,staging,prod}

# Copy and customize for each environment
cp main.tf environments/dev/
cp variables.tf environments/dev/
# Customize terraform.tfvars for each environment
```

## 📋 Module Guidelines

### 1. **Module Structure**
Each module should have:
```
modules/service-name/
├── main.tf          # Resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── README.md        # Documentation
```

### 2. **Module Design Principles**
- **Single Responsibility**: Each module does one thing well
- **Reusability**: Modules should be reusable across environments
- **Dependency Management**: Use `depends_on` for explicit dependencies
- **Output Sharing**: Modules should expose outputs for other modules to use

### 3. **Variable Management**
```hcl
# In modules/gcs/variables.tf
variable "bucket_name" {
  description = "The name of the GCS bucket"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be globally unique."
  }
}
```

## 🔄 Service Dependencies

### 1. **Implicit Dependencies**
```hcl
# Module B uses output from Module A
module "service_b" {
  source = "./modules/service-b"
  
  # This creates an implicit dependency
  service_account_email = module.service_a.service_account_email
}
```

### 2. **Explicit Dependencies**
```hcl
module "service_b" {
  source = "./modules/service-b"
  
  depends_on = [module.service_a]
}
```

### 3. **Conditional Dependencies**
```hcl
module "ml_training" {
  source = "./modules/compute"
  
  # Only create if training is enabled
  count = var.enable_ml_training ? 1 : 0
  
  service_account_email = module.dvc_gcs.service_account_email
}
```

## 🎛️ Configuration Management

### 1. **Environment Variables**
```bash
# Set environment-specific variables
export TF_VAR_environment="dev"
export TF_VAR_bucket_name="my-dev-datasets"
```

### 2. **Multiple tfvars Files**
```bash
# Use different var files for different environments
terraform plan -var-file="dev.tfvars"
terraform plan -var-file="prod.tfvars"
```

### 3. **Workspace Management**
```bash
# Use Terraform workspaces for environment separation
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
terraform workspace select dev
```

## 🔐 Security Best Practices

### 1. **Service Account Management**
```hcl
# Create service accounts in a shared module
module "shared" {
  source = "./modules/shared"
  
  project_id = var.project_id
  environment = var.environment
}

# Use service accounts in other modules
module "gcs" {
  source = "./modules/gcs"
  
  service_account_email = module.shared.dvc_service_account_email
}
```

### 2. **IAM Permissions**
- Use least privilege principle
- Create custom roles when needed
- Use service accounts instead of user accounts

### 3. **State Management**
```hcl
# Use remote state for team collaboration
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "ml-ops-project"
  }
}
```

## 📊 Monitoring and Cost Management

### 1. **Resource Tagging**
```hcl
# Consistent labeling across modules
locals {
  common_labels = {
    environment = var.environment
    project     = "ml-ops"
    managed_by  = "terraform"
    cost_center = "ai-research"
  }
}

# Use in modules
resource "google_storage_bucket" "example" {
  labels = merge(local.common_labels, {
    purpose = "dvc-datasets"
  })
}
```

### 2. **Cost Optimization**
- Use lifecycle rules for storage
- Implement auto-scaling for compute
- Monitor resource usage

## 🚀 Next Steps

1. **Start Simple**: Use your current modular GCS setup
2. **Add Services Gradually**: Add new modules as you need them
3. **Environment Separation**: When you need multiple environments, create the environment structure
4. **CI/CD Integration**: Set up automated deployments
5. **Monitoring**: Add monitoring and alerting modules

## 📚 Examples

See `main-with-multiple-services.tf` for a complete example of how to organize multiple services in a single configuration.

## 🤝 Team Collaboration

- Use consistent naming conventions
- Document all modules thoroughly
- Use remote state for team collaboration
- Implement code review for Terraform changes
- Use Terraform Cloud or similar for enterprise features 