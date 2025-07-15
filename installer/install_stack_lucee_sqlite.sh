#!/bin/bash

# --- Lucee + SQLite Stack Installer Recipe ---
# This script launches a new EC2 instance and installs Lucee and SQLite.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="Lucee-SQLite-Server"
INSTALLERS=(
    "install_lucee.sh"
    "install_sqlite.sh"
)

echo "--- Starting Lucee + SQLite Stack Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "${INSTALLERS[@]}"
echo "--- Lucee + SQLite Stack Deployment Finished ---"
