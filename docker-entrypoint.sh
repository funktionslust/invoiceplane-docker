#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Function to wait for database
wait_for_db() {
    if [ -n "${DB_HOST}" ] && [ -n "${DB_PORT}" ]; then
        log "Waiting for database at ${DB_HOST}:${DB_PORT}..."
        timeout=60
        while ! mysqladmin ping -h"${DB_HOST}" -P"${DB_PORT}" --silent; do
            timeout=$((timeout - 1))
            if [ $timeout -eq 0 ]; then
                log "ERROR: Database connection timeout!"
                exit 1
            fi
            sleep 1
        done
        log "Database is ready!"
    fi
}

# Helper function to safely set ipconfig value (only if current value is empty)
set_ipconfig_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    local current_value

    current_value=$(grep "^${key}=" "${file}" | cut -d'=' -f2-)

    # Only set if current value is empty
    if [ -z "${current_value}" ] || [ "${current_value}" = "''" ] || [ "${current_value}" = '""' ]; then
        sed -i "s|^${key}=.*|${key}=${value}|" "${file}"
        return 0
    fi
    return 1
}

# Function to setup InvoicePlane configuration
setup_config() {
    local db_config="/var/www/html/application/config/database.php"
    local ip_config="/var/www/html/ipconfig.php"
    local config_config="/var/www/html/application/config/config.php"

    # Create ipconfig.php if it doesn't exist
    if [ ! -f "${ip_config}" ]; then
        log "Creating ipconfig.php..."
        if [ -f "/var/www/html/ipconfig.php.example" ]; then
            cp /var/www/html/ipconfig.php.example "${ip_config}"
            chown www-data:www-data "${ip_config}"
            chmod 644 "${ip_config}"
            log "ipconfig.php created from example"
        else
            log "WARNING: ipconfig.php.example not found"
        fi
    fi

    # Configure ipconfig.php values from environment variables
    # Only set if the value is currently empty (don't overwrite setup wizard values)
    if [ -f "${ip_config}" ]; then
        log "Configuring ipconfig.php from environment variables..."

        # IP_URL - always update (not set by setup wizard)
        if [ -n "${IP_URL}" ]; then
            sed -i "s|^IP_URL=.*|IP_URL=${IP_URL}|" "${ip_config}"
            log "  Set IP_URL=${IP_URL}"
        fi

        # ENABLE_DEBUG
        if [ -n "${ENABLE_DEBUG}" ]; then
            sed -i "s|^ENABLE_DEBUG=.*|ENABLE_DEBUG=${ENABLE_DEBUG}|" "${ip_config}"
            log "  Set ENABLE_DEBUG=${ENABLE_DEBUG}"
        fi

        # CI_ENV
        if [ -n "${CI_ENV}" ]; then
            sed -i "s|^CI_ENV=.*|CI_ENV=${CI_ENV}|" "${ip_config}"
            log "  Set CI_ENV=${CI_ENV}"
        fi

        # X_FRAME_OPTIONS
        if [ -n "${X_FRAME_OPTIONS}" ]; then
            sed -i "s|^X_FRAME_OPTIONS=.*|X_FRAME_OPTIONS=${X_FRAME_OPTIONS}|" "${ip_config}"
            log "  Set X_FRAME_OPTIONS=${X_FRAME_OPTIONS}"
        fi

        # ENABLE_X_CONTENT_TYPE_OPTIONS
        if [ -n "${ENABLE_X_CONTENT_TYPE_OPTIONS}" ]; then
            sed -i "s|^ENABLE_X_CONTENT_TYPE_OPTIONS=.*|ENABLE_X_CONTENT_TYPE_OPTIONS=${ENABLE_X_CONTENT_TYPE_OPTIONS}|" "${ip_config}"
            log "  Set ENABLE_X_CONTENT_TYPE_OPTIONS=${ENABLE_X_CONTENT_TYPE_OPTIONS}"
        fi

        # SESS_REGENERATE_DESTROY
        if [ -n "${SESS_REGENERATE_DESTROY}" ]; then
            sed -i "s|^SESS_REGENERATE_DESTROY=.*|SESS_REGENERATE_DESTROY=${SESS_REGENERATE_DESTROY}|" "${ip_config}"
            log "  Set SESS_REGENERATE_DESTROY=${SESS_REGENERATE_DESTROY}"
        fi

        # DISABLE_SETUP
        if [ -n "${DISABLE_SETUP}" ]; then
            sed -i "s|^DISABLE_SETUP=.*|DISABLE_SETUP=${DISABLE_SETUP}|" "${ip_config}"
            log "  Set DISABLE_SETUP=${DISABLE_SETUP}"
        fi

        # REMOVE_INDEXPHP
        if [ -n "${REMOVE_INDEXPHP}" ]; then
            sed -i "s|^REMOVE_INDEXPHP=.*|REMOVE_INDEXPHP=${REMOVE_INDEXPHP}|" "${ip_config}"
            log "  Set REMOVE_INDEXPHP=${REMOVE_INDEXPHP}"
        fi

        # Database settings - only if empty (setup wizard sets these)
        if [ -n "${IP_DB_HOSTNAME}" ]; then
            if set_ipconfig_value "${ip_config}" "DB_HOSTNAME" "'${IP_DB_HOSTNAME}'"; then
                log "  Set DB_HOSTNAME=${IP_DB_HOSTNAME}"
            fi
        fi

        if [ -n "${IP_DB_USERNAME}" ]; then
            if set_ipconfig_value "${ip_config}" "DB_USERNAME" "'${IP_DB_USERNAME}'"; then
                log "  Set DB_USERNAME=${IP_DB_USERNAME}"
            fi
        fi

        if [ -n "${IP_DB_PASSWORD}" ]; then
            if set_ipconfig_value "${ip_config}" "DB_PASSWORD" "'${IP_DB_PASSWORD}'"; then
                log "  Set DB_PASSWORD=***"
            fi
        fi

        if [ -n "${IP_DB_DATABASE}" ]; then
            if set_ipconfig_value "${ip_config}" "DB_DATABASE" "'${IP_DB_DATABASE}'"; then
                log "  Set DB_DATABASE=${IP_DB_DATABASE}"
            fi
        fi

        if [ -n "${IP_DB_PORT}" ]; then
            if set_ipconfig_value "${ip_config}" "DB_PORT" "${IP_DB_PORT}"; then
                log "  Set DB_PORT=${IP_DB_PORT}"
            fi
        fi

        # SESS_EXPIRATION
        if [ -n "${SESS_EXPIRATION}" ]; then
            sed -i "s|^SESS_EXPIRATION=.*|SESS_EXPIRATION=${SESS_EXPIRATION}|" "${ip_config}"
            log "  Set SESS_EXPIRATION=${SESS_EXPIRATION}"
        fi

        # SESS_MATCH_IP
        if [ -n "${SESS_MATCH_IP}" ]; then
            sed -i "s|^SESS_MATCH_IP=.*|SESS_MATCH_IP=${SESS_MATCH_IP}|" "${ip_config}"
            log "  Set SESS_MATCH_IP=${SESS_MATCH_IP}"
        fi

        # LEGACY_CALCULATION - only if empty (setup wizard may set this)
        if [ -n "${LEGACY_CALCULATION}" ]; then
            if set_ipconfig_value "${ip_config}" "LEGACY_CALCULATION" "${LEGACY_CALCULATION}"; then
                log "  Set LEGACY_CALCULATION=${LEGACY_CALCULATION}"
            fi
        fi

        # ENABLE_INVOICE_DELETION
        if [ -n "${ENABLE_INVOICE_DELETION}" ]; then
            sed -i "s|^ENABLE_INVOICE_DELETION=.*|ENABLE_INVOICE_DELETION=${ENABLE_INVOICE_DELETION}|" "${ip_config}"
            log "  Set ENABLE_INVOICE_DELETION=${ENABLE_INVOICE_DELETION}"
        fi

        # DISABLE_READ_ONLY
        if [ -n "${DISABLE_READ_ONLY}" ]; then
            sed -i "s|^DISABLE_READ_ONLY=.*|DISABLE_READ_ONLY=${DISABLE_READ_ONLY}|" "${ip_config}"
            log "  Set DISABLE_READ_ONLY=${DISABLE_READ_ONLY}"
        fi

        # SUMEX_SETTINGS
        if [ -n "${SUMEX_SETTINGS}" ]; then
            sed -i "s|^SUMEX_SETTINGS=.*|SUMEX_SETTINGS=${SUMEX_SETTINGS}|" "${ip_config}"
            log "  Set SUMEX_SETTINGS=${SUMEX_SETTINGS}"
        fi

        # SUMEX_URL
        if [ -n "${SUMEX_URL}" ]; then
            sed -i "s|^SUMEX_URL=.*|SUMEX_URL=${SUMEX_URL}|" "${ip_config}"
            log "  Set SUMEX_URL=${SUMEX_URL}"
        fi

        log "ipconfig.php configuration complete"
    fi

    # Auto-disable setup if it's completed (unless explicitly set to false)
    if [ -f "${ip_config}" ]; then
        local setup_completed=$(grep "^SETUP_COMPLETED=" "${ip_config}" | cut -d'=' -f2)
        local disable_setup=$(grep "^DISABLE_SETUP=" "${ip_config}" | cut -d'=' -f2)

        if [ "${setup_completed}" = "true" ] && [ "${disable_setup}" != "true" ] && [ -z "${DISABLE_SETUP}" ]; then
            log "Setup completed, automatically disabling setup wizard for security"
            sed -i "s|^DISABLE_SETUP=.*|DISABLE_SETUP=true|" "${ip_config}"
        fi
    fi

    # Configure proxy headers support
    if [ -f "${config_config}" ]; then
        log "Configuring proxy header support..."
        # Add proxy configuration if not already present
        if ! grep -q "proxy_ips" "${config_config}"; then
            sed -i "/\$config\['index_page'\]/a \$config['proxy_ips'] = '';" "${config_config}"
        fi
        log "Proxy configuration updated"
    fi

    # Create database.php if it doesn't exist or if forced
    if [ ! -f "${db_config}" ] || [ "${FORCE_CONFIG_UPDATE}" = "true" ]; then
        log "Setting up database configuration..."

        if [ -n "${IP_DB_HOSTNAME}" ] && [ -n "${IP_DB_DATABASE}" ] && [ -n "${IP_DB_USERNAME}" ] && [ -n "${IP_DB_PASSWORD}" ]; then
            cat > "${db_config}" << EOF
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

\$active_group = 'default';
\$query_builder = TRUE;

\$db['default'] = array(
    'dsn'   => '',
    'hostname' => '${IP_DB_HOSTNAME}',
    'username' => '${IP_DB_USERNAME}',
    'password' => '${IP_DB_PASSWORD}',
    'database' => '${IP_DB_DATABASE}',
    'dbdriver' => 'mysqli',
    'dbprefix' => '${IP_DB_PREFIX:-ip_}',
    'pconnect' => FALSE,
    'db_debug' => FALSE,
    'cache_on' => FALSE,
    'cachedir' => '',
    'char_set' => 'utf8',
    'dbcollat' => 'utf8_general_ci',
    'swap_pre' => '',
    'encrypt' => FALSE,
    'compress' => FALSE,
    'stricton' => FALSE,
    'failover' => array(),
    'save_queries' => TRUE
);
EOF
            chown www-data:www-data "${db_config}"
            chmod 644 "${db_config}"
            log "Database configuration created successfully"
        else
            log "WARNING: Database environment variables not set. Please configure manually."
        fi
    else
        log "Database configuration already exists. Skipping setup."
    fi
}

