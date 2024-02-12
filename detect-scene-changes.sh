#!/bin/bash

# Process input flags including input video as first argument
# then --nocut to skip the cut step

# Usage check
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <input video> [--nocut]"
    exit 1
fi

# Check if input video exists
if [[ ! -f "$1" ]]; then
    echo "Input video $1 not found."
    exit 1
fi

# Initialize variables
INPUT_VIDEO="$1"
NOCUT=false
SCRIPT_DIR=$(dirname "$0")
INPUT_EXT="${INPUT_VIDEO##*.}"
CROPPED_VIDEO="temp_cropped_$(date +%s)_$(basename "$INPUT_VIDEO" ".$INPUT_EXT").mp4"
DETECT_SCENE_SCRIPT="${SCRIPT_DIR}/detect-scene-changes.py"
SCENE_CHANGE_TIMESTAMPS_FILE=$(mktemp "/tmp/scene_changes_$(date +%s)_$(basename "$INPUT_VIDEO" ".$INPUT_EXT").txt")

# Process additional flags
shift # move past first argument
while (( "$#" )); do
    case "$1" in
        --nocut)
            NOCUT=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if the temporary file already exists
if [[ -f "$CROPPED_VIDEO" ]]; then
    echo "Temporary file $CROPPED_VIDEO already exists. Please remove it before running this script."
    exit 1
fi

# Crop the video by 10% from each edge (20% total reduction in size), preserving the center
ffmpeg -i "$INPUT_VIDEO" -vf "crop=in_w*0.8:in_h*0.8" -c:a copy "$CROPPED_VIDEO"
if [[ $? -ne 0 ]]; then
    echo "Error cropping video."
    exit 1
fi

# Check if the Python scene detection script exists and is executable
if [[ ! -f "$DETECT_SCENE_SCRIPT" ]]; then
    echo "Scene detection script not found in $SCRIPT_DIR"
    exit 1
fi

python3 "$DETECT_SCENE_SCRIPT" "$CROPPED_VIDEO" "$SCENE_CHANGE_TIMESTAMPS_FILE"
if [[ $? -ne 0 ]]; then
    echo "Error detecting scene changes."
    rm "$CROPPED_VIDEO"
    exit 1
fi

# Cleanup cropped video immediately if --nocut is specified or on script exit
cleanup() {
    rm -f "$CROPPED_VIDEO"
    if [[ "$INPUT_VIDEO" != "$INPUT_VIDEO_MKV_COPY" ]]; then
        rm -f "$INPUT_VIDEO_MKV_COPY"
    fi
}
trap cleanup EXIT

if [[ "$NOCUT" == true ]]; then
    echo "Skipping the cut step."
    exit 0
fi

# Convert input video to mkv format if it's a DV file, to avoid issues during the cut step
if [[ "$INPUT_EXT" == "dv" ]]; then
    INPUT_VIDEO_MKV_COPY="/tmp/$(basename "$INPUT_VIDEO" ".$INPUT_EXT").mkv"
    ffmpeg -i "$INPUT_VIDEO" -c copy "$INPUT_VIDEO_MKV_COPY"
else
    INPUT_VIDEO_MKV_COPY="$INPUT_VIDEO"
fi

OUTPUT_PATH=$(dirname "$INPUT_VIDEO")

# Call the external script to split the video at the detected timestamps
"${SCRIPT_DIR}/cut-at-timestamps.sh" "$INPUT_VIDEO_MKV_COPY" "$SCENE_CHANGE_TIMESTAMPS_FILE" "$OUTPUT_PATH"
