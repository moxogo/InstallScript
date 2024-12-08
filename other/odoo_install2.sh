# Update the server
sudo apt-get update
sudo apt-get upgrade -y
# Install necessary packages and libraries
sudo apt-get install -y python3-pip python3-dev libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev npm git
# Install Node.js and npm
sudo apt-get install -y nodejs
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css
sudo apt-get install -y node-less
# Install PostgreSQL
sudo apt-get install -y postgresql
sudo su - postgres -c "createuser --createdb --username postgres --no-createrole --superuser --pwprompt odoo18"
# Create a system user for Odoo
sudo adduser --system --home=/opt/odoo18 --group odoo18
# Switch to the Odoo system user
sudo su - odoo18 -s /bin/bash
# Clone the Odoo repository
git clone https://www.github.com/odoo/odoo --depth 1 --branch master --single-branch .
# Exit the Odoo user session
exit
# Install Python virtual environment package
sudo apt install -y python3-venv
# Create a Python virtual environment
sudo python3 -m venv /odoo18/venv
# Activate the virtual environment
sudo -s
cd /odoo18/
source /odoo18/venv/bin/activate
# Install Python dependencies
pip install -r requirements.txt
# Install wkhtmltopdf
sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.6/wkhtmltox_0.12.6-1.focal_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6-1.focal_amd64.deb
sudo apt-get install -y xfonts-75dpi
sudo apt install -f
# Deactivate the virtual environment
deactivate
# Create Odoo configuration file
sudo cp /odoo18/debian/odoo.conf /etc/odoo18.conf
sudo nano /etc/odoo18.conf
# Add the following content to the configuration file
# [options]
# admin_passwd = admin
# db_host = False
# db_port = False
# db_user = odoo18
# db_password = False
# addons_path = /opt/odoo18/addons
# logfile = /var/log/odoo/odoo.log
# Start Odoo server
sudo /opt/odoo18/venv/bin/python3 /opt/odoo18/odoo-bin -c /etc/odoo18.conf
