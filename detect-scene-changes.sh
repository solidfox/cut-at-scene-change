#!/bin/bash

# Process input flags including input video as first argument
# then --nocut to skip the cut step

# Check if input video is provided
if [ -z "$1" ]; then
    echo "No input video provided."
    exit 1
fi

# Check if input video exists
if [ ! -f "$1" ]; then
    echo "Input video $1 not found."
    exit 1
fi

# Set the input video as the first argument
INPUT_VIDEO="$1"

NOCUT=false
# Check for further flags
if [ "$2" == "--nocut" ]; then
    NOCUT=true
fi

# Generate a unique temporary filename for the cropped video with an MP4 extension
CROPPED_VIDEO="temp_cropped_$(date +%s)_$(basename "$INPUT_VIDEO" .dv).mp4"

# Get the directory of the current script to locate necessary scripts
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

SCENE_CHANGE_TIMESTAMPS_FILE=$(mktemp "/tmp/scene_changes_$(date +%s)_$(basename "$INPUT_VIDEO" .dv).txt")

python3 "$DETECT_SCENE_SCRIPT" "$CROPPED_VIDEO" "$SCENE_CHANGE_TIMESTAMPS_FILE"

# Remove the temporary cropped video file
rm "$CROPPED_VIDEO"

if [ "$NOCUT" = true ]; then
    echo "Skipping the cut step."
    exit 0
fi

# If the input video is a DV file, create an mkv copy in /tmp to avoid issues with the cut step
if [ "${INPUT_VIDEO: -3}" == ".dv" ]; then
    INPUT_VIDEO_MKV_COPY="/tmp/$(basename "$INPUT_VIDEO" .dv).mkv"
    ffmpeg -i "$INPUT_VIDEO" -c copy "$INPUT_VIDEO_MKV_COPY"
else
    INPUT_VIDEO_MKV_COPY="$INPUT_VIDEO"
fi

OUTPUT_PATH=$(dirname "$INPUT_VIDEO")

# Call the external script to split the video at the detected timestamps
"${SCRIPT_DIR}/cut-at-timestamps.sh" "$INPUT_VIDEO_MKV_COPY" "$SCENE_CHANGE_TIMESTAMPS_FILE" "$OUTPUT_PATH"

# Remove the mkv copy if it is in /tmp and was created for a DV file
if [ "${INPUT_VIDEO: -3}" == ".dv" ] && [ "${INPUT_VIDEO_MKV_COPY:0:5}" == "/tmp/" ]; then
    rm "$INPUT_VIDEO_MKV_COPY"
fi