#!/bin/bash

# --- Pipecat Installation Script ---
# Installs the Pipecat real-time conversational AI framework.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/pipecat_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Pipecat installation."
log_to_file "Pipecat installer started."

say "Installing system dependencies required by Pipecat for audio."
log_to_file "Installing portaudio-devel and other build tools."
sudo yum install -y portaudio-devel gcc
log_to_file "System dependencies installed."

say "Installing Pipecat A I via pip."
log_to_file "Running pip install pipecat-ai."
pip3 install pipecat-ai
say "Pipecat A I has been installed."
log_to_file "Pipecat-ai installed successfully."

say "Pipecat installation is complete."
log_to_file "Pipecat installer finished successfully."
say "You can now import pipecat in your Python scripts to build real-time voice and text agents."
