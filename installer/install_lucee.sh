#!/bin/bash

# --- Lucee Installation Script ---
# This script is executed on a new EC2 instance to install the Lucee CFML Engine.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/lucee_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Lucee installation."
log_to_file "Lucee installation script started."

# 1. Prerequisite: Install Java
say "Checking for Java, which is required by Lucee."
log_to_file "Checking for Java prerequisite."
if ! command -v java &>/dev/null; then
    say "Java not found. Installing Java 11 Open J D K."
    log_to_file "Java not found. Installing OpenJDK 11."
    sudo yum install -y java-11-openjdk-devel
    log_to_file "Java installation complete."
else
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    say "Java is already installed. Version: $JAVA_VERSION"
    log_to_file "Java already installed. Version: $JAVA_VERSION"
fi

# 2. Download and Install Lucee
say "Downloading the Lucee installer. This may take a moment."
log_to_file "Downloading Lucee installer."
# Using a known stable version of the Lucee installer
curl -L -o lucee-installer.run "https://cdn.lucee.org/lucee-5.3.9.166-pl0-linux-x64-installer.run"
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
# Using the unattended mode to automate the installation
sudo ./lucee-installer.run \
  --mode unattended \
  --luceepassword "$LUCEE_PASSWORD" \
  --installconn false \
  --startatboot true
log_to_file "Lucee unattended installation finished."

# The installer automatically starts the service, but we'll ensure it's running.
say "Ensuring the Lucee service is running."
sudo /opt/lucee/lucee_ctl status
log_to_file "Checked Lucee service status."

say "Lucee installation is complete. The administrator password has been saved to the log file."
log_to_file "Lucee installation script finished successfully."
say "You can find the admin password in the lucee underscore install dot log file on this server."
