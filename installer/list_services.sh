#!/bin/bash

# --- List Services Utility ---
# Scans the service manifest directory and outputs a JSON array of all
# available services and their access information.

# The directory where service manifests are stored.
SERVICE_MANIFEST_DIR="/home/$(whoami)/.gemini/services"

# Check if the directory exists
if [ ! -d "$SERVICE_MANIFEST_DIR" ]; then
    echo "[]" # Output an empty JSON array if no services are registered
    exit 0
fi

# Find all .json files, format them into a JSON array, and print to stdout.
# Using jq for robust JSON processing.
# The -s flag reads all JSON objects into an array.
find "$SERVICE_MANIFEST_DIR" -name "*.json" -print0 | xargs -0 -I {} cat {} | jq -s .
