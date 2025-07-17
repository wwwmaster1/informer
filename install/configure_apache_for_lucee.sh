#!/bin/bash

# --- Configure Apache for Lucee Utility ---
# Configures Apache to act as a reverse proxy for a Lucee/Tomcat instance.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/apache_lucee_config.log"

say() {
    echo "{$1}"
}

log_to_file() {
    echo "$(date +%s): $1" >>"$LOG_FILE"
}

# --- Script Body ---
say "Configuring Apache as a reverse proxy for Lucee."
log_to_file "Apache-Lucee configuration script started."

# Define the Apache configuration for the reverse proxy
LUCEE_PROXY_CONF=$(cat <<'EOF'
<IfModule mod_proxy.c>
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8888/
    ProxyPassReverse / http://127.0.0.1:8888/
</IfModule>
EOF
)

# Create the configuration file in Apache's conf.d directory
say "Creating the Lucee proxy configuration file."
echo "$LUCEE_PROXY_CONF" | sudo tee /etc/httpd/conf.d/lucee_proxy.conf
log_to_file "Created /etc/httpd/conf.d/lucee_proxy.conf"

say "Restarting Apache to apply the new configuration."
sudo systemctl restart httpd
log_to_file "Apache service restarted."

say "Apache has been configured to serve Lucee applications."
log_to_file "Configuration complete."
