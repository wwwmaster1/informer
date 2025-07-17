#!/bin/bash

# --- Universal EC2 Stack Launcher ---
# Validates environment, generates credentials if needed, provisions an EC2
# instance, and optionally installs a dynamic software stack.

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
source "$ROOT_DIR/install/utils/credential_utils.sh"


# --- Main Execution ---
log_master "Started."
say "Loading configuration."
log_to_file "Script started."

# 1. Validate or Generate Credentials
validate_and_prepare_deployment

# 2. Parse Arguments
if [ -z "$1" ]; then
    say "No instance name provided. Generating a default name."
    INSTANCE_NAME="deployment-server-$(date +%s)"
    log_to_file "Generated instance name: $INSTANCE_NAME"
    INSTALL_ARGS=("$@")
else
    INSTANCE_NAME="$1"
    shift
    INSTALL_ARGS=("$@")
fi

# 3. Launch EC2 Instance
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

# --- 4. Conditional Remote Installation ---
if [ ${#INSTALL_ARGS[@]} -gt 0 ]; then
    say "Waiting for S S H to become available."
    log_to_file "Attempting to establish SSH connection..."
    max_attempts=15
    attempt_num=1
    # We add -v to get verbose output and redirect stderr (2) to our log file for debugging.
    until ssh -v -o "StrictHostKeyChecking=no" -o "ConnectTimeout=10" -o "ConnectionAttempts=1" -i "$SSH_KEY_PATH" "$SSH_USERNAME@$PUBLIC_IP" exit >/dev/null 2>>"$LOG_FILE"; do
        if [ $attempt_num -ge $max_attempts ]; then
            say "Error: Could not establish an S S H connection after $max_attempts attempts."
            log_master "CRITICAL: SSH connection timed out."
            log_to_file "Check this log for SSH connection errors. Common issues include incorrect security group rules (port 22 must be open), or wrong local SSH key permissions (should be 400)."
            exit 1
        fi
        say "Still waiting for S S H... (Attempt $attempt_num of $max_attempts)"
        log_to_file "SSH attempt $attempt_num failed. Retrying in 10 seconds."
        sleep 10
        attempt_num=$((attempt_num+1))
    done
    log_to_file "SSH connection established successfully."

    say "Beginning remote installation."
    log_master "Beginning remote installation on $INSTANCE_ID."

    if [ -n "$REPO_DIR_NAME" ]; then
        REPO_NAME="$REPO_DIR_NAME"
    elif [ -n "$GIT_REPO_URL" ]; then
        REPO_NAME=$(basename "$GIT_REPO_URL" .git)
    else
        REPO_NAME="informer" # Default for local file transfer
    fi
    log_to_file "Using remote repository directory name: $REPO_NAME"

    REMOTE_PROJECT_PATH="/home/$SSH_USERNAME/$REPO_NAME"
    REMOTE_COMMAND="cd $REMOTE_PROJECT_PATH/install && chmod +x install_stack.sh && ./install_stack.sh ${INSTALL_ARGS[*]}"

    if [ -n "$GIT_REPO_URL" ]; then
        say "Cloning repository from $GIT_REPO_URL into ~/$REPO_NAME on the remote instance."
        log_master "Cloning remote repo: $GIT_REPO_URL"
        ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "sudo yum install -y git && git clone --branch ${GIT_BRANCH:-main} ${GIT_REPO_URL} ${REMOTE_PROJECT_PATH} && ${REMOTE_COMMAND}"
    else
        say "No Git repository specified. Copying local installers to ~/$REPO_NAME instead."
        log_master "No Git repo specified. Using local file transfer."
        ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "mkdir -p $REMOTE_PROJECT_PATH/install"
        scp -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" -r "$SCRIPT_DIR"/* "$SSH_USERNAME@$PUBLIC_IP:$REMOTE_PROJECT_PATH/install/"
        ssh -i "$SSH_KEY_PATH" -o "StrictHostKeyChecking=no" "$SSH_USERNAME@$PUBLIC_IP" "$REMOTE_COMMAND"
    fi
else
    say "No installer scripts were provided. Provisioning a bare instance."
    log_master "No installers provided. Skipping installation."
fi

# --- 5. Final Success Message ---
say "Orchestration Complete."
log_master "Finished."
log_to_file "Script finished successfully."

# Check if a web server was part of the installation to provide an accurate final message.
WEB_SERVER_INSTALLED=false
for ARG in "${INSTALL_ARGS[@]}"; do
    if [[ "$ARG" == "install_apache.sh" || "$ARG" == "install_nginx.sh" || "$ARG" == "install_lucee.sh" ]]; then
        WEB_SERVER_INSTALLED=true
        break
    elif [[ "$ARG" == *.stack ]]; then
        STACK_FILE="$SCRIPT_DIR/$ARG"
        if [ -f "$STACK_FILE" ] && grep -q -E "install_apache.sh|install_nginx.sh|install_lucee.sh" "$STACK_FILE"; then
            WEB_SERVER_INSTALLED=true
            break
        fi
    fi
done

if [ "$WEB_SERVER_INSTALLED" = true ]; then
    say "Your new server, $INSTANCE_NAME, is running at H T T P colon slash slash $PUBLIC_IP"
else
    say "Your new server, $INSTANCE_NAME, is running at I P address $PUBLIC_IP"
fi
