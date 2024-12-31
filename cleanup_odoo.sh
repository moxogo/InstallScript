#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
POSTGRES_PASSWORD="your_secure_password"
POSTGRES_USER="odoo18"
POSTGRES_DB="odoo18"
SYSTEM_USER="odoo18"
INSTALL_DIR="/odoo18"
VENV_DIR="/odoo18/venv"
LOG_DIR="/var/log/odoo"
CONFIG_FILE="/etc/odoo.conf"
SERVICE_FILE="/etc/systemd/system/odoo.service"

# Function to remove PostgreSQL database and user
remove_postgres() {
    echo "Removing PostgreSQL database and user..."
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"
    sudo -u postgres psql -c "DROP ROLE IF EXISTS $POSTGRES_USER;"
}

# Function to remove system user and home directory
remove_system_user() {
    echo "Removing system user and home directory..."
    sudo killall -u $SYSTEM_USER || true
    sudo userdel -f -r $SYSTEM_USER || true
}

# Function to remove installation directory
remove_install_dir() {
    echo "Removing installation directory..."
    sudo rm -rf $INSTALL_DIR
}

# Function to remove virtual environment directory
remove_venv_dir() {
    echo "Removing virtual environment directory..."
    sudo rm -rf $VENV_DIR
}

# Function to remove log files and directory
remove_log_files() {
    echo "Removing log files and directory..."
    sudo rm -rf $LOG_DIR
}

# Function to remove configuration file
remove_config_file() {
    echo "Removing configuration file..."
    sudo rm -f $CONFIG_FILE
}

# Function to remove systemd service file
remove_service_file() {
    echo "Removing systemd service file..."
    sudo rm -f $SERVICE_FILE
}

# Execute functions to clean up any previous installations
remove_postgres
remove_system_user
remove_install_dir
remove_venv_dir
remove_log_files
remove_config_file
remove_service_file

echo "Cleanup completed successfully!"