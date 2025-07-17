#!/bin/bash

# --- Certbot Installation Script ---
# Installs Certbot for obtaining SSL/TLS certificates from Let's Encrypt.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/../logs/certbot_install.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Certbot installation."
log_to_file "Certbot installer started."

say "Certbot requires the Extra Packages for Enterprise Linux repository. Installing it now."
log_to_file "Installing epel-release."
sudo yum install -y epel-release
log_to_file "EPEL repository installed."

say "Installing Certbot."
log_to_file "Running sudo yum install certbot."
sudo yum install -y certbot
log_to_file "Certbot package installed."

say "Certbot installation is complete."
log_to_file "Certbot installer finished successfully."
say "You can now use Certbot to issue certificates for your web server, for example, sudo certbot --apache or sudo certbot --nginx."
