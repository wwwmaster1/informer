#!/bin/bash

# --- n8n Installation Script (via Docker) ---
# Installs and starts n8n, a workflow automation tool, using Docker Compose.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/n8n_install.log"
N8N_DIR="$HOME/n8n"
# Manifests will be created relative to the script's location.
SERVICE_MANIFEST_DIR="$(dirname "${BASH_SOURCE[0]}")/../services"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting n8n installation."
log_to_file "n8n installer started."

if ! command -v docker-compose &>/dev/null; then
    say "Error: Docker Compose is required but not found. Please include install_docker.sh and install_docker_compose.sh in your stack."
    log_to_file "CRITICAL: docker-compose command not found."
    exit 1
fi

say "Creating a directory for n8n configuration and data."
mkdir -p "$N8N_DIR"
log_to_file "Created directory at $N8N_DIR."

say "Creating a docker-compose dot Y M L file for n8n."
log_to_file "Creating docker-compose.yml in $N8N_DIR."

# Create the docker-compose.yml file
cat <<EOF > "$N8N_DIR/docker-compose.yml"
version: '3.7'

services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    volumes:
      - ./n8n_data:/home/node/.n8n
    environment:
      - GENERIC_TIMEZONE=\${GENERIC_TIMEZONE}
EOF

log_to_file "docker-compose.yml created."

say "Starting the n8n container in the background."
log_to_file "Running docker-compose up -d."
(cd "$N8N_DIR" && docker-compose up -d)
log_to_file "n8n container started."

# --- Create Service Manifest ---
say "Creating service manifest for n8n."
mkdir -p "$SERVICE_MANIFEST_DIR"
cat <<EOF > "$SERVICE_MANIFEST_DIR/n8n.json"
{
  "serviceName": "n8n",
  "description": "A workflow automation tool.",
  "accessMethod": {
    "type": "http",
    "protocol": "webhook",
    "baseUrl": "http://localhost:5678",
    "usage": "Trigger workflows by POSTing to unique webhook URLs. Example: curl -X POST http://localhost:5678/webhook/YOUR_ID"
  }
}
EOF
log_to_file "Service manifest created at $SERVICE_MANIFEST_DIR/n8n.json"

say "n8n installation is complete."
log_to_file "n8n installer finished successfully."
say "You should be able to access n8n at H T T P colon slash slash your server I P colon 5 6 7 8."