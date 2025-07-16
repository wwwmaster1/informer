#!/bin/bash

# --- Enhanced TTS Installation and Management Script ---
# This script validates the environment, installs all prerequisites including the AWS CLI,
# and sets up a voice-enabled shell environment on a Linux EC2 instance.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
say() {
    echo "$1"
}

log_note() {
    echo "- $1" >>"$NOTES_FILE"
}

update_env_var() {
    local key=$1
    local value=$2
    sed -i "s|^$key=.*|$key=\"$value\"|" "$ENV_FILE"
}

# --- 1. Initial Configuration and Validation ---
say "Starting the text to speech system setup."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ENV_FILE="$SCRIPT_DIR/tts_setup.env"
NOTES_FILE="$SCRIPT_DIR/NOTES.md"
BASH_RC_PATH="$HOME/.bashrc"

# --- Validation Block ---
say "Performing system and configuration validation."

# Validate that the .env file exists
if [ ! -f "$ENV_FILE" ]; then
    say "Error: The environment file named tts_setup.env was not found in the script's directory. Please create it before proceeding."
    exit 1
fi

# Source the environment file to load variables
source "$ENV_FILE"

# Validate that the .bashrc file exists
if [ ! -f "$BASH_RC_PATH" ]; then
    say "Error: The .bashrc file was not found in your home directory. This file is required to set up the command alias."
    exit 1
}

# Validate that the user has sudo privileges
if ! sudo -n true 2>/dev/null; then
    say "Error: This script requires passwordless sudo privileges to install system packages. Please configure sudo access."
    exit 1
fi

say "Validation complete. All initial checks passed."
# --- End of Validation Block ---


# --- 2. Install Prerequisites ---
say "Checking for prerequisite packages."

# Install curl and unzip, required for AWS CLI installation
if ! command -v curl &>/dev/null || ! command -v unzip &>/dev/null; then
    say "Installing curl and unzip, which are needed for setup."
    sudo yum update -y >/dev/null
    sudo yum install -y curl unzip >/dev/null
    say "Prerequisites installed."
else
    say "Core prerequisites are already installed."
fi

# --- 3. Install and Configure AWS CLI ---
if ! command -v aws &>/dev/null; then
    say "The A W S Command Line Interface is not installed. Installing it now."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" >/dev/null
    unzip awscliv2.zip >/dev/null
    sudo ./aws/install >/dev/null
    rm -rf awscliv2.zip aws
    say "A W S C L I installed."
else
    say "The A W S Command Line Interface is already installed."
fi

# Configure AWS CLI if credentials are provided in the .env file
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    say "Configuring A W S C L I with credentials from the environment file."
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
    aws configure set region "$AWS_REGION"
    log_note "Configured AWS CLI with provided credentials."
else
    say "Skipping A W S C L I configuration. The system will rely on the I A M role."
fi


# --- 4. Install and Manage TTS Engine ---
say "Checking for the text to speech engine."
if ! command -v espeak-ng &>/dev/null; then
    say "The e-speak-next-generation text to speech engine is not installed. Installing it now."
    sudo yum install -y espeak-ng >/dev/null
    say "Installation of e-speak complete."
else
    say "The e-speak text to speech engine is already installed."
fi

# Version Management Logic (same as before)
if [[ "$UPDATE" == "latest" ]]; then
    say "Updating the text to speech engine to the latest version."
    sudo yum update -y espeak-ng >/dev/null
    log_note "Updated TTS engine to the latest version at $(date -u)."
elif [ -n "$VERSION" ]; then
    say "Attempting to install version $VERSION of the text to speech engine."
    if sudo yum install -y "espeak-ng-$VERSION" >/dev/null 2>&1; then
        say "Successfully installed version $VERSION."
        log_note "Installed specific version $VERSION of TTS engine at $(date -u)."
    else
        say "Warning: Version $VERSION could not be installed. The currently installed version will be used instead."
        log_note "Attempted to install version $VERSION of TTS engine but failed."
    fi
fi


# --- 5. Create Speakable Alias and Help Function ---
say "Setting up the voice command alias."
CANDIDATE_ALIASES=("say" "speak" "utter")
CHOSEN_ALIAS=""

for ALIAS_NAME in "${CANDIDATE_ALIASES[@]}"; do
    if ! grep -q "alias $ALIAS_NAME=" "$BASH_RC_PATH"; then
        CHOSEN_ALIAS=$ALIAS_NAME
        break
    fi
done

if [ -z "$CHOSEN_ALIAS" ]; then
    CHOSEN_ALIAS="mpg"
    say "All standard alias names were taken, so the alias was set to M P G."
fi

# Add the TTS function and alias to .bashrc
if ! grep -q "tts_speak()" "$BASH_RC_PATH"; then
    echo -e "\n# Function for Text-to-Speech\ntts_speak() { espeak-ng -v en-us -s 150 \"\$@\"; }" >> "$BASH_RC_PATH"
    echo "alias $CHOSEN_ALIAS='tts_speak'" >> "$BASH_RC_PATH"
    say "The alias '$CHOSEN_ALIAS' is now set to speak text."
    log_note "Set the TTS alias to '$CHOSEN_ALIAS'."
fi

# Add the help function and alias to .bashrc
if ! grep -q "tts_help()" "$BASH_RC_PATH"; then
    HELP_FUNCTION_DEFINITION="\n# Function to provide help for the TTS system\ntts_help() { say \"You can use the command '$CHOSEN_ALIAS' followed by the text you want to hear. For example, '$CHOSEN_ALIAS' hello world.\"; }\n"
    echo -e "$HELP_FUNCTION_DEFINITION" >> "$BASH_RC_PATH"
    echo "alias ttshelp='tts_help'" >> "$BASH_RC_PATH"
    say "You can say 'ttshelp' to hear instructions again."
fi


# --- 6. Update Environment and Notes ---
say "Updating system information."
PUBLIC_IP_ADDR=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "not available")
PUBLIC_HOSTNAME_VAL=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname || echo "not available")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

update_env_var "PUBLIC_IP" "$PUBLIC_IP_ADDR"
update_env_var "PUBLIC_HOSTNAME" "$PUBLIC_HOSTNAME_VAL"
update_env_var "TTS_ALIAS" "$CHOSEN_ALIAS"
update_env_var "LAST_UPDATE_TIMESTAMP" "$TIMESTAMP"

log_note "System information updated at $TIMESTAMP. Public IP is $PUBLIC_IP_ADDR."


# --- 7. Finalization ---
chmod +x "$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
say "Setup is complete. The text to speech system is ready. The alias is '$CHOSEN_ALIAS'."
say "Please start a new shell session or reload your shell to use the new command."