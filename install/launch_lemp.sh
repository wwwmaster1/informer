#!/bin/bash

# --- LEMP Stack Launcher Recipe ---
# This script provisions a new EC2 instance and deploys a classic LEMP stack.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="LEMP-Stack-Server"
STACK_FILE="lemp.stack"

echo "--- Starting LEMP Stack Remote Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "$STACK_FILE"
echo "--- LEMP Stack Remote Deployment Finished ---"