# Function to set proper permissions
set_permissions() {
    log "Setting file permissions..."

    # Ensure critical directories exist
    mkdir -p /var/www/html/uploads/archive \
             /var/www/html/uploads/customer_files \
             /var/www/html/uploads/temp \
             /var/www/html/application/logs

    # Set ownership
    chown -R www-data:www-data /var/www/html/uploads \
                                /var/www/html/application/logs \
                                /var/www/html/application/config 2>/dev/null || true

    # Set permissions
    find /var/www/html/uploads -type d -exec chmod 755 {} \; 2>/dev/null || true
    find /var/www/html/uploads -type f -exec chmod 644 {} \; 2>/dev/null || true
    find /var/www/html/application/logs -type d -exec chmod 755 {} \; 2>/dev/null || true
    find /var/www/html/application/logs -type f -exec chmod 644 {} \; 2>/dev/null || true

    log "Permissions set successfully"
}

# Function to setup timezone
setup_timezone() {
    if [ -n "${TZ}" ]; then
        log "Setting timezone to ${TZ}..."
        ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
        echo "${TZ}" > /etc/timezone
    fi
}

# Function to configure proxy networks
configure_proxy_networks() {
    local apache_conf="/etc/apache2/sites-available/000-default.conf"

    if [ -n "${PROXY_NETWORKS}" ]; then
        log "Configuring trusted proxy networks: ${PROXY_NETWORKS}"

        # Remove existing RemoteIPInternalProxy lines if any
        sed -i '/RemoteIPInternalProxy/d' "${apache_conf}"

        # Add new RemoteIPInternalProxy directives after RemoteIPHeader
        for network in ${PROXY_NETWORKS}; do
            log "  Adding trusted proxy network: ${network}"
            sed -i "/RemoteIPHeader X-Forwarded-For/a \    RemoteIPInternalProxy ${network}" "${apache_conf}"
        done

        log "Proxy network configuration complete"
    else
        log "No PROXY_NETWORKS specified, using defaults from image"
    fi
}

