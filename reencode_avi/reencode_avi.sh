#!/bin/bash

# Directory containing the .avi files
DIRECTORY="~/Documents/NeuroRestore/Data/Natalya_20200723_ARM_SIMI"  # You can change this to your specific directory

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null
then
    echo "ffmpeg could not be found, please install it to continue"
    exit 1
fi

# Find all .avi files in the directory
shopt -s nullglob
avi_files=("$DIRECTORY"/*.avi)

# Check if there are any .avi files in the directory
if [ ${#avi_files[@]} -eq 0 ]; then
    echo "No .avi files found in the directory"
    exit 1
fi

# Iterate over all .avi files in the directory
for file in "${avi_files[@]}"; do
    if [[ -f "$file" ]]; then
        # Get the base filename without the extension
        base_filename=$(basename "$file" .avi)
        
        # Set the output filename
        output_file="${DIRECTORY}${base_filename}_reencoded.avi"
        
        # Re-encode the video
        ffmpeg -i "$file" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 192k "$output_file"
        
        # Check if re-encoding was successful
        if [[ $? -eq 0 ]]; then
            echo "Successfully re-encoded $file to $output_file"
        else
            echo "Failed to re-encode $file"
        fi
    else
        echo "$file is not a valid file"
    fi
done