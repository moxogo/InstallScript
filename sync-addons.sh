#!/bin/bash

# Create necessary directories if they don't exist
mkdir -p moxogo18
mkdir -p addons
mkdir -p logs
mkdir -p backups

# Set proper permissions
chmod -R 755 moxogo18/
chown -R root:root moxogo18/

# Restart Odoo container to pick up new changes
docker-compose restart web

# Show the updated module list
echo "Current modules in moxogo18:"
ls -la moxogo18/

echo "Synchronization complete. Odoo service restarted."