# Function to install e-invoice templates
install_einvoice_templates() {
    if [ -n "${INSTALL_EINVOICE_TEMPLATES}" ]; then
        log "Installing e-invoice templates: ${INSTALL_EINVOICE_TEMPLATES}"

        local script_path="/usr/local/bin/download-einvoice-templates.sh"

        if [ ! -f "${script_path}" ]; then
            log "ERROR: E-invoice download script not found at ${script_path}"
            return 1
        fi

        cd /var/www/html

        # Split comma-separated template list
        IFS=',' read -ra TEMPLATES <<< "${INSTALL_EINVOICE_TEMPLATES}"

        for template_id in "${TEMPLATES[@]}"; do
            # Trim whitespace
            template_id=$(echo "${template_id}" | xargs)

            log "  Installing template: ${template_id}"

            # Map template ID to selection number
            case "${template_id}" in
                facturxv10|facturx|1)
                    selection=1
                    ;;
                ublexamv20|ubl|2)
                    selection=2
                    ;;
                zugferdv23extended|zugferd-extended|3)
                    selection=3
                    ;;
                zugferdv23basic|zugferd-basic|4)
                    selection=4
                    ;;
                zugferdv23basicwl|zugferd-basicwl|5)
                    selection=5
                    ;;
                facturaev32|facturae|6)
                    selection=6
                    ;;
                fatturapav12|fatturapa|7)
                    selection=7
                    ;;
                *)
                    log "  ERROR: Unknown template ID: ${template_id}"
                    log "  Valid options: facturxv10, ublexamv20, zugferdv23extended, zugferdv23basic, zugferdv23basicwl, facturaev32, fatturapav12"
                    continue
                    ;;
            esac

            # Run the download script non-interactively
            if echo "${selection}" | bash "${script_path}" > /dev/null 2>&1; then
                log "  [OK] Template ${template_id} installed successfully"
            else
                log "  [ERROR] Failed to install template ${template_id}"
            fi
        done

        log "E-invoice template installation complete"
    fi
}

# Main execution
main() {
    log "Starting InvoicePlane container initialization..."

    # Setup timezone
    setup_timezone

    # Configure proxy networks
    configure_proxy_networks

    # Wait for database if configured
    if [ -n "${IP_DB_HOSTNAME}" ]; then
        # Set DB_HOST and DB_PORT for wait_for_db function
        DB_HOST="${IP_DB_HOSTNAME}"
        DB_PORT="${IP_DB_PORT:-3306}"
        wait_for_db
    fi

    # Setup configuration
    setup_config

    # Set permissions
    set_permissions

    # Install e-invoice templates if requested
    install_einvoice_templates

    log "Initialization complete. Starting application..."

    # Execute the main command
    exec "$@"
}

# Run main function
main "$@"
