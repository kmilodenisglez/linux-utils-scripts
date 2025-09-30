#!/bin/bash
# nvme-monitor.sh - NVMe monitor with rotating logs, cumulative alerts,
# secure error handling, desktop notifications, and Telegram (optional).
set -euo pipefail

# Optional: load env file if exists (useful when testing from shell)
# shellcheck disable=SC1090
[ -f "${HOME}/.config/nvme-monitor.env" ] && source "${HOME}/.config/nvme-monitor.env"

# --- Telegram Function ---
send_telegram() {
    local message="$1"
    if [ -n "${TELEGRAM_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
        # send text with simple Markdown-escaping (avoid problematic characters)
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
             -d chat_id="${TELEGRAM_CHAT_ID}" \
             -d text="$message" \
             -d parse_mode=Markdown > /dev/null 2>&1 || true
    fi
}

# --- Determine real user's home ---
if [ -n "${SUDO_USER:-}" ]; then
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    if [ -z "$USER_HOME" ]; then
        echo "Error: Could not determine the home directory of $SUDO_USER" >&2
        exit 1
    fi
else
    USER_HOME="$HOME"
fi

LOG_DIR="$USER_HOME/nvme_logs"
mkdir -p "$LOG_DIR"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT="$LOG_DIR/smart_report_$DATE.txt"
ALERTS="$LOG_DIR/alerts_accumulated.txt"

# --- Configure the environment to notify-send if we are under sudo ---
if [ -n "${SUDO_USER:-}" ]; then
    export DISPLAY="$(sudo -u "$SUDO_USER" printenv DISPLAY 2>/dev/null || echo '')"
    export DBUS_SESSION_BUS_ADDRESS="$(sudo -u "$SUDO_USER" printenv DBUS_SESSION_BUS_ADDRESS 2>/dev/null || echo '')"
fi

# --- Rotation helpers ---
rotate_reports() {
    find "$LOG_DIR" -maxdepth 1 -type f -name "smart_report_*.txt" -printf '%T@ %p\0' 2>/dev/null \
    | sort -z -n \
    | head -z -n -10 \
    | cut -z -d' ' -f2- \
    | xargs -0 -r rm -f || true
}
rotate_alerts() {
    if [ -f "$ALERTS" ] && [ "$(wc -l < "$ALERTS")" -gt 200 ]; then
        tail -n 200 "$ALERTS" > "$ALERTS.tmp" && mv "$ALERTS.tmp" "$ALERTS"
    fi
}

# --- Detect NVMe drives ---
mapfile -t DISKS < <(ls /dev/nvme*n1 2>/dev/null || true)
if [ ${#DISKS[@]} -eq 0 ]; then
    MSG="⚠️ No NVMe devices found (/dev/nvme*n1)"
    echo "$MSG" | tee -a "$ALERTS"
    rotate_alerts
    rotate_reports
    exit 0
fi

# Determine if smartctl needs sudo
if [ "$(id -u)" -ne 0 ]; then
    SMART_CMD="sudo /usr/sbin/smartctl"
else
    SMART_CMD="/usr/sbin/smartctl"
fi

ALERT_OCCURRED=false

{
    echo "=== NVMe SMART Monitor - $DATE ==="
} > "$REPORT"

for DISK in "${DISKS[@]}"; do
    MSG=""
    MSG_ERRORS=""

    if [ ! -b "$DISK" ]; then
        MSG="❌ The disk $DISK does not exist"
        echo "$MSG" | tee -a "$ALERTS"
        ALERT_OCCURRED=true
        continue
    fi

    echo -e "\n--- Report for $DISK ---" | tee -a "$REPORT"

    SMART_OUTPUT=$($SMART_CMD -a "$DISK" 2>&1 || true)
    echo "$SMART_OUTPUT" | tee -a "$REPORT"

    PERCENT_USED=$(echo "$SMART_OUTPUT" | grep -i "Percentage Used" | awk '{print $3}' | tr -d '%' || echo 0)
    ERRORS=$(echo "$SMART_OUTPUT" | grep -i "Error Information Log Entries" | awk '{print $5}' || echo 0)

    PERCENT_USED="${PERCENT_USED:-0}"
    ERRORS="${ERRORS:-0}"
    [[ "$PERCENT_USED" =~ ^[0-9]+$ ]] || PERCENT_USED=0
    [[ "$ERRORS" =~ ^[0-9]+$ ]] || ERRORS=0

    METRICS_FILE="$LOG_DIR/$(basename "$DISK")_metrics.txt"
    LAST_PERCENT=0
    LAST_ERRORS=0
    if [ -f "$METRICS_FILE" ]; then
        while IFS='=' read -r key value; do
            case "$key" in
                PERCENT)     LAST_PERCENT="$value" ;;
                ERRORS_PREV) LAST_ERRORS="$value" ;;
            esac
        done < "$METRICS_FILE"
    fi
    [[ "$LAST_PERCENT" =~ ^[0-9]+$ ]] || LAST_PERCENT=0
    [[ "$LAST_ERRORS" =~ ^[0-9]+$ ]] || LAST_ERRORS=0

    ALERT_TRIGGERED=false

    if [ "$PERCENT_USED" -gt "$LAST_PERCENT" ]; then
        MSG="⚠️ $DISK - Increased Percentage Used: $LAST_PERCENT% → $PERCENT_USED%"
        ALERT_TRIGGERED=true
    fi

    if [ "$ERRORS" -gt "$LAST_ERRORS" ]; then
        MSG_ERRORS="⚠️ $DISK - Errors increased: $LAST_ERRORS → $ERRORS"
        ALERT_TRIGGERED=true
    fi

    {
        echo "PERCENT=$PERCENT_USED"
        echo "ERRORS_PREV=$ERRORS"
    } > "$METRICS_FILE"

    if [ "$ALERT_TRIGGERED" = true ]; then
        ALERT_OCCURRED=true
        [ -n "${MSG:-}" ] && echo "$MSG" | tee -a "$ALERTS"
        [ -n "${MSG_ERRORS:-}" ] && echo "$MSG_ERRORS" | tee -a "$ALERTS"

        if [ -n "${DISPLAY:-}" ] && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
            [ -n "${MSG:-}" ] && notify-send --urgency=normal "SSD Monitor" "$MSG"
            [ -n "${MSG_ERRORS:-}" ] && notify-send --urgency=critical "SSD Monitor" "$MSG_ERRORS"
        fi

        [ -n "${MSG:-}" ] && send_telegram "$MSG"
        [ -n "${MSG_ERRORS:-}" ] && send_telegram "$MSG_ERRORS"
    fi
done

rotate_reports
rotate_alerts

if [ "$ALERT_OCCURRED" = false ]; then
    if [ -n "${DISPLAY:-}" ] && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        notify-send "SSD Monitor" "✅ Review completed - no issues detected"
    fi
    # Optional Telegram success notification
    send_telegram "✅ SSD Monitor: Review completed - no issues detected"
fi

exit 0
