#!/bin/bash

# --- Node.js Installation Script ---
# Installs Node.js using NVM (Node Version Manager), the recommended way to manage Node versions.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$SCRIPT_DIR/nodejs_install.log"

say() {
    echo "$1"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Node.js installation."
log_to_file "Node.js installation script started."

if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    say "Node.js is already installed. Version: $NODE_VERSION"
    log_to_file "Node.js is already installed. Version: $NODE_VERSION"
else
    say "Node.js not found. Installing Node.js using NVM..."
    log_to_file "Node.js not found, attempting installation via NVM."
    
    # Download and run the NVM installation script
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Source NVM to make it available in the current shell
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install the latest Long-Term Support (LTS) version of Node.js
    say "Installing LTS version of Node.js..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    
    NODE_VERSION=$(node --version)
    say "Node.js installation complete. Version: $NODE_VERSION"
    log_to_file "Node.js installation complete. Version: $NODE_VERSION"
    
    say "Please close and reopen your terminal or run 'source ~/.bashrc' to use node and npm."
fi

say "Node.js setup is complete."
log_to_file "Node.js installation script finished."
