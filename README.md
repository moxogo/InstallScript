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
sudo rm -rf /odoo18/odoo-venv
sudo apt-get remove -y nodejs npm
sudo apt-get autoremove -y
```
```bash
source /odoo18/odoo-venv/bin/activate
cd /odoo18/odoo18-server
pip3 install -r requirements.txt
pip3 install babel psycopg2-binary werkzeug lxml python-dateutil pytz pillow gevent greenlet
```


Certainly! Here is the content for "Harden Ubuntu OS" converted into a GitHub markdown page:

# Harden Ubuntu OS

Hardening a Ubuntu OS, specifically version 24.04 and above, involves several steps to improve security. Below is a comprehensive script along with necessary configurations and optional recommendations to help you secure your system.

## Hardening Script for Ubuntu 24.04 and Above

### Script: `harden_ubuntu.sh`

```bash
#!/bin/bash

echo "Starting Ubuntu Hardening Script..."

# Update and Upgrade System
echo "Updating and upgrading system packages..."
sudo apt update -y
sudo apt upgrade -y
sudo apt dist-upgrade -y

# Remove Unnecessary Packages
echo "Removing unnecessary packages..."
sudo apt autoremove -y

# Install Security Tools
echo "Installing necessary security tools..."
sudo apt install -y fail2ban ufw apparmor clamav clamav-daemon unattended-upgrades

# Configure Unattended Upgrades
echo "Configuring unattended upgrades..."
sudo cp /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades.bak
echo 'APT::Periodic::Update-Package-Lists "1";' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades

# Enable and Configure UFW
echo "Enabling and configuring UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp  # Allow SSH
sudo ufw allow 80/tcp  # Allow HTTP
sudo ufw allow 443/tcp # Allow HTTPS
sudo ufw enable

# Enable and Configure AppArmor
echo "Enabling and configuring AppArmor..."
sudo systemctl enable apparmor
sudo systemctl start apparmor

# Install and Configure Fail2Ban
echo "Configuring Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Configure SSH
echo "Hardening SSH..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Install and Configure ClamAV
echo "Configuring ClamAV..."
sudo systemctl enable clamav-daemon
sudo systemctl start clamav-daemon
sudo freshclam
sudo clamscan -r / --bell -i

# Hardening File Permissions
echo "Hardening file permissions..."
sudo chmod 700 /home/*
sudo chmod 750 /var/log
sudo chmod 640 /etc/sudoers
sudo chmod 640 /etc/sudoers.d/*

# Verify Cron Jobs
echo "Verifying cron jobs..."
sudo chmod 600 /etc/crontab
sudo chmod 600 /etc/cron.hourly
sudo chmod 600 /etc/cron.daily
sudo chmod 600 /etc/cron.weekly
sudo chmod 600 /etc/cron.monthly
sudo chmod 600 /etc/cron.d
sudo chmod 600 /etc/cron.deny
sudo chmod 644 /etc/cron.allow

# Disable Unnecessary Services
echo "Disabling unnecessary services..."
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon

# Set Up Regular Backups
echo "Setting up regular backups..."
sudo apt install -y debconf-utils
sudo debconf-set-selections <<< "debconf debconf/frontend select noninteractive"
sudo apt install -y backupninja
sudo sed -i 's|# - day:|  - day:|' /etc/backupninja/nightly.conf

# Enable Automatic Security Updates
echo "Enabling automatic security updates..."
sudo sed -i 's|"\${distro_id}:${distro_codename}";|"\${distro_id}:${distro_codename}-security";|' /etc/apt/apt.conf.d/50unattended-upgrades

# Disable Root Login via Console
echo "Disabling root login via console..."
sudo passwd -l root

# Install and Configure Firewall GUI (Optional)
echo "Optionally installing GUFW for GUI management..."
sudo apt install -y gufw

echo "Ubuntu Hardening Script Completed."

Detailed Explanations and Optional Configurations
1. Update and Upgrade System
Command: sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y
Purpose: Ensure the system is up-to-date with the latest security patches.
2. Remove Unnecessary Packages
Command: sudo apt autoremove -y
Purpose: Remove unused packages to reduce attack surface.
3. Install Security Tools
Command: sudo apt install -y fail2ban ufw apparmor clamav clamav-daemon unattended-upgrades
Purpose: Install essential security tools:
Fail2Ban: Prevents brute-force attacks by banning IP addresses.
UFW (Uncomplicated Firewall): Simplifies firewall management.
AppArmor: Application confinement security module.
ClamAV: Antivirus software.
Unattended Upgrades: Manages automatic updates.
4. Configure Unattended Upgrades
Purpose: Ensure that security updates are applied automatically.
Configuration:
echo 'APT::Periodic::Update-Package-Lists "1";' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades

5. Enable and Configure UFW
Purpose: Secure the system by allowing only necessary traffic.
Configuration:
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp # HTTPS
sudo ufw enable

6. Enable and Configure AppArmor
Purpose: Enable AppArmor for application confinement.
Configuration:
sudo systemctl enable apparmor
sudo systemctl start apparmor

7. Install and Configure Fail2Ban
Purpose: Prevent brute-force attacks by monitoring log files and banning IP addresses.
Configuration:
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

8. Harden SSH
Purpose: Secure SSH access.
Configuration:
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

9. Install and Configure ClamAV
Purpose: Scan for malware and viruses.
Configuration:
sudo systemctl enable clamav-daemon
sudo systemctl start clamav-daemon
sudo freshclam
sudo clamscan -r / --bell -i

10. Harden File Permissions
Purpose: Ensure proper file permissions to prevent unauthorized access.
Configuration:
sudo chmod 700 /home/*
sudo chmod 750 /var/log
sudo chmod 640 /etc/sudoers
sudo chmod 640 /etc/sudoers.d/*

11. Verify Cron Jobs
Purpose: Ensure cron jobs are secure.
Configuration:
sudo chmod 600 /etc/crontab
sudo chmod 600 /etc/cron.hourly
sudo chmod 600 /etc/cron.daily
sudo chmod 600 /etc/cron.weekly
sudo chmod 600 /etc/cron.monthly
sudo chmod 600 /etc/cron.d
sudo chmod 600 /etc/cron.deny
sudo chmod 644 /etc/cron.allow

12. Disable Unnecessary Services
Purpose: Reduce attack vectors by disabling unnecessary services.
Configuration:
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon

13. Set Up Regular Backups
Purpose: Ensure data is backed up regularly.
Configuration:
sudo apt install -y debconf-utils
sudo debconf-set-selections <<< "debconf debconf/frontend select noninteractive"
sudo apt install -y backupninja
sudo sed -i 's|# - day:|  - day:|' /etc/backupninja/nightly.conf

14. Enable Automatic Security Updates
Purpose: Ensure that security updates are applied automatically.
Configuration:
sudo sed -i 's|"\${distro_id}:${distro_codename}";|"\${distro_id}:${distro_codename}-security";|' /etc/apt/apt.conf.d/50unattended-upgrades

15. Disable Root Login via Console
Purpose: Prevent root login via console to enhance security.
Configuration:
sudo passwd -l root

16. Install and Configure Firewall GUI (Optional)
Purpose: Provide a graphical user interface for managing the UFW firewall.
Optional Installation:
sudo apt install -y gufw

17. Secure Bootloader Configuration
Purpose: Secure the GRUB bootloader to prevent unauthorized access.
Configuration:
Set a GRUB password to prevent unauthorized access to the bootloader menu.
Edit the GRUB configuration file:
sudo nano /etc/default/grub

Add or modify the following line to set a password:
GRUB_CMDLINE_LINUX_DEFAULT="text"
GRUB_CMDLINE_LINUX=""
GRUB_PASSWORD="your_encrypted_password"

Use grub-mkpasswd-pbkdf2 to generate an encrypted password:
sudo grub-mkpasswd-pbkdf2

Add the generated password to the GRUB configuration file.
Update the GRUB configuration:
sudo update-grub

18. Install and Configure Intrusion Detection System (Optional)
Purpose: Detect and respond to unauthorized access attempts.
Optional Installation:
sudo apt install -y aide

Configuration:
Initialize the AIDE database:
sudo aideinit

Link the initial database to the active one:
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

19. Additional Security Best Practices
Purpose: Implement additional security practices to enhance system security.
Log Management:
Configure logrotate to manage log files:
sudo nano /etc/logrotate.conf

Ensure logs are rotated and deleted as needed.
Auditd:
Install and configure auditd for system auditing:
sudo apt install -y auditd audispd-plugins
sudo systemctl enable auditd
sudo systemctl start auditd

Configure auditing rules as needed.
Disable Unnecessary Filesystems:
Edit /etc/fstab to disable unnecessary filesystems:
sudo nano /etc/fstab

Comment out or remove entries for cgroup, tmpfs, debugfs, fuse, etc.
Kernel Parameters:
Configure kernel parameters for better security:
sudo nano /etc/sysctl.conf

Add the following lines:
# Enable IP forwarding
net.ipv4.ip_forward = 0

# Enable protection against SYN flood
net.ipv4.tcp_syncookies = 1

# Enable protection against IP spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable ICMP redirect acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# Disable ICMP send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Enable TCP SYN flood protection
net.ipv4.tcp_synack_retries = 2

# Increase the local port range
net.ipv4.ip_local_port_range = 1024 65000

# Enable EXEC Shield
kernel.exec-shield = 1
kernel.randomize_va_space = 2

20. Postfix Configuration (if applicable)
Purpose: Secure the Postfix mail server.
Configuration:
sudo nano /etc/postfix/main.cf

Ensure the following lines are set:
smtpd_use_tls = yes
smtpd_tls_cert_file = /path/to/certificate.crt
smtpd_tls_key_file = /path/to/private.key
smtpd_tls_auth_only = yes
smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination

21. Apache Configuration (if applicable)
Purpose: Secure the Apache web server.
Configuration:
sudo nano /etc/apache2/apache2.conf

Ensure the following lines are set:
ServerTokens Prod
ServerSignature Off
TraceEnable Off

Enable security modules like mod_security:
sudo apt install -y libapache2-mod-security2
sudo a2enmod security2
sudo systemctl restart apache2

Final Steps
Review and Test:
Review the configuration files and settings to ensure they meet your security requirements.
Test the system to ensure that all configurations are working as expected without disrupting services.
Regular Audits:
Regularly audit your system for vulnerabilities and misconfigurations.
Use security tools like lynis or OpenVAS for vulnerability scanning.
Running the Script

To run the script, save it to a file (e.g., harden_ubuntu.sh), make it executable, and execute it:

sudo nano harden_ubuntu.sh
sudo chmod +x harden_ubuntu.sh
sudo ./harden_ubuntu.sh


By following these steps and configurations, you can significantly enhance the security of your Ubuntu 24.04 and above system.


Feel free to copy this markdown content into your GitHub repository. If you need any further assistance or modifications, let me know!
