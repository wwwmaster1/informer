#!/bin/bash

# --- Credential Utilities Library ---
# Provides granular functions to validate and generate deployment credentials.
# Intended to be sourced by orchestrator scripts.

# Assumes the following variables are set in the calling script:
# - say()
# - log_master()
# - log_to_file()
# - ROOT_DIR
# - ENV_FILE
# - ENV_EXAMPLE_FILE

_create_env_backup() {
    # Only create one backup per run.
    if [ -z "$BACKUP_FILE" ]; then
        BACKUP_FILE="${ENV_FILE}.bak.$(date +%s)"
        say "Backing up existing configuration to a new file."
        cp "$ENV_FILE" "$BACKUP_FILE"
        log_to_file "Backed up old env file to $BACKUP_FILE"
    fi
}

ensure_aws_auth() {
    say "Checking A W S authentication."
    if [ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ]; then
        say "Using exported A W S access keys."
        log_master "Using exported AWS access keys for authentication."
        return 0
    fi
    if aws sts get-caller-identity >/dev/null 2>&1; then
        say "A W S C L I is configured. Proceeding."
        log_master "Using configured AWS CLI profile for authentication."
    else
        say "Error: A W S authentication failed. Please either configure the A W S C L I with 'aws configure' or export your A W S_ACCESS_KEY_ID and A W S_SECRET_ACCESS_KEY."
        log_master "CRITICAL: AWS authentication failed."
        exit 1
    fi
}

ensure_ssh_key() {
    say "Validating local S S H key."
    
    # If the path is the default placeholder, generate a new key.
    if [[ "${SSH_KEY_PATH:-}" == "/path/to/your/private-key.pem" ]]; then
        say "S S H key path is a placeholder. Generating a new key."
        log_master "Generating new SSH key pair."
        _create_env_backup

        local KEY_NAME="deployment-$(date +%s)"
        local KEY_FILE_BASE="$ROOT_DIR/$KEY_NAME"
        ssh-keygen -t rsa -b 4096 -f "$KEY_FILE_BASE" -N "" -C "$KEY_NAME"
        chmod 400 "$KEY_FILE_BASE"
        log_to_file "Generated new SSH key at $KEY_FILE_BASE"
        
        sed -i.bak "s|/path/to/your/private-key.pem|$KEY_FILE_BASE|g" "$ENV_FILE"
        rm "${ENV_FILE}.bak"
        export SSH_KEY_PATH="$KEY_FILE_BASE"
    
    # If the path is set but the file doesn't exist, it's an error.
    elif [ ! -f "${SSH_KEY_PATH:-}" ]; then
        say "Error: The S S H key specified in your ec2_setup.env file was not found at the path: $SSH_KEY_PATH"
        log_master "CRITICAL: SSH key file not found at specified path: ${SSH_KEY_PATH}"
        exit 1
    # If the file exists, check its permissions.
    else
        local perms
        perms=$(stat -c "%a" "$SSH_KEY_PATH")
        if [[ "$perms" != "400" && "$perms" != "600" ]]; then
            say "Warning: Your S S H key has incorrect permissions. Fixing them now to 400."
            log_to_file "Correcting permissions for $SSH_KEY_PATH from $perms to 400."
            chmod 400 "$SSH_KEY_PATH"
        fi
    fi
    
    say "S S H key is valid."
    log_to_file "SSH key at $SSH_KEY_PATH is valid."
}

ensure_ec2_key_pair() {
    say "Validating A W S E C 2 Key Pair."
    if [[ "${EC2_KEY_NAME:-}" == "your-ec2-key-name" ]]; then
        say "E C 2 Key Pair name is a placeholder. Importing the local S S H key into A W S."
        log_master "Importing SSH key to EC2."
        _create_env_backup

        local EC2_KEY_NAME_GEN
        EC2_KEY_NAME_GEN=$(basename "$SSH_KEY_PATH")
        
        say "Importing public key to A W S as '$EC2_KEY_NAME_GEN'."
        aws ec2 import-key-pair --key-name "$EC2_KEY_NAME_GEN" --public-key-material fileb://"${SSH_KEY_PATH}.pub"
        log_to_file "Imported public key to AWS as $EC2_KEY_NAME_GEN"

        sed -i.bak "s/your-ec2-key-name/$EC2_KEY_NAME_GEN/g" "$ENV_FILE"
        rm "${ENV_FILE}.bak"
        export EC2_KEY_NAME="$EC2_KEY_NAME_GEN"
    fi
    say "E C 2 Key Pair is configured."
    log_to_file "EC2 Key Pair $EC2_KEY_NAME is configured."
}

validate_and_prepare_deployment() {
    say "Starting deployment validation."
    
    if [ ! -f "$ENV_FILE" ]; then
        say "Configuration file not found. Creating one from the example."
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
    fi
    
    # Source the environment file, exporting all its variables to the shell.
    set -a
    source "$ENV_FILE"
    set +a

    ensure_aws_auth
    ensure_ssh_key
    ensure_ec2_key_pair

    if [ -n "$BACKUP_FILE" ]; then
        say "Credential configuration was updated. Please review the changes."
        log_to_file "Created new credentials and updated $ENV_FILE."
    else
        say "All deployment credentials are valid."
    fi
    
    # Re-source one last time to ensure the calling script has all final values
    source "$ENV_FILE"
}