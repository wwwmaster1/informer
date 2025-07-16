#!/bin/bash

# --- Crawl4AI Installation Script ---
# Installs Crawl4AI, a Python library for AI-focused web crawling.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/crawl4ai_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Crawl for A I installation."
log_to_file "Crawl4AI installer started."

say "Installing Crawl for A I via pip."
log_to_file "Running pip install crawl4ai."
pip3 install crawl4ai
say "Crawl for A I has been installed."
log_to_file "Crawl4AI installed successfully."

say "Crawl for A I installation is complete."
log_to_file "Crawl4AI installer finished successfully."
say "You can now import crawl4ai in your Python scripts."
