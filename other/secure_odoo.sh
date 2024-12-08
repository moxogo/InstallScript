#!/bin/bash
################################################################################
# Script for securing Odoo installation on Ubuntu 24.04
# Author: Willie
#-------------------------------------------------------------------------------
# This script will implement security measures for your Odoo installation
# Make the file executable:
# sudo chmod +x secure_odoo.sh
# Execute the script:
# ./secure_odoo.sh
################################################################################

# Configuration Variables
OE_USER="odoo"
OE_HOME="/$OE_USER"
OE_CONFIG="${OE_USER}-server"
SSH_PORT="2222"
SSH_ALLOW_PASSWORD="True"
FAIL2BAN_BANTIME="3600"
FAIL2BAN_FINDTIME="300"
FAIL2BAN_MAXRETRY="3"
OE_PORT="9090"
LONGPOLLING_PORT="8072"

# Generate random database password
DB_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

#--------------------------------------------------
# Security Improvements
#--------------------------------------------------
echo -e "\n---- Configuring System Security ----"

# Configure SSH
echo -e "\n---- Configuring SSH ----"
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
if [ "$SSH_ALLOW_PASSWORD" = "False" ]; then
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
fi
sudo systemctl restart sshd

# Install and Configure UFW Firewall
echo -e "\n---- Installing and Configuring Firewall ----"
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow $SSH_PORT/tcp  # SSH port
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow $OE_PORT/tcp # Odoo port
sudo ufw allow $LONGPOLLING_PORT/tcp # Odoo longpolling port
echo "y" | sudo ufw enable

# Install and Configure Fail2ban
echo -e "\n---- Configuring Fail2ban ----"
sudo apt-get install -y fail2ban
sudo cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = $FAIL2BAN_MAXRETRY
findtime = $FAIL2BAN_FINDTIME
bantime = $FAIL2BAN_BANTIME

[odoo]
enabled = true
port = $OE_PORT
filter = odoo
logpath = /var/log/$OE_USER/$OE_CONFIG.log
maxretry = 5
findtime = $FAIL2BAN_FINDTIME
bantime = $FAIL2BAN_BANTIME
EOF

# Create Odoo fail2ban filter
sudo cat <<EOF > /etc/fail2ban/filter.d/odoo.conf
[Definition]
failregex = ^.*Login failed for db:.*$
ignoreregex =
EOF

# Restart fail2ban
sudo systemctl restart fail2ban

# Install and configure auditd for system auditing
echo -e "\n---- Installing and Configuring Audit System ----"
sudo apt-get install -y auditd audispd-plugins
sudo systemctl enable auditd
sudo systemctl start auditd

# Configure System Parameters
echo -e "\n---- Configuring System Parameters ----"
sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak
sudo cat <<EOF >> /etc/sysctl.conf
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Increase system file descriptor limit
fs.file-max = 65535

# Increase TCP max buffer size
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864

# Increase number of incoming connections
net.core.somaxconn = 65535

# Decrease TIME_WAIT seconds
net.ipv4.tcp_fin_timeout = 20

# Decrease TIMEOUT for closing connections
net.ipv4.tcp_keepalive_time = 1200
EOF

sudo sysctl -p

# Secure PostgreSQL
echo -e "\n---- Securing PostgreSQL ----"
sudo -u postgres psql -c "ALTER USER $OE_USER WITH PASSWORD '$DB_PASSWORD';"
sudo sed -i "s/^local.*all.*all.*peer$/local   all             all                                     md5/" /etc/postgresql/*/main/pg_hba.conf
sudo sed -i "s/^host.*all.*all.*127.0.0.1.*ident$/host    all             all             127.0.0.1/32            md5/" /etc/postgresql/*/main/pg_hba.conf
sudo systemctl restart postgresql

# Update Odoo config with secure database password
sudo sed -i "s/db_password = ${OE_USER}/db_password = ${DB_PASSWORD}/" /etc/${OE_CONFIG}.conf

# Set secure permissions for Odoo
echo -e "\n---- Setting secure permissions ----"
sudo mkdir -p /var/log/$OE_USER
sudo chown -R $OE_USER:$OE_USER /var/log/$OE_USER
sudo chmod 755 /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

# Install ClamAV for antivirus protection
echo -e "\n---- Installing ClamAV Antivirus ----"
sudo apt-get install -y clamav clamav-daemon
sudo systemctl start clamav-freshclam
sudo systemctl enable clamav-freshclam

# Create backup directory with secure permissions
echo -e "\n---- Creating secure backup directory ----"
sudo mkdir -p /var/backups/odoo
sudo chown $OE_USER:$OE_USER /var/backups/odoo
sudo chmod 750 /var/backups/odoo

# Output important information
echo -e "\n---- Security Setup Complete ----"
echo "-----------------------------------------------------------"
echo "Security measures have been implemented!"
echo "New SSH Port: $SSH_PORT"
echo "UFW Status: Active"
echo "Fail2ban Status: Active"
echo "Audit System: Active"
echo "New Database Password: $DB_PASSWORD"
echo ""
echo "IMPORTANT: Please save the database password securely!"
echo "Make sure to update your SSH connection settings to use port $SSH_PORT"
echo "-----------------------------------------------------------"
