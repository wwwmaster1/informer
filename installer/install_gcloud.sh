#!/bin/bash

# --- Google Cloud SDK Installation Script ---
# Installs the Google Cloud SDK if it is not found.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LOG_FILE="$SCRIPT_DIR/gcloud_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Checking for Google Cloud S D K."
log_to_file "Google Cloud SDK installer started."

if [ -d "$HOME/google-cloud-sdk" ]; then
    say "The Google Cloud S D K appears to be installed already."
    log_to_file "Google Cloud SDK directory found. Skipping installation."
else
    say "Google Cloud S D K not found. Installing it now. This may take a few minutes."
    log_to_file "Google Cloud SDK not found, starting installation."
    curl https://sdk.cloud.google.com | bash -s -- --disable-prompts > /dev/null
    log_to_file "Google Cloud SDK installation script finished."
    
    # Add gcloud to the shell profile
    SHELL_PROFILE=""
    if [ -n "$BASH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.zshrc"
    else
        SHELL_PROFILE="$HOME/.profile"
    fi
    
    if [ -f "$SHELL_PROFILE" ]; then
        echo -e "\n# Add Google Cloud SDK to PATH" >> "$SHELL_PROFILE"
        echo "source '$HOME/google-cloud-sdk/path.bash.inc'" >> "$SHELL_PROFILE"
        say "The Google Cloud S D K has been added to your shell profile."
        log_to_file "GCloud SDK path added to $SHELL_PROFILE."
    else
        say "Could not automatically add the Google Cloud S D K to your path. Please add it manually."
        log_to_file "Could not find shell profile to add GCloud SDK path."
    fi
fi

log_to_file "Google Cloud SDK installer finished."
