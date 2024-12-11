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

# Function to check if domain is accessible
check_domain() {
    local domain=$1
    if ! ping -c 1 $domain &> /dev/null; then
        error "Domain $domain is not accessible. Please check your DNS settings."
        return 1
    fi
    return 0
}

# Create required directories
log "Creating required directories..."
mkdir -p ./nginx/ssl
mkdir -p ./nginx/letsencrypt
chmod -R 755 ./nginx

# Check domain before proceeding
log "Checking domain accessibility..."
if ! check_domain $DOMAIN; then
    exit 1
fi

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
cp ./nginx/conf/ssl.conf.template ./nginx/conf/default.conf
sed -i "s/\${DOMAIN}/$DOMAIN/g" ./nginx/conf/default.conf
sed -i "s/\${ODOO_PORT}/8069/g" ./nginx/conf/default.conf
sed -i "s/\${ODOO_CHAT_PORT}/8072/g" ./nginx/conf/default.conf

# Restart nginx to apply SSL
log "Restarting nginx..."
docker-compose restart nginx

# Create SSL renewal script
log "Creating SSL renewal script..."
cat > renew-ssl.sh << EOF
#!/bin/bash
cd $(pwd)
docker-compose run --rm certbot renew --quiet
docker-compose restart nginx
EOF

chmod +x renew-ssl.sh

# Add to crontab if not already present
log "Setting up automatic renewal cron job..."
(crontab -l 2>/dev/null | grep -v "renew-ssl.sh"; echo "0 12 * * * $(pwd)/renew-ssl.sh") | sort - | uniq - | crontab -

# Verify SSL certificate
log "Verifying SSL certificate..."
sleep 10
if curl -k -s -I https://$DOMAIN 2>&1 | grep -q "200 OK"; then
    log "SSL certificate is working properly"
else
    error "SSL verification failed. Please check your configuration"
    error "You may need to wait a few minutes for DNS propagation"
fi

log "SSL setup completed!"
log "Your site should now be accessible via HTTPS"
log "Certificate will automatically renew daily at 12:00"
