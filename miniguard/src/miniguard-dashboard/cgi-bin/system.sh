#!/bin/sh
echo "Content-Type: application/json"
echo ""

# CPU info
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
if [ -z "$CPU_MODEL" ]; then
    CPU_MODEL=$(grep "Processor" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
fi
CPU_CORES=$(grep -c "processor" /proc/cpuinfo)

# Load average
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
LOAD1=$(echo $LOAD | awk '{print $1}')
LOAD5=$(echo $LOAD | awk '{print $2}')
LOAD15=$(echo $LOAD | awk '{print $3}')

# Memory
MEM_TOTAL=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
MEM_FREE=$(grep "^MemFree:" /proc/meminfo | awk '{print $2}')
MEM_BUFFERS=$(grep "^Buffers:" /proc/meminfo | awk '{print $2}')
MEM_CACHED=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')

[ -z "$MEM_TOTAL" ] && MEM_TOTAL=1
[ -z "$MEM_FREE" ] && MEM_FREE=0
[ -z "$MEM_BUFFERS" ] && MEM_BUFFERS=0
[ -z "$MEM_CACHED" ] && MEM_CACHED=0

MEM_USED=$((MEM_TOTAL - MEM_FREE - MEM_BUFFERS - MEM_CACHED))
if [ $MEM_USED -lt 0 ]; then
    MEM_USED=$((MEM_TOTAL - MEM_FREE))
fi
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

# Uptime (seconds)
UPTIME_SEC=$(cut -d. -f1 /proc/uptime)
UPTIME_H=$((UPTIME_SEC / 3600))
UPTIME_M=$(( (UPTIME_SEC % 3600) / 60 ))

# Process count
PROC_COUNT=$(ls /proc | grep -c '^[0-9]')

cat <<EOF
{
  "hostname": "$(hostname)",
  "cpu_model": "${CPU_MODEL:-ARM Cortex-A9}",
  "cpu_cores": ${CPU_CORES:-1},
  "load_1": ${LOAD1:-0.00},
  "load_5": ${LOAD5:-0.00},
  "load_15": ${LOAD15:-0.00},
  "mem_total_kb": $MEM_TOTAL,
  "mem_used_kb": $MEM_USED,
  "mem_percent": $MEM_PERCENT,
  "uptime_h": $UPTIME_H,
  "uptime_m": $UPTIME_M,
  "process_count": $PROC_COUNT,
  "kernel": "$(uname -r)",
  "arch": "$(uname -m)"
}
EOF
