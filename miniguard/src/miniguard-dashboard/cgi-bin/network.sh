#!/bin/sh
echo "Content-Type: application/json"
echo ""

# Get eth0 interface info
ETH_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
ETH_MAC=$(ip link show eth0 2>/dev/null | grep "link/ether" | awk '{print $2}')

# Read traffic stats from /proc/net/dev
RAW_STATS=$(grep "eth0" /proc/net/dev)
if [ -n "$RAW_STATS" ]; then
    RX_BYTES=$(echo "$RAW_STATS" | sed 's/.*eth0://' | awk '{print $1}')
    TX_BYTES=$(echo "$RAW_STATS" | sed 's/.*eth0://' | awk '{print $9}')
else
    RX_BYTES=0
    TX_BYTES=0
fi

[ -z "$RX_BYTES" ] && RX_BYTES=0
[ -z "$TX_BYTES" ] && TX_BYTES=0

RX_MB=$(echo "$RX_BYTES" | awk '{printf "%.2f", $1/1048576}')
TX_MB=$(echo "$TX_BYTES" | awk '{printf "%.2f", $1/1048576}')

# Ping test to gateway (QEMU default user-net gateway is 10.0.2.2)
PING_RESULT=$(ping -c 1 -W 1 10.0.2.2 > /dev/null 2>&1 && echo "ok" || echo "fail")

# DNS Nameserver
DNS_NS=$(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}')

cat <<EOF
{
  "interface": "eth0",
  "ip": "${ETH_IP:-N/A}",
  "mac": "${ETH_MAC:-N/A}",
  "rx_mb": ${RX_MB:-0.00},
  "tx_mb": ${TX_MB:-0.00},
  "gateway_ping": "$PING_RESULT",
  "dns": "${DNS_NS:-N/A}"
}
EOF
