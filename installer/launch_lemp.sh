#!/bin/bash

# --- LEMP Stack Installer Recipe ---
# This script launches a new EC2 instance and installs a classic LEMP stack:
# Linux, Nginx, MariaDB (MySQL), and Python.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="LEMP-Stack-Server"
INSTALLERS=(
    "install_nginx.sh"
    "install_mysql.sh"
    "install_python.sh"
)

echo "--- Starting LEMP Stack Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "${INSTALLERS[@]}"
echo "--- LEMP Stack Deployment Finished ---"
