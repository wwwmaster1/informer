#!/bin/bash

# --- List Services Utility ---
# Scans the service manifest directory within the project and outputs a JSON
# array of all available services and their access information.

# This script should be run from the project root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SERVICE_MANIFEST_DIR="$SCRIPT_DIR/services"

# Check if the directory exists
if [ ! -d "$SERVICE_MANIFEST_DIR" ]; then
    # If it doesn't exist, try looking in the install directory's parent
    # This handles the case where it's run from within the install folder
    ALT_MANIFEST_DIR="$SCRIPT_DIR/../services"
    if [ -d "$ALT_MANIFEST_DIR" ]; then
        SERVICE_MANIFEST_DIR="$ALT_MANIFEST_DIR"
    else
        echo "[]" # Output an empty JSON array if no services are registered
        exit 0
    fi
fi

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "{\"error\": \"jq is not installed. Please install jq to use this script.\"}"
    exit 1
fi

# Find all .json files, format them into a JSON array, and print to stdout.
find "$SERVICE_MANIFEST_DIR" -name "*.json" -print0 | xargs -0 -I {} cat {} | jq -s .