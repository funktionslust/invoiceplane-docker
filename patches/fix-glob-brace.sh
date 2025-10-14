#!/bin/bash
# Fix for GLOB_BRACE issue in Alpine/musl libc environments
# InvoicePlane v1.6.x uses GLOB_BRACE which is not supported in musl libc
# This patch replaces the problematic glob call with a compatible implementation

set -e

TARGET_FILE="/var/www/html/index.php"

# Check if the file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "WARNING: $TARGET_FILE not found. Skipping GLOB_BRACE patch."
    exit 0
fi

# Check if the file needs patching (look for GLOB_BRACE)
if ! grep -q "GLOB_BRACE" "$TARGET_FILE" 2>/dev/null; then
    echo "INFO: GLOB_BRACE not found in $TARGET_FILE. Patch may already be applied or not needed."
    exit 0
fi

echo "Applying GLOB_BRACE compatibility patch to $TARGET_FILE..."

# Create a temporary file with the fix
cat > /tmp/glob-fix.php << 'EOF'
// Automatic temp pdf & xml files cleanup (GLOB_BRACE compatibility fix)
$pdf_files = glob(UPLOADS_TEMP_FOLDER . '*.pdf');
$xml_files = glob(UPLOADS_TEMP_FOLDER . '*.xml');
if ($pdf_files === false) $pdf_files = [];
if ($xml_files === false) $xml_files = [];
array_map('unlink', array_merge($pdf_files, $xml_files));
EOF

# Find the line number containing GLOB_BRACE
LINE_NUM=$(grep -n "GLOB_BRACE" "$TARGET_FILE" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "WARNING: Could not find line with GLOB_BRACE. Skipping patch."
    exit 0
fi

echo "Found GLOB_BRACE at line $LINE_NUM"

# Create new file with the fix
head -n $((LINE_NUM - 1)) "$TARGET_FILE" > /tmp/index_new.php
cat /tmp/glob-fix.php >> /tmp/index_new.php
tail -n +$((LINE_NUM + 1)) "$TARGET_FILE" >> /tmp/index_new.php

# Replace the original file
mv /tmp/index_new.php "$TARGET_FILE"

# Cleanup
rm -f /tmp/glob-fix.php

echo "Successfully applied GLOB_BRACE compatibility patch"
