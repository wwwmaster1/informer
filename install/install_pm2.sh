#!/bin/bash

# --- PM2 (Process Manager) Installation Script ---
# Installs PM2, a production process manager for Node.js applications.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/../logs/pm2_install.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting PM2 installation."
log_to_file "PM2 installer started."

if command -v pm2 &>/dev/null; then
    say "PM2 is already installed."
    log_to_file "PM2 found, skipping installation."
else
    say "Installing PM2 globally via N P M."
    log_to_file "Running sudo npm install -g pm2."
    sudo npm install -g pm2
    say "PM2 has been installed."
    log_to_file "PM2 installed successfully."
fi

say "PM2 installation is complete."
log_to_file "PM2 installer finished successfully."
