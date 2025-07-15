#!/bin/bash

# --- Dynamic EC2 Orchestration Script ---
# Validates the environment, launches a new EC2 instance, and runs a series of
# specified installation scripts on it.

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
log_to_file "Script started. Loading environment."

if [ "$#" -lt 1 ]; then
    say "Error: You must provide at least one installer script name as an argument."
    log_master "CRITICAL: No installer scripts provided."
    log_to_file "CRITICAL: No installer scripts provided."
    echo "Usage: $0 [instance-name] [installer1.sh] [installer2.sh] ..."
    exit 1
fi

# --- Load .env file ---
if [ ! -f "$ENV_FILE" ]; then
    say "Error: The configuration file E C 2 setup dot E N V was not found."
    log_to_file "CRITICAL: Configuration file not found at $ENV_FILE"
    exit 1
fi
source "$ENV_FILE"
log_to_file "Configuration file loaded."

# --- 2. Set Instance Name and Installers ---
INSTANCE_NAME="$1"
shift # The rest of the arguments are the installer scripts
INSTALLER_SCRIPTS=("$@")
say "Preparing to launch instance '$INSTANCE_NAME' and run ${#INSTALLER_SCRIPTS[@]} installer(s)."
log_to_file "Instance Name: $INSTANCE_NAME"
log_to_file "Installers: ${INSTALLER_SCRIPTS[*]}"


# --- 3. Launch EC2 Instance ---
say "Requesting E C 2 instance launch."
log_to_file "Requesting EC2 instance launch in region $AWS_REGION."
# ... (rest of the script remains the same until remote installation)
INSTANCE_ID=$(aws ec2 run-instances \
    --region "$AWS_REGION" \
    --image-id "$EC2_AMI_ID" \
    --instance-type "${EC2_INSTANCE_TYPE:-t2.micro}" \
    --key-name "$EC2_KEY_NAME" \
    --security-group-ids "$EC2_SECURITY_GROUP_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    say "Error: Failed to launch the E C 2 instance."
    log_to_file "CRITICAL: Failed to launch EC2 instance."
    exit 1
fi

say "Instance created successfully with I D: $INSTANCE_ID"
log_to_file "Instance created with ID: $INSTANCE_ID"

# --- 4. Wait for Instance to be Ready ---
say "Waiting for the instance to enter the running state."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
log_to_file "Instance is now in 'running' state."

say "Waiting for system status checks to pass."
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
log_to_file "Instance status checks are now 'ok'."

PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
say "Instance is ready at Public I P: $PUBLIC_IP"
log_to_file "Instance ready. Public IP: $PUBLIC_IP"

# --- 5. Run Remote Installation Sequence ---
say "Beginning remote installation sequence."
log_master "Beginning remote installation sequence on $INSTANCE_ID."

# Wait for SSH to become available
say "Waiting for S S H to become available."
until ssh -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -i "$SSH_KEY_PATH" "$SSH_USERNAME@$PUBLIC_IP" exit 2>/dev/null; do
    say "Still waiting for S S H."
    log_to_file "Waiting for SSH..."
    sleep 10
done
log_to_file "SSH is ready."

for SCRIPT_NAME in "${INSTALLER_SCRIPTS[@]}"; do
    LOCAL_SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
    REMOTE_SCRIPT_PATH="/home/$SSH_USERNAME/$SCRIPT_NAME"

    if [ ! -f "$LOCAL_SCRIPT_PATH" ]; then
        say "Warning: Installer script '$SCRIPT_NAME' not found locally. Skipping."
        log_master "Skipping remote execution of $SCRIPT_NAME - file not found."
        log_to_file "Skipping $SCRIPT_NAME because it was not found at $LOCAL_SCRIPT_PATH."
        continue
    fi

    say "Transferring $SCRIPT_NAME to the remote instance."
    log_master "Handoff -> $SCRIPT_NAME (on remote instance)"
    scp -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$LOCAL_SCRIPT_PATH" "$SSH_USERNAME@$PUBLIC_IP:$REMOTE_SCRIPT_PATH"
    log_to_file "Copied $SCRIPT_NAME to remote instance."

    say "Executing $SCRIPT_NAME on the remote instance."
    ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "chmod +x $REMOTE_SCRIPT_PATH && $REMOTE_SCRIPT_PATH"
    log_to_file "Executed remote installation script: $SCRIPT_NAME."
    log_master "Return <- $SCRIPT_NAME (on remote instance)"
done

say "Orchestration Complete."
log_master "Finished."
log_to_file "Script finished successfully."
say "Your new server, $INSTANCE_NAME, is running at H T T P colon slash slash $PUBLIC_IP"
