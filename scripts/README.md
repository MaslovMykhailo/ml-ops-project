# Scripts Documentation

## export_yolo.py

A Python script to download annotations in YOLO format from Label Studio using the official SDK.

### Features

- Uses the official `label-studio-sdk` for reliable API communication
- Downloads annotations in YOLO format
- Automatically extracts and organizes files in the `data/annotations` directory
- Supports versioning with subdirectories
- Configurable project ID, output directory, and version
- Proper error handling and validation
- **Environment variable support** via `.env` files

### Configuration

#### Environment Variables

The script supports loading configuration from environment variables. You can set them in several ways:

1. **Using a `.env` file** (recommended):
   ```bash
   # Copy the example file
   cp .env.example .env
   
   # Edit .env with your actual values
   LABEL_STUDIO_URL=https://your-label-studio-instance.com
   LABEL_STUDIO_API_KEY=your-api-key-here
   PROJECT_ID=1
   ```

2. **Directly in your shell**:
   ```bash
   export LABEL_STUDIO_URL="https://your-label-studio-instance.com"
   export LABEL_STUDIO_API_KEY="your-api-key-here"
   export PROJECT_ID=1
   ```

3. **Command line arguments** (highest priority):
   ```bash
   python scripts/export_yolo.py --url "https://..." --api-key "..." --project-id 1
   ```

#### Priority Order

The script uses the following priority order for configuration:
1. Command line arguments (highest priority)
2. Environment variables
3. Default values (lowest priority)

### Usage

#### Basic usage (uses defaults or .env file):
```bash
python scripts/export_yolo.py
```

#### With custom parameters:
```bash
python scripts/export_yolo.py \
  --url "https://your-label-studio-instance.com" \
  --api-key "your-api-key" \
  --project-id 2
```

#### Command line arguments:

- `--url`: Label Studio server URL (default: from environment or empty)
- `--api-key`: Label Studio API key (default: from environment or empty)
- `--project-id`: Project ID to export (default: from environment or 1)

### Output Structure

The script creates the following directory structure:
```
data/
└── yolo/
    ├── classes.txt
    ├── images/
    │   ├── image1.jpg
    │   ├── image2.jpg
    │   └── ...
    ├── labels/
    │   ├── image1.txt
    │   ├── image2.txt
    │   └── ...
    ├── dataset.yaml
    └── ...
```

### Dependencies

Make sure you have the required dependencies installed:
```bash
pip install label-studio-sdk
```

Or install all project dependencies:
```bash
pip install -r requirements.txt
```

### Comparison with export-yolo.sh

The Python script (`export_yolo.py`) offers several advantages over the bash script (`export-yolo.sh`):

1. **Official SDK**: Uses the official Label Studio SDK instead of raw HTTP requests
2. **Better Error Handling**: More robust error handling and validation
3. **Flexibility**: More configurable with command-line arguments
4. **Cross-platform**: Works on Windows, macOS, and Linux
5. **Type Safety**: Better code structure with type hints
6. **Maintainability**: Easier to maintain and extend

### Example Output

```
Connecting to Label Studio at https://label-studio-dev-x6qz26evla-lm.a.run.app...
Found project: My Object Detection Project
Exporting annotations from project #1 in YOLO format...
Export successful! Extracting files...
Annotations saved to: data/annotations/v1
Done. You can now use the exported data for your YOLO model training.
``` 