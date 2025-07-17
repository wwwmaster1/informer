#!/bin/bash

# --- vsftpd (FTP Server) Installation Script ---
# Installs and provides basic hardening for the vsftpd FTP server.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/../logs/vsftpd_install.log"
SERVICE_MANIFEST_DIR="$(dirname "${BASH_SOURCE[0]}")/../services"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting vsftpd installation."
log_to_file "vsftpd installer started."

say "Installing vsftpd package."
log_to_file "Running sudo yum install vsftpd."
sudo yum install -y vsftpd

say "Applying basic security configuration."
log_to_file "Disabling anonymous login in vsftpd.conf."
# Make a backup of the original config file
sudo cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.original
# Disable anonymous access
sudo sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf
log_to_file "Configuration updated."

say "Starting the vsftpd service."
log_to_file "Starting vsftpd service."
sudo systemctl start vsftpd

say "Enabling the vsftpd service to start on boot."
log_to_file "Enabling vsftpd service."
sudo systemctl enable vsftpd

# --- Create Service Manifest ---
say "Creating service manifest for vsftpd."
mkdir -p "$SERVICE_MANIFEST_DIR"
cat <<EOF > "$SERVICE_MANIFEST_DIR/vsftpd.json"
{
  "serviceName": "vsftpd",
  "description": "A secure FTP server for file transfers.",
  "accessMethod": {
    "type": "network",
    "protocol": "ftp",
    "port": 21,
    "usage": "Connect using an FTP client (e.g., FileZilla, ftp command) to the server's IP address on port 21."
  }
}
EOF
log_to_file "Service manifest created at $SERVICE_MANIFEST_DIR/vsftpd.json"

say "vsftpd installation and basic hardening is complete."
log_to_file "vsftpd installer finished successfully."