#!/bin/bash

# --- vsftpd (FTP Server) Installation Script ---
# Installs and provides basic hardening for the vsftpd FTP server.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/vsftpd_install.log"

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

say "vsftpd installation and basic hardening is complete."
log_to_file "vsftpd installer finished successfully."
