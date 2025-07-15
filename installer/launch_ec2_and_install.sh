#!/bin/bash

# --- EC2 Orchestration Script ---
# Validates the environment, launches a new EC2 instance, and runs a setup script on it.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MASTER_LOG_FILE="$SCRIPT_DIR/install.log"
EC2_LOG_FILE="$SCRIPT_DIR/ec2_launch.log"
LOG_FILE="$EC2_LOG_FILE" # For existing log_to_file calls
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

# --- 1. Load Configuration and Validate ---
log_master "Started."
say "Loading configuration and validating prerequisites."
log_to_file "Script started. Loading environment."

# --- Validation Block ---
if [ ! -f "$ENV_FILE" ]; then
    say "Error: The configuration file named E C 2 setup dot E N V was not found."
    log_to_file "CRITICAL: Configuration file not found at $ENV_FILE"
    exit 1
fi
source "$ENV_FILE"
log_to_file "Configuration file loaded."

# Validate required variables
if [ -z "$EC2_KEY_NAME" ] || [ -z "$EC2_SECURITY_GROUP_ID" ] || [ -z "$SSH_KEY_PATH" ] || [ -z "$SSH_USERNAME" ] || [ -z "$AWS_REGION" ] || [ -z "$EC2_AMI_ID" ]; then
    say "Error: One or more required variables are missing from your E C 2 setup dot E N V file."
    log_to_file "CRITICAL: Missing one or more required variables in $ENV_FILE"
    exit 1
fi

# Validate SSH key file existence
if [ ! -f "$SSH_KEY_PATH" ]; then
    say "Error: The S S H private key file was not found at the path you specified."
    log_to_file "CRITICAL: SSH key file not found at $SSH_KEY_PATH"
    exit 1
fi

# Validate required commands
log_master "Handoff -> install_aws_cli.sh"
say "Checking for A W S C L I."
log_to_file "Handing off to AWS CLI installer."
bash "$SCRIPT_DIR/install_aws_cli.sh"
say "Resuming E C 2 launch."
log_to_file "Returned from AWS CLI installer."
log_master "Return <- install_aws_cli.sh"

if ! command -v ssh &>/dev/null || ! command -v scp &>/dev/null; then
    say "Error: An S S H client is required. Please install S S H and S C P."
    log_to_file "CRITICAL: 'ssh' or 'scp' command not found."
    exit 1
fi

say "Validation successful. All prerequisites are met."
log_to_file "Validation complete."
# --- End of Validation Block ---

# --- 2. Set Instance Name ---
INSTANCE_NAME="WebServer-Launched-By-Script"
if [ -n "$1" ]; then
    INSTANCE_NAME="$1"
    say "A custom instance name was provided. The new instance will be named $INSTANCE_NAME."
    log_to_file "Using custom instance name: $INSTANCE_NAME"
else
    say "No custom instance name was provided. Using the default name: $INSTANCE_NAME."
    log_to_file "Using default instance name: $INSTANCE_NAME"
fi

# --- 3. Launch EC2 Instance ---
say "Requesting E C 2 instance launch. This may take a moment."
log_to_file "Requesting EC2 instance launch in region $AWS_REGION."

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
    say "Error: Failed to launch the E C 2 instance. Please check your A W S C L I configuration and permissions."
    log_to_file "CRITICAL: Failed to launch EC2 instance."
    exit 1
fi

say "Instance created successfully with I D: $INSTANCE_ID"
log_to_file "Instance created with ID: $INSTANCE_ID"

# --- 4. Wait for Instance to be Ready ---
say "Waiting for the instance to enter the running state."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
log_to_file "Instance is now in 'running' state."

say "Waiting for system status checks to pass. This can take a few minutes."
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
log_to_file "Instance status checks are now 'ok'."

PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
say "Instance is ready at Public I P: $PUBLIC_IP"
log_to_file "Instance ready. Public IP: $PUBLIC_IP"

# --- 5. Run Remote Installation ---
INSTALL_SCRIPT_NAME="install_apache.sh"
LOCAL_INSTALL_SCRIPT="$SCRIPT_DIR/$INSTALL_SCRIPT_NAME"
REMOTE_SCRIPT_PATH="/home/$SSH_USERNAME/$INSTALL_SCRIPT_NAME"

if [ ! -f "$LOCAL_INSTALL_SCRIPT" ]; then
    say "Error: The installation script named install web server dot S H was not found."
    log_to_file "CRITICAL: Installation script not found at $LOCAL_INSTALL_SCRIPT"
    exit 1
fi

say "Waiting for S S H to become available."
until ssh -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -i "$SSH_KEY_PATH" "$SSH_USERNAME@$PUBLIC_IP" exit 2>/dev/null; do
    say "Still waiting for S S H."
    log_to_file "Waiting for SSH..."
    sleep 10
done

say "S S H is ready. Copying the installation script to the instance."
log_master "Handoff -> $INSTALL_SCRIPT_NAME (on remote instance)"
scp -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$LOCAL_INSTALL_SCRIPT" "$SSH_USERNAME@$PUBLIC_IP:$REMOTE_SCRIPT_PATH"
log_to_file "Copied $INSTALL_SCRIPT_NAME to remote instance."

say "Executing the installation script on the instance."
ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "chmod +x $REMOTE_SCRIPT_PATH && $REMOTE_SCRIPT_PATH"
log_to_file "Executed remote installation script."
log_master "Return <- $INSTALL_SCRIPT_NAME (on remote instance)"

say "Orchestration Complete."
log_to_file "Script finished successfully."
say "Your new web server is running at H T T P colon slash slash $PUBLIC_IP"