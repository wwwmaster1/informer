# Gemini Agent Operational Manual

This document provides the necessary information for an AI agent to effectively use and extend this server provisioning toolkit.

## 1. Project Overview

This is a modular toolkit for provisioning new servers (locally or on EC2) and installing specific software stacks. The primary deployment method is to clone this repository onto a fresh EC2 instance and execute installers from there.

## 2. Core Philosophy & Conventions

*   **Directory Structure:** All installers, stack manifests, and launchers are located in the `/install` directory. The root directory contains this manual, primary configuration files, and shared utility scripts like `credential_utils.sh`.
*   **Modularity:** Each script in `/install` should do one job.
*   **Logging:** A two-tier system. A master `install.log` in the root provides a high-level timeline. Detailed logs for each component are created in the `/install` directory on the target machine.
*   **Service Discovery:** After installation, run `./list_services.sh` to get a machine-readable JSON list of all installed services, their ports, and access protocols. The script is located in the project root.

## 3. Key Scripts & How to Use Them

### Remote Provisioning (EC2)

*   **File:** `install/launch_ec2_and_install.sh`
*   **Purpose:** Provisions a new EC2 instance, clones this repository onto it (if `GIT_REPO_URL` is set in `ec2_setup.env`), and installs a software stack.
*   **Primary Workflow (Git-Based):**
    1.  Set the `GIT_REPO_URL` in `ec2_setup.env`.
    2.  The script will clone the repo onto the new server.
    3.  It will then execute the `install/install_stack.sh` script *from the cloned repo* with the arguments you provide.
*   **Usage:**
    ```bash
    # The first argument is the instance name.
    # Subsequent arguments are passed to install_stack.sh on the remote server.
    
    # Example: Deploy a server with the LAMP stack recipe.
    ./install/launch_ec2_and_install.sh "My-LAMP-Server" lamp.stack
    ```

### Local Installation

*   **File:** `install/install_stack.sh`
*   **Purpose:** Installs a software stack on the **local** machine.
*   **Usage:**
    ```bash
    # Arguments can be .sh installers or .stack manifests from the /install directory.
    
    # Example: Install the LEMP stack locally.
    ./install/install_stack.sh lemp.stack
    ```

## 4. Stack Manifests (`.stack` files)

*   **Location:** `/install`
*   **Purpose:** Recipes that define a software stack by listing the required installer scripts.
*   **Format:** `installer: script_name.sh`

## 5. Adding New Components

1.  Create your new `install_new_component.sh` script inside the `/install` directory, following all conventions.
2.  Commit and push the new script to your Git repository.
3.  You can now deploy it immediately using the `launch_ec2_and_install.sh` script.