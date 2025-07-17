#!/bin/bash

# --- Universal EC2 Stack Launcher ---
# Validates environment, generates credentials if needed, provisions an EC2
# instance, and installs a dynamic software stack.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
MASTER_LOG_FILE="$ROOT_DIR/install.log"
EC2_LOG_FILE="$ROOT_DIR/ec2_launch.log"
LOG_FILE="$EC2_LOG_FILE"
ENV_FILE="$ROOT_DIR/ec2_setup.env"
ENV_EXAMPLE_FILE="$ROOT_DIR/ec2_setup.env.example"

say() {
    echo "{$1}"
}

log_master() {
    echo "$(date +%s): [launch_ec2_and_install.sh] $1" >>"$MASTER_LOG_FILE"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Credential Validation and Generation ---
# Source the shared credential utility script
source "$ROOT_DIR/credential_utils.sh"


# --- Main Execution ---
log_master "Started."
say "Loading configuration."
log_to_file "Script started."

# 1. Validate or Generate Credentials
validate_or_generate_credentials

# 2. Parse Arguments
if [ "$#" -lt 2 ]; then
    say "Error: You must provide an instance name and at least one installer or stack file."
    exit 1
fi
INSTANCE_NAME="$1"
shift
INSTALL_ARGS=("$@")

# 3. Launch EC2 Instance
# (The rest of the script remains the same as the previous version)
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

say "Waiting for S S H to become available."
until ssh -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -i "$SSH_KEY_PATH" "$SSH_USERNAME@$PUBLIC_IP" exit 2>/dev/null; do
    say "Still waiting..." && sleep 10
done
log_to_file "SSH is ready."

say "Beginning remote installation."
log_master "Beginning remote installation on $INSTANCE_ID."
REMOTE_COMMAND="cd /home/$SSH_USERNAME/gemini/install && ./install_stack.sh ${INSTALL_ARGS[*]}"

if [ -n "$GIT_REPO_URL" ]; then
    say "Cloning repository from $GIT_REPO_URL onto the remote instance."
    log_master "Cloning remote repo: $GIT_REPO_URL"
    ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "sudo yum install -y git && git clone --branch ${GIT_BRANCH:-main} ${GIT_REPO_URL} /home/${SSH_USERNAME}/gemini && ${REMOTE_COMMAND}"
else
    say "No Git repository specified. Copying local installers instead."
    log_master "No Git repo specified. Using local file transfer."
    ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "mkdir -p /home/$SSH_USERNAME/gemini/install"
    scp -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" -r "$SCRIPT_DIR"/* "$SSH_USERNAME@$PUBLIC_IP:/home/$SSH_USERNAME/gemini/install/"
    ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "$REMOTE_COMMAND"
fi

say "Orchestration Complete."
log_master "Finished."
log_to_file "Script finished successfully."
say "Your new server, $INSTANCE_NAME, is running at H T T P colon slash slash $PUBLIC_IP"