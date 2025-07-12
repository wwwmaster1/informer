#!/bin/bash

# --- Script for Voice-Controlled Gemini CLI Installation ---
# This script automates the setup of the Google Cloud CLI and Gemini tools
# on a Linux system, configured for voice-based interaction.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper function for voice-friendly output ---
say() {
    echo "$1"
    ECHOS+=("[$(date +'%Y-%m-%d %H:%M:%S')] $1")
}

# --- Configuration and Setup ---
say "Starting the Gemini command line interface setup."

# Find the directory where the script is located to source the .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    say "Error: The dot E N V file was not found. Please create it and fill in your project details."
    exit 1
fi

# Source the environment file
source "$ENV_FILE"

# Validate that the required variables are set
if [ -z "$GCP_PROJECT_ID" ] || [ "$GCP_PROJECT_ID" == "your-gcp-project-id-here" ]; then
    say "Error: Your Google Cloud Project I D is not set in the environment file."
    exit 1
fi

if [ -z "$GCP_KEY_FILE_PATH" ] || [ "$GCP_KEY_FILE_PATH" == "/path/to/your/service-account-key.json" ]; then
    say "Error: The path to your Google Cloud key file is not set in the environment file."
    exit 1
fi

if [ ! -f "$GCP_KEY_FILE_PATH" ]; then
    say "Error: The specified Google Cloud key file was not found at the path you provided."
    exit 1
fi

# --- Install Google Cloud SDK ---
if ! command -v gcloud &>/dev/null; then
    say "The Google Cloud command line tool is not installed. Installing it now."
    # Download and install quietly
    curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts >/dev/null 2>&1
    say "Google Cloud tool installed."
else
    say "The Google Cloud command line tool is already installed."
fi

# Source the Google Cloud SDK paths to make gcloud command available
# The installer adds this to .bashrc, but we need it for the current session.
source "$HOME/google-cloud-sdk/path.bash.inc"

# --- Authenticate and Configure Project ---
say "Authenticating with your Google Cloud account."
gcloud auth activate-service-account --key-file="$GCP_KEY_FILE_PATH"

say "Setting the project to $GCP_PROJECT_ID."
gcloud config set project "$GCP_PROJECT_ID"

# --- Install/Update Gemini Components ---
say "Installing the latest Gemini components."
gcloud components install alpha -q
gcloud components update -q

# --- Create a Speakable Alias ---
BASH_RC_PATH="$HOME/.bashrc"
CANDIDATE_ALIASES=("gemini" "genie" "gemma" "google" "assistant")
CHOSEN_ALIAS=""

for ALIAS_NAME in "${CANDIDATE_ALIASES[@]}"; do
    if ! grep -q "alias $ALIAS_NAME=" "$BASH_RC_PATH"; then
        CHOSEN_ALIAS=$ALIAS_NAME
        break
    fi
done

if [ -z "$CHOSEN_ALIAS" ]; then
    # If all common aliases are taken, create a unique one.
    CHOSEN_ALIAS="gemini$(date +%s)"
    say "All standard alias names were taken. A unique alias, $CHOSEN_ALIAS, has been created."
else
    say "The alias '$CHOSEN_ALIAS' will be used to run commands."
fi

# Add the alias to .bashrc
{
    echo -e "\n# Alias for Voice-Controlled Gemini CLI"
    echo "alias $CHOSEN_ALIAS='gcloud alpha gemini'"
} >>"$BASH_RC_PATH"

# --- Finalization ---
# Make the script itself executable
chmod +x "$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

say "Setup is complete. The alias is '$CHOSEN_ALIAS'. The system is now ready to accept Gemini commands."

# Note: We do not need to 'source .bashrc' here because the alias will be available
# in the next shell session, which is the intended use case for a voice assistant.
# The user's next spoken command will start a new shell and the alias will be active.
