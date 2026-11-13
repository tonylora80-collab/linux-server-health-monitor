#!/bin/bash

# Automated Linux Server Health & Security Monitor
# Copyright (c) 2026 C C Marketing Media Group LLC

REPORT_FILE="server_health_report.log"
TIMESTAMP=$(date -u "+%Y-%m-%d %H:%M:%S UTC")
DISK_THRESHOLD=80

echo "==========================================" | tee -a $REPORT_FILE
echo "SERVER HEALTH & SECURITY REPORT" | tee -a $REPORT_FILE
echo "Generated: $TIMESTAMP" | tee -a $REPORT_FILE
echo "Hostname:  $(hostname)" | tee -a $REPORT_FILE
echo "==========================================" | tee -a $REPORT_FILE

# 1. System Uptime
echo -e "\n[1] SYSTEM UPTIME:" | tee -a $REPORT_FILE
uptime -p | tee -a $REPORT_FILE

# 2. Memory (RAM) Usage
echo -e "\n[2] MEMORY USAGE:" | tee -a $REPORT_FILE
free -h | awk 'NR==1 || NR==2 {print $0}' | tee -a $REPORT_FILE

# 3. Root Disk Space Usage with Threshold Alert
echo -e "\n[3] DISK SPACE (/):" | tee -a $REPORT_FILE
df -h / | awk 'NR==1 || NR==2 {print $0}' | tee -a $REPORT_FILE

DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_PCT" -ge "$DISK_THRESHOLD" ]; then
    echo "[ALERT] Disk usage is at ${DISK_PCT}% (Exceeds ${DISK_THRESHOLD}% threshold)" | tee -a $REPORT_FILE
else
    echo "[OK] Disk usage is healthy at ${DISK_PCT}% (Threshold: ${DISK_THRESHOLD}%)" | tee -a $REPORT_FILE
fi

# 4. Security Audit: Check Failed Login Attempts
echo -e "\n[4] SECURITY AUDIT (Failed Logins):" | tee -a $REPORT_FILE
if [ -f /var/log/auth.log ]; then
    FAILED_COUNT=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0")
    echo "Failed password attempts (auth.log): $FAILED_COUNT" | tee -a $REPORT_FILE
elif command -v journalctl >/dev/null 2>&1; then
    FAILED_COUNT=$(journalctl -n 500 --no-pager 2>/dev/null | grep -ic "authentication failure\|Failed password" || echo "0")
    echo "Recent authentication failures (systemd journal): $FAILED_COUNT" | tee -a $REPORT_FILE
else
    echo "No authentication log source available." | tee -a $REPORT_FILE
fi

echo -e "\nReport saved to $REPORT_FILE\n"
