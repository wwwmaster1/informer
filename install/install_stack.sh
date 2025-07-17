#!/bin/bash

# --- Local Stack Installer ---
# Reads installer scripts (.sh) or stack manifests (.stack) and executes
# them on the local machine to install a complete software stack.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MASTER_LOG_FILE="$SCRIPT_DIR/install.log"
LOCAL_INSTALL_LOG_FILE="$SCRIPT_DIR/local_stack_install.log"
LOG_FILE="$LOCAL_INSTALL_LOG_FILE"

say() {
    echo "{$1}"
}

log_master() {
    echo "$(date +%s): [install_stack.sh] $1" >>"$MASTER_LOG_FILE"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- 1. Argument Parsing ---
log_master "Started."
say "Starting local stack installation."
log_to_file "Script started."

if [ "$#" -lt 1 ]; then
    say "Error: You must provide at least one installer script (.sh) or stack file (.stack)."
    log_master "CRITICAL: No arguments provided."
    echo "Usage: $0 [installer1.sh | stack1.stack] ..."
    exit 1
fi

ARGUMENTS=("$@")
INSTALLER_SEQUENCE=()

say "Parsing arguments to build installation sequence."
log_to_file "Parsing arguments: ${ARGUMENTS[*]}"

for ARG in "${ARGUMENTS[@]}"; do
    if [[ "$ARG" == *.stack ]]; then
        log_to_file "Found stack file: $ARG. Reading for installers."
        STACK_FILE="$SCRIPT_DIR/$ARG"
        if [ -f "$STACK_FILE" ]; then
            while IFS= read -r SCRIPT_NAME; do
                INSTALLER_SEQUENCE+=("$SCRIPT_NAME")
            done < <(grep -E '^installer:' "$STACK_FILE" | cut -d' ' -f2)
        else
            say "Warning: Stack file '$ARG' not found. Skipping."
            log_to_file "Stack file not found: $STACK_FILE. Skipping."
        fi
    elif [[ "$ARG" == *.sh ]]; then
        INSTALLER_SEQUENCE+=("$ARG")
    else
        say "Warning: Argument '$ARG' is not a valid .sh or .stack file. Skipping."
        log_to_file "Invalid argument skipped: $ARG"
    fi
done

say "Plan: Executing ${#INSTALLER_SEQUENCE[@]} installation script(s) locally."
log_to_file "Execution Plan: [${INSTALLER_SEQUENCE[*]}]"

# --- 2. Execute Installation Sequence ---
say "Beginning local installation sequence."
log_master "Beginning local installation sequence."

for SCRIPT_NAME in "${INSTALLER_SEQUENCE[@]}"; do
    LOCAL_SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

    if [ ! -f "$LOCAL_SCRIPT_PATH" ]; then
        say "Warning: Installer script '$SCRIPT_NAME' not found. Skipping."
        log_master "Skipping local execution of $SCRIPT_NAME - file not found."
        log_to_file "Skipping $SCRIPT_NAME because it was not found at $LOCAL_SCRIPT_PATH."
        continue
    fi

    say "Executing $SCRIPT_NAME locally."
    log_master "Handoff -> $SCRIPT_NAME (local)"
    bash "$LOCAL_SCRIPT_PATH"
    log_to_file "Finished executing script: $SCRIPT_NAME."
    log_master "Return <- $SCRIPT_NAME (local)"
done

say "Local stack installation is complete."
log_master "Finished."
log_to_file "Script finished successfully."
