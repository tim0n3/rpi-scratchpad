#!/bin/bash

# Check if a filename is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename.tar.gz>"
    exit 1
fi

# Extract the file name without extension
filename=$(basename "$1" .tar.gz)

# Extract the file listing from the tar.gz file
tar -tzvf "$1" | awk '{print $6, $3}' | sed "s#$filename/##"

# Explanation of the commands:
# - `tar -tzvf "$1"` lists the contents of the tar.gz file with file sizes and paths.
# - `awk '{print $6, $3}'` selects the 6th and 3rd columns (filename and size).
# - `sed "s#$filename/##"` removes the leading directory (if any) from the file paths.
