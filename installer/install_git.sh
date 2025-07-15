#!/bin/bash

# --- Git Installation Script ---
# Installs Git, the distributed version control system.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/git_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Git installation."
log_to_file "Git installer started."

if command -v git &>/dev/null; then
    say "Git is already installed."
    log_to_file "Git found, skipping installation."
else
    say "Installing the Git package."
    log_to_file "Running sudo yum install git."
    sudo yum install -y git
    say "Git has been installed."
    log_to_file "Git installed successfully."
fi

say "Git installation is complete."
log_to_file "Git installer finished successfully."
