#!/bin/bash

INPUT_VIDEO="$1"  # Use the first command line argument as the input video
TIMESTAMPS_FILE="/tmp/scene_timestamps.txt"  # Assuming the timestamps file is in /tmp
COUNTER=1

# Check if input video is provided
if [ -z "$INPUT_VIDEO" ]; then
    echo "No input video provided."
    exit 1
fi

# Extract filename without extension
BASENAME=$(basename -- "$INPUT_VIDEO")
FILENAME="${BASENAME%.*}"
EXTENSION="${BASENAME##*.}"

# Read timestamps into an array
TIMESTAMPS=()
while IFS= read -r line
do
    TIMESTAMPS+=("$line")
done < "$TIMESTAMPS_FILE"

# Process each timestamp
for line in "${TIMESTAMPS[@]}"
do
    START_TIME=$(echo "$line" | cut -d' ' -f1)
    END_TIME=$(echo "$line" | cut -d' ' -f2)
    OUTPUT_VIDEO="${FILENAME}_cut_${COUNTER}.${EXTENSION}"

    echo
    echo "----------------------------------------"
    echo "$line"
    echo "Cutting scene $COUNTER from $START_TIME to $END_TIME"
    echo

    ffmpeg -i "$INPUT_VIDEO" -ss "$START_TIME" -to "$END_TIME" -c copy "$OUTPUT_VIDEO"
    ((COUNTER++))
done