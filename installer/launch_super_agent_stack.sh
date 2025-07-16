#!/bin/bash

# --- Super-Agent Stack Launcher Recipe ---
# This script provisions a new EC2 instance and deploys a full agentic stack,
# including n8n, Playwright, Pipecat, ChromaDB, Ollama, and more.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Define the stack components
INSTANCE_NAME="Super-Agent-Server"
STACK_FILE="super_agent.stack"

echo "--- Starting Super-Agent Stack Remote Deployment ---"
# Call the main launcher with the predefined stack
bash "$SCRIPT_DIR/launch_ec2_and_install.sh" "$INSTANCE_NAME" "$STACK_FILE"
echo "--- Super-Agent Stack Remote Deployment Finished ---"
