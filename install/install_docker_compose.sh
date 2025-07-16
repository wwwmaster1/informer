#!/bin/bash

# --- Docker Compose Installation Script ---
# Installs Docker Compose for defining and running multi-container Docker applications.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/docker_compose_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Docker Compose installation."
log_to_file "Docker Compose installer started."

if [ -x "/usr/local/bin/docker-compose" ]; then
    say "Docker Compose appears to be installed already."
    log_to_file "Docker Compose found, skipping installation."
else
    say "Docker Compose not found. Downloading it from GitHub."
    log_to_file "Downloading Docker Compose from GitHub releases."
    
    # Fetch the latest version of Docker Compose and install it
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    say "Making the Docker Compose binary executable."
    log_to_file "Applying executable permissions to docker-compose binary."
    sudo chmod +x /usr/local/bin/docker-compose
    
    say "Docker Compose has been installed."
    log_to_file "Docker Compose installed successfully."
fi

say "Docker Compose installation is complete."
log_to_file "Docker Compose installer finished successfully."
