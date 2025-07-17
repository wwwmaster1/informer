#!/bin/bash

# --- AWS CLI Installation Script ---
# Checks for the AWS CLI and installs it if it's not found.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/aws_cli_install.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
if command -v aws &>/dev/null; then
    say "A W S C L I is already installed."
    log_to_file "AWS CLI found, skipping installation."
else
    say "A W S C L I not found. Attempting to install it now."
    log_to_file "AWS CLI not found, starting installation."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        say "Detected Linux. Installing A W S C L I."
        log_to_file "Detected Linux, using curl to fetch AWS CLI."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install
        rm -rf awscliv2.zip aws
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        say "Detected mac O S. Installing A W S C L I."
        log_to_file "Detected macOS, using curl to fetch AWS CLI package."
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        say "Error: This script cannot automatically install the A W S C L I on your operating system: $OSTYPE"
        log_to_file "CRITICAL: Unsupported OS for auto-install: $OSTYPE"
        exit 1
    fi
    say "A W S C L I installation complete."
    log_to_file "AWS CLI installed successfully."
fi
