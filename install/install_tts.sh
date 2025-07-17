#!/bin/bash

# --- Text-to-Speech (TTS) Installation Script ---
# Installs the necessary components for Google Cloud Text-to-Speech.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
LOG_FILE="$ROOT_DIR/logs/tts_install.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting T T S installation."
log_to_file "TTS installer started."

say "Enabling the Google Text-to-Speech A P I."
log_to_file "Enabling texttospeech.googleapis.com"
gcloud services enable texttospeech.googleapis.com
log_to_file "A P I enabled."

say "T T S installation is complete."
log_to_file "TTS installer finished successfully."
