#!/bin/bash

# --- Redis Installation Script ---
# Installs Redis, an in-memory data structure store.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/../logs/redis_install.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Redis installation."
log_to_file "Redis installer started."

say "Installing Redis 6 using Amazon Linux Extras."
log_to_file "Installing redis6."
sudo amazon-linux-extras install -y redis6
log_to_file "Redis installation complete."

say "Starting the Redis service."
log_to_file "Starting redis service."
sudo systemctl start redis

say "Enabling the Redis service to start on boot."
log_to_file "Enabling redis service."
sudo systemctl enable redis

say "Redis installation is complete."
log_to_file "Redis installer finished successfully."
