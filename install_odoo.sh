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
ODOO_PORT=8069

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

echo "Installed Requirements. Press Enter to Continue!"
read

# Install Python3 virtual environment
sudo apt install -y python3-venv
sudo mkdir -p $VENV_DIR
sudo python3 -m venv $VENV_DIR

echo "Activated Virtual Environment.Press Enter to Continue!"
read

# Activate the virtual environment and install Odoo dependencies
source $VENV_DIR/bin/activate

# Install Python dependencies
sudo -H pip3 install -r $INSTALL_DIR/requirements.txt

# Install additional Python packages
#pip install pyopenssl geoip2 jinja2 babel psycopg2 polib lxml pypdf2 reportlab passlib pytz werkzeug Pillow reportlab PyPDF2 polib psycopg2-binary decorator python-dateutil lxml lxml[html_clean] beautifulsoup4 zeep psutil rjsmin docutils qrcode num2words vobject django-bootstrap4 lxml[html_clean] beautifulsoup4 libsass psycopg2-binary pdfminer python-crontab html2text pmdarima scipy numpy formio-data dropbox pysftp botocore boto3 paramiko pydrive2 openpyxl sortedcontainers redis>=4.5.4 prometheus-client>=0.17.1 psutil>=5.9.5 py-healthcheck>=1.10.1
pip install pyopenssl geoip2 jinja2 babel psycopg2 polib lxml pypdf2 reportlab passlib pytz werkzeug Pillow reportlab PyPDF2 polib psycopg2-binary decorator python-dateutil lxml lxml[html_clean] beautifulsoup4 zeep psutil rjsmin docutils qrcode num2words vobject django-bootstrap4 lxml[html_clean] beautifulsoup4 libsass psycopg2-binary pdfminer python-crontab html2text pmdarima scipy numpy formio-data dropbox pysftp botocore boto3 paramiko pydrive2 openpyxl sortedcontainers redis prometheus-client psutil py-healthcheck xlsxwriter python-stdnum

# Install Wkhtmltopdf and its dependencies
sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo apt-get install -y xfonts-75dpi
sudo apt install -f

# Fix broken packages
sudo apt-get install -f
deactivate

echo "Deactivate Virtual Environment.Press Enter to Continue!"
read

# Create a configuration file
sudo cp $INSTALL_DIR/debian/odoo.conf /etc/odoo18.conf
cat <<EOF | sudo tee /etc/odoo18.conf
[options]
admin_passwd = $ADMIN_PASSWORD
master_passwd = $ADMIN_PASSWORD
db_host = db
db_port = 5432
db_user = $POSTGRES_USER
db_password = $DB_PASSWORD
db_name = $POSTGRES_DB
addons_path = $INSTALL_DIR/addons,$INSTALL_DIR/moxogo18
data_dir = $INSTALL_DIR/data
http_port = $ODOO_PORT
longpolling_port = 8072
proxy_mode = True
workers = 4
max_cron_threads = 2
limit_time_cpu = 1200
limit_time_real = 2400
log_level = info
log_handler = [':INFO']
logfile = $LOG_FILE
logrotate = True
db_sslmode = disable
db_maxconn = 128
db_encoding = UTF8
dbfilter = .*
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
list_db = True
secure_cert_file = False
server_wide_modules = base,web
websocket = True
transient_age_limit = 1.0
osv_memory_count_limit = False
db_template = template0
unaccent = True
url_prefix = /mxg

# Performance settings
http_enable = True
http_interface =
gevent_port = 8072
xmlrpc = True
xmlrpc_interface =
db_prefetch = True
osv_memory_age_limit = 1.0
load_language = en_US
without_demo = True
log_db = False
log_db_level = warning
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
    # Install Nginx
    sudo apt install nginx -y

    # Install Certbot for SSL
    sudo apt install certbot python3-certbot-nginx -y

    # Create Nginx configuration for Odoo
    sudo tee /etc/nginx/sites-available/odoo <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Redirect HTTP to HTTPS
    location / {
        proxy_pass http://127.0.0.1:$ODOO_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Static files
    location /web/static/ {
        alias $INSTALL_DIR/.local/share/Odoo/filestore/;
    }
}

# HTTPS server
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:$ODOO_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Static files
    location /web/static/ {
        alias $INSTALL_DIR/.local/share/Odoo/filestore/;
    }
}
EOF

    # Enable the Nginx configuration
    sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/

    # Test Nginx configuration and restart Nginx
    sudo nginx -t && sudo systemctl restart nginx

    # Obtain SSL certificate
    sudo certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --no-eff-email

    echo "Nginx has been configured as a reverse proxy for Odoo v18 with SSL."
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
