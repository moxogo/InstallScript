#!/bin/bash

set -e

# Install cron if not present
if ! command -v crontab &> /dev/null; then
    apt-get update && apt-get install -y cron
fi

# Create required directories
mkdir -p ./nginx/ssl
mkdir -p ./nginx/letsencrypt
mkdir -p ./nginx/conf

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down

# Start nginx container only
echo "Starting nginx..."
docker-compose up -d nginx

# Wait for nginx to start
echo "Waiting for nginx to start..."
sleep 10

# Request the certificate
echo "Requesting SSL certificate..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/html \
    --email wizearch55@gmail.com \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d mxg18.mxgsoft.com

# Stop containers
echo "Stopping containers..."
docker-compose down

# Start all services
echo "Starting all services..."
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 15

# Set up auto-renewal if crontab is available
if command -v crontab &> /dev/null; then
    echo "Setting up automatic renewal..."
    (crontab -l 2>/dev/null; echo "0 12 * * * cd $(pwd) && docker-compose run --rm certbot renew --quiet && docker-compose restart nginx") | sort - | uniq - | crontab -
else
    echo "Warning: crontab not available. Automatic renewal not configured."
fi

echo "SSL Certificate has been obtained. Your site should now be accessible via HTTPS."
