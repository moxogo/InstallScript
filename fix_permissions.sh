#!/bin/bash

# Exit on error
set -e

# Base directory
BASE_DIR="$(pwd)"

# Create necessary directories if they don't exist
mkdir -p "$BASE_DIR/addons"
mkdir -p "$BASE_DIR/moxogo18"
mkdir -p "$BASE_DIR/config"
mkdir -p "$BASE_DIR/logs"
mkdir -p "$BASE_DIR/nginx/conf"
mkdir -p "$BASE_DIR/nginx/ssl"
mkdir -p "$BASE_DIR/nginx/letsencrypt"

# Set ownership (assuming odoo user ID is 101)
sudo chown -R 101:101 "$BASE_DIR/addons"
sudo chown -R 101:101 "$BASE_DIR/moxogo18"
sudo chown -R 101:101 "$BASE_DIR/logs"

# Set permissions
sudo chmod -R 755 "$BASE_DIR/addons"
sudo chmod -R 755 "$BASE_DIR/moxogo18"
sudo chmod -R 755 "$BASE_DIR/logs"

# Create an empty __init__.py in addons directories if they don't exist
touch "$BASE_DIR/addons/__init__.py"
touch "$BASE_DIR/moxogo18/__init__.py"

# Verify the directory structure
echo "Directory structure:"
ls -la "$BASE_DIR"
echo -e "\nAddons directory:"
ls -la "$BASE_DIR/addons"
echo -e "\nCustom addons directory:"
ls -la "$BASE_DIR/moxogo18"

echo "Permissions and directories have been fixed"
