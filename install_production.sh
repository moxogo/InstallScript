#!/bin/bash

# Exit on error
set -e

echo "=== Starting Odoo Production Installation ==="

# Function to handle errors
handle_error() {
    echo "Error occurred in script at line: $1"
    echo "Error code: $2"
    exit $2
}

# Set up error handling
trap 'handle_error ${LINENO} $?' ERR

# Function to handle Nginx and port 80
handle_nginx() {
    echo "Checking for existing Nginx installation..."
    
    # Stop and disable system Nginx
    if systemctl is-active --quiet nginx; then
        echo "Stopping system Nginx..."
        sudo systemctl stop nginx
        echo "Disabling system Nginx..."
        sudo systemctl disable nginx
    fi

    # Remove Nginx packages
    if dpkg -l | grep -q "^ii.*nginx"; then
        echo "Removing system Nginx packages..."
        sudo apt-get remove nginx nginx-common -y
        sudo apt-get autoremove -y
    fi

    # Clean up Nginx directories
    if [ -d "/etc/nginx" ] || [ -d "/var/log/nginx" ]; then
        echo "Cleaning up Nginx directories..."
        sudo rm -rf /etc/nginx
        sudo rm -rf /var/log/nginx
    fi

    # Check for any process using port 80
    if netstat -tuln | grep -q ":80 "; then
        echo "Warning: Port 80 is in use. Checking process..."
        pid=$(sudo lsof -t -i:80)
        if [ ! -z "$pid" ]; then
            process=$(ps -p $pid -o comm=)
            echo "Process using port 80: $process (PID: $pid)"
            echo "Attempting to stop the process..."
            sudo kill -15 $pid
            sleep 2
            if netstat -tuln | grep -q ":80 "; then
                echo "Failed to free port 80. Please stop the process manually."
                exit 1
            fi
        fi
    fi
}

# 1. Handle existing Nginx and port 80
echo "1. Handling existing Nginx installation and port conflicts..."
handle_nginx

# 2. Update system
echo "2. Updating system..."
sudo apt-get update
sudo apt-get upgrade -y

# 3. Install required packages
echo "3. Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    python3-pip \
    certbot \
    python3-certbot-nginx

# 4. Install Docker
echo "4. Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# 5. Install Docker Compose
echo "5. Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# 6. Create directory structure
echo "6. Creating directory structure..."
sudo mkdir -p /odoo
cd /odoo
sudo mkdir -p {config,addons,nginx/conf,nginx/ssl,nginx/letsencrypt,logs,moxogo18}

# 7. Set proper permissions
echo "7. Setting permissions..."
sudo chown -R $USER:$USER /odoo
sudo chmod -R 755 /odoo

# 8. Generate strong passwords
echo "8. Generating secure passwords..."
POSTGRES_PASSWORD=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 32)

# 9. Create .env file
echo "9. Creating .env file..."
cat > .env << EOL
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
DOMAIN=your-domain.com
EMAIL=your-email@domain.com
POSTGRES_USER=odoo
PGDATA=/var/lib/postgresql/data/pgdata
EOL

# 10. Final setup and permissions
echo "10. Setting final permissions..."
sudo chown -R $USER:$USER .env
sudo chmod 600 .env

# Create log file and set permissions
sudo mkdir -p /var/log/odoo
sudo chown -R 101:101 /var/log/odoo

echo "=== Installation Complete ==="
echo "Please save these credentials:"
echo "PostgreSQL Password: $POSTGRES_PASSWORD"
echo "Admin Password: $ADMIN_PASSWORD"
echo ""
echo "Next steps:"
echo "1. Update the .env file with your domain and email"
echo "2. Get SSL certificate:"
echo "   sudo certbot certonly --webroot -w /odoo/nginx/letsencrypt -d your-domain.com"
echo "3. Start the services:"
echo "   docker-compose -f docker-compose.prod.yml up -d"
echo "1. Update your domain in nginx/conf/odoo.conf"
echo "2. Start the services with: docker-compose -f docker-compose.prod.yml up -d"
echo "3. Check the logs with: docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "Postgres Password (save this): ${POSTGRES_PASSWORD}"
echo "Admin Password (save this): ${ADMIN_PASSWORD}"
echo ""
echo "=== Remember to save these passwords securely! ==="

# Start the containers
echo "Starting Docker containers..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
docker-compose -f docker-compose.prod.yml up -d

# Check container status
echo "Checking container status..."
docker ps

echo ""
echo "Your Odoo server is now available at:"
echo "http://$(wget -qO- ipv4.icanhazip.com):8069"
