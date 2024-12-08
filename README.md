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

sudo wget https://raw.githubusercontent.com/moxogo/InstallScript/refs/heads/main/harden_ubuntu.sh
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

## Odoo 18 Docker Production Installation Guide

This repository contains Docker configuration files and installation scripts for deploying Odoo 18 in a production environment.

## Prerequisites

- A VPS/Server with Ubuntu/Debian
- Domain name pointed to your server
- Basic knowledge of Docker and Linux commands

## Directory Structure

```bash
/odoo/
├── addons/           # Custom addons
├── config/           # Odoo configuration
├── logs/            # Log files
├── nginx/
│   ├── conf/        # Nginx configuration
│   ├── ssl/         # SSL certificates
│   └── letsencrypt/ # Let's Encrypt files
├── Dockerfile
├── docker-compose.prod.yml
├── install_production.sh
├── requirements.custom.txt  # Custom Python dependencies
└── .env
```

## Installation Steps

### 1. Initial Server Setup

```bash
# Connect to your server
ssh user@your-server-ip

# Clone the repository or create directory structure
mkdir -p /odoo
cd /odoo
```

```
git clone https://github.com/moxogo/InstallScript.git
```
```
sudo docker logs installscript-web-1
sudo docker logs installscript-nginx-1
```

```
# Rebuild the containers if needed
docker-compose -f docker-compose.prod.yml build

# Stop the containers
sudo docker-compose -f docker-compose.prod.yml down

# Start them again
sudo docker-compose -f docker-compose.prod.yml up -d
```
```
# Check Nginx configuration
sudo docker exec installscript-nginx-1 nginx -t

# Check if the configuration file is properly mounted
sudo docker exec installscript-nginx-1 ls -l /etc/nginx/conf.d/
```

```
# Check Nginx logs
sudo docker exec installscript-nginx-1 tail -f /var/log/nginx/access.log
sudo docker exec installscript-nginx-1 tail -f /var/log/nginx/error.log
```
```
# Add moxogo custom addons
sudo mkdir -p /odoo/moxogo18
sudo chown -R $USER:$USER /odoo/moxogo18

# Check if Odoo can see the custom addons
sudo docker logs installscript-web-1 | grep "moxogo"
``````

### 2. Run Installation Script

```bash
# Make script executable
chmod +x install_production.sh

# Before running the script, stop and disable system Nginx if it exists
sudo systemctl stop nginx
sudo systemctl disable nginx
sudo apt-get remove nginx nginx-common -y  # Optional: only if you want to completely remove system Nginx

# Run installation script
./install_production.sh
```

The script will:
- Stop and disable system Nginx if it exists
- Update system packages
- Install Docker and Docker Compose
- Create necessary directories
- Generate secure passwords
- Set up initial configuration

### 3. Configure Environment

Edit the `.env` file with your settings:
```bash
nano .env
```

Update the following variables:
```env
POSTGRES_PASSWORD=your_generated_postgres_password
ADMIN_PASSWORD=your_generated_admin_password
DOMAIN=your-domain.com
EMAIL=your-email@domain.com
```

### 4. Custom Python Dependencies

If your modules require additional Python packages:

1. Edit `requirements.custom.txt`:
```bash
nano requirements.custom.txt
```

2. Add your dependencies:
```txt
# Example:
pandas==2.0.0
numpy==1.24.0
requests==2.31.0
```

3. Rebuild the Docker image:
```bash
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

### 5. Custom Addons Configuration

1. Place your custom addons in `/odoo/moxogo18/`
2. The `addons_path` in `odoo.conf` is configured to include:
   - `/mnt/extra-addons`
   - `/mnt/custom-addons`
   - `/usr/lib/python3/dist-packages/odoo/addons`

3. Verify addons recognition:
```bash
docker logs installscript-web-1 | grep "addons paths"
```

### 6. WebSocket Configuration

The setup includes WebSocket support for real-time features:

1. Odoo Configuration (`config/odoo.conf`):
```ini
# WebSocket configuration
longpolling_port = 8072
websocket = True
```

2. Nginx Configuration includes WebSocket proxying:
```nginx
# WebSocket support
location /websocket {
    proxy_pass http://odoochat;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
}
```

## Security Setup

### Firewall Configuration

```bash
# Install and configure UFW
sudo apt-get install -y ufw
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# Install fail2ban
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Maintenance Commands

### Container Management

```bash
# Stop services
docker-compose -f docker-compose.prod.yml down

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Restart services
docker-compose -f docker-compose.prod.yml restart

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Backup Commands

```bash
# Backup database
docker-compose -f docker-compose.prod.yml exec db pg_dump -U odoo postgres > backup.sql

# Backup filestore
tar -czf filestore_backup.tar.gz /odoo/addons
```

### Update Commands

```bash
# Pull latest images
docker-compose -f docker-compose.prod.yml pull

# Rebuild and restart containers
docker-compose -f docker-compose.prod.yml up -d --build
```

## Post-Installation

1. Access Odoo at: https://your-domain.com
2. Create your first database using the admin password from `.env`
3. Install required modules
4. Configure outgoing email servers

## Monitoring

### Log Monitoring

```bash
# View Odoo logs
tail -f /odoo/logs/odoo.log

# View Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### System Monitoring

```bash
# Check container status
docker ps

# Check system resources
htop

# Check disk usage
df -h
```

## Automatic Updates

### SSL Certificate Renewal

```bash
# Test automatic renewal
sudo certbot renew --dry-run

# Add to crontab
echo "0 0 1 * * certbot renew" | sudo tee -a /etc/crontab
```

## Troubleshooting

### Common Issues

1. **Cannot connect to Odoo**
   - Check if containers are running: `docker ps`
   - Check Nginx logs: `tail -f /var/log/nginx/error.log`
   - Verify SSL certificate: `certbot certificates`

2. **Database connection issues**
   - Check PostgreSQL logs: `docker-compose -f docker-compose.prod.yml logs db`
   - Verify environment variables in `.env`

3. **Permission issues**
   - Run: `sudo chown -R $USER:$USER /odoo`
   - Check log file permissions: `ls -la /odoo/logs`

4. **WebSocket connection errors**
   - Check if port 8072 is accessible
   - Verify Nginx WebSocket configuration
   - Check Odoo logs for WebSocket-related errors:
     ```bash
     docker logs installscript-web-1 | grep -i "websocket"
     ```
   - Ensure proxy_mode and websocket are enabled in odoo.conf

5. **Custom addons not recognized**
   - Verify the addons path in odoo.conf
   - Check permissions of the custom addons directory
   - Update the apps list in Odoo interface
   - Check Odoo logs for addon loading errors

6. **Python dependency issues**
   - Check if requirements.custom.txt is properly formatted
   - Verify the Docker build logs for installation errors
   - Try installing dependencies manually in the container:
     ```bash
     docker exec -it installscript-web-1 pip3 install package_name
     ```

7. **Nginx port conflicts**
   - Check if system Nginx is running: `sudo systemctl status nginx`
   - Stop and disable system Nginx: `sudo systemctl stop nginx` and `sudo systemctl disable nginx`
   - Check what's using port 80: `sudo lsof -i :80`
   - Remove system Nginx (optional): `sudo apt-get remove nginx nginx-common -y` and `sudo apt-get autoremove -y`
   - Clean up Nginx directories: `sudo rm -rf /etc/nginx` and `sudo rm -rf /var/log/nginx`

## Support

For issues and support:
1. Check the logs
2. Review configuration files
3. Consult Odoo documentation
4. Check Docker documentation

## License

This installation guide and associated scripts are provided under [Your License].

## Remove old installations
If you have multiple versions of Odoo installed, you can remove the old ones by running the following commands:
```bash
sudo apt purge odoo
sudo apt autoremove
sudo userdel -r odoo
sudo rm -rf /odoo
sudo rm -f /usr/bin/node /usr/local/bin/node
sudo rm -rf /odoo18/mxg-venv
sudo apt-get remove -y nodejs npm
sudo apt-get autoremove -y
```
```bash
source /odoo18/mxg-venv/bin/activate
cd /odoo18/odoo18-server
pip3 install -r requirements.txt
pip3 install babel psycopg2-binary werkzeug lxml python-dateutil pytz pillow gevent greenlet
