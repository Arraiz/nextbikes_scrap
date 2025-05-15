#!/bin/bash

# Script to compress a specific date's nextbikes data folder

# Configuration
# Get the path to the project root directory (one level up from scripts)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${PROJECT_ROOT}/data"
DATE_FORMAT="%d-%m-%Y"
FOLDER_PREFIX="nextbikes-"

# Function to display usage information
show_usage() {
    echo "Usage: $0 [DATE]"
    echo "Compresses the nextbikes data folder for a specific date."
    echo ""
    echo "Arguments:"
    echo "  DATE    Date in DD-MM-YYYY format (e.g., 15-06-2023)"
    echo "          If not provided, yesterday's date will be used."
    echo ""
    echo "Examples:"
    echo "  $0                  # Compress yesterday's folder"
    echo "  $0 15-06-2023       # Compress folder for June 15, 2023"
    exit 1
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
fi

# Determine which date to use
if [ -z "$1" ]; then
    # No date provided, use yesterday
    TARGET_DATE=$(date -d "yesterday" +"$DATE_FORMAT")
    echo "No date provided. Using yesterday's date: $TARGET_DATE"
else
    # Validate the provided date format
    if [[ ! "$1" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
        echo "ERROR: Invalid date format. Please use DD-MM-YYYY format (e.g., 15-06-2023)."
        show_usage
    fi
    
    # Check if the date is valid
    if ! date -d "$(echo "$1" | sed 's/-/\//g')" >/dev/null 2>&1; then
        echo "ERROR: Invalid date. Please provide a valid date in DD-MM-YYYY format."
        exit 1
    fi
    
    TARGET_DATE="$1"
fi

# Set up folder paths
TARGET_FOLDER="${FOLDER_PREFIX}${TARGET_DATE}"
TARGET_PATH="${DATA_DIR}/${TARGET_FOLDER}"

# Log file
LOG_FILE="${DATA_DIR}/compression_log.txt"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Check if the folder exists
if [ ! -d "$TARGET_PATH" ]; then
    log_message "ERROR: Folder $TARGET_PATH does not exist. Nothing to compress."
    exit 1
fi

# Check if the folder is already compressed
if [ -f "${TARGET_PATH}.tar.gz" ]; then
    log_message "WARNING: Archive ${TARGET_PATH}.tar.gz already exists."
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "Compression cancelled by user."
        exit 0
    fi
    log_message "User chose to overwrite existing archive."
fi

# Compress the folder
log_message "Starting compression of $TARGET_PATH"
tar -czf "${TARGET_PATH}.tar.gz" -C "$DATA_DIR" "$TARGET_FOLDER"

# Check if compression was successful
if [ $? -eq 0 ]; then
    log_message "Successfully compressed $TARGET_PATH to ${TARGET_PATH}.tar.gz"
    
    # Calculate compression stats
    ORIGINAL_SIZE=$(du -sh "$TARGET_PATH" | cut -f1)
    COMPRESSED_SIZE=$(du -sh "${TARGET_PATH}.tar.gz" | cut -f1)
    
    log_message "Original size: $ORIGINAL_SIZE, Compressed size: $COMPRESSED_SIZE"
    
    # Ask if the user wants to remove the original folder
    read -p "Do you want to remove the original folder to save space? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$TARGET_PATH"
        log_message "Removed original folder $TARGET_PATH"
    else
        log_message "Original folder kept intact."
    fi
else
    log_message "ERROR: Failed to compress $TARGET_PATH"
    exit 1
fi

exit 0 