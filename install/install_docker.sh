#!/bin/bash

# --- Docker Installation Script ---
# Installs the Docker Engine for running containerized applications.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/docker_install.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Docker installation."
log_to_file "Docker installer started."

say "Installing Docker using Amazon Linux Extras."
log_to_file "Installing docker."
sudo amazon-linux-extras install -y docker
log_to_file "Docker installation complete."

say "Adding the current user to the docker group to run commands without sudo."
log_to_file "Adding user to docker group."
# On Amazon Linux, the default user is ec2-user. We use whoami for more portability.
sudo usermod -a -G docker "$(whoami)"
log_to_file "User added to docker group."

say "Starting the Docker service."
log_to_file "Starting docker service."
sudo systemctl start docker

say "Enabling the Docker service to start on boot."
log_to_file "Enabling docker service."
sudo systemctl enable docker

say "Docker installation is complete."
log_to_file "Docker installer finished successfully."
say "IMPORTANT: You will need to log out and log back in for the group changes to take effect and run docker without sudo."
log_to_file "Instructed user to log out and back in."
