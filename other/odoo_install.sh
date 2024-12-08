#!/bin/bash

# Update the server
echo "Updating the server..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install necessary dependencies
echo "Installing necessary dependencies..."
sudo apt-get install -y git python3-pip build-essential wget python3-dev python3-venv \
                       libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev \
                       libssl-dev libffi-dev libxml2-dev libpq-dev \
                       libjpeg-dev libsasl2-modules libldap2-dev libpng-dev

# Install PostgreSQL
echo "Installing PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib

# Create a new PostgreSQL user for Odoo
echo "Creating PostgreSQL user for Odoo..."
sudo -u postgres createuser -s odoo
sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'odoo';"

# Install Wkhtmltopdf
echo "Installing Wkhtmltopdf..."
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.6/wkhtmltox_0.12.6-1.focal_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6-1.focal_amd64.deb
sudo apt-get install -f
rm wkhtmltox_0.12.6-1.focal_amd64.deb

# Create Odoo user
echo "Creating Odoo system user..."
sudo adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --gecos 'ODOO' --group odoo

# Create Odoo directory
echo "Creating Odoo directory..."
sudo mkdir /var/log/odoo
sudo chown odoo:odoo /var/log/odoo

# Install Python dependencies
echo "Creating Python virtual environment..."
sudo -u odoo mkdir -p /opt/odoo/odoo18_venv
sudo -u odoo python3 -m venv /opt/odoo/odoo18_venv
source /opt/odoo/odoo18_venv/bin/activate

echo "Installing Python dependencies..."
pip install --upgrade pip
pip install Babel PyPDF2 passlib pillow decorator pyusb greenlet gevent psutil num2words
pip install -r https://raw.githubusercontent.com/odoo/odoo/18.0/requirements.txt

# Deactivate virtual environment
deactivate

# Clone Odoo 18
echo "Cloning Odoo 18..."
sudo -u odoo git clone -b 18.0 https://www.github.com/odoo/odoo /opt/odoo/odoo-server

# Create custom config file
echo "Creating custom config file..."
sudo mkdir -p /etc/odoo
sudo cp /opt/odoo/odoo-server/debian/odoo.conf /etc/odoo/odoo.conf
sudo chown odoo: /etc/odoo/odoo.conf
sudo chmod 640 /etc/odoo/odoo.conf

# Set permissions
echo "Setting permissions..."
sudo chown -R odoo: /opt/odoo/

# Create startup file
echo "Creating startup file..."
sudo cp /opt/odoo/odoo-server/debian/init.d/odoo /etc/init.d/odoo
sudo sed -i "s#DAEMON=/usr/bin/odoo#DAEMON=/opt/odoo/odoo18_venv/bin/python /opt/odoo/odoo-server/odoo-bin#" /etc/init.d/odoo
sudo sed -i "s#CONFIGFILE=\"/etc/odoo/odoo.conf\"#CONFIGFILE=\"/etc/odoo/odoo.conf\"#" /etc/init.d/odoo
sudo chmod +x /etc/init.d/odoo
sudo chown root: /etc/init.d/odoo

# Modify configuration file
echo "Modifying configuration file..."
sudo sed -i 's#db_user = odoo#db_user = odoo#' /etc/odoo/odoo.conf
sudo sed -i "s#logfile = /var/log/odoo/odoo-server.log#logfile = /var/log/odoo/odoo-server.log#" /etc/odoo/odoo.conf

# Enable and start Odoo service
echo "Enabling and starting Odoo service..."
sudo update-rc.d odoo defaults
sudo service odoo start

# Cleanup
echo "Installation completed. Cleaning up..."
sudo apt-get clean

echo "Odoo 18 is now installed and running. You can access it at http://<your_server_ip>:8069"