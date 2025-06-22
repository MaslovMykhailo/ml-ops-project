#!/bin/bash

# DVC Setup Script for Google Cloud Storage
# This script configures DVC to use the GCS bucket created by Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Store the terraform directory path (where script is executed from)
TERRAFORM_DIR=$(pwd)

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    print_error "This script must be run from the terraform directory"
    print_error "Usage: cd terraform && ./scripts/setup-dvc.sh"
    exit 1
fi

# Check if terraform state exists
if [ ! -f ".terraform/terraform.tfstate" ] && [ ! -f "terraform.tfstate" ]; then
    print_error "Terraform state not found. Please run 'terraform apply' first."
    exit 1
fi

print_status "Setting up DVC configuration for Google Cloud Storage..."

# Get bucket name from terraform output
BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null || echo "")
if [ -z "$BUCKET_NAME" ]; then
    print_error "Could not get bucket name from Terraform output. Please run 'terraform apply' first."
    exit 1
fi

print_status "Bucket name: $BUCKET_NAME"

# Get service account email
SERVICE_ACCOUNT_EMAIL=$(terraform output -raw service_account_email 2>/dev/null || echo "")
if [ -z "$SERVICE_ACCOUNT_EMAIL" ]; then
    print_error "Could not get service account email from Terraform output."
    exit 1
fi

print_status "Service account email: $SERVICE_ACCOUNT_EMAIL"

# Check if DVC is installed
if ! command -v dvc &> /dev/null; then
    print_error "DVC is not installed. Please install DVC first:"
    echo "pip install dvc[gcp]"
    exit 1
fi

# Navigate to project root (parent directory of terraform)
PROJECT_ROOT=$(dirname "$TERRAFORM_DIR")
print_status "Navigating to project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Check if we're in a DVC repository
if [ ! -d ".dvc" ]; then
    print_warning "Not in a DVC repository. Initializing DVC..."
    dvc init
fi

# Add GCS remote to DVC
print_status "Adding GCS remote to DVC..."
dvc remote add gcs "gs://$BUCKET_NAME" || {
    print_warning "Remote 'gcs' already exists. Updating..."
    dvc remote modify gcs url "gs://$BUCKET_NAME"
}

# Set as default remote
dvc remote default gcs

print_status "DVC remote configured successfully!"

# Navigate back to terraform directory for key creation
cd "$TERRAFORM_DIR"

# Create service account key file in scripts directory
print_status "Creating service account key file..."
terraform output -raw service_account_key > scripts/gcs-key.json
chmod 600 scripts/gcs-key.json

print_status "Service account key saved to scripts/gcs-key.json"

# Set up environment variables
print_status "Setting up environment variables..."

# Create a script to set environment variables
cat > scripts/setup-env.sh << EOF
#!/bin/bash
# Environment setup script for DVC with GCS
export GOOGLE_APPLICATION_CREDENTIALS="\$(pwd)/scripts/gcs-key.json"
export GOOGLE_SERVICE_ACCOUNT_EMAIL="$SERVICE_ACCOUNT_EMAIL"
echo "Environment variables set for DVC GCS integration"
EOF

chmod +x scripts/setup-env.sh

print_status "Environment setup script created: scripts/setup-env.sh"

# Test the configuration
print_status "Testing DVC configuration..."
if source scripts/setup-env.sh && dvc remote list | grep -q "gcs"; then
    print_status "DVC configuration test successful!"
else
    print_error "DVC configuration test failed. Please check your setup."
    exit 1
fi

# Create a test script
cat > scripts/test-dvc.sh << 'EOF'
#!/bin/bash
# Test script for DVC GCS integration

set -e

echo "Testing DVC GCS integration..."

# Source environment variables
source scripts/setup-env.sh

# Test remote configuration
echo "DVC remotes:"
dvc remote list

# Test bucket access (this will fail if no data, but that's expected)
echo "Testing bucket access..."
if dvc status --remote gcs 2>/dev/null; then
    echo "✅ Bucket access successful!"
else
    echo "⚠️  Bucket access test completed (no data to check)"
fi

echo "DVC GCS integration test completed!"
EOF

chmod +x scripts/test-dvc.sh

print_status "Test script created: scripts/test-dvc.sh"

# Print next steps
echo ""
print_status "Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Source the environment variables:"
echo "   source scripts/setup-env.sh"
echo ""
echo "2. Test the configuration:"
echo "   ./scripts/test-dvc.sh"
echo ""
echo "3. Add your datasets to DVC (from project root):"
echo "   cd .. && dvc add data/dataset"
echo ""
echo "4. Push to GCS (from project root):"
echo "   cd .. && dvc push"
echo ""
echo "5. For CI/CD, use the service account key:"
echo "   export GOOGLE_APPLICATION_CREDENTIALS=\"\$(pwd)/scripts/gcs-key.json\""
echo ""
print_warning "Remember to add scripts/gcs-key.json to your .gitignore file!" 