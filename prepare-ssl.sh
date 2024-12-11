#!/bin/bash

# Create required directories
mkdir -p ./nginx/ssl
mkdir -p ./nginx/letsencrypt
mkdir -p ./nginx/conf

# Set proper permissions
chmod -R 755 ./nginx
chmod -R 755 ./nginx/letsencrypt

# Clean up any existing containers
docker-compose down

# Remove any existing SSL files
rm -rf ./nginx/ssl/*
rm -rf ./nginx/letsencrypt/*

# Start nginx
docker-compose up -d nginx

# Wait for nginx to start
echo "Waiting for nginx to start..."
sleep 10

# Test nginx configuration
echo "Testing nginx configuration..."
docker-compose exec nginx nginx -t

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

# Restart nginx to apply changes
docker-compose restart nginx

echo "SSL setup complete. Check the output for any errors."
