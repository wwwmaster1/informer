#!/bin/bash

# --- Ollama Installation Script ---
# Installs Ollama to run and manage local LLMs.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/../logs/ollama_install.log"
SERVICE_MANIFEST_DIR="$(dirname "${BASH_SOURCE[0]}")/../services"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Ollama installation."
log_to_file "Ollama installer started."

if command -v ollama &>/dev/null; then
    say "Ollama is already installed."
    log_to_file "Ollama command found, skipping installation."
else
    say "Downloading and running the official Ollama installation script."
    log_to_file "Running ollama install script from ollama.com."
    curl -fsSL https://ollama.com/install.sh | sh
    log_to_file "Ollama installation script finished."
    say "Ollama has been installed."
fi

# --- Create Service Manifest ---
say "Creating service manifest for Ollama."
mkdir -p "$SERVICE_MANIFEST_DIR"
cat <<EOF > "$SERVICE_MANIFEST_DIR/ollama.json"
{
  "serviceName": "Ollama",
  "description": "A server for running local Large Language Models.",
  "accessMethod": {
    "type": "http",
    "protocol": "rest_api",
    "baseUrl": "http://localhost:11434",
    "usage": "Interact with the Ollama API. Example: curl http://localhost:11434/api/generate -d '{\"model\": \"llama3\", \"prompt\":\"Why is the sky blue?\"}'"
  }
}
EOF
log_to_file "Service manifest created at $SERVICE_MANIFEST_DIR/ollama.json"


say "Ollama installation is complete."
log_to_file "Ollama installer finished successfully."
say "You can now pull a model with 'ollama run model-name', for example: ollama run llama3"
log_to_file "Instructed user on how to pull a model."