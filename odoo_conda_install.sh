#!/bin/bash

# Step 1: Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
source ~/.bashrc
conda init

# Step 2: Create a Conda environment with Python v12
conda create --name odoo-env python=12 -y
conda activate odoo-env

# Step 3: Install dependencies
conda install -c conda-forge babel libxslt libxml2 postgresql psycopg2 nodejs less wkhtmltopdf -y

# Step 4: Clone the Odoo v18 repository
git clone -b 18.0 https://github.com/odoo/odoo.git
cd odoo

# Step 5: Install Python dependencies
pip install -r requirements.txt

# Step 6: Configure PostgreSQL
sudo service postgresql start
sudo -u postgres createuser -s odoo
sudo -u postgres createdb odoo

# Step 7: Create Odoo configuration file
cp odoo.conf.example odoo.conf
sed -i 's/db_user = .*/db_user = odoo/' odoo.conf
sed -i 's/db_password = .*/db_password =/' odoo.conf

# Step 8: Start Odoo
./odoo-bin -c odoo.conf