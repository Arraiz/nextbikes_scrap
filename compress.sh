#!/bin/bash

# Wrapper script to easily run the compression scripts

# Get the absolute path of the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"

# Function to display usage information
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo "Manages the compression of nextbikes data folders."
    echo ""
    echo "Commands:"
    echo "  install      Install the daily compression cronjob"
    echo "  compress     Compress a specific date's folder (default: yesterday)"
    echo "  help         Show this help message"
    echo ""
    echo "Options for 'compress':"
    echo "  DATE         Date in DD-MM-YYYY format (e.g., 15-06-2023)"
    echo ""
    echo "Examples:"
    echo "  $0 install                  # Install the cronjob"
    echo "  $0 compress                 # Compress yesterday's folder"
    echo "  $0 compress 15-06-2023      # Compress folder for June 15, 2023"
    exit 1
}

# Check if scripts directory exists
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "ERROR: Scripts directory not found at $SCRIPTS_DIR"
    exit 1
fi

# Check if the command is provided
if [ -z "$1" ] || [ "$1" == "help" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_usage
fi

# Process commands
case "$1" in
    install)
        # Run the installation script
        echo "Installing compression cronjob..."
        bash "${SCRIPTS_DIR}/install_compression_cron.sh"
        ;;
    compress)
        # Run the compression script with the provided date or default to yesterday
        if [ -z "$2" ]; then
            echo "Compressing yesterday's folder..."
            bash "${SCRIPTS_DIR}/compress_specific_date.sh"
        else
            echo "Compressing folder for $2..."
            bash "${SCRIPTS_DIR}/compress_specific_date.sh" "$2"
        fi
        ;;
    *)
        echo "ERROR: Unknown command '$1'"
        show_usage
        ;;
esac

exit 0 