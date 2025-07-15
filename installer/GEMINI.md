# Gemini Agent Operational Manual

This document provides the necessary information for an AI agent to effectively use and extend this server provisioning toolkit.

## 1. Project Overview

This is a modular toolkit for provisioning new servers (locally or on EC2) and installing specific software stacks using a library of self-contained installer scripts.

## 2. Core Philosophy & Conventions

Adherence to these conventions is critical for maintaining the project.

*   **Modularity:** Every installer script (`install_*.sh`) should be responsible for installing only **one** piece of software (e.g., `install_apache.sh`, `install_git.sh`).
*   **Idempotency:** Scripts should be runnable multiple times without causing errors. Where possible, check if a tool is already installed before attempting to install it.
*   **Logging (Two-Tier System):**
    *   **Master Log (`install.log`):** The main orchestrator scripts (`launch_ec2_and_install.sh`, `install_stack.sh`) write high-level status updates here (e.g., "Started", "Handoff -> script.sh", "Finished"). This provides a timeline.
    *   **Detailed Logs (`*_install.log`):** Each individual installer script logs its detailed, verbose output to its own unique file (e.g., `apache_install.log`, `nodejs_install.log`). This is for debugging specific component failures.
*   **Verbalization (`say()`):** Use the `say "message"` function for all user-facing output that should be spoken. Do not put commands or code in the `say` function.
*   **Configuration (`.env` files):** All secrets and environment-specific variables (API keys, key paths, etc.) must be stored in dedicated `.env` files (`gemini.env`, `ec2_setup.env`). These files should never be committed to version control.

## 3. Key Scripts & How to Use Them

This is the primary interface for using the toolkit.

### Remote Provisioning (EC2)

*   **File:** `launch_ec2_and_install.sh`
*   **Purpose:** Provisions a new EC2 instance and installs a software stack on it.
*   **Usage:**
    ```bash
    # The first argument is the instance name.
    # Subsequent arguments can be .sh installers or .stack manifests.
    
    # Example 1: Deploy a server with the LAMP stack recipe.
    ./launch_ec2_and_install.sh "My-LAMP-Server" lamp.stack
    
    # Example 2: Deploy a server with Nginx and Redis.
    ./launch_ec2_and_install.sh "My-Custom-Server" install_nginx.sh install_redis.sh
    ```

### Local Installation

*   **File:** `install_stack.sh`
*   **Purpose:** Installs a software stack on the local machine.
*   **Usage:**
    ```bash
    # Arguments can be .sh installers or .stack manifests.
    
    # Example 1: Install the LEMP stack locally.
    ./install_stack.sh lemp.stack
    
    # Example 2: Install Git and Docker locally.
    ./install_stack.sh install_git.sh install_docker.sh
    ```

## 4. Stack Manifests (`.stack` files)

*   **Purpose:** `.stack` files are recipes that define a complete software stack by listing the required installer scripts.
*   **Format:** A simple text file with one installer per line, using the `installer:` directive.
    ```
    # --- My Custom Stack ---
    installer: install_nginx.sh
    installer: install_redis.sh
    installer: install_docker.sh
    ```

## 5. Adding New Components

### Creating a New Installer

1.  Create a new file named `install_NEW_COMPONENT.sh`.
2.  Follow the conventions: include `say()` for verbal output and `log_to_file()` for detailed logging to a unique `NEW_COMPONENT_install.log` file.
3.  Check if the component is already installed to ensure idempotency.
4.  You can now use this new installer directly with the `launch_ec2_and_install.sh` or `install_stack.sh` scripts.

### Creating a New Stack Recipe

1.  Create a new file named `my_stack.stack`.
2.  Add the `installer: script_name.sh` directive for each component in the stack, in the desired installation order.
3.  You can now deploy this entire stack using `./launch_ec2_and_install.sh "My-New-Stack" my_stack.stack`.
