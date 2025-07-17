#!/bin/bash

# --- Lucee Installation Script ---
# This script is executed on a new EC2 instance to install the Lucee CFML Engine.
# This installer is self-contained and includes its own Java/Tomcat runtime.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")"/lucee_install.log"
SERVICE_MANIFEST_DIR="$(dirname "${BASH_SOURCE[0]}")"/../services"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Lucee installation."
log_to_file "Lucee installation script started."

# The Lucee installer is self-contained and does not require a separate Java installation.
say "Downloading the latest Lucee installer. This may take a moment."
log_to_file "Downloading Lucee installer."
curl -L -o lucee-installer.run "https://cdn.lucee.org/lucee-6.2.1.122-linux-x64-installer.run"
log_to_file "Lucee download complete."

say "Making the Lucee installer executable."
chmod +x lucee-installer.run
log_to_file "Set executable permission on Lucee installer."

# Generate a random password for the Lucee server admin
LUCEE_PASSWORD=$(openssl rand -base64 12)
say "A new random password has been generated for the Lucee administrator."
log_to_file "Generated new Lucee admin password."
echo "IMPORTANT: The Lucee administrator password is: $LUCEE_PASSWORD" >> "$LOG_FILE"

say "Running the Lucee installer in unattended mode."
log_to_file "Starting unattended Lucee installation."
sudo ./lucee-installer.run \
  --mode unattended \
  --luceepassword "$LUCEE_PASSWORD" \
  --installconn false \
  --startatboot true
log_to_file "Lucee unattended installation finished."

say "Ensuring the Lucee service is running."
sudo /opt/lucee/lucee_ctl status
log_to_file "Checked Lucee service status."

# --- Create Service Manifest ---
say "Creating service manifest for Lucee."
mkdir -p "$SERVICE_MANIFEST_DIR"
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
