#!/bin/bash

# --- Playwright Installation Script ---
# Installs Playwright's system dependencies and browser binaries.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/../logs/playwright_install.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Playwright installation."
log_to_file "Playwright installer started."

say "Installing system dependencies required by Playwright. This may take a moment."
log_to_file "Running npx playwright install-deps."
# We may need to run this as root if the user doesn't have permissions
if sudo -n true 2>/dev/null; then
    sudo npx playwright install-deps
else
    npx playwright install-deps
fi
log_to_file "System dependencies installed."

say "Installing Playwright browser binaries (Chromium, Firefox, WebKit)."
log_to_file "Running npx playwright install."
npx playwright install
log_to_file "Browser binaries installed."

say "Playwright setup is complete."
log_to_file "Playwright installer finished successfully."
say "Note: Playwright itself should be installed as a local dependency in your Node.js project via npm install playwright."
log_to_file "Instructed user to install playwright locally in their project."
