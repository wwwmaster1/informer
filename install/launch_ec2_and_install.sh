#!/bin/bash

# --- Universal EC2 Stack Launcher ---
# Provisions a new EC2 instance, clones a Git repository onto it, and then
# executes a stack installation based on .sh or .stack files.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MASTER_LOG_FILE="$SCRIPT_DIR/../install.log" # Log to root
EC2_LOG_FILE="$SCRIPT_DIR/../ec2_launch.log" # Log to root
LOG_FILE="$EC2_LOG_FILE"
ENV_FILE="$SCRIPT_DIR/../ec2_setup.env" # Env file is in root

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
    say "Error: You must provide an instance name and at least one installer or stack file."
    log_master "CRITICAL: Not enough arguments provided."
    echo "Usage: $0 [instance-name] [installer1.sh | stack1.stack] ..."
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    say "Error: The configuration file ec2_setup.env was not found in the project root."
    log_to_file "CRITICAL: Configuration file not found at $ENV_FILE"
    exit 1
fi
source "$ENV_FILE"
log_to_file "Configuration file loaded."

# --- 2. Launch EC2 Instance (No changes here) ---
INSTANCE_NAME="$1"
shift
INSTALL_ARGS=("$@")

say "Requesting E C 2 instance launch for '$INSTANCE_NAME'."
log_to_file "Requesting EC2 instance launch in region $AWS_REGION."
INSTANCE_ID=$(aws ec2 run-instances --region "$AWS_REGION" --image-id "$EC2_AMI_ID" --instance-type "${EC2_INSTANCE_TYPE:-t2.micro}" --key-name "$EC2_KEY_NAME" --security-group-ids "$EC2_SECURITY_GROUP_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" --query 'Instances[0].InstanceId' --output text)
if [ -z "$INSTANCE_ID" ]; then say "Error: Failed to launch E C 2 instance." && exit 1; fi
say "Instance created with I D: $INSTANCE_ID"
log_to_file "Instance created: $INSTANCE_ID"

say "Waiting for instance to be ready."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
say "Instance is ready at Public I P: $PUBLIC_IP"
log_to_file "Instance ready at $PUBLIC_IP"

# --- 3. Wait for SSH ---
say "Waiting for S S H to become available."
until ssh -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -i "$SSH_KEY_PATH" "$SSH_USERNAME@$PUBLIC_IP" exit 2>/dev/null; do
    say "Still waiting..." && sleep 10
done
log_to_file "SSH is ready."

# --- 4. Remote Execution (New Logic) ---
say "Beginning remote installation."
log_master "Beginning remote installation on $INSTANCE_ID."

# This is the command that will be run on the remote server.
# It changes directory into the cloned repo and runs the local stack installer.
REMOTE_COMMAND="cd /home/$SSH_USERNAME/gemini/install && ./install_stack.sh ${INSTALL_ARGS[*]}"

# If a Git repo is specified, clone it first. This is the preferred method.
if [ -n "$GIT_REPO_URL" ]; then
    say "Cloning repository from $GIT_REPO_URL onto the remote instance."
    log_master "Cloning remote repo: $GIT_REPO_URL"
    
    # Install git, clone the repo, then run the command.
    ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "sudo yum install -y git && git clone --branch ${GIT_BRANCH:-main} ${GIT_REPO_URL} /home/${SSH_USERNAME}/gemini && ${REMOTE_COMMAND}"
    
else
    # Fallback for local development: copy the files and run the command.
    say "No Git repository specified. Copying local installers instead."
    log_master "No Git repo specified. Using local file transfer."
    
    # Create the directory structure
    ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "mkdir -p /home/$SSH_USERNAME/gemini/install"
    
    # Copy the entire contents of the local install directory
    scp -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" -r "$SCRIPT_DIR"/* "$SSH_USERNAME@$PUBLIC_IP:/home/$SSH_USERNAME/gemini/install/"
    
    # Run the command
    ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "$REMOTE_COMMAND"
fi

say "Orchestration Complete."
log_master "Finished."
log_to_file "Script finished successfully."
say "Your new server, $INSTANCE_NAME, is running at H T T P colon slash slash $PUBLIC_IP"
