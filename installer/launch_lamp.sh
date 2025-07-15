#!/bin/bash

# --- LAMP Stack Launcher Recipe ---
# This script provisions a new EC2 instance and deploys a classic LAMP stack.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="LAMP-Stack-Server"
STACK_FILE="lamp.stack"

echo "--- Starting LAMP Stack Remote Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "$STACK_FILE"
echo "--- LAMP Stack Remote Deployment Finished ---"
