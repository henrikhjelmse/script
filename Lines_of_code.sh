#!/bin/bash

# Script Description:
# This script analyzes a given directory and counts the total number of lines in files
# with specified extensions, including files in subdirectories.
# It provides:
# 1. Total number of matching files and lines.
# 2. Number of files and lines for each file type.
# 3. A detailed breakdown showing each file with its individual line count.

# Define an array of file extensions to analyze
extensions=("html" "css" "js" "py")

# Check if a directory path was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <directory path>"
  exit 1
fi

# Assign the provided directory path to a variable
directory="$1"

# Check if the given directory exists
if [ ! -d "$directory" ]; then
  echo "Error: '$directory' is not a valid directory."
  exit 1
fi

echo "Analyzing directory: $directory"
echo "-------------------------------------------"

# Find all files matching the extensions in the array
files=$(find "$directory" -type f \( $(printf -- '-name "*.%s" -o ' "${extensions[@]}" | sed 's/ -o $//') \))

# If no matching files are found
if [ -z "$files" ]; then
  echo "No files with the specified extensions (${extensions[*]}) found in the directory."
  exit 0
fi

# Count the total number of lines
total_lines=$(echo "$files" | xargs cat | wc -l)

# Initialize variables for file and line counts per extension
declare -A file_count
declare -A line_count

# Loop through each extension to calculate counts
for ext in "${extensions[@]}"; do
  file_count[$ext]=$(find "$directory" -type f -name "*.$ext" | wc -l)
  line_count[$ext]=$(find "$directory" -type f -name "*.$ext" -exec cat {} + | wc -l)
done

# Display summary information
echo "Total number of files: $(echo "$files" | wc -l)"
echo "Total number of lines: $total_lines"
echo
echo "Number of files by type:"
for ext in "${extensions[@]}"; do
  echo "  $ext: ${file_count[$ext]}"
done
echo
echo "Number of lines by type:"
for ext in "${extensions[@]}"; do
  echo "  $ext: ${line_count[$ext]}"
done
echo "-------------------------------------------"

# List files with their individual line count
echo "Detailed file information:"
echo "$files" | while read -r file; do
  line_count=$(wc -l < "$file")
  echo "  $file: $line_count lines"
done
