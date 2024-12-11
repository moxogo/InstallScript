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
required_vars=("DOMAIN" "EMAIL")
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

# Create required directories with proper permissions
log "Creating required directories..."
mkdir -p ./nginx/ssl
mkdir -p ./nginx/letsencrypt
chmod -R 755 ./nginx

# Stop and remove existing containers
log "Stopping existing containers..."
docker-compose down

# Start nginx container
log "Starting nginx container..."
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

# Copy SSL configuration
log "Configuring nginx for SSL..."
envsubst '${DOMAIN} ${ODOO_PORT} ${ODOO_CHAT_PORT}' < ./nginx/conf/ssl.conf.template > ./nginx/conf/default.conf

# Start all services
log "Starting all services..."
docker-compose up -d

# Wait for services to start
log "Waiting for services to initialize..."
sleep 15

# Verify SSL certificate
log "Verifying SSL certificate..."
if curl -k -s -I https://$DOMAIN 2>&1 | grep -q "200 OK"; then
    log "SSL certificate is working properly"
else
    error "SSL verification failed. Please check your configuration"
    error "You may need to wait a few minutes for DNS propagation"
fi

log "SSL setup completed!"
log "Your site should now be accessible via HTTPS"
log "Certificate will automatically renew every 12 hours"
