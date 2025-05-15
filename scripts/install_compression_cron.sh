#!/bin/bash

# Script to install a cronjob for compressing the previous day's data folder

# Get the absolute path of the compress script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPRESS_SCRIPT="${SCRIPT_DIR}/compress_previous_day.sh"

# Make the compression script executable
chmod +x "$COMPRESS_SCRIPT"

# Check if the script exists
if [ ! -f "$COMPRESS_SCRIPT" ]; then
    echo "ERROR: Compression script not found at $COMPRESS_SCRIPT"
    exit 1
fi

# Create a temporary file for the crontab
TEMP_CRON=$(mktemp)

# Export current crontab
crontab -l > "$TEMP_CRON" 2>/dev/null || echo "# New crontab" > "$TEMP_CRON"

# Check if the cronjob already exists
if grep -q "$COMPRESS_SCRIPT" "$TEMP_CRON"; then
    echo "The cronjob already exists in your crontab. No changes made."
    rm "$TEMP_CRON"
    exit 0
fi

# Add the new cronjob to run at 1:00 AM every day
echo "# NextBikes data compression job - Added on $(date +'%Y-%m-%d')" >> "$TEMP_CRON"
echo "0 1 * * * $COMPRESS_SCRIPT >> ${SCRIPT_DIR}/data/cron_execution.log 2>&1" >> "$TEMP_CRON"

# Install the new crontab
crontab "$TEMP_CRON"
CRON_STATUS=$?

# Clean up
rm "$TEMP_CRON"

# Check if crontab installation was successful
if [ $CRON_STATUS -eq 0 ]; then
    echo "Successfully installed cronjob to compress previous day's data at 1:00 AM daily."
    echo "The compression script is located at: $COMPRESS_SCRIPT"
    echo "Logs will be written to ${SCRIPT_DIR}/data/compression_log.txt"
    echo "Cron execution logs will be written to ${SCRIPT_DIR}/data/cron_execution.log"
    
    # Show the current crontab for verification
    echo -e "\nCurrent crontab:"
    crontab -l
else
    echo "ERROR: Failed to install the cronjob."
    exit 1
fi

exit 0 