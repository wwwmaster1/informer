#!/bin/bash

# --- cURL Installation Script ---
# Installs curl if it is not found.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/curl_install.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Checking for curl."
log_to_file "cURL installer started."

if command -v curl &>/dev/null; then
    say "curl is already installed."
    log_to_file "curl is already installed. Skipping."
else
    say "curl is not found. Installing it now."
    log_to_file "curl not found, attempting installation."
    sudo yum install -y curl >/dev/null
    say "curl has been installed."
    log_to_file "curl installed successfully."
fi

log_to_file "cURL installer finished."