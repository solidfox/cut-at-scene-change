#!/bin/bash

INPUT_VIDEO="$1"  # Use the first command line argument as the input video
TIMESTAMPS_FILE="$2"  # Assuming the timestamps file is in /tmp
OUTPUT_PATH="$3"  # Use the third command line argument as the output path
COUNTER=1

# Check if input video is provided
if [ -z "$INPUT_VIDEO" ]; then
    echo "No input video provided."
    exit 1
fi

# Check if timestamps file is provided
if [ -z "$TIMESTAMPS_FILE" ]; then
    echo "No timestamps file provided."
    exit 1
fi

# Extract filename without extension
BASENAME=$(basename -- "$INPUT_VIDEO")
FILENAME="${BASENAME%.*}"
EXTENSION="${BASENAME##*.}"

# Set the output path to the input video directory if not provided
if [ -z "$OUTPUT_PATH" ]; then
    OUTPUT_PATH=$(dirname "$INPUT_VIDEO")
fi

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
    CAPTION=$(echo "$line" | cut -d' ' -f3-)
    OUTPUT_VIDEO="${OUTPUT_PATH}/${FILENAME}_scene_${COUNTER}.${EXTENSION}"

    echo
    echo "----------------------------------------"
    echo "$line"
    echo "Cutting scene $COUNTER from $START_TIME to $END_TIME"
    echo

    # Losslessly cut the video and add caption as metadata caption
    # Apple compatible metadata
    # com.apple.quicktime.keywords: 
    # com.apple.quicktime.description: test
    # com.apple.quicktime.location.ISO6709: +59.2731+017.8017+000.000/
    # com.apple.quicktime.creationdate: 2022-02-09T22:11:04+01:00
    # https://developer.apple.com/documentation/quicktime-file-format/quicktime_metadata_keys
    ffmpeg -i "$INPUT_VIDEO" \
           -ss "$START_TIME" \
           -to "$END_TIME" \
           -c copy \
           -metadata com.apple.quicktime.title="$FILENAME" \
           -metadata com.apple.quicktime.keywords="camcorder, DV8" \
           -metadata com.apple.quicktime.description="$CAPTION" \
           -metadata com.apple.quicktime.information="Original Tape Name $FILENAME cut $COUNTER @ $START_TIME - $END_TIME"  \
           "$OUTPUT_VIDEO"
    # Error out of for look if ffmpeg fails
    if [ $? -ne 0 ]; then
        echo "Error cutting video at timestamp $line"
        exit 1
    fi
    ((COUNTER++))
done