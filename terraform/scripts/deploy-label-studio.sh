#!/bin/bash

# Label Studio Deployment Script
# This script automates the deployment of Label Studio on Google Cloud Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    error "This script must be run from the terraform directory"
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    error "terraform.tfvars file not found. Please create it first."
fi

# Check if Label Studio is enabled
if ! grep -q "enable_label_studio = true" terraform.tfvars; then
    error "Label Studio is not enabled in terraform.tfvars. Set enable_label_studio = true"
fi

# Check if admin password is set
if ! grep -q "label_studio_admin_password" terraform.tfvars; then
    error "label_studio_admin_password is not set in terraform.tfvars"
fi

log "Starting Label Studio deployment..."

# Check prerequisites
log "Checking prerequisites..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    error "Google Cloud CLI (gcloud) is not installed. Please install it first."
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    error "Terraform is not installed. Please install it first."
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    error "You are not authenticated with Google Cloud. Run 'gcloud auth login' first."
fi

success "Prerequisites check passed"

# Get project ID from terraform.tfvars
PROJECT_ID=$(grep "project_id" terraform.tfvars | cut -d'"' -f2)
if [ -z "$PROJECT_ID" ]; then
    error "Could not extract project_id from terraform.tfvars"
fi

log "Using project: $PROJECT_ID"

# Check if project exists and user has access
if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    error "Project $PROJECT_ID does not exist or you don't have access to it"
fi

# Check if billing is enabled
if ! gcloud billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" | grep -q "True"; then
    error "Billing is not enabled for project $PROJECT_ID. Please enable billing first."
fi

success "Project validation passed"

# Initialize Terraform
log "Initializing Terraform..."
terraform init
success "Terraform initialized"

# Plan the deployment
log "Planning deployment..."
if ! terraform plan -out=tfplan; then
    error "Terraform plan failed"
fi

# Show what will be created
log "Resources that will be created:"
terraform show tfplan | grep -E "(Plan:|#|resource|module)" | head -20

# Ask for confirmation
echo
warning "This will create the following resources:"
echo "  - Compute Engine instance for Label Studio"
echo "  - VPC and subnet"
echo "  - Firewall rules"
echo "  - GCS bucket for data storage"
echo "  - Service account with necessary permissions"
echo
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Deployment cancelled by user"
    rm -f tfplan
    exit 0
fi

# Apply the configuration
log "Applying Terraform configuration..."
if ! terraform apply tfplan; then
    error "Terraform apply failed"
fi

# Clean up plan file
rm -f tfplan

# Get deployment outputs
log "Deployment completed successfully!"
echo
success "Label Studio has been deployed!"

# Show important information
echo
echo "=== Deployment Information ==="
echo "Label Studio URL: $(terraform output -raw label_studio_url)"
echo "Instance Name: $(terraform output -raw label_studio_instance_name)"
echo "External IP: $(terraform output -raw label_studio_external_ip)"
echo "Data Bucket: $(terraform output -raw label_studio_data_bucket)"
echo "SSH Command: $(terraform output -raw label_studio_ssh_command)"
echo

# Show admin credentials (masked)
ADMIN_CREDS=$(terraform output -json label_studio_admin_credentials)
USERNAME=$(echo "$ADMIN_CREDS" | jq -r '.username')
PASSWORD=$(echo "$ADMIN_CREDS" | jq -r '.password')

echo "=== Access Credentials ==="
echo "Username: $USERNAME"
echo "Password: ${PASSWORD:0:3}***${PASSWORD: -3}"
echo

# Show next steps
echo "=== Next Steps ==="
echo "1. Open the Label Studio URL in your browser"
echo "2. Log in with the admin credentials"
echo "3. Create your first labeling project"
echo "4. Upload your datasets"
echo

# Show monitoring commands
echo "=== Monitoring Commands ==="
echo "Check instance status:"
echo "  gcloud compute instances describe $(terraform output -raw label_studio_instance_name) --zone=$(grep zone terraform.tfvars | cut -d'"' -f2)"
echo
echo "SSH into instance:"
echo "  $(terraform output -raw label_studio_ssh_command)"
echo
echo "Check Label Studio logs:"
echo "  gcloud compute ssh label-studio@$(terraform output -raw label_studio_instance_name) --zone=$(grep zone terraform.tfvars | cut -d'"' -f2) --command='sudo journalctl -u label-studio -f'"
echo

success "Label Studio deployment completed successfully!" 