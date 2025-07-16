#!/bin/bash

# --- MariaDB (MySQL) Installation Script ---
# Installs MariaDB, the default, open-source relational database on Amazon Linux 2.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/mariadb_install.log"
SERVICE_MANIFEST_DIR="$(dirname "${BASH_SOURCE[0]}")/../services"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting Maria D B installation."
log_to_file "MariaDB installer started."

say "Installing Maria D B server using Amazon Linux Extras."
log_to_file "Installing mariadb10.5."
sudo amazon-linux-extras install -y mariadb10.5
log_to_file "MariaDB installation complete."

say "Starting the Maria D B service."
log_to_file "Starting mariadb service."
sudo systemctl start mariadb

say "Enabling the Maria D B service to start on boot."
log_to_file "Enabling mariadb service."
sudo systemctl enable mariadb

# --- Create Service Manifest ---
say "Creating service manifest for Maria D B."
mkdir -p "$SERVICE_MANIFEST_DIR"
cat <<EOF > "$SERVICE_MANIFEST_DIR/mariadb.json"
{
  "serviceName": "MariaDB",
  "description": "A relational database server, compatible with MySQL.",
  "accessMethod": {
    "type": "network",
    "protocol": "mysql",
    "port": 3306,
    "usage": "Connect using a MySQL client or library to localhost on port 3306."
  }
}
EOF
log_to_file "Service manifest created at $SERVICE_MANIFEST_DIR/mariadb.json"

say "Maria D B installation is complete."
log_to_file "MariaDB installer finished successfully."
say "IMPORTANT: For a production environment, you should run the mysql underscore secure underscore installation command to secure your database."
log_to_file "Instructed user to run mysql_secure_installation."