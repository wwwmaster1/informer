#!/bin/bash

# --- Lucee + SQLite Stack Launcher Recipe ---
# This script provisions a new EC2 instance and deploys Lucee and SQLite.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="Lucee-SQLite-Server"
STACK_FILE="lucee_sqlite.stack"

echo "--- Starting Lucee + SQLite Stack Remote Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "$STACK_FILE"
echo "--- Lucee + SQLite Stack Remote Deployment Finished ---"
