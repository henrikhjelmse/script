#!/bin/bash

# HOW TO USE THIS SCRIPT:
# This script scans a given directory and all its subdirectories for video files.
# It checks if each file is compatible with Chrome's video player (H.264 codec).
# If a file is not compatible, it will convert it using ffmpeg.
# If an NVIDIA GPU is available, the script will use NVENC for hardware acceleration.
#
# USAGE:
# ./script.sh <directory path> [DELETE_ORIGINAL]
#
# PARAMETERS:
# <directory path>      - The directory to scan for video files.
# [DELETE_ORIGINAL]     - Optional (default: 0). Set to 1 to delete the original files after conversion.
#
# EXAMPLE:
# ./script.sh /path/to/videos 1
# This will convert all non-Chrome-compatible videos in /path/to/videos and delete the originals.

# Check if a directory path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory path> [DELETE_ORIGINAL]"
    exit 1
fi

SEARCH_DIR="$1"
DELETE_ORIGINAL=${2:-0}  # Default value is 0 if not specified

# Function to check if a video is Chrome-compatible
is_chrome_compatible() {
    local file="$1"
    local codec_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 -- "$file")
    
    # Chrome primarily supports h264 for video
    if [[ "$codec_info" == "h264" ]]; then
        return 0 # File is compatible
    else
        return 1 # File is not compatible
    fi
}

# Check if NVIDIA GPU is available
has_nvidia_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        return 0 # NVIDIA GPU detected
    else
        return 1 # No NVIDIA GPU detected
    fi
}

USE_GPU=0
if has_nvidia_gpu; then
    USE_GPU=1
    echo "NVIDIA GPU detected. Enabling NVENC acceleration."
else
    echo "No NVIDIA GPU detected. Using CPU encoding."
fi

# Find all video files in the directory and its subdirectories
find "$SEARCH_DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \) -print0 | while IFS= read -r -d '' file; do
    output_file="${file%.*}_convert.mp4"
    
    # Check if the converted file already exists
    if [ -f "$output_file" ]; then
        echo "Converted file already exists: $output_file. Skipping conversion."
        continue
    fi
    
    if ! is_chrome_compatible "$file"; then
        echo "Converting: $file -> $output_file"
        
        if [[ "$USE_GPU" -eq 1 ]]; then
            ffmpeg -i "$file" -c:v h264_nvenc -preset slow -cq 23 -c:a aac -b:a 128k -- "$output_file"
        else
            ffmpeg -i "$file" -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 128k -- "$output_file"
        fi
        
        # Delete the original file if the variable is set to 1
        if [[ "$DELETE_ORIGINAL" -eq 1 ]]; then
            rm -- "$file"
            echo "Original file deleted: $file"
        fi
    else
        echo "Compatible: $file"
    fi
done
