# ML Ops Project

A comprehensive ML Ops infrastructure implementing end-to-end machine learning workflows from data management to production deployment.

## Architecture Overview

This project implements a **cloud-native ML Ops pipeline** with the following components:

1. **Data Management Layer**
   - **DVC (Data Version Control)** for dataset versioning and storage
   - **Google Cloud Storage (GCS)** as the remote storage backend
   - **Label Studio** for data annotation and labeling

2. **Model Training Layer**
   - **Ray Cluster** for distributed training
   - **YOLOv8** object detection model training
   - **Weights & Biases (W&B)** for experiment tracking and model registry

3. **Model Serving Layer**
   - **Ray Serve** for model deployment and inference
   - **FastAPI** for REST API endpoints
   - **Docker containerization**

4. **Infrastructure as Code**
   - **Terraform** for infrastructure provisioning
   - **Google Cloud Platform** services
   - **CI/CD pipelines** with GitHub Actions

## Services and Technologies Used

### **Cloud Infrastructure (Google Cloud Platform)**

- **Google Cloud Storage (GCS)**: Dataset storage and versioning
- **Cloud Run**: Label Studio deployment
- **Cloud SQL (PostgreSQL)**: Label Studio database
- **Memorystore (Redis)**: Label Studio caching
- **Compute Engine**: Training infrastructure (via Ray)
- **Service Accounts**: Secure authentication and authorization

### **ML/AI Tools**

- **DVC**: Data version control and pipeline management
- **Label Studio**: Data annotation and labeling platform
- **Ray**: Distributed computing framework for training and serving
- **YOLOv8 (Ultralytics)**: Object detection model
- **Weights & Biases**: Experiment tracking and model registry
- **FastAPI**: REST API framework for model serving

### **DevOps & CI/CD**

- **Terraform**: Infrastructure as Code
- **GitHub Actions**: CI/CD pipelines
- **Docker**: Containerization
- **Anyscale**: Ray cluster management

## Project Structure

```
ml-ops-project/
├── data/                    # DVC-managed datasets
│   ├── yolo.dvc            # YOLO dataset tracking
│   └── dataset.dvc         # General dataset tracking
├── ray-train/              # Model training components
│   ├── train_yolo.py       # YOLO training script
│   ├── config.yaml         # Training configuration
│   └── submit_job.py       # Ray job submission
├── ray-deploy/             # Model serving components
│   └── object_detection.py # FastAPI + Ray Serve deployment
├── terraform/              # Infrastructure as Code
│   ├── modules/
│   │   ├── gcs/           # GCS bucket and service accounts
│   │   └── label-studio/  # Label Studio deployment
│   └── main.tf            # Main infrastructure configuration
├── scripts/               # Utility scripts
│   └── export_yolo.py     # Label Studio to YOLO export
├── .github/workflows/     # CI/CD pipelines
│   ├── ray_train.yml      # Training pipeline
│   └── ray_deploy.yml     # Deployment pipeline
└── requirements.txt       # Python dependencies
```

## Workflow and Pipeline

### **1. Data Pipeline**

- **Data Collection**: Datasets stored in GCS via DVC
- **Data Labeling**: Label Studio deployed on Cloud Run for annotation
- **Data Export**: Scripts to export labeled data to YOLO format
- **Version Control**: DVC tracks dataset versions and changes

### **2. Training Pipeline**

- **Configuration**: YAML-based training configuration
- **Distributed Training**: Ray cluster for scalable training
- **Experiment Tracking**: W&B integration for metrics and artifacts
- **Model Registry**: Trained models stored in W&B model registry

### **3. Deployment Pipeline**

- **Model Serving**: Ray Serve with FastAPI for inference
- **Containerization**: Docker-based deployment
- **Auto-scaling**: Ray Serve handles traffic scaling
- **API Endpoints**: REST API for object detection

### **4. CI/CD Pipeline**

- **Automated Training**: GitHub Actions trigger training on code changes
- **Automated Deployment**: Manual deployment with model artifact selection
- **Environment Management**: Terraform manages infrastructure state

## Getting Started

### **Prerequisites**

```bash
# Install dependencies
pip install -r requirements.txt

# Set up environment variables
export WANDB_API_KEY="your_wandb_api_key"
export ANYSCALE_CLI_TOKEN="your_anyscale_token"
```

### **Infrastructure Setup**

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the infrastructure
terraform plan

# Apply the infrastructure
terraform apply
```

### **Data Management**

```bash
# Pull datasets from DVC
dvc pull

# Add new datasets
dvc add data/new_dataset
git add data/new_dataset.dvc
git commit -m "Add new dataset"
dvc push
```

### **Model Training**

```bash
# Local training
cd ray-train
python train_yolo.py

# Ray cluster training
anyscale job submit \
  --compute-config ray-train \
  --requirements requirements.txt \
  --working-dir . \
  --wait \
  -- python train_yolo.py
```

### **Model Deployment**

```bash
# Deploy via GitHub Actions (manual trigger)
# Or deploy locally
cd ray-deploy
anyscale service deploy object_detection:entrypoint \
  --name yolo-deployment \
  --env WANDB_MODEL_ARTIFACT="your_model_artifact" \
  --requirements requirements.txt \
  --working-dir .
```

## Configuration

### **Training Configuration** (`ray-train/config.yaml`)

```yaml
model: yolov8n.pt
data: coco8.yaml
epochs: 2
batch: 16
imgsz: 640
device: cpu
workers: 2
wandb_project: "ml-ops-project"
run_name: "yolo-cpu-ray-training"
```

### **Terraform Variables** (`terraform/terraform.tfvars`)

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"
bucket_name = "your-dvc-datasets-bucket"
environment = "dev"
```

## Key Features

1. **Data Versioning**: DVC tracks dataset changes and versions
2. **Distributed Training**: Ray enables scalable model training
3. **Experiment Tracking**: W&B provides comprehensive ML experiment management
4. **Model Registry**: Centralized model storage and versioning
5. **Automated Deployment**: CI/CD pipelines for training and deployment
6. **Infrastructure as Code**: Terraform manages all cloud resources
7. **Data Labeling**: Label Studio for annotation workflows
8. **API Serving**: REST API for model inference
9. **Auto-scaling**: Ray Serve handles traffic scaling automatically
10. **Monitoring**: W&B provides training and inference monitoring

## CI/CD Workflows

### **Training Pipeline** (`.github/workflows/ray_train.yml`)

- Triggered on pull requests to main branch
- Runs YOLO training on Ray cluster
- Integrates with W&B for experiment tracking

### **Deployment Pipeline** (`.github/workflows/ray_deploy.yml`)

- Manual trigger with model artifact selection
- Deploys model to Ray Serve
- Provides deployment URLs and testing commands

## Security

- **Service Accounts**: Secure authentication for cloud services
- **IAM Roles**: Least privilege access control
- **Private Networks**: Secure communication between services
- **Environment Variables**: Sensitive data managed via secrets

## Monitoring and Observability

- **W&B Dashboard**: Training metrics and model performance
- **Ray Dashboard**: Cluster monitoring and resource usage
- **Cloud Logging**: Centralized logging for all services
- **Metrics**: Performance monitoring and alerting
