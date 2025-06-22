# Terraform Setup Scripts

This directory contains scripts for setting up and managing the ML Ops infrastructure.

## Scripts

### `setup-dvc.sh`
Main script for configuring DVC to work with Google Cloud Storage.

**Usage:**
```bash
cd terraform
./scripts/setup-dvc.sh
```

**What it does:**
1. Reads Terraform outputs to get GCS bucket name and service account details
2. Initializes DVC in the project root (if not already initialized)
3. Configures DVC remote to use the GCS bucket
4. Creates service account key file (`scripts/gcs-key.json`)
5. Creates environment setup script (`scripts/setup-env.sh`)
6. Creates test script (`scripts/test-dvc.sh`)

**Prerequisites:**
- Must be run from `terraform/` directory
- Terraform must be applied first (`terraform apply`)
- DVC must be installed (`pip install dvc[gcp]`)

### `setup-env.sh` (generated)
Script to set up environment variables for DVC GCS integration.

**Usage:**
```bash
cd terraform
source scripts/setup-env.sh
```

### `test-dvc.sh` (generated)
Test script to verify DVC GCS integration.

**Usage:**
```bash
cd terraform
./scripts/test-dvc.sh
```

## Generated Files

After running `setup-dvc.sh`, the following files will be created in the `scripts/` directory:

- `gcs-key.json` - Service account key for GCS access
- `setup-env.sh` - Environment variables setup script
- `test-dvc.sh` - DVC integration test script

## Security Notes

- The `gcs-key.json` file contains sensitive credentials
- Add `scripts/gcs-key.json` to your `.gitignore` file
- Never commit the service account key to version control

## Directory Structure

```
ml-ops-project/
├── terraform/
│   ├── scripts/
│   │   ├── setup-dvc.sh          # Main setup script
│   │   ├── README.md             # Documentation
│   │   ├── gcs-key.json          # Generated (ignored)
│   │   ├── setup-env.sh          # Generated (ignored)
│   │   └── test-dvc.sh           # Generated (ignored)
│   ├── main.tf
│   └── ...
├── .dvc/
├── data/
└── ...
```

## Execution Pattern

All scripts are designed to be executed from the `terraform/` directory:

```bash
# Navigate to terraform directory
cd terraform

# Run setup script
./scripts/setup-dvc.sh

# Use generated scripts
source scripts/setup-env.sh
./scripts/test-dvc.sh
``` 