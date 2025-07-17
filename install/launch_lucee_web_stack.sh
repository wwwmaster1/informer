#!/bin/bash

# --- Lucee Web Stack Launcher Recipe ---
# This script provisions a new EC2 instance and deploys a production-ready
# Lucee stack using Apache as a reverse proxy.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="Lucee-Web-Server"
STACK_FILE="lucee_web.stack"

echo "--- Starting Lucee Web Stack Remote Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "$STACK_FILE"
echo "--- Lucee Web Stack Remote Deployment Finished ---"
