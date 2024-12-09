#!/bin/bash

COMPOSE="/usr/local/bin/docker-compose --no-ansi"
DOCKER="/usr/bin/docker"

cd /root/InstallScript
$COMPOSE run certbot renew --webroot --webroot-path=/var/www/html && $COMPOSE kill -s SIGHUP nginx

# This script should be added to crontab to run twice daily:
# 0 */12 * * * /root/InstallScript/nginx/ssl/ssl-renew.sh >> /var/log/cron.log 2>&1
