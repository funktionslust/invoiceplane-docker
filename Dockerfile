FROM php:8.1-apache-bookworm

LABEL maintainer="Funktionslust GmbH - Wolfgang Stark <info@funktionslust.digital>" \
      org.opencontainers.image.title="InvoicePlane" \
      org.opencontainers.image.description="Self-hosted open source invoicing application" \
      org.opencontainers.image.url="https://invoiceplane.com" \
      org.opencontainers.image.source="https://github.com/funktionslust/invoiceplane-docker" \
      org.opencontainers.image.vendor="Funktionslust"

# Build arguments
ARG INVOICEPLANE_VERSION=1.6.3
ARG DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV INVOICEPLANE_VERSION=${INVOICEPLANE_VERSION} \
    TZ=UTC \
    PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_FILESIZE=32M \
    PHP_POST_MAX_SIZE=32M \
    PHP_MAX_EXECUTION_TIME=300 \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_DOCUMENT_ROOT=/var/www/html \
    PROXY_NETWORKS="172.16.0.0/12 10.0.0.0/8"

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    nano \
    vim \
    wget \
    unzip \
    curl \
    ca-certificates \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    mariadb-client \
    tzdata \
    supervisor \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    exif \
    gd \
    intl \
    mysqli \
    pdo_mysql \
    soap \
    xml \
    xsl \
    zip \
    opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable Apache modules
RUN a2enmod rewrite headers expires deflate mime

# Configure PHP
RUN { \
    echo 'memory_limit = ${PHP_MEMORY_LIMIT}'; \
    echo 'upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}'; \
    echo 'post_max_size = ${PHP_POST_MAX_SIZE}'; \
    echo 'max_execution_time = ${PHP_MAX_EXECUTION_TIME}'; \
    echo 'date.timezone = ${TZ}'; \
    echo 'expose_php = Off'; \
    echo 'display_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /var/log/apache2/php_errors.log'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.interned_strings_buffer = 8'; \
    echo 'opcache.max_accelerated_files = 10000'; \
    echo 'opcache.revalidate_freq = 2'; \
    echo 'opcache.fast_shutdown = 1'; \
    echo 'opcache.enable_cli = 0'; \
    } > /usr/local/etc/php/conf.d/invoiceplane.ini

# Configure Apache virtual host
RUN { \
    echo '<VirtualHost *:80>'; \
    echo '    ServerAdmin webmaster@localhost'; \
    echo '    DocumentRoot /var/www/html'; \
    echo ''; \
    echo '    <Directory /var/www/html>'; \
    echo '        Options -Indexes +FollowSymLinks'; \
    echo '        AllowOverride All'; \
    echo '        Require all granted'; \
    echo '        DirectoryIndex index.php index.html'; \
    echo '    </Directory>'; \
    echo ''; \
    echo '    # Trust proxy headers (configured dynamically by entrypoint)'; \
    echo '    RemoteIPHeader X-Forwarded-For'; \
    echo ''; \
    echo '    # Security headers'; \
    echo '    Header always set X-Content-Type-Options "nosniff"'; \
    echo '    Header always set X-Frame-Options "SAMEORIGIN"'; \
    echo '    Header always set X-XSS-Protection "1; mode=block"'; \
    echo '    Header always set Referrer-Policy "strict-origin-when-cross-origin"'; \
    echo ''; \
    echo '    # Logging'; \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log'; \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined'; \
    echo ''; \
    echo '    # Compression'; \
    echo '    <IfModule mod_deflate.c>'; \
    echo '        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json'; \
    echo '    </IfModule>'; \
    echo '</VirtualHost>'; \
    } > /etc/apache2/sites-available/000-default.conf

# Enable Apache RemoteIP module for proxy support
RUN a2enmod remoteip

# Download and install InvoicePlane
WORKDIR /tmp
RUN if [ "${INVOICEPLANE_VERSION}" = "development" ]; then \
        wget -q https://github.com/InvoicePlane/InvoicePlane/archive/refs/heads/development.zip -O invoiceplane.zip; \
    else \
        wget -q https://github.com/InvoicePlane/InvoicePlane/releases/download/v${INVOICEPLANE_VERSION}/v${INVOICEPLANE_VERSION}.zip -O invoiceplane.zip; \
    fi \
    && unzip -q invoiceplane.zip -d /tmp/invoiceplane \
    && rm invoiceplane.zip \
    && mv /tmp/invoiceplane/*/* /var/www/html/ \
    && rm -rf /tmp/invoiceplane

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html/uploads/archive \
    /var/www/html/uploads/customer_files \
    /var/www/html/uploads/temp \
    /var/www/html/application/logs \
    && chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

# Copy entrypoint script and utility scripts
COPY docker-entrypoint.sh /usr/local/bin/
COPY scripts/download-einvoice-templates.sh /usr/local/bin/
COPY scripts/view-logs.sh /usr/local/bin/logs
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/download-einvoice-templates.sh /usr/local/bin/logs

# Create volumes for persistent data
VOLUME ["/var/www/html/uploads", "/var/www/html/application/logs"]

WORKDIR /var/www/html

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
