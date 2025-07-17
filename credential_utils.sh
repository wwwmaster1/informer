#!/bin/bash

# --- Credential Utilities ---
# A library of shared functions for validating and generating deployment
# credentials, such as SSH keys and .env files.

# This script is intended to be sourced by other scripts, not executed directly.
# It assumes that helper functions like say() and log_master() are defined
# in the calling script.

validate_or_generate_credentials() {
    say "Validating deployment credentials."
    
    if [ ! -f "$ENV_FILE" ]; then
        say "Configuration file not found. Creating one from the example."
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
    fi

    # Temporarily source to check variables
    source "$ENV_FILE"

    # Check for placeholders or missing key file
    if [[ "${EC2_KEY_NAME:-}" == "your-ec2-key-name" ]] || [[ "${SSH_KEY_PATH:-}" == "/path/to/your/private-key.pem" ]] || [ ! -f "${SSH_KEY_PATH:-}" ]; then
        say "Deployment credentials are incomplete or missing. Generating new credentials now."
        log_master "Generating new deployment credentials."

        # 1. Backup old file
        BACKUP_FILE="${ENV_FILE}.bak.$(date +%s)"
        say "Backing up existing configuration to $BACKUP_FILE"
        cp "$ENV_FILE" "$BACKUP_FILE"
        log_to_file "Backed up old env file to $BACKUP_FILE"

        # 2. Generate new SSH key pair in the root directory
        KEY_NAME="gemini-deployment-$(date +%s)"
        KEY_FILE_BASE="$ROOT_DIR/$KEY_NAME"
        say "Generating a new 4096-bit SSH key pair named $KEY_NAME."
        ssh-keygen -t rsa -b 4096 -f "$KEY_FILE_BASE" -N "" -C "$KEY_NAME"
        chmod 400 "$KEY_FILE_BASE"
        log_to_file "Generated new SSH key at $KEY_FILE_BASE"

        # 3. Import the public key to AWS EC2
        say "Importing the new public key to A W S E C 2 with the name $KEY_NAME."
        aws ec2 import-key-pair --key-name "$KEY_NAME" --public-key-material fileb://"${KEY_FILE_BASE}.pub"
        log_to_file "Imported public key to AWS as $KEY_NAME"

        # 4. Create a new, populated .env file from the example
        say "Creating a new, updated ec2_setup.env file."
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        
        # 5. Use sed to replace placeholders with new values
        sed -i.bak "s|your-ec2-key-name|$KEY_NAME|g" "$ENV_FILE"
        sed -i.bak "s|/path/to/your/private-key.pem|$KEY_FILE_BASE|g" "$ENV_FILE"
        rm "${ENV_FILE}.bak" # Clean up sed's backup file
        log_to_file "Created new $ENV_FILE with generated credentials."

        say "New credentials have been generated and saved."
    else
        say "Valid credentials found. Proceeding with deployment."
        log_master "Using existing deployment credentials."
    fi
    
    # Re-source the file in the calling script's context to ensure it has the latest variables
    source "$ENV_FILE"
}
