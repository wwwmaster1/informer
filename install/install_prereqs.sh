#!/bin/bash

# --- Prerequisite Installation Script ---
# Installs tools required by the main Gemini CLI installer.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/.gemini_install.log"

say() {
    echo "$1"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting prerequisite check."
log_to_file "Prerequisite script started."

PREREQS=("curl" "unzip")

for tool in "${PREREQS[@]}"; do
    say "Checking for $tool."
    if command -v "$tool" &>/dev/null; then
        version=$($tool --version | head -n 1)
        say "$tool is already installed."
        log_to_file "$tool is installed. Version: $version"

        say "Running a quick test for $tool."
        if "$tool" --version &>/dev/null; then
            say "$tool test passed."
            log_to_file "$tool passed runtime check."
        else
            say "Warning: $tool seems to be installed but is not working correctly."
            log_to_file "$tool FAILED runtime check."
        fi
    else
        say "$tool is not found. Installing it now."
        log_to_file "$tool not found, attempting installation."
        sudo yum install -y "$tool" >/dev/null
        say "$tool has been installed."
        log_to_file "$tool installed successfully."
    fi
done

say "Prerequisite check complete."
log_to_file "Prerequisite script finished."
