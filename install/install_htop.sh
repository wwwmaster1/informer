#!/bin/bash

# --- htop Installation Script ---
# Installs htop, an interactive process viewer.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/htop_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting htop installation."
log_to_file "htop installer started."

if command -v htop &>/dev/null; then
    say "htop is already installed."
    log_to_file "htop found, skipping installation."
else
    say "htop requires the Extra Packages for Enterprise Linux repository. Installing it now."
    log_to_file "Installing epel-release."
    sudo yum install -y epel-release
    log_to_file "EPEL repository installed."

    say "Installing htop."
    log_to_file "Running sudo yum install htop."
    sudo yum install -y htop
    say "htop has been installed."
    log_to_file "htop installed successfully."
fi

say "htop installation is complete."
log_to_file "htop installer finished successfully."
