#!/bin/bash

# Pull latest changes if using git
cd moxogo18
git pull

# Sync and restart
./sync-addons.sh

echo "Modules updated and Odoo restarted"
