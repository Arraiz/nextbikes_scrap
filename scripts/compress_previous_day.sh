#!/bin/bash

# Script to compress the previous day's nextbikes data folder

# Configuration
# Get the path to the project root directory (one level up from scripts)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${PROJECT_ROOT}/data"
DATE_FORMAT="%d-%m-%Y"
FOLDER_PREFIX="nextbikes-"

# Get yesterday's date in the required format
YESTERDAY=$(date -d "yesterday" +"$DATE_FORMAT")
YESTERDAY_FOLDER="${FOLDER_PREFIX}${YESTERDAY}"
YESTERDAY_PATH="${DATA_DIR}/${YESTERDAY_FOLDER}"

# Log file
LOG_FILE="${DATA_DIR}/compression_log.txt"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Check if the folder exists
if [ ! -d "$YESTERDAY_PATH" ]; then
    log_message "ERROR: Folder $YESTERDAY_PATH does not exist. Nothing to compress."
    exit 1
fi

# Check if the folder is already compressed
if [ -f "${YESTERDAY_PATH}.tar.gz" ]; then
    log_message "WARNING: Archive ${YESTERDAY_PATH}.tar.gz already exists. Skipping compression."
    exit 0
fi

# Compress the folder
log_message "Starting compression of $YESTERDAY_PATH"
tar -czf "${YESTERDAY_PATH}.tar.gz" -C "$DATA_DIR" "$YESTERDAY_FOLDER"

# Check if compression was successful
if [ $? -eq 0 ]; then
    log_message "Successfully compressed $YESTERDAY_PATH to ${YESTERDAY_PATH}.tar.gz"
    
    # Calculate compression stats
    ORIGINAL_SIZE=$(du -sh "$YESTERDAY_PATH" | cut -f1)
    COMPRESSED_SIZE=$(du -sh "${YESTERDAY_PATH}.tar.gz" | cut -f1)
    
    log_message "Original size: $ORIGINAL_SIZE, Compressed size: $COMPRESSED_SIZE"
    
    # Optional: Remove the original folder to save space
    # Uncomment the next line if you want to delete the original folder after compression
    # rm -rf "$YESTERDAY_PATH"
    # log_message "Removed original folder $YESTERDAY_PATH"
else
    log_message "ERROR: Failed to compress $YESTERDAY_PATH"
    exit 1
fi

exit 0 