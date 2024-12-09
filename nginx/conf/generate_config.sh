#!/bin/bash

# Default values
ODOO_HOST=${ODOO_HOST:-"web"}
ODOO_PORT=${ODOO_PORT:-"8069"}
ODOO_CHAT_PORT=${ODOO_CHAT_PORT:-"8072"}
NGINX_PORT=${NGINX_PORT:-"80"}
SERVER_NAME=${SERVER_NAME:-"localhost"}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --odoo-host HOST       Odoo host (default: web)"
    echo "  --odoo-port PORT       Odoo port (default: 8069)"
    echo "  --chat-port PORT       Odoo chat port (default: 8072)"
    echo "  --nginx-port PORT      Nginx listen port (default: 80)"
    echo "  --server-name NAME     Server name (default: localhost)"
    echo "  -h, --help            Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --odoo-host)
            ODOO_HOST="$2"
            shift 2
            ;;
        --odoo-port)
            ODOO_PORT="$2"
            shift 2
            ;;
        --chat-port)
            ODOO_CHAT_PORT="$2"
            shift 2
            ;;
        --nginx-port)
            NGINX_PORT="$2"
            shift 2
            ;;
        --server-name)
            SERVER_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Export variables for envsubst
export ODOO_HOST
export ODOO_PORT
export ODOO_CHAT_PORT
export NGINX_PORT
export SERVER_NAME

# Generate the configuration file
envsubst '${ODOO_HOST} ${ODOO_PORT} ${ODOO_CHAT_PORT} ${NGINX_PORT} ${SERVER_NAME}' \
    < odoo.conf.template \
    > odoo.conf

echo "Nginx configuration generated with:"
echo "  Odoo Host: $ODOO_HOST"
echo "  Odoo Port: $ODOO_PORT"
echo "  Chat Port: $ODOO_CHAT_PORT"
echo "  Nginx Port: $NGINX_PORT"
echo "  Server Name: $SERVER_NAME"
