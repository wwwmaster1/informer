#!/bin/bash

# --- PostgreSQL Installation Script ---
# Installs PostgreSQL, a powerful, open-source object-relational database system.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/../logs/postgresql_install.log"
SERVICE_MANIFEST_DIR="$(dirname "${BASH_SOURCE[0]}")/../services"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Starting PostgreSQL installation."
log_to_file "PostgreSQL installer started."

say "Installing PostgreSQL 14 server using Amazon Linux Extras."
log_to_file "Installing postgresql14."
sudo amazon-linux-extras install -y postgresql14
log_to_file "PostgreSQL installation complete."

say "Initializing the PostgreSQL database."
log_to_file "Initializing the database with postgresql-setup."
sudo postgresql-setup --initdb
log_to_file "Database initialized."

say "Starting the PostgreSQL service."
log_to_file "Starting postgresql service."
sudo systemctl start postgresql

say "Enabling the PostgreSQL service to start on boot."
log_to_file "Enabling postgresql service."
sudo systemctl enable postgresql

# --- Create Service Manifest ---
say "Creating service manifest for PostgreSQL."
mkdir -p "$SERVICE_MANIFEST_DIR"
cat <<EOF > "$SERVICE_MANIFEST_DIR/postgresql.json"
{
  "serviceName": "PostgreSQL",
  "description": "An open-source object-relational database system.",
  "accessMethod": {
    "type": "network",
    "protocol": "postgresql",
    "port": 5432,
    "usage": "Connect using a PostgreSQL client (e.g., psql) or library to localhost on port 5432."
  }
}
EOF
log_to_file "Service manifest created at $SERVICE_MANIFEST_DIR/postgresql.json"

say "PostgreSQL installation is complete."
log_to_file "PostgreSQL installer finished successfully."
say "You may now connect to the database as the postgres user."