#!/bin/bash

# Define variables
POSTGRES_USER="odoo18"
POSTGRES_DB="odoo18"
SYSTEM_USER="odoo18"
INSTALL_DIR="/odoo18"
ODOO_BRANCH="18.0"
ADMIN_PASSWORD="admin123"
DB_PASSWORD="123123"
VENV_DIR="/odoo18/venv"
LOG_DIR="/var/log/odoo"
CONFIG_FILE="/etc/odoo.conf"
SERVICE_FILE="/etc/systemd/system/odoo.service"
LOG_FILE="/var/log/odoo/odoo18.log"
#  Configure Nginx
DOMAIN="your_domain_or_IP"
EMAIL="your_email@example.com"
ODOO_PORT="8069"

# Update and upgrade the system
sudo apt-get update
sudo apt-get upgrade -y

# Install necessary security packages
sudo apt-get install -y openssh-server fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Install Python3 and other development tools
sudo apt-get install -y python3-pip python3-dev libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev

# Install NodeJS for Less compilation
sudo apt-get install -y npm
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css
sudo apt-get install -y node-less

# Install PostgreSQL
sudo apt-get install -y postgresql
sudo -u postgres psql -c "CREATE ROLE $POSTGRES_USER WITH LOGIN PASSWORD '$DB_PASSWORD' CREATEDB;"
sudo -u postgres createdb --username postgres --owner=$POSTGRES_USER $POSTGRES_DB

# Add the Odoo user
sudo adduser --system --home=$INSTALL_DIR --group $SYSTEM_USER

# Install Git
sudo apt-get install -y git

# Clone the Odoo repository
sudo -u $SYSTEM_USER -H git clone https://www.github.com/odoo/odoo --depth 1 --branch $ODOO_BRANCH --single-branch $INSTALL_DIR

# Add Odoo Repository on Ubuntu
# wget -O - https://nightly.odoo.com/odoo.key | sudo gpg --dearmor -o /usr/share/keyrings/odoo-archive-keyring.gpg
# echo 'deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/18.0/nightly/deb/ ./' | sudo tee /etc/apt/sources.list.d/odoo.list
# sudo apt-get update && sudo apt-get install -y odoo

# echo "Installed Requirements. Press Enter to Continue!"
# read

# Install Python3 virtual environment
sudo apt install -y python3-venv
sudo mkdir -p $VENV_DIR
sudo python3 -m venv $VENV_DIR

echo "Activated Virtual Environment.Press Enter to Continue!"
read

# Activate the virtual environment and install Odoo dependencies
source $VENV_DIR/bin/activate

# Fix permissions for pip
sudo chown -R $SYSTEM_USER:$SYSTEM_USER $VENV_DIR

# Install Python dependencies as odoo user
sudo -H -u $SYSTEM_USER $VENV_DIR/bin/pip3 install -r $INSTALL_DIR/requirements.txt

# Install additional Python packages with specific versions
sudo -H -u $SYSTEM_USER $VENV_DIR/bin/pip3 install \
    babel>=2.6.0 \
    decorator>=4.3.0 \
    docutils>=0.14 \
    gevent>=1.1.2 \
    greenlet>=0.4.13 \
    html2text>=2018.1.9 \
    Jinja2>=2.10.1 \
    libsass>=0.17.0 \
    lxml>=4.3.2 \
    MarkupSafe>=1.1.0 \
    num2words>=0.5.6 \
    ofxparse>=0.19 \
    passlib>=1.7.1 \
    Pillow>=5.4.1 \
    polib>=1.1.0 \
    psutil>=5.6.6 \
    psycopg2>=2.7.7 \
    pydot>=1.4.1 \
    python-dateutil>=2.7.3 \
    pytz>=2019.1 \
    pyusb>=1.0.2 \
    qrcode>=6.1 \
    reportlab>=3.5.13 \
    requests>=2.21.0 \
    zeep>=3.2.0 \
    python-stdnum>=1.8 \
    vobject>=0.9.6.1 \
    werkzeug>=0.14

# Install Wkhtmltopdf and its dependencies
sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo apt-get install -y xfonts-75dpi
sudo apt install -f

# Fix broken packages
sudo apt-get install -fl
deactivate

echo "Deactivate Virtual Environment.Press Enter to Continue!"
read

# Create a configuration file
sudo cp $INSTALL_DIR/debian/odoo.conf /etc/odoo18.conf
cat <<EOF | sudo tee /etc/odoo18.conf
[options]
# Basic Configuration
admin_passwd = $ADMIN_PASSWORD
db_host = localhost
db_port = 5432
db_user = $POSTGRES_USER
db_password = $DB_PASSWORD
db_name = $POSTGRES_DB
addons_path = $INSTALL_DIR/addons,$INSTALL_DIR/moxogo18
data_dir = $INSTALL_DIR/data

