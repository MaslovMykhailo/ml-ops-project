#!/bin/bash

# Fix Label Studio Installation Script
# This script manually installs Label Studio on the instance

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

# Get instance details from terraform output
INSTANCE_NAME=$(terraform output -raw label_studio_instance_name)
ZONE=$(grep zone terraform.tfvars | cut -d'"' -f2)
PROJECT_ID=$(grep project_id terraform.tfvars | cut -d'"' -f2)
ADMIN_PASSWORD=$(grep label_studio_admin_password terraform.tfvars | cut -d'"' -f2)

log "Fixing Label Studio installation on instance: $INSTANCE_NAME"

# Create the installation script
cat > /tmp/install_label_studio.sh << 'INSTALL_SCRIPT'
#!/bin/bash

set -e

# Variables
LABEL_STUDIO_VERSION="1.9.2"
ADMIN_USER="admin"
ADMIN_PASSWORD="label-studio-test"
PROJECT_ID="annular-hexagon-463620-h2"
GCS_BUCKET_NAME="annular-hexagon-463620-h2-label-studio-data-dev"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting manual Label Studio installation..."

# Install required packages
log "Installing required packages..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl wget unzip

# Switch to label-studio user
log "Switching to label-studio user..."
su - label-studio << EOF

# Create application directory
mkdir -p ~/label-studio
cd ~/label-studio

# Create Python virtual environment
log "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install Label Studio
log "Installing Label Studio version $LABEL_STUDIO_VERSION..."
pip install label-studio==$LABEL_STUDIO_VERSION

# Create Label Studio configuration directory
mkdir -p ~/.local/share/label-studio

# Create systemd service file
sudo tee /etc/systemd/system/label-studio.service > /dev/null << 'SERVICE'
[Unit]
Description=Label Studio
After=network.target

[Service]
Type=simple
User=label-studio
Group=label-studio
WorkingDirectory=/home/label-studio/label-studio
Environment=PATH=/home/label-studio/label-studio/venv/bin
ExecStart=/home/label-studio/label-studio/venv/bin/label-studio start --host 0.0.0.0 --port 8080 --username admin --password label-studio-test
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

EOF

# Set up Google Cloud authentication
log "Setting up Google Cloud authentication..."
gcloud auth activate-service-account --key-file=/etc/google/auth/service-account-key.json || true
gcloud config set project $PROJECT_ID

# Start Label Studio service
log "Starting Label Studio service..."
systemctl daemon-reload
systemctl enable label-studio
systemctl start label-studio

# Wait for service to start
log "Waiting for Label Studio to start..."
sleep 30

# Check if service is running
if systemctl is-active --quiet label-studio; then
    log "Label Studio service is running successfully!"
    
    # Get the external IP
    EXTERNAL_IP=\$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    
    log "Label Studio is available at: http://\${EXTERNAL_IP}:8080"
    log "Admin username: $ADMIN_USER"
    log "Admin password: $ADMIN_PASSWORD"
    
else
    log "ERROR: Label Studio service failed to start!"
    systemctl status label-studio
    exit 1
fi

log "Label Studio installation completed successfully!"
INSTALL_SCRIPT

# Copy the script to the instance
log "Copying installation script to instance..."
gcloud compute scp /tmp/install_label_studio.sh label-studio@$INSTANCE_NAME:/tmp/ --zone=$ZONE

# Run the installation script
log "Running installation script on instance..."
gcloud compute ssh label-studio@$INSTANCE_NAME --zone=$ZONE --command="sudo bash /tmp/install_label_studio.sh"

# Clean up
rm -f /tmp/install_label_studio.sh

success "Label Studio installation completed!"

# Show the access information
echo
echo "=== Label Studio Access Information ==="
echo "URL: http://$(terraform output -raw label_studio_external_ip):8080"
echo "Username: admin"
echo "Password: $ADMIN_PASSWORD"
echo

success "Label Studio should now be accessible!" 