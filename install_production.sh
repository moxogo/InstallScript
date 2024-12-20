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
    
    # Function to check if port 80 is in use
    check_port_80() {
        if sudo lsof -i :80 >/dev/null 2>&1; then
            return 0  # Port is in use
        else
            return 1  # Port is free
        fi
    }

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
    if check_port_80; then
        echo "Warning: Port 80 is still in use after stopping Nginx."
        echo "Checking processes using port 80:"
        sudo lsof -i :80
        
        echo "Attempting to identify and stop processes..."
        
        # Try to find and stop any remaining Nginx processes
        if pgrep nginx >/dev/null; then
            echo "Found remaining Nginx processes. Stopping them..."
            sudo pkill nginx
        fi
        
        # Wait a moment and check again
        sleep 2
        
        if check_port_80; then
            echo "Port 80 is still in use. Please check the following processes:"
            sudo lsof -i :80
            echo "You may need to manually stop these processes."
            read -p "Press Enter to continue once port 80 is free, or Ctrl+C to exit..."
            
            # Final check
            if check_port_80; then
                echo "Port 80 is still in use. Please free up the port before continuing."
                exit 1
            fi
        fi
    fi

    echo "Port 80 is now available for use."
}

# Function to handle PostgreSQL
handle_postgres() {
    echo "Checking for existing PostgreSQL installation..."
    
    # Check if PostgreSQL is running
    if systemctl is-active --quiet postgresql; then
        echo "PostgreSQL is running on the system"
        echo "Note: Docker PostgreSQL will use port 5433 instead of 5432"
        
        # Optionally stop system PostgreSQL
        read -p "Do you want to stop the system PostgreSQL? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Stopping PostgreSQL..."
            sudo systemctl stop postgresql
            sudo systemctl disable postgresql
        fi
    fi

    # Check if port 5433 is available
    if netstat -tuln | grep -q ":5433 "; then
        echo "Warning: Port 5433 is also in use"
        echo "Please free up either port 5432 or 5433 before continuing"
        exit 1
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
sudo mkdir -p {config,addons,nginx/conf,nginx/ssl,nginx/letsencrypt,logs,moxogo18,static}

# 7. Set proper permissions
echo "7. Setting permissions..."
sudo chown -R $USER:$USER /odoo
sudo chmod -R 755 /odoo

# 8. Fix module structure
echo "8. Fixing module structure..."
# chmod +x fix_module_structure.sh
# ./fix_module_structure.sh

# 9. Generate strong passwords
echo "9. Generating secure passwords..."
POSTGRES_PASSWORD=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 32)

# 10. Create .env file
echo "10. Creating .env file..."
cat > .env << EOL
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
DOMAIN=your-domain.com
EMAIL=your-email@domain.com
POSTGRES_USER=odoo
PGDATA=/var/lib/postgresql/data/pgdata
EOL

# 11. Final setup and permissions
echo "11. Setting final permissions..."
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
echo "   docker-compose -f docker-compose.yml up -d"
echo "1. Update your domain in nginx/conf/odoo.conf"
echo "2. Start the services with: docker-compose -f docker-compose.yml up -d"
echo "3. Check the logs with: docker-compose -f docker-compose.yml logs -f"
echo ""
echo "Postgres Password (save this): ${POSTGRES_PASSWORD}"
echo "Admin Password (save this): ${ADMIN_PASSWORD}"
echo ""
echo "=== Remember to save these passwords securely! ==="

# Handle PostgreSQL before starting containers
echo "Checking PostgreSQL configuration..."
handle_postgres

# Copy necessary files to /odoo
echo "Copying configuration files..."
SCRIPT_DIR="/root/InstallScript"
cp "$SCRIPT_DIR/docker-compose.yml" /odoo/
cp -r "$SCRIPT_DIR/config" /odoo/
cp -r "$SCRIPT_DIR/nginx" /odoo/ 2>/dev/null || true

# Change to /odoo directory
cd /odoo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
else
    error "Error: .env file not found"
    exit 1
fi

# Set default values if not in .env
POSTGRES_DB=${POSTGRES_DB:-odoo}
POSTGRES_USER=${POSTGRES_USER:-odoo}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-odoo123}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
ODOO_PORT=${ODOO_PORT:-8069}
ODOO_CHAT_PORT=${ODOO_CHAT_PORT:-8072}

# Create necessary directories
log "Creating directories..."
mkdir -p ./nginx/ssl
mkdir -p ./nginx/letsencrypt
mkdir -p ./nginx/conf
mkdir -p ./config
mkdir -p ./addons
mkdir -p ./logs/odoo

# Copy configuration files
log "Copying configuration files..."
cp -n config/odoo.conf.template config/odoo.conf 2>/dev/null || true

# Initial docker setup
log "Starting initial docker setup..."
docker-compose down -v
docker-compose build
docker-compose up -d

# Wait for services to be healthy
log "Waiting for services to be healthy..."
sleep 30

# Check if services are running
if ! docker-compose ps | grep -q "Up"; then
    error "Docker services failed to start properly"
    docker-compose logs
    exit 1
fi

log "Initial installation completed successfully!"
log "You can now run './ssl-setup.sh' to configure SSL"
log "Services are accessible at:"
log "- Odoo: http://localhost:${ODOO_PORT}"
log "- Chat: http://localhost:${ODOO_CHAT_PORT}"
echo ""
echo "Your Odoo server is now available at:"
echo "http://$(wget -qO- ipv4.icanhazip.com):${ODOO_PORT}"