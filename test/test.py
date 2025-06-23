import cv2
import numpy as np
import requests
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get server URL and API key from environment variables
server_url = os.getenv("DETECT_API_URL")
api_key = os.getenv("DETECT_API_KEY")

# Check if environment variables are set
if not server_url:
    raise ValueError("DETECT_API_URL environment variable is not set. Please create a .env file with DETECT_API_URL=your_server_url")
if not api_key:
    raise ValueError("DETECT_API_KEY environment variable is not set. Please create a .env file with DETECT_API_KEY=your_api_key")

# Test image URL (receipt image for testing)
image_url = "https://pandapaperroll.com/wp-content/uploads/2020/05/Receipt-paper-types-1.jpg"

# Download and decode the image
resp = requests.get(image_url)
image_nparray = np.asarray(bytearray(resp.content), dtype=np.uint8)
image = cv2.imdecode(image_nparray, cv2.IMREAD_COLOR)

# Send request to the object detection server
resp = requests.get(f"{server_url}detect?image_url={image_url}", headers={"Authorization": api_key})

detections = resp.json()["objects"]

# Draw bounding boxes and labels for each detected object
for item in detections:
    class_name = item["class"]
    coords = item["coordinates"]

    # Draw rectangle around detected object
    cv2.rectangle(image, (int(coords[0]), int(coords[1])), (int(coords[2]), int(coords[3])), (0, 0, 0), 2)

    # Add class label above the bounding box
    cv2.putText(image, class_name, (int(coords[0]), int(coords[1] - 5)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 2)

# Save the annotated image
cv2.imwrite("output.jpeg", image)