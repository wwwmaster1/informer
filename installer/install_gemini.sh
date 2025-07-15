#!/bin/bash

# --- Gemini CLI Installation Script for Voice Control ---
# This script validates the environment, installs all prerequisites via
# independent scripts, and sets up the Gemini CLI with a simple, speakable alias.

# Clear any EXIT traps to prevent infinite loops
trap - EXIT
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MASTER_LOG_FILE="$SCRIPT_DIR/install.log"
GEMINI_LOG_FILE="$SCRIPT_DIR/gemini_install.log"
LOG_FILE="$GEMINI_LOG_FILE" # For existing log_to_file calls
ENV_FILE="$SCRIPT_DIR/gemini.env"

say() {
    echo "{$1}"
}

log_master() {
    echo "$(date +%s): [install_gemini.sh] $1" >>"$MASTER_LOG_FILE"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- 1. Initial Validation ---
log_master "Started."
say "Starting Gemini command line interface setup."
log_to_file "Main script started."

# Validate .env file existence
if [ ! -f "$ENV_FILE" ]; then
    say "Error: The environment file named gemini dot E N V was not found. Please create it."
    log_to_file "CRITICAL: gemini.env not found."
    exit 1
fi
source "$ENV_FILE"
log_to_file "Environment file loaded."

# Validate GCP_PROJECT_ID
if [ -z "$GCP_PROJECT_ID" ] || [[ "$GCP_PROJECT_ID" == "your-gcp-project-id-here" ]]; then
    say "Error: Your Google Cloud Project I D is not set in the environment file."
    log_to_file "CRITICAL: GCP_PROJECT_ID is not set."
    exit 1
fi

# Validate GCP_KEY_FILE_PATH
if [ -z "$GCP_KEY_FILE_PATH" ] || [[ "$GCP_KEY_FILE_PATH" == "/path/to/your/service-account-key.json" ]]; then
    say "Error: The path to your Google Cloud key file is not set in the environment file."
    log_to_file "CRITICAL: GCP_KEY_FILE_PATH is not set."
    exit 1
fi

# Validate key file existence
if [ ! -f "$GCP_KEY_FILE_PATH" ]; then
    say "Error: The specified Google Cloud key file was not found at the path you provided."
    log_to_file "CRITICAL: GCP key file not found at $GCP_KEY_FILE_PATH"
    exit 1
fi

# Validate sudo privileges
if ! sudo -n true 2>/dev/null; then
    say "Error: This script requires passwordless sudo privileges to install system packages."
    log_to_file "CRITICAL: Passwordless sudo is not available."
    exit 1
fi
say "Initial validation passed."
log_to_file "All initial validations passed."

# --- 2. Run Prerequisite Scripts ---
say "Now beginning prerequisite checks."

log_master "Handoff -> install_curl.sh"
say "Handing off to the curl installation script."
bash "$SCRIPT_DIR/install_curl.sh"
say "Resuming main installation."
log_master "Return <- install_curl.sh"

log_master "Handoff -> install_unzip.sh"
say "Handing off to the unzip installation script."
bash "$SCRIPT_DIR/install_unzip.sh"
say "Resuming main installation."
log_master "Return <- install_unzip.sh"

log_master "Handoff -> install_python.sh"
say "Handing off to the Python installation script."
bash "$SCRIPT_DIR/install_python.sh"
say "Resuming main installation."
log_master "Return <- install_python.sh"

log_master "Handoff -> install_gcloud.sh"
say "Handing off to the Google Cloud tool installation script."
bash "$SCRIPT_DIR/install_gcloud.sh"
say "Resuming main installation."
log_master "Return <- install_gcloud.sh"

log_master "Handoff -> install_nodejs.sh"
say "Handing off to the Node.js installation script."
bash "$SCRIPT_DIR/install_nodejs.sh"
say "Resuming main installation."
log_master "Return <- install_nodejs.sh"

say "All prerequisite checks are complete."
log_to_file "Finished calling all prerequisite scripts."

# --- 3. Configure Google Cloud SDK ---
say "Detecting shell configuration file."
if [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
else
    SHELL_PROFILE="$HOME/.profile"
fi

if [ -f "$SHELL_PROFILE" ]; then
    say "Found shell profile at $SHELL_PROFILE."
    log_to_file "Detected shell profile: $SHELL_PROFILE"
    source "$SHELL_PROFILE"
    source "$HOME/google-cloud-sdk/path.bash.inc"
    log_to_file "Sourced shell profile and gcloud SDK for current session."
else
    say "Could not automatically detect your shell profile. You may need to manually source your configuration files."
    log_to_file "Could not auto-detect shell profile."
fi

say "Authenticating with your Google Cloud account."
gcloud auth activate-service-account --key-file="$GCP_KEY_FILE_PATH"
log_to_file "Authenticated with service account."

say "Setting the project to $GCP_PROJECT_ID."
gcloud config set project "$GCP_PROJECT_ID"
log_to_file "Set GCP project to $GCP_PROJECT_ID."

say "Updating Google Cloud components and installing the latest Gemini components."
gcloud components update -q
gcloud components install alpha -q
log_to_file "Updated gcloud components and installed alpha."

# --- 4. Create Speakable Alias ---
say "Choosing a voice command alias."
CANDIDATE_ALIASES=("gemini" "gemma" "coder")
CHOSEN_ALIAS=""

for ALIAS_NAME in "${CANDIDATE_ALIASES[@]}"; do
    if ! grep -q "alias $ALIAS_NAME=" "$SHELL_PROFILE" 2>/dev/null; then
        CHOSEN_ALIAS=$ALIAS_NAME
        break
    fi
done

if [ -z "$CHOSEN_ALIAS" ]; then
    CHOSEN_ALIAS="gemini-cli"
    say "All preferred alias names were taken. The alias has been set to gemini dash C L I."
    log_to_file "All candidate aliases were taken. Using fallback: $CHOSEN_ALIAS."
fi

say "The alias to run commands will be: $CHOSEN_ALIAS"
log_to_file "Selected alias: $CHOSEN_ALIAS"

# Add the alias to the detected shell profile
if [ -f "$SHELL_PROFILE" ]; then
    if ! grep -q "alias $CHOSEN_ALIAS=" "$SHELL_PROFILE"; then
        {
            echo -e "\n# Alias for Voice-Controlled Gemini CLI"
            echo "alias $CHOSEN_ALIAS='gcloud alpha gemini'"
        } >>"$SHELL_PROFILE"
        log_to_file "Alias written to $SHELL_PROFILE."
        say "Alias '$CHOSEN_ALIAS' has been added to your shell profile. Please restart your terminal or run 'source $SHELL_PROFILE' to use it."
    fi
else
    say "Could not automatically add the alias. Please manually add the following line to your shell configuration file."
    log_to_file "Could not auto-add alias. Instructing user to manually add: alias $CHOSEN_ALIAS='gcloud alpha gemini'"
    echo "Your shell configuration file is usually .bashrc, .zshrc, or .profile in your home directory."
    echo "Add this line:"
    echo "alias $CHOSEN_ALIAS='gcloud alpha gemini'"
fi


# --- 5. Finalization ---
chmod +x "$SCRIPT_DIR/install_gemini.sh"
log_to_file "Set executable permissions on the main installation script."

say "Setup is complete. The system is now ready. Your command alias is $CHOSEN_ALIAS."
log_to_file "Main script finished successfully."