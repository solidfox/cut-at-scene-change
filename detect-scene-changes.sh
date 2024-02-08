#!/bin/bash

# Ensure a video file path is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <video_file>"
    exit 1
fi

# Define input video file
INPUT_VIDEO="$1"

# Generate a unique temporary filename for the cropped video with an MP4 extension
# Using a timestamp: CROPPED_VIDEO="temp_cropped_$(date +%s)_$(basename "$INPUT_VIDEO" .dv).mp4"
# Or using a UUID: CROPPED_VIDEO="temp_cropped_$(uuidgen)_$(basename "$INPUT_VIDEO" .dv).mp4"
CROPPED_VIDEO="temp_cropped_$(date +%s)_$(basename "$INPUT_VIDEO" .dv).mp4"

# Get the directory of the current script to locate the Python script
SCRIPT_DIR=$(dirname "$0")
DETECT_SCENE_SCRIPT="${SCRIPT_DIR}/detect-scene-changes.py"

# Check if the temporary file already exists
if [ -f "$CROPPED_VIDEO" ]; then
    echo "Temporary file $CROPPED_VIDEO already exists. Please remove it before running this script."
    exit 1
fi

# Crop the video by 10% from each edge (20% total reduction in size), preserving the center
ffmpeg -i "$INPUT_VIDEO" -vf "crop=in_w*0.8:in_h*0.8" -c:a copy "$CROPPED_VIDEO"

# Check if the Python scene detection script exists and is executable
if [ ! -f "$DETECT_SCENE_SCRIPT" ]; then
    echo "Scene detection script not found in $SCRIPT_DIR"
    exit 1
fi

# Run the scene detection script on the cropped video
python3 "$DETECT_SCENE_SCRIPT" "$CROPPED_VIDEO"

# Remove the temporary cropped video file
rm "$CROPPED_VIDEO"
