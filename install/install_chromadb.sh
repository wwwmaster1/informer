#!/bin/bash

# --- ChromaDB Installation Script ---
# Installs ChromaDB, the open-source embedding database.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/chromadb_install.log"
SERVICE_MANIFEST_DIR="$(dirname "${BASH_SOURCE[0]}")/../services"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Chroma D B installation."
log_to_file "ChromaDB installer started."

if command -v chroma &>/dev/null; then
    say "Chroma D B appears to be installed already."
    log_to_file "Chroma command found, skipping installation."
else
    say "Installing Chroma D B via pip."
    log_to_file "Running pip install chromadb."
    pip3 install chromadb
    say "Chroma D B has been installed."
    log_to_file "ChromaDB installed successfully."
fi

# --- Create Service Manifest ---
say "Creating service manifest for Chroma D B."
mkdir -p "$SERVICE_MANIFEST_DIR"
cat <<EOF > "$SERVICE_MANIFEST_DIR/chromadb.json"
{
  "serviceName": "ChromaDB",
  "description": "An open-source embedding database for agent memory and semantic search.",
  "accessMethod": {
    "type": "http",
    "protocol": "rest_api",
    "baseUrl": "http://localhost:8000",
    "usage": "Run a persistent server with 'chroma run --host 0.0.0.0' and interact with the Python client or REST API."
  }
}
EOF
log_to_file "Service manifest created at $SERVICE_MANIFEST_DIR/chromadb.json"

say "Chroma D B installation is complete."
log_to_file "ChromaDB installer finished successfully."
say "You can now import chromadb in your Python scripts or run a persistent server with: chroma run --host 0.0.0.0"
log_to_file "Instructed user on how to use ChromaDB."