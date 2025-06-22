import argparse
import os
import time
import json
import shutil
import logging

from dotenv import load_dotenv
from tqdm import tqdm
from label_studio_sdk import Client
from label_studio_sdk.converter import Converter
from label_studio_sdk._extensions.label_studio_tools.core.utils.io import get_local_path

# Load environment variables from .env file
load_dotenv()

LABEL_STUDIO_URL = ''  # Change to your Label Studio URL
LABEL_STUDIO_API_KEY = ''  # Replace with your API Key
LABEL_STUDIO_PROJECT_ID = 1  # Replace with your Project ID

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] [%(module)s] - %(message)s')


def prepare_export(project):
    logger.info("Creating export snapshot for project.")
    export_result = project.export_snapshot_create(title='YOLO Export Snapshot')
    export_id = export_result['id']
    logger.info(f"Export snapshot created with ID: {export_id}")

    logger.info("Waiting for export snapshot to be ready.")
    while project.export_snapshot_status(export_id).is_in_progress():
        time.sleep(1.0)

    logger.info("Downloading export snapshot in JSON format.")
    status, snapshot_path = project.export_snapshot_download(export_id, export_type='JSON')
    if status != 200:
        logger.error(f"Failed to download export snapshot: {status}")
        raise Exception(f"Failed to download export snapshot: {status}")

    logger.info(f"Export snapshot downloaded successfully to {snapshot_path}.")
    with open(snapshot_path, 'r') as f:
        exported_tasks = json.load(f)

    return snapshot_path, exported_tasks


def run(url: str, api_key: str, project_id: int):
    logger.info("Connecting to Label Studio.")
    ls = Client(url=url, api_key=api_key)
    ls.check_connection()
    logger.info("Connected to Label Studio successfully.")

    logger.info(f"Retrieving project with ID: {project_id}.")
    project = ls.get_project(project_id)

    logger.info("Downloading export snapshot and loading exported tasks.")
    snapshot_path, exported_tasks = prepare_export(project)

    logger.info("Initializing Converter with labeling config.")
    label_config = project.params['label_config']
    converter = Converter(config=label_config, project_dir=os.path.dirname(snapshot_path), download_resources=False)

    logger.info("Converting to YOLO format.")
    output_dir = 'data/yolo'
    converter.convert_to_yolo(input_data=snapshot_path, output_dir=output_dir, is_dir=False)

    logger.info("Creating directory for YOLO images.")
    yolo_images_dir = os.path.join(output_dir, 'images')
    os.makedirs(yolo_images_dir, exist_ok=True)

    logger.info("Downloading images for exported tasks.")
    for task in tqdm(exported_tasks):
        image_url = next(iter(task['data'].values()))
        if image_url:
            max_retries = 100
            retry_delay = 1  # initial delay in seconds
            for attempt in range(1, max_retries + 1):
                try:
                    local_image_path = get_local_path(
                        url=image_url,
                        hostname=url,
                        access_token=api_key,
                        task_id=task['id'],
                        download_resources=True
                    )
                    name = os.path.basename(local_image_path).split('__', 1)[-1]
                    destination_path = os.path.join(yolo_images_dir, name)
                    shutil.copy2(local_image_path, destination_path)
                    logger.info(f"Copied image {local_image_path} to {destination_path}")
                    break  # Break the retry loop if download is successful
                except Exception as e:
                    logger.error(f"Error downloading image for task {task['id']}: {e}")
                    if attempt < max_retries:
                        sleep_time = retry_delay * (2 ** (attempt - 1))  # Exponential backoff
                        logger.info(f"Retrying in {sleep_time} seconds... (Attempt {attempt}/{max_retries})")
                        time.sleep(sleep_time)
                    else:
                        logger.error(f"Failed to download image for task {task['id']} after {max_retries} attempts.")
        else:
            logger.warning(f"No image URL found for task {task['id']}")
    logger.info("YOLO export with images completed successfully.")

    return True

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='YOLO Export Script for Label Studio'
    )
    parser.add_argument(
        '--url',
        type=str,
        default=os.getenv('LABEL_STUDIO_URL', LABEL_STUDIO_URL),
        help='Label Studio URL',
    )
    parser.add_argument(
        '--api-key',
        type=str,
        default=os.getenv('LABEL_STUDIO_API_KEY', LABEL_STUDIO_API_KEY),
        help='Label Studio API Key',
    )
    parser.add_argument(
        '--project-id',
        type=int,
        default=int(os.getenv('PROJECT_ID', LABEL_STUDIO_PROJECT_ID)),
        help='Label Studio Project ID',
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()
    run(args.url, args.api_key, args.project_id)