#!/bin/bash

# --- Unzip Installation Script ---
# Installs unzip if it is not found.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LOG_FILE="$SCRIPT_DIR/unzip_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Checking for unzip."
log_to_file "Unzip installer started."

if command -v unzip &>/dev/null; then
    say "unzip is already installed."
    log_to_file "unzip is already installed. Skipping."
else
    say "unzip is not found. Installing it now."
    log_to_file "unzip not found, attempting installation."
    sudo yum install -y unzip >/dev/null
    say "unzip has been installed."
    log_to_file "unzip installed successfully."
fi

log_to_file "Unzip installer finished."