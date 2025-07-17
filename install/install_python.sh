#!/bin/bash

# --- Python Installation Script ---
# Installs Python 3 if it is not found.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/python_install.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Checking for Python."
log_to_file "Python installer started."

if command -v python3 &>/dev/null; then
    say "Python 3 is already installed."
    log_to_file "Python 3 is already installed. Skipping."
else
    say "Python 3 is not found. Installing it now."
    log_to_file "Python 3 not found, attempting installation."
    sudo yum install -y python3 >/dev/null
    say "Python 3 has been installed."
    log_to_file "Python 3 installed successfully."
fi

log_to_file "Python installer finished."