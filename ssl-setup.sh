#!/bin/bash

# SSL Setup and Automation Script
set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
else
    echo "Error: .env file not found"
    exit 1
fi

# Verify required environment variables
required_vars=("DOMAIN" "EMAIL" "ENABLE_SSL")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in .env file"
        exit 1
    fi
done

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    error "Please run as root"
    exit 1
fi

# Install required packages
log "Installing required packages..."
apt-get update
apt-get install -y cron certbot

# Create required directories
log "Creating required directories..."
mkdir -p ./nginx/ssl
mkdir -p ./nginx/letsencrypt
mkdir -p ./nginx/conf

# Function to check if domain is accessible
check_domain() {
    local domain=$1
    if ! ping -c 1 $domain &> /dev/null; then
        error "Domain $domain is not accessible. Please check your DNS settings."
        return 1
    fi
    return 0
}

# Check domain before proceeding
log "Checking domain accessibility..."
if ! check_domain $DOMAIN; then
    exit 1
fi

# Stop existing containers
log "Stopping existing containers..."
docker-compose down

# Start nginx container only
log "Starting nginx for certificate acquisition..."
docker-compose up -d nginx

# Wait for nginx to start
log "Waiting for nginx to initialize..."
sleep 10

# Request the certificate
log "Requesting SSL certificate..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/html \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN

# Create SSL renewal script
log "Creating SSL renewal script..."
cat > /root/renew-ssl.sh << EOF
#!/bin/bash
cd $(pwd)
docker-compose run --rm certbot renew --quiet
docker-compose restart nginx
EOF

chmod +x /root/renew-ssl.sh

# Add to crontab
log "Setting up automatic renewal cron job..."
(crontab -l 2>/dev/null | grep -v "renew-ssl.sh"; echo "0 12 * * * /root/renew-ssl.sh") | sort - | uniq - | crontab -

# Verify cron job
log "Verifying cron job installation..."
if crontab -l | grep -q "renew-ssl.sh"; then
    log "Cron job installed successfully"
else
    error "Failed to install cron job"
    exit 1
fi

# Start all services
log "Starting all services..."
docker-compose up -d

# Wait for services to start
log "Waiting for services to initialize..."
sleep 15

# Verify SSL certificate
log "Verifying SSL certificate..."
if curl -s -I https://$DOMAIN 2>&1 | grep -q "200 OK"; then
    log "SSL certificate is working properly"
else
    error "SSL verification failed. Please check your configuration"
fi

log "SSL setup completed successfully!"
log "Your site should now be accessible via HTTPS"
log "Certificate will automatically renew daily at 12:00"
