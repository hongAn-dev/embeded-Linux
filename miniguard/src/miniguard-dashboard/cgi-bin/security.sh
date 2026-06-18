#!/bin/sh
echo "Content-Type: application/json"
echo ""

LOG_FILE="/var/log/messages"

if [ -f "$LOG_FILE" ]; then
    ENTRIES=$(grep "\[FW_DROP\]" "$LOG_FILE" | tail -20 | awk '
    {
        src="?"; dst="?"; proto="?"; dpt="?";
        for (i=1; i<=NF; i++) {
            if ($i ~ /^SRC=/) { split($i, a, "="); src=a[2] }
            if ($i ~ /^DST=/) { split($i, a, "="); dst=a[2] }
            if ($i ~ /^PROTO=/) { split($i, a, "="); proto=a[2] }
            if ($i ~ /^DPT=/) { split($i, a, "="); dpt=a[2] }
        }
        time=$1 " " $2 " " $3;
        printf "{\"time\":\"%s\",\"src\":\"%s\",\"dst\":\"%s\",\"proto\":\"%s\",\"port\":\"%s\"},", time, src, dst, proto, dpt
    }' | sed 's/,$//')
    COUNT=$(grep -c "\[FW_DROP\]" "$LOG_FILE")
else
    ENTRIES=""
    COUNT=0
fi

# Active iptables rules count
RULES=$(iptables -L -n 2>/dev/null | grep -c "^[A-Z]" || echo 0)

cat <<EOF
{
  "total_blocked": $COUNT,
  "active_rules": $RULES,
  "recent_events": [$ENTRIES]
}
EOF
