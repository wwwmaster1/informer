#!/bin/bash

# --- Nginx Installation Script ---
# This script is executed on a new EC2 instance to set up an Nginx web server.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/nginx_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Nginx web server installation."
log_to_file "Nginx installation script started."

say "Updating all system packages."
log_to_file "Running sudo yum update."
sudo yum update -y

say "Installing the Nginx web server."
log_to_file "Running sudo yum install nginx."
# The '-y' flag is for amazon-linux-extras
sudo amazon-linux-extras install -y nginx1

say "Creating a placeholder index dot H T M L file."
log_to_file "Creating placeholder index.html for Nginx."
echo "<h1>Welcome to your new Nginx Web Server</h1><p>Installation was successful!</p>" | sudo tee /usr/share/nginx/html/index.html

say "Starting the Nginx web server."
log_to_file "Starting nginx service."
sudo systemctl start nginx

say "Enabling the Nginx service to start on boot."
log_to_file "Enabling nginx service."
sudo systemctl enable nginx

say "Nginx web server installation is complete."
log_to_file "Nginx installation script finished successfully."
