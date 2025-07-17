#!/bin/bash

# --- Lucee Configuration Utilities ---
# Provides functions to validate and generate Lucee-specific credentials.

# Assumes the following variables are set in the calling script:
# - say()
# - log_to_file()
# - ROOT_DIR

LUCEE_ENV_FILE="$ROOT_DIR/lucee.env"
LUCEE_ENV_EXAMPLE_FILE="$ROOT_DIR/lucee.env.example"

validate_or_generate_lucee_password() {
    say "Validating Lucee administrator password."
    
    if [ ! -f "$LUCEE_ENV_FILE" ]; then
        say "Lucee environment file not found. Creating one from the example."
        cp "$LUCEE_ENV_EXAMPLE_FILE" "$LUCEE_ENV_FILE"
    fi

    source "$LUCEE_ENV_FILE"

    if [[ "${LUCEE_ADMIN_PASSWORD:-}" == "YOUR_LUCEE_PASSWORD_HERE" ]]; then
        say "Lucee admin password is a placeholder. Generating a new random password."
        log_to_file "Generating new Lucee admin password."
        
        local NEW_PASSWORD
        NEW_PASSWORD=$(openssl rand -base64 12)
        
        # Use sed to update the file, being careful with special characters
        sed -i.bak "s|YOUR_LUCEE_PASSWORD_HERE|$NEW_PASSWORD|g" "$LUCEE_ENV_FILE"
        rm "${LUCEE_ENV_FILE}.bak"
        
        # Export the variable to the current shell
        export LUCEE_ADMIN_PASSWORD="$NEW_PASSWORD"
        
        say "A new password has been generated and saved to the lucee dot env file."
        log_to_file "Generated and saved new Lucee admin password."
    else
        say "Using existing Lucee admin password from lucee dot env file."
        log_to_file "Using existing Lucee admin password."
    fi
    
    # Export the variable so the Lucee installer can see it
    export LUCEE_ADMIN_PASSWORD
}
