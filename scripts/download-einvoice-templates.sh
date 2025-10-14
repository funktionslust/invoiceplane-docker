#!/bin/bash
set -e

# InvoicePlane E-Invoice Templates Downloader
# Downloads additional e-invoice templates from the official repository

REPO_URL="https://api.github.com/repos/InvoicePlane/InvoicePlane-e-invoices/contents"
TEMPLATES_DIR="application/libraries/XMLtemplates"
CONFIGS_DIR="application/helpers/XMLconfigs"

echo "================================================"
echo "InvoicePlane E-Invoice Templates Downloader"
echo "================================================"
echo ""

# Check if running in InvoicePlane directory
if [ ! -d "$TEMPLATES_DIR" ] || [ ! -d "$CONFIGS_DIR" ]; then
    echo "Error: This script must be run from the InvoicePlane root directory"
    echo "Expected directories:"
    echo "  - $TEMPLATES_DIR"
    echo "  - $CONFIGS_DIR"
    exit 1
fi

# Fetch available templates
echo "Fetching available e-invoice templates..."
echo ""

# Available templates (hardcoded list based on repository structure)
templates=(
    "Factur-X v1.0 (French)"
    "UBL 2.0 Example (Universal)"
    "ZUGFeRD v2.3 Extended (German)"
    "ZUGFeRD v2.3 Basic (German)"
    "ZUGFeRD v2.3 Basic WL (German)"
    "FacturaE v3.2 (Spanish)"
    "FatturaPA v1.2 (Italian)"
)

template_ids=(
    "facturxv10"
    "ublexamv20"
    "zugferdv23extended"
    "zugferdv23basic"
    "zugferdv23basicwl"
    "facturaev32"
    "fatturapav12"
)

echo "Available e-invoice templates:"
echo ""
for i in "${!templates[@]}"; do
    echo "$((i+1)). ${templates[$i]}"
done
echo "0. Exit"
echo ""

read -p "Select template to download (0-${#templates[@]}): " selection

if [ "$selection" = "0" ]; then
    echo "Exiting..."
    exit 0
fi

if [ "$selection" -lt 1 ] || [ "$selection" -gt "${#templates[@]}" ]; then
    echo "Error: Invalid selection"
    exit 1
fi

idx=$((selection-1))
selected_template="${templates[$idx]}"
selected_id="${template_ids[$idx]}"

echo ""
echo "Selected: $selected_template"
echo ""

# Download files
echo "Downloading template files..."

# Base raw GitHub URL
RAW_URL="https://raw.githubusercontent.com/InvoicePlane/InvoicePlane-e-invoices/development"

# Determine files to download based on template
needs_base_xml=false
template_file=""
config_file=""
additional_template_files=()

case "$selected_id" in
    "facturxv10")
        template_file="Facturxv10Xml.php"
        config_file="Facturxv10.php"
        needs_base_xml=true
        ;;
    "ublexamv20")
        template_file="Ublexamv20Xml.php"
        config_file="Ublexamv20.php"
        ;;
    "zugferdv23extended")
        template_file="Facturxv10Xml.php"  # Uses Facturxv10 generator
        config_file="Zugferdv23extended.php"
        needs_base_xml=true
        ;;
    "zugferdv23basic")
        template_file="Facturxv10Xml.php"  # Uses Facturxv10 generator
        config_file="Zugferdv23basic.php"
        needs_base_xml=true
        ;;
    "zugferdv23basicwl")
        template_file="Facturxv10Xml.php"  # Uses Facturxv10 generator
        config_file="Zugferdv23basicwl.php"
        needs_base_xml=true
        ;;
    "facturaev32")
        template_file="Facturaev32Xml.php"
        config_file="Facturaev32.php"
        additional_template_files=("Facturae/Constantes_4_0.php")
        ;;
    "fatturapav12")
        template_file="Fatturapav12Xml.php"
        config_file="Fatturapav12.php"
        ;;
    *)
        echo "Error: Unknown template ID"
        exit 1
        ;;
