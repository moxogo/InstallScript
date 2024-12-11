#!/bin/bash

# Create required directories
mkdir -p ./nginx/ssl
mkdir -p ./nginx/letsencrypt

# Stop existing containers
docker-compose down

# Start nginx container only
docker-compose up -d nginx

# Wait for nginx to start
sleep 5

# Request the certificate
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/html \
    --email wizearch55@gmail.com \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d mxg18.mxgsoft.com

# Stop nginx
docker-compose down

# Start all services
docker-compose up -d

echo "SSL Certificate has been obtained. Your site should now be accessible via HTTPS."

# Add automatic renewal
(crontab -l 2>/dev/null; echo "0 12 * * * cd /root/InstallScript && docker-compose run --rm certbot renew --quiet && docker-compose restart nginx") | crontab -
