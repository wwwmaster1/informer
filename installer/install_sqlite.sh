#!/bin/bash

# --- SQLite 3 Installation Script ---
# Installs the command-line interface for SQLite 3.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/sqlite_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting SQLite 3 installation."
log_to_file "SQLite installer started."

if command -v sqlite3 &>/dev/null; then
    say "SQLite 3 is already installed."
    log_to_file "SQLite 3 found, skipping installation."
else
    say "Installing the SQLite 3 package."
    log_to_file "Running sudo yum install sqlite."
    sudo yum install -y sqlite
    say "SQLite 3 has been installed."
    log_to_file "SQLite 3 installed successfully."
fi

say "SQLite 3 installation is complete."
log_to_file "SQLite installer finished successfully."