esac

# Download BaseXml.php if needed
if [ "$needs_base_xml" = true ]; then
    echo "  Checking for BaseXml.php dependency..."
    if [ -f "$TEMPLATES_DIR/BaseXml.php" ]; then
        echo "  [INFO] BaseXml.php already exists, updating..."
    fi
    if curl -fsSL "$RAW_URL/application/libraries/XMLtemplates/BaseXml.php" -o "$TEMPLATES_DIR/BaseXml.php"; then
        echo "  [OK] Downloaded BaseXml.php (required dependency)"
        chmod 644 "$TEMPLATES_DIR/BaseXml.php" 2>/dev/null || true
    else
        echo "  [ERROR] Failed to download BaseXml.php (required!)"
        echo "    Template may not work without this file"
    fi
fi

# Download template file
echo "  Downloading $template_file..."
if curl -fsSL "$RAW_URL/application/libraries/XMLtemplates/$template_file" -o "$TEMPLATES_DIR/$template_file"; then
    echo "  [OK] Downloaded $template_file"
    chmod 644 "$TEMPLATES_DIR/$template_file" 2>/dev/null || true
else
    echo "  [ERROR] Failed to download $template_file"
    echo "    Please check: $RAW_URL/application/libraries/XMLtemplates/$template_file"
    exit 1
fi

# Download additional template files if any
for extra_file in "${additional_template_files[@]}"; do
    echo "  Downloading additional file: $extra_file..."
    mkdir -p "$TEMPLATES_DIR/$(dirname "$extra_file")" 2>/dev/null || true
    if curl -fsSL "$RAW_URL/application/libraries/XMLtemplates/$extra_file" -o "$TEMPLATES_DIR/$extra_file"; then
        echo "  [OK] Downloaded $extra_file"
        chmod 644 "$TEMPLATES_DIR/$extra_file" 2>/dev/null || true
    else
        echo "  [WARN] Failed to download $extra_file (may be optional)"
    fi
done

# Download config file
echo "  Downloading $config_file..."
if curl -fsSL "$RAW_URL/application/helpers/XMLconfigs/$config_file" -o "$CONFIGS_DIR/$config_file"; then
    echo "  [OK] Downloaded $config_file"
    chmod 644 "$CONFIGS_DIR/$config_file" 2>/dev/null || true
else
    echo "  [ERROR] Failed to download $config_file"
    echo "    Please check: $RAW_URL/application/helpers/XMLconfigs/$config_file"
    exit 1
fi

# Download additional files if needed (e.g., FatturaPA has subdirectories)
if [ "$selected_id" = "fatturapav12" ]; then
    echo "  Downloading FatturaPA schema files..."
    mkdir -p "$TEMPLATES_DIR/fatturapa"

    # Download schema files
    for file in "Schema_del_file_xml_FatturaPA_versione_1.2.1.xsd" "xmldsig-core-schema.xsd"; do
        echo "    Downloading $file..."
        if curl -fsSL "$RAW_URL/application/libraries/XMLtemplates/fatturapa/$file" -o "$TEMPLATES_DIR/fatturapa/$file"; then
            echo "    [OK] Downloaded $file"
            chmod 644 "$TEMPLATES_DIR/fatturapa/$file" 2>/dev/null || true
        else
            echo "    [WARN] Failed to download $file (may cause validation errors)"
        fi
    done
fi

echo ""
echo "================================================"
echo "Installation complete!"
echo "================================================"
echo ""
echo "Template installed: $selected_template"
echo ""
echo "Next steps:"
echo "1. Go to InvoicePlane → Clients → Edit Client"
echo "2. In the 'E-Invoice' section, select '$selected_template'"
echo "3. Configure client details (VAT ID, address, etc.)"
echo "4. Generate invoices - XML will be created automatically"
echo ""
echo "For more information:"
echo "https://github.com/InvoicePlane/InvoicePlane-e-invoices"
echo ""
