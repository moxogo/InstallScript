FROM nginx:alpine

# Switch to root user to install packages
USER root

# Install nano using apk (Alpine's package manager)
RUN apk add --no-cache nano

# Install envsubst
RUN apk add --no-cache gettext

# Set working directory
WORKDIR /etc/nginx

# The default nginx user is already non-root, so we don't need to switch
