#!/bin/bash
# InvoicePlane Application Log Viewer
# View application logs from InvoicePlane

set -e

LOG_DIR="/var/www/html/application/logs"
FOLLOW=false
LINES=50

usage() {
    cat << EOF
Usage: logs [OPTIONS]

View InvoicePlane application logs

OPTIONS:
    -f, --follow        Follow log output (tail -f)
    -n, --lines N       Show last N lines (default: 50)
    -h, --help          Show this help message

EXAMPLES:
    logs           # Show last 50 lines
    logs -f        # Follow logs
    logs -n 100    # Show last 100 lines

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Find the most recent log file
LOG_FILE=$(ls -t ${LOG_DIR}/log-*.php 2>/dev/null | head -1)

if [ -z "$LOG_FILE" ]; then
    echo "No log files found in ${LOG_DIR}"
    exit 1
fi

echo "Viewing: $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# View logs
if [ "$FOLLOW" = true ]; then
    tail -f "$LOG_FILE"
else
    tail -n "$LINES" "$LOG_FILE"
fi
