#!/bin/bash

# --- Web Server Installation Script ---
# This script is executed on a new EC2 instance to set up an Apache web server.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
# The log file will be created in the home directory of the user running the script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/apache_install.log"
SERVICE_MANIFEST_DIR="$SCRIPT_DIR/../services"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting web server installation."
log_to_file "Web server installation script started."

say "Updating all system packages."
log_to_file "Running sudo yum update."
sudo yum update -y

say "Installing the Apache H T T P Server."
log_to_file "Running sudo yum install httpd."
sudo yum install -y httpd

say "Creating a placeholder index dot H T M L file."
log_to_file "Creating placeholder index.html."
echo "<h1>Welcome to your new Web Server</h1><p>Installation was successful!</p>" | sudo tee /var/www/html/index.html

say "Starting the Apache web server."
log_to_file "Starting httpd service."
sudo systemctl start httpd

say "Enabling the Apache service to start on boot."
log_to_file "Enabling httpd service."
sudo systemctl enable httpd

# --- Create Service Manifest ---
say "Creating service manifest for Apache."
mkdir -p "$SERVICE_MANIFEST_DIR"
cat <<EOF > "$SERVICE_MANIFEST_DIR/apache.json"
{
  "serviceName": "Apache",
  "description": "A standard HTTP web server.",
  "accessMethod": {
    "type": "http",
    "protocol": "http",
    "baseUrl": "http://localhost:80",
    "usage": "Serves web content from /var/www/html/. Access via a web browser."
  }
}
EOF
log_to_file "Service manifest created at $SERVICE_MANIFEST_DIR/apache.json"

say "Web server installation is complete."
log_to_file "Web server installation script finished successfully."
