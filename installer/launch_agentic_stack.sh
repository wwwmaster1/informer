#!/bin/bash

# --- Agentic Stack Launcher Recipe ---
# This script provisions a new EC2 instance and deploys a full agentic stack,
# including n8n, Playwright, Docker, and PM2.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="Agentic-Stack-Server"
STACK_FILE="agentic.stack"

echo "--- Starting Agentic Stack Remote Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "$STACK_FILE"
echo "--- Agentic Stack Remote Deployment Finished ---"
