#!/bin/bash

# Exit on error
set -e

echo "=== Starting Odoo Production Installation ==="

# 1. Update system
echo "1. Updating system..."
sudo apt-get update
sudo apt-get upgrade -y

# 2. Install required packages
echo "2. Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    python3-pip \
    certbot \
    python3-certbot-nginx

# 3. Install Docker
echo "3. Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 4. Install Docker Compose
echo "4. Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 5. Create directory structure
echo "5. Creating directory structure..."
sudo mkdir -p /opt/odoo
cd /opt/odoo
sudo mkdir -p {config,addons,nginx/conf,nginx/ssl,nginx/letsencrypt,logs}

# 6. Set proper permissions
echo "6. Setting permissions..."
sudo chown -R $USER:$USER /opt/odoo

# 7. Generate strong passwords
echo "7. Generating secure passwords..."
POSTGRES_PASSWORD=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 32)

# 8. Create .env file
echo "8. Creating .env file..."
cat > .env << EOL
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
DOMAIN=your-domain.com
EMAIL=your-email@domain.com
EOL

echo "=== Installation completed ==="
echo ""
echo "Next steps:"
echo "1. Update the .env file with your domain and email"
echo "2. Get SSL certificate:"
echo "   sudo certbot certonly --webroot -w /opt/odoo/nginx/letsencrypt -d your-domain.com"
echo "3. Start the services:"
echo "   docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo "Postgres Password (save this): ${POSTGRES_PASSWORD}"
echo "Admin Password (save this): ${ADMIN_PASSWORD}"
echo ""
echo "=== Remember to save these passwords securely! ==="
