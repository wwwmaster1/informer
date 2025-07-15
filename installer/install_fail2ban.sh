#!/bin/bash

# --- Fail2Ban Installation Script ---
# Installs Fail2Ban, a tool to prevent brute-force attacks.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/fail2ban_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Fail2Ban installation."
log_to_file "Fail2Ban installer started."

say "Fail2Ban requires the Extra Packages for Enterprise Linux repository. Installing it now."
log_to_file "Installing epel-release."
sudo yum install -y epel-release
log_to_file "EPEL repository installed."

say "Installing Fail2Ban."
log_to_file "Running sudo yum install fail2ban."
sudo yum install -y fail2ban
log_to_file "Fail2Ban package installed."

say "Starting the Fail2Ban service."
log_to_file "Starting fail2ban service."
sudo systemctl start fail2ban

say "Enabling the Fail2Ban service to start on boot."
log_to_file "Enabling fail2ban service."
sudo systemctl enable fail2ban

say "Fail2Ban installation is complete."
log_to_file "Fail2Ban installer finished successfully."
say "Default configuration is running. For custom rules, create a jail dot local file in the slash etc slash fail2ban directory."
log_to_file "Instructed user on jail.local configuration."
