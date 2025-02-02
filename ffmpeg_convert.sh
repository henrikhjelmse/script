#!/bin/bash
# Video Conversion Script with improved path handling
# Requires: ffmpeg, ffprobe
#
# This script scans a given directory for video files and converts them to a Chrome-compatible H.264 format using ffmpeg.
# It supports both CPU and NVIDIA GPU-based encoding, automatically detecting if a GPU is available.
# The script also offers an option to delete the original files after conversion.

# Enable better error handling
set -euo pipefail
IFS=$'\n\t'

# Check for required dependencies
check_dependencies() {
    local missing_deps=()
    
    for dep in ffmpeg ffprobe; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them and try again."
        exit 1
    fi
}

# Function to check if a video is Chrome-compatible
is_chrome_compatible() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return 1
    fi
    local codec_info
    codec_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 -- "$file" 2>/dev/null)
    [[ "$codec_info" == "h264" ]]
}

# Check if NVIDIA GPU is available
has_nvidia_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi &> /dev/null
        return $?
    fi
    return 1
}

# Function to safely convert a file
convert_file() {
    local input_file="$1"
    local output_file="$2"
    local use_gpu="$3"
    local temp_output="${output_file}.mp4"  # Ensure correct format
    local log_file="conversion_log.txt"

    if [[ "$use_gpu" -eq 1 ]]; then
        echo "Attempting GPU conversion..." >> "$log_file"
        if ! ffmpeg -y -i "$input_file" -c:v h264_nvenc -preset slow -cq 23 -c:a aac -b:a 128k "$temp_output" 2>> "$log_file"; then
            echo "GPU conversion failed, falling back to CPU..." >> "$log_file"
            if ! ffmpeg -y -i "$input_file" -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 128k "$temp_output" 2>> "$log_file"; then
                echo "CPU conversion also failed" >> "$log_file"
                return 1
            fi
        fi
    else
        echo "Using CPU conversion..." >> "$log_file"
        if ! ffmpeg -y -i "$input_file" -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 128k "$temp_output" 2>> "$log_file"; then
            echo "CPU conversion failed" >> "$log_file"
            return 1
        fi
    fi

    mv "$temp_output" "$output_file"
    return 0
}

# Main conversion function
convert_videos() {
    local search_dir="$1"
    local delete_original="$2"
    local use_gpu="$3"
    local log_file="conversion_log.txt"
    
    search_dir=$(realpath -m "$search_dir")
    
    if [ ! -d "$search_dir" ]; then
        echo "Error: Directory not found - $search_dir"
        exit 1
    fi
    
    local files=()
    while IFS= read -r -d $'\0' file; do
        files+=("$file")
    done < <(find "$search_dir" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \) -print0)
    
    local total_files=${#files[@]}
    
    if [ "$total_files" -eq 0 ]; then
        echo "No video files found in the directory: $search_dir"
        return
    fi
    
    echo "Starting conversion of $total_files files..."
    echo "Directory: $search_dir"
    echo "GPU acceleration: $([ "$use_gpu" -eq 1 ] && echo "enabled" || echo "disabled")"
    echo "Delete originals: $([ "$delete_original" -eq 1 ] && echo "yes" || echo "no")"
    echo "-----------------------------------"
    
    for ((i = 0; i < total_files; i++)); do
        local file="${files[$i]}"
        local current_file=$((i + 1))
        
        local dir_path=$(dirname "$file")
        local base_name=$(basename "$file")
        local filename="${base_name%.*}"
        local output_file="${dir_path}/${filename}_convert.mp4"
        
        echo -ne "\rProcessing file $current_file/$total_files: $base_name"
        
        if [ -f "$output_file" ]; then
            echo -e "\nSkipping (already exists): $base_name"
            continue
        fi
        
        if [ ! -f "$file" ]; then
            echo -e "\nError: File not found - $base_name"
            continue
        fi
        
        if ! is_chrome_compatible "$file"; then
            echo -e "\nConverting: $base_name"
            
            if convert_file "$file" "$output_file" "$use_gpu"; then
                if [[ "$delete_original" -eq 1 ]]; then
                    rm -- "$file"
                    echo -e "Original file deleted: $base_name"
                fi
                echo -e "Successfully converted: $base_name"
            else
                echo -e "\nError: Conversion failed for: $base_name"
                echo "Check conversion_log.txt for details"
            fi
        else
            echo -e "\nAlready compatible: $base_name"
        fi
    done
    
    echo -e "\nProcessing complete!"
    echo "Log file available at: $log_file"
}

if [ $# -eq 2 ]; then
    SEARCH_DIR="$1"
    DELETE_ORIGINAL="$2"
    
    if [[ ! "$DELETE_ORIGINAL" =~ ^[0-1]$ ]]; then
        echo "Error: Second parameter must be 0 or 1"
        echo "Usage: $0 <directory_path> <delete_original>"
        echo "Example: $0 /path/to/videos 1"
        exit 1
    fi
    
    USE_GPU=0
    if has_nvidia_gpu; then
        USE_GPU=1
        echo "NVIDIA GPU detected. Hardware acceleration enabled."
    else
        echo "No NVIDIA GPU detected. Using CPU encoding."
    fi
    
    check_dependencies
    convert_videos "$SEARCH_DIR" "$DELETE_ORIGINAL" "$USE_GPU"
else
    echo "Usage: $0 <directory_path> <delete_original>"
    echo "Example: $0 /path/to/videos 1"
    exit 1
fi
