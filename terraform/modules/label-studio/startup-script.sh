#!/bin/bash

# Label Studio Startup Script
# This script installs and configures Label Studio on a Google Cloud Compute Engine instance

set -e

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Label Studio installation..."

# Update system packages
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
log "Installing required packages..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Google Cloud SDK
log "Installing Google Cloud SDK..."
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
apt-get install -y google-cloud-sdk

# Create label-studio user
log "Creating label-studio user..."
useradd -m -s /bin/bash label-studio || true
usermod -aG sudo label-studio

# Switch to label-studio user for installation
log "Switching to label-studio user..."
su - label-studio << 'EOF'

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
log "Installing Label Studio version ${label_studio_version}..."
pip install label-studio==${label_studio_version}

# Create Label Studio configuration directory
mkdir -p ~/.local/share/label-studio

# Create Label Studio configuration file
cat > ~/.local/share/label-studio/label_studio_config.xml << 'CONFIG'
<?xml version="1.0" encoding="UTF-8"?>
<label-studio>
    <core>
        <debug>false</debug>
        <log_level>INFO</log_level>
        <internal_host>0.0.0.0</internal_host>
        <internal_port>8080</internal_port>
        <external_host>0.0.0.0</external_host>
        <external_port>8080</external_port>
    </core>
    <storage>
        <backend>gcs</backend>
        <gcs>
            <bucket>${gcs_bucket_name}</bucket>
            <project_id>${project_id}</project_id>
        </gcs>
    </storage>
    <database>
        <backend>sqlite</backend>
        <sqlite>
            <path>~/.local/share/label-studio/label_studio.db</path>
        </sqlite>
    </database>
    <redis>
        <host>localhost</host>
        <port>6379</port>
    </redis>
</label-studio>
CONFIG

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
ExecStart=/home/label-studio/label-studio/venv/bin/label-studio start --host 0.0.0.0 --port 8080 --username ${admin_user} --password ${admin_password}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

# Create startup script
cat > ~/start-label-studio.sh << 'STARTUP'
#!/bin/bash
cd ~/label-studio
source venv/bin/activate

# Initialize Label Studio with admin user
label-studio start \
    --host 0.0.0.0 \
    --port 8080 \
    --username ${admin_user} \
    --password ${admin_password} \
    --init \
    --no-browser
STARTUP

chmod +x ~/start-label-studio.sh

# Create a simple health check script
cat > ~/health-check.sh << 'HEALTH'
#!/bin/bash
curl -f http://localhost:8080/health/ || exit 1
HEALTH

chmod +x ~/health-check.sh

EOF

# Set up Google Cloud authentication for the service account
log "Setting up Google Cloud authentication..."
gcloud auth activate-service-account --key-file=/etc/google/auth/service-account-key.json || true

# Configure gcloud for the project
gcloud config set project ${project_id}

# Enable required APIs
log "Enabling required Google Cloud APIs..."
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com

# Set up firewall rules for Label Studio
log "Setting up firewall rules..."
gcloud compute firewall-rules create label-studio-web \
    --allow tcp:8080 \
    --source-ranges 0.0.0.0/0 \
    --target-tags label-studio \
    --description "Allow Label Studio web access" || true

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
    EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    
    log "Label Studio is available at: http://$${EXTERNAL_IP}:8080"
    log "Admin username: ${admin_user}"
    log "Admin password: ${admin_password}"
    
    # Create a simple status page
    cat > /var/www/html/status.html << STATUS
<!DOCTYPE html>
<html>
<head>
    <title>Label Studio Status</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 20px; border-radius: 5px; margin: 20px 0; }
        .success { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .info { background-color: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
    </style>
</head>
<body>
    <h1>Label Studio Deployment Status</h1>
    <div class="status success">
        <h2>✅ Label Studio is Running</h2>
        <p><strong>URL:</strong> <a href="http://$${EXTERNAL_IP}:8080">http://$${EXTERNAL_IP}:8080</a></p>
        <p><strong>Admin Username:</strong> ${admin_user}</p>
        <p><strong>Environment:</strong> ${environment}</p>
        <p><strong>Project ID:</strong> ${project_id}</p>
    </div>
    <div class="status info">
        <h3>📋 Next Steps:</h3>
        <ol>
            <li>Access Label Studio at the URL above</li>
            <li>Log in with the admin credentials</li>
            <li>Create your first project</li>
            <li>Upload your datasets</li>
        </ol>
    </div>
</body>
</html>
STATUS
    
else
    log "ERROR: Label Studio service failed to start!"
    systemctl status label-studio
    exit 1
fi

log "Label Studio installation completed successfully!" 