#!/bin/bash

# --- Universal EC2 Stack Launcher ---
# Validates the environment, launches a new EC2 instance, and installs a
# dynamic stack based on .sh or .stack files provided as arguments.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MASTER_LOG_FILE="$SCRIPT_DIR/install.log"
EC2_LOG_FILE="$SCRIPT_DIR/ec2_launch.log"
LOG_FILE="$EC2_LOG_FILE"
ENV_FILE="$SCRIPT_DIR/ec2_setup.env"

say() {
    echo "{$1}"
}

log_master() {
    echo "$(date +%s): [launch_ec2_and_install.sh] $1" >>"$MASTER_LOG_FILE"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- 1. Argument and Configuration Validation ---
log_master "Started."
say "Loading configuration and validating prerequisites."
log_to_file "Script started."

if [ "$#" -lt 2 ]; then
    say "Error: You must provide an instance name and at least one installer script (.sh) or stack file (.stack)."
    log_master "CRITICAL: Not enough arguments provided."
    echo "Usage: $0 [instance-name] [installer1.sh | stack1.stack] ..."
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    say "Error: The configuration file E C 2 setup dot E N V was not found."
    log_to_file "CRITICAL: Configuration file not found at $ENV_FILE"
    exit 1
fi
source "$ENV_FILE"
log_to_file "Configuration file loaded."

# --- 2. Parse Arguments and Build Installer List ---
INSTANCE_NAME="$1"
shift
ARGUMENTS=("$@")
INSTALLER_SEQUENCE=()
UNIQUE_INSTALLERS=()

say "Parsing arguments to build installation sequence."
log_to_file "Parsing arguments: ${ARGUMENTS[*]}"

for ARG in "${ARGUMENTS[@]}"; do
    if [[ "$ARG" == *.stack ]]; then
        log_to_file "Found stack file: $ARG. Reading for installers."
        STACK_FILE="$SCRIPT_DIR/$ARG"
        if [ -f "$STACK_FILE" ]; then
            # Use grep and cut to parse 'installer: script.sh' lines
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

# Create a list of unique installer files to copy
UNIQUE_INSTALLERS=($(printf "%s\n" "${INSTALLER_SEQUENCE[@]}" | sort -u))

say "Plan: Launch instance '$INSTANCE_NAME', copy ${#UNIQUE_INSTALLERS[@]} script(s), and execute ${#INSTALLER_SEQUENCE[@]} installation(s)."
log_to_file "Execution Plan: Copy [${UNIQUE_INSTALLERS[*]}] and run [${INSTALLER_SEQUENCE[*]}]"

# --- 3. Launch EC2 Instance ---
# (This section remains the same)
say "Requesting E C 2 instance launch."
log_to_file "Requesting EC2 instance launch in region $AWS_REGION."
INSTANCE_ID=$(aws ec2 run-instances --region "$AWS_REGION" --image-id "$EC2_AMI_ID" --instance-type "${EC2_INSTANCE_TYPE:-t2.micro}" --key-name "$EC2_KEY_NAME" --security-group-ids "$EC2_SECURITY_GROUP_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" --query 'Instances[0].InstanceId' --output text)
if [ -z "$INSTANCE_ID" ]; then say "Error: Failed to launch E C 2 instance." && exit 1; fi
say "Instance created with I D: $INSTANCE_ID"
log_to_file "Instance created: $INSTANCE_ID"

# --- 4. Wait for Instance to be Ready ---
# (This section remains the same)
say "Waiting for instance to enter the running state."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
say "Waiting for system status checks to pass."
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
say "Instance is ready at Public I P: $PUBLIC_IP"
log_to_file "Instance ready at $PUBLIC_IP"

# --- 5. Run Remote Installation Sequence ---
say "Beginning remote installation sequence."
log_master "Beginning remote installation sequence on $INSTANCE_ID."

# Wait for SSH
say "Waiting for S S H."
until ssh -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -i "$SSH_KEY_PATH" "$SSH_USERNAME@$PUBLIC_IP" exit 2>/dev/null; do
    say "Still waiting..." && sleep 10
done
log_to_file "SSH is ready."

# Copy all unique installer scripts at once
say "Transferring all required installation scripts."
for SCRIPT_NAME in "${UNIQUE_INSTALLERS[@]}"; do
    LOCAL_SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
    REMOTE_SCRIPT_PATH="/home/$SSH_USERNAME/$SCRIPT_NAME"
    if [ -f "$LOCAL_SCRIPT_PATH" ]; then
        scp -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$LOCAL_SCRIPT_PATH" "$SSH_USERNAME@$PUBLIC_IP:$REMOTE_SCRIPT_PATH"
        log_to_file "Copied $SCRIPT_NAME to remote instance."
    fi
done

# Execute the installers in the specified sequence
say "Executing installation scripts in sequence."
for SCRIPT_NAME in "${INSTALLER_SEQUENCE[@]}"; do
    REMOTE_SCRIPT_PATH="/home/$SSH_USERNAME/$SCRIPT_NAME"
    say "Executing $SCRIPT_NAME on the remote instance."
    log_master "Handoff -> $SCRIPT_NAME (on remote instance)"
    ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "chmod +x $REMOTE_SCRIPT_PATH && $REMOTE_SCRIPT_PATH"
    log_to_file "Executed remote script: $SCRIPT_NAME."
    log_master "Return <- $SCRIPT_NAME (on remote instance)"
done

say "Orchestration Complete."
log_master "Finished."
log_to_file "Script finished successfully."
say "Your new server, $INSTANCE_NAME, is running at H T T P colon slash slash $PUBLIC_IP"