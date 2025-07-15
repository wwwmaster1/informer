#!/bin/bash

# --- LAMP Stack Installer Recipe ---
# This script launches a new EC2 instance and installs a classic LAMP stack:
# Linux, Apache, MariaDB (MySQL), and Python.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="LAMP-Stack-Server"
INSTALLERS=(
    "install_apache.sh"
    "install_mysql.sh"
    "install_python.sh"
)

echo "--- Starting LAMP Stack Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "${INSTALLERS[@]}"
echo "--- LAMP Stack Deployment Finished ---"