# HTTP Service Configuration
http_port = $ODOO_PORT
http_enable = True
proxy_mode = True
longpolling_port = 8072
xmlrpc = True
xmlrpc_interface =
xmlrpc_port = 8069

# Workers Configuration
workers = 4  # Formula: 2 x NUM_CPU + 1
max_cron_threads = 2
limit_time_cpu = 600
limit_time_real = 1200
limit_time_real_cron = 1800

# Memory Management
limit_memory_hard = 2684354560  # 2.5GB
limit_memory_soft = 2147483648  # 2GB
limit_request = 8192
limit_memory_request = 536870912  # 512MB

# Database Settings
db_maxconn = 64  # (workers + max_cron_threads) * 2
db_sslmode = disable
db_template = template0
db_encoding = UTF8
unaccent = True

# Performance Tuning
osv_memory_age_limit = 1.0
osv_memory_count_limit = False
db_prefetch = True
auto_reload = False
without_demo = True

# Logging Configuration
log_level = info
log_handler = [':INFO']
logfile = $LOG_FILE
logrotate = True
log_db = False
log_db_level = warning

# Security Settings
server_wide_modules = base,web
list_db = False
dbfilter = ^${POSTGRES_DB}$
secure_cert_file = False
websocket = True

# Email Settings
email_from = False
smtp_server = localhost
smtp_port = 25
smtp_ssl = False
smtp_user = False
smtp_password = False

# Misc Settings
transient_age_limit = 1.0
cache_timeout = 100000
csv_internal_sep = ,
EOF

# Set permissions for the configuration file
sudo chown odoo18: /etc/odoo18.conf
sudo chmod 640 /etc/odoo18.conf

# Create log directory
sudo mkdir /var/log/odoo
sudo chown odoo18:root /var/log/odoo
sudo chmod -R 755 /var/log/odoo
echo "Creating log file: $LOG_FILE"
sudo touch "$LOG_FILE"
sudo chown $USER:$USER "$LOG_FILE"

# Create service file for Odoo
cat <<EOF | sudo tee /etc/systemd/system/odoo18.service
[Unit]
Description=Odoo18
Documentation=https://moxogo.com
[Service]
Type=simple
User=$SYSTEM_USER
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/odoo-bin -c /etc/odoo18.conf
[Install]
WantedBy=default.target
EOF

# Set permissions for the service file
sudo chmod 755 /etc/systemd/system/odoo18.service
sudo chown root: /etc/systemd/system/odoo18.service

# Reload systemd, start Odoo and enable it at boot
sudo systemctl daemon-reload
sudo systemctl enable odoo18

sudo systemctl stop odoo18
sudo -u odoo18 /odoo18/odoo-bin -d odoo18 -i base --stop-after-init
sudo systemctl start odoo18

# Function to install Nginx and configure as reverse proxy
install_nginx() {
    # Install Nginx and Certbot with proper plugins
    sudo apt install nginx python3-certbot python3-certbot-nginx -y
    
    # Ensure Nginx is running
    sudo systemctl start nginx
    sudo systemctl enable nginx

    # Remove existing symlink if it exists
    sudo rm -f /etc/nginx/sites-enabled/odoo
    sudo rm -f /etc/nginx/sites-available/odoo

    # Create initial HTTP-only configuration
    sudo tee /etc/nginx/sites-available/odoo <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Add .well-known location for SSL certificate validation
    location /.well-known {
        root /var/www/html;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

    # Enable the site
    sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl restart nginx

    # Request SSL certificate
    sudo certbot --nginx --agree-tos --email $EMAIL -d $DOMAIN --non-interactive

    # Create the final HTTPS configuration
    sudo tee /etc/nginx/sites-available/odoo <<EOF
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl;
    server_name $DOMAIN;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Proxy settings
    location / {
        proxy_pass http://127.0.0.1:$ODOO_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }

    # Static files
    location /web/static/ {
        alias $INSTALL_DIR/.local/share/Odoo/filestore/;
        expires 30d;
        access_log off;
    }

    # Increase timeouts for long polling
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    # General settings
    client_max_body_size 100M;
    keepalive_timeout 300;
}
EOF

    # Test and reload Nginx
    sudo nginx -t && sudo systemctl restart nginx

    # Setup auto-renewal for SSL certificate
    sudo systemctl enable certbot.timer
    sudo systemctl start certbot.timer

    echo "Nginx has been configured with SSL for $DOMAIN"
}

# Prompt user for proxy setup
read -p "Do you want to set up Nginx as a reverse proxy for Odoo? (yes/no): " setup_proxy

if [ "$setup_proxy" == "yes" ]; then
    install_nginx
else
    echo "Skipping Nginx setup. Odoo will be accessible via IP address only."
fi

# Check Odoo logs
sudo tail -f /var/log/odoo/odoo18.log
