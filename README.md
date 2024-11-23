# InstallScript
Moxogo Install

# [Moxogo](https://moxogo.com "Moxogo's Homepage") Install Script

This script is based on the install script from Yenthe but goes a bit further and has been improved. This script will also give you the ability to define http_port in the .conf file that is generated under /etc/
This script can be safely used in a multi-odoo code base server because the default Odoo port is changed BEFORE the Odoo is started.

## Installing Nginx
If you set the parameter ```INSTALL_NGINX``` to ```True``` you should also configure workers. Without workers you will probably get connection loss issues. Look at [the deployment guide from Odoo](https://www.odoo.com/documentation/18.0/administration/install/deploy.html) on how to configure workers.

## Installation procedure

##### 1. Download the script:
```
sudo wget https://raw.githubusercontent.com/moxogo/InstallScript/refs/heads/main/moxogo_install.sh
```
```
sudo apt install nano
```

##### 2. Modify the parameters as you wish.
There are a few things you can configure, this is the most used list:<br/>
```OE_USER``` will be the username for the system user.<br/>
```GENERATE_RANDOM_PASSWORD``` if this is set to ```True``` the script will generate a random password, if set to ```False```we'll set the password that is configured in ```OE_SUPERADMIN```. By default the value is ```True``` and the script will generate a random and secure password.<br/>
```INSTALL_WKHTMLTOPDF``` set to ```False``` if you do not want to install Wkhtmltopdf, if you want to install it you should set it to ```True```.<br/>
```OE_PORT``` is the port where Odoo should run on, for example 8069.<br/>
```OE_VERSION``` is the Odoo version to install, for example ```16.0``` for Odoo V16.<br/>
```IS_ENTERPRISE``` will install the Enterprise version on top of ```16.0``` if you set it to ```True```, set it to ```False``` if you want the community version of Odoo 16.<br/>
```OE_SUPERADMIN``` is the master password for this Odoo installation.<br/>
```INSTALL_NGINX``` is set to ```False``` by default. Set this to ```True``` if you want to install Nginx.<br/>
```WEBSITE_NAME``` Set the website name here for nginx configuration<br/>
```ENABLE_SSL``` Set this to ```True``` to install [certbot](https://github.com/certbot/certbot) and configure nginx with https using a free Let's Encrypted certificate<br/>
```ADMIN_EMAIL``` Email is needed to register for Let's Encrypt registration. Replace the default placeholder with an email of your organisation.<br/>
```INSTALL_NGINX``` and ```ENABLE_SSL``` must be set to ```True``` and the placeholder in ```ADMIN_EMAIL``` must be replaced with a valid email address for certbot installation<br/>
  _By enabling SSL though Let's Encrypt you agree to the following [policies](https://www.eff.org/code/privacy/policy)_ <br/>

#### 3. Make the script executable
```
sudo chmod +x moxogo_install.sh
```
##### 4. Execute the script:
```
sudo ./moxogo_install.sh
```

## Minimal server requirements
While technically you can run an Odoo instance on 1GB (1024MB) of RAM it is absolutely not advised. A Linux instance typically uses 300MB-500MB and the rest has to be split among Odoo, postgreSQL and others. If you install an Odoo you should make sure to use at least 2GB of RAM. This script might fail with less resources too.

## Security Hardening
After installing Odoo, you can enhance your server's security by running the security hardening script.

##### 1. Download the security script:
```bash
sudo wget https://raw.githubusercontent.com/moxogo/InstallScript/refs/heads/main/secure_odoo.sh
```

##### 2. Make it executable:
```bash
sudo chmod +x secure_odoo.sh
```

##### 3. Configure security parameters (optional):
You can modify these security parameters in the script:
- `SSH_PORT`: SSH port number (default: 2222)
- `SSH_ALLOW_PASSWORD`: Allow password authentication (default: True)
- `FAIL2BAN_BANTIME`: Ban duration in seconds (default: 3600)
- `FAIL2BAN_FINDTIME`: Time window for failures in seconds (default: 300)
- `FAIL2BAN_MAXRETRY`: Maximum retry attempts (default: 3)

##### 4. Run the security script:
```bash
sudo ./secure_odoo.sh
```

The security script implements the following measures:
- SSH hardening with custom port
- UFW firewall configuration
- Fail2ban installation and configuration
- System parameter optimization
- PostgreSQL security hardening
- File permission security
- ClamAV antivirus installation
- Secure backup directory setup
- Audit system configuration

After running the script, make note of:
1. The new database password generated
2. The new SSH port (if you changed it from default 2222)
3. The UFW firewall rules
4. Location of the secure backup directory: `/var/backups/odoo`

**Note**: Make sure to save the database password shown at the end of the script execution, as it will be needed for database management.

## Remove old installations
If you have multiple versions of Odoo installed, you can remove the old ones by running the following commands:
```bash
sudo apt purge odoo
sudo apt autoremove
sudo userdel -r odoo
sudo rm -rf /odoo
sudo rm -f /usr/bin/node /usr/local/bin/node
sudo apt-get remove -y nodejs npm
sudo apt-get autoremove -y
```
```bash
source /odoo18/odoo-venv/bin/activate
cd /odoo18/odoo18-server
pip3 install -r requirements.txt
pip3 install babel psycopg2-binary werkzeug lxml python-dateutil pytz pillow gevent greenlet
```
