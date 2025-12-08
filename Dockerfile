# IGV Web App Studio for Seqera Platform

# Add a default Connect client version. Can be overridden by build arg
ARG CONNECT_CLIENT_VERSION="0.8"

# Seqera base image
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

FROM ubuntu:20.04

# Install nginx, curl, and jq for downloading IGV webapp and processing JSON  
RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    nginx \
    curl \
    unzip \
    jq \
    python3 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy connect client from Seqera base image and install early
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

# Create directories for IGV webapp
RUN mkdir -p /opt/igv-webapp /etc/nginx/sites-enabled

# Download IGV webapp from GitHub releases
WORKDIR /tmp
RUN curl -L -o igv-webapp.zip https://github.com/igvteam/igv-webapp/archive/refs/heads/master.zip \
    && unzip igv-webapp.zip \
    && cp -r igv-webapp-master/* /opt/igv-webapp/ \
    && rm -rf igv-webapp.zip igv-webapp-master

# Copy nginx configuration template
COPY nginx.conf /etc/nginx/sites-available/igv-app

# Copy data discovery and config generation scripts
COPY discover-data-links.sh /usr/local/bin/discover-data-links.sh
COPY generate-igv-config.sh /usr/local/bin/generate-igv-config.sh
COPY igvwebConfig.template.js /opt/igv-webapp/js/igvwebConfig.template.js

# Copy example user config for documentation
COPY example-user-config.json /opt/igv-webapp/example-user-config.json

# Create startup script that uses dynamic port
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh \
    && chmod +x /usr/local/bin/discover-data-links.sh \
    && chmod +x /usr/local/bin/generate-igv-config.sh

# Remove default nginx configuration and create symlink
RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/igv-app /etc/nginx/sites-enabled/default

# Create a non-root user for better security
RUN useradd -m -s /bin/bash igvuser && \
    echo "igvuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to connect user
USER igvuser

# Use connect client as entrypoint with our startup script
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint", "/usr/local/bin/start.sh"]