#!/bin/bash

# --- Lucee Installation Script ---
# This script is executed on a new EC2 instance to install the Lucee CFML Engine.
# It uses an environment variable for the admin password.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
LOG_FILE="$SCRIPT_DIR/lucee_install.log"
SERVICE_MANIFEST_DIR="$SCRIPT_DIR/../services"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_GLE"
}

# --- Source Utilities ---
source "$SCRIPT_DIR/utils/lucee_utils.sh"

# --- Script Body ---
# Ensure log and service directories exist before doing anything else.
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$SERVICE_MANIFEST_DIR"

say "Starting Lucee installation."
log_to_file "Lucee installation script started."

# 1. Validate or generate the Lucee admin password
validate_or_generate_lucee_password
log_to_file "Lucee password has been set as an environment variable."
echo "IMPORTANT: The Lucee administrator password is: $LUCEE_ADMIN_PASSWORD" >> "$LOG_FILE"

# 2. Download and Install Lucee
say "Downloading the latest Lucee installer. This may take a moment."
log_to_file "Downloading Lucee installer."
curl -L -o lucee-installer.run "https://cdn.lucee.org/lucee-6.2.1.122-linux-x64-installer.run"
log_to_file "Lucee download complete."

say "Making the Lucee installer executable."
chmod +x lucee-installer.run
log_to_file "Set executable permission on Lucee installer."

say "Running the Lucee installer in unattended mode."
log_to_file "Starting unattended Lucee installation using environment variable for password."
# The installer will automatically pick up the LUCEE_ADMIN_PASSWORD variable.
sudo ./lucee-installer.run \
  --mode unattended \
  --installconn false \
  --startatboot true
log_to_file "Lucee unattended installation finished."

say "Ensuring the Lucee service is running."
sudo /opt/lucee/lucee_ctl status
log_to_file "Checked Lucee service status."

# 3. Create Service Manifest
say "Creating service manifest for Lucee."
cat <<EOF > "$SERVICE_MANIFEST_DIR/lucee.json"
{
  "serviceName": "Lucee",
  "description": "A CFML Application Server running on Tomcat.",
  "accessMethod": {
    "type": "http",
    "protocol": "http",
    "baseUrl": "http://localhost:8888",
    "usage": "This service runs on a non-standard port. It is typically accessed via a reverse proxy like Apache or Nginx on port 80."
  }
}
EOF
log_to_file "Service manifest created at $SERVICE_MANIFEST_DIR/lucee.json"

say "Lucee installation is complete. The administrator password has been saved to the log file."
log_to_file "Lucee installation script finished successfully."
say "You can find the admin password in the lucee underscore install dot log file on this server."
