FROM odoo:18.0

USER root

# Install dependencies and wkhtmltopdf
RUN apt-get update && apt-get install -y \
    wget \
    xfonts-base \
    xfonts-75dpi \
    libjpeg62 \
    python3-venv \
    && wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb \
    && dpkg -i wkhtmltox_0.12.6.1-3.jammy_amd64.deb \
    && apt-get install -f -y \
    && rm wkhtmltox_0.12.6.1-3.jammy_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories and set permissions
RUN mkdir -p /mnt/.local/sessions && \
    chown -R odoo:odoo /mnt/.local && \
    chmod -R 700 /mnt/.local

# Install Python dependencies in a virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python dependencies
COPY requirements.custom.txt /tmp/requirements.custom.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.custom.txt && \
    rm /tmp/requirements.custom.txt

USER odoo
