# MiniGuard — Work Plan

> **Dự án:** Building a Linux Based Embedded System Using Buildroot  
> **Tên sản phẩm:** MiniGuard — Custom Embedded Linux Security Monitor  
> **Platform:** QEMU ARM (vexpress-a9) trên Ubuntu VM  
> **Nhóm:** 2–3 người · 3 tuần

---

## Mục lục

1. [Tổng quan sản phẩm](#1-tổng-quan-sản-phẩm)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Phân công công việc](#3-phân-công-công-việc)
4. [Tuần 1 — Build nền tảng](#4-tuần-1--build-nền-tảng)
5. [Tuần 2 — Xây dựng tính năng](#5-tuần-2--xây-dựng-tính-năng)
6. [Tuần 3 — Tích hợp & Demo](#6-tuần-3--tích-hợp--demo)
7. [Chi tiết kỹ thuật từng module](#7-chi-tiết-kỹ-thuật-từng-module)
8. [Kịch bản demo](#8-kịch-bản-demo)
9. [Tiêu chí đánh giá](#9-tiêu-chí-đánh-giá)
10. [Cấu trúc thư mục dự án](#10-cấu-trúc-thư-mục-dự-án)
11. [Lệnh tham khảo nhanh](#11-lệnh-tham-khảo-nhanh)

---

## 1. Tổng quan sản phẩm

### MiniGuard là gì?

MiniGuard là một hệ thống Linux nhúng tối giản được build hoàn toàn từ source bằng Buildroot, chạy trên QEMU ARM. Hệ thống đóng vai trò một **embedded security gateway** có khả năng tự giám sát và hiển thị trạng thái qua web browser.

### Điểm khác biệt so với nhóm khác

Phần lớn các nhóm khi làm Buildroot chỉ dừng ở mức: chạy `make menuconfig` → `make` → boot được là xong. MiniGuard làm xa hơn ở ba điểm:

- Hệ thống có **mục đích cụ thể** (security monitor), không phải Linux chạy rỗng
- Có **web dashboard thực sự** mở được bằng trình duyệt, nhìn vào là hiểu hệ thống đang làm gì
- Toàn bộ ứng dụng được đóng gói thành **custom Buildroot package** đúng chuẩn — đây là phần kỹ thuật sâu nhất và ít nhóm nào làm tới

### Tính năng cuối cùng

| Tính năng | Mô tả | Độ khó |
|-----------|-------|--------|
| QEMU boot | Hệ thống boot trong < 5 giây | Cơ bản |
| SSH access | Dropbear SSH vào hệ thống từ host | Cơ bản |
| System monitor | Dashboard hiển thị CPU, RAM, uptime, process list | Trung bình |
| Network monitor | Hiển thị IP, interface, traffic stats | Trung bình |
| Firewall | iptables rules + log blocked connections | Trung bình |
| Security log viewer | Tab trên web hiển thị firewall log realtime | Trung bình |
| Custom package | Toàn bộ dashboard là 1 Buildroot package chuẩn | Nâng cao |
| Auto-start | Dashboard tự khởi động cùng hệ thống | Nâng cao |

---

## 2. Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────┐
│                    HOST MACHINE                          │
│              Ubuntu VM (Buildroot env)                   │
│                                                          │
│   Browser ──HTTP:80──►  ┌──────────────────────────┐   │
│   Terminal ──SSH:22──►  │   QEMU ARM vexpress-a9   │   │
│                         │                            │   │
│                         │  ┌──────────────────────┐ │   │
│                         │  │  U-Boot Bootloader   │ │   │
│                         │  └──────────┬───────────┘ │   │
│                         │             │              │   │
│                         │  ┌──────────▼───────────┐ │   │
│                         │  │  Linux Kernel 6.x    │ │   │
│                         │  │  netfilter · virtio  │ │   │
│                         │  └──────────┬───────────┘ │   │
│                         │             │              │   │
│                         │  ┌──────────▼───────────┐ │   │
│                         │  │  Root Filesystem     │ │   │
│                         │  │  BusyBox + musl libc │ │   │
│                         │  └──────────┬───────────┘ │   │
│                         │             │              │   │
│                         │  ┌──────────▼───────────┐ │   │
│                         │  │   System Services    │ │   │
│                         │  │  Dropbear │ lighttpd  │ │   │
│                         │  │  iptables │ syslogd   │ │   │
│                         │  └──────────┬───────────┘ │   │
│                         │             │              │   │
│                         │  ┌──────────▼───────────┐ │   │
│                         │  │  miniguard-dashboard │ │   │
│                         │  │  (Custom BR Package) │ │   │
│                         │  │  Shell CGI · HTML UI │ │   │
│                         │  └──────────────────────┘ │   │
│                         └──────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Luồng dữ liệu dashboard

```
/proc/cpuinfo ──►
/proc/meminfo ──►  [shell CGI script]  ──► lighttpd ──► Browser
/proc/net/dev ──►       parse &
/var/log/fw.log ──►    format JSON
```

---

## 3. Phân công công việc

### Nếu nhóm 3 người

| | Người A — System Lead | Người B — App Dev | Người C — Integration |
|---|---|---|---|
| **Tuần 1** | Buildroot config, QEMU boot, kernel modules | Nghiên cứu lighttpd + CGI trên BusyBox | Cấu hình iptables, test network trong QEMU |
| **Tuần 2** | Viết custom package `.mk` + `Config.in` | Viết 3 CGI scripts (system / network / security) | Firewall rules + log parser script |
| **Tuần 3** | Tích hợp tất cả vào 1 build, fix boot issues | Hoàn thiện HTML UI (auto-refresh, đẹp hơn) | Viết báo cáo + chuẩn bị slide demo |

### Nếu nhóm 2 người

| | Người A — Backend + System | Người B — Frontend + Docs |
|---|---|---|
| **Tuần 1** | Buildroot config, QEMU, kernel, iptables | Nghiên cứu CGI, viết prototype HTML dashboard |
| **Tuần 2** | Custom package, init script, firewall log | CGI scripts, HTML UI hoàn chỉnh |
| **Tuần 3** | Tích hợp, build cuối, fix bug | Báo cáo, slide, kịch bản demo |

### Quy tắc làm việc nhóm

- Dùng Git: branch `main` (ổn định) + `dev` (đang làm) + `feature/tên-tính-năng`
- Họp nhanh 15 phút mỗi ngày: làm gì hôm qua, hôm nay, bị chặn ở đâu
- Mỗi tính năng xong phải test được bằng lệnh cụ thể trước khi merge

---

## 4. Tuần 1 — Build nền tảng

**Mục tiêu cuối tuần:** Hệ thống boot được trên QEMU, SSH vào được, ping ra ngoài được

### Ngày 1–2: Setup Buildroot

```bash
# Lấy Buildroot bản ổn định
cd ~
wget https://buildroot.org/downloads/buildroot-2024.02.tar.gz
tar xf buildroot-2024.02.tar.gz
cd buildroot-2024.02

# Dùng defconfig cho QEMU ARM làm điểm xuất phát
make qemu_arm_vexpress_defconfig

# Mở menuconfig để xem và điều chỉnh
make menuconfig
```

### Ngày 2: Cấu hình trong menuconfig

Đi qua từng mục theo thứ tự sau, chỉ thay đổi những gì cần thiết:

```
Target options
  └─ Target Architecture: ARM (Little Endian)
  └─ Target Architecture Variant: cortex-A9
  └─ Target ABI: EABIhf

Toolchain
  └─ C library: musl          ← nhẹ hơn glibc, phù hợp embedded
  └─ Enable C++ support: YES  ← cần cho một số package

System configuration
  └─ System hostname: miniguard
  └─ System banner: Welcome to MiniGuard Embedded Linux
  └─ Root password: miniguard123
  └─ Network interface to configure: eth0
  └─ IP to assign: 10.0.2.15           ← QEMU user-mode networking

Target packages
  └─ Networking applications
      └─ [*] dropbear           ← SSH server
      └─ [*] lighttpd           ← web server
      └─ [*] iptables           ← firewall
  └─ Shell and utilities
      └─ [*] busybox            ← đã bật sẵn
  └─ System tools
      └─ [*] procps-ng          ← ps, top với nhiều option hơn

Filesystem images
  └─ ext2/3/4 root filesystem: YES
      └─ ext4
  └─ exact size: 64M
```

### Ngày 3: Kernel config

```bash
make linux-menuconfig
```

Các module cần bật:

```
Networking support
  └─ Networking options
      └─ [*] Network packet filtering (Netfilter)   ← cần cho iptables
          └─ [*] IP: Netfilter Configuration
              └─ [*] iptables support
              └─ [*] Packet filtering
              └─ [*] LOG target support              ← ghi log firewall

Device Drivers
  └─ [*] Virtio drivers                             ← QEMU virtual devices
      └─ [*] PCI driver for virtio devices
      └─ [*] Virtio network driver
      └─ [*] Virtio block driver

File systems
  └─ [*] Proc filesystem support
  └─ [*] Sysfs filesystem support
  └─ [*] Tmpfs virtual memory filesystem
```

### Ngày 4–5: Build lần đầu và boot

```bash
# Build (lần đầu mất 45–90 phút tùy máy)
make -j$(nproc) 2>&1 | tee build.log

# Kết quả nằm ở:
ls output/images/
# zImage           ← kernel
# vexpress*.dtb    ← device tree
# rootfs.ext4      ← root filesystem

# Boot với QEMU
qemu-system-arm \
  -M vexpress-a9 \
  -kernel output/images/zImage \
  -dtb output/images/vexpress-v2p-ca9.dtb \
  -drive file=output/images/rootfs.ext4,if=sd,format=raw \
  -append "root=/dev/mmcblk0 rw console=ttyAMA0,115200" \
  -nographic \
  -net nic \
  -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80
```

**Giải thích lệnh QEMU quan trọng:**
- `-net user,hostfwd=tcp::2222-:22` → forward port 2222 trên host vào port 22 (SSH) trong QEMU
- `hostfwd=tcp::8080-:80` → forward port 8080 trên host vào port 80 (web) trong QEMU

**Test checklist cuối tuần 1:**
```bash
# Từ host, SSH vào QEMU
ssh -p 2222 root@localhost     # password: miniguard123

# Trong QEMU kiểm tra
hostname          # phải ra: miniguard
uname -r          # xem kernel version
ip addr           # kiểm tra eth0 có IP
ping 10.0.2.2     # ping ra gateway QEMU
free -m           # kiểm tra RAM
df -h             # kiểm tra storage
cat /proc/cpuinfo # phải thấy ARM Cortex-A9
```

**Nếu build thất bại:**
```bash
# Xem 50 dòng lỗi cuối
tail -50 build.log | grep -i error

# Rebuild một package cụ thể
make <package-name>-rebuild

# Clean và build lại từ đầu (khi thay đổi toolchain/kernel)
make clean && make
```

---

## 5. Tuần 2 — Xây dựng tính năng

**Mục tiêu cuối tuần:** Dashboard chạy được, firewall log được, custom package tồn tại trong Buildroot tree

### Module A: Rootfs Overlay

Tạo cấu trúc thư mục để override file trong rootfs:

```bash
mkdir -p board/miniguard/rootfs_overlay/etc/init.d
mkdir -p board/miniguard/rootfs_overlay/etc/lighttpd
mkdir -p board/miniguard/rootfs_overlay/usr/share/miniguard/cgi-bin
mkdir -p board/miniguard/rootfs_overlay/usr/share/miniguard/html
mkdir -p board/miniguard/rootfs_overlay/var/log
```

Trong `menuconfig`, bật overlay:

```
System configuration
  └─ Root filesystem overlay directories: board/miniguard/rootfs_overlay
```

### Module B: lighttpd Web Server Config

Tạo file `board/miniguard/rootfs_overlay/etc/lighttpd/lighttpd.conf`:

```
server.modules = (
    "mod_cgi",
    "mod_rewrite"
)

server.document-root = "/usr/share/miniguard/html"
server.port          = 80
server.bind          = "0.0.0.0"

# CGI config
cgi.assign = ( ".sh" => "/bin/sh" )

# MIME types
mimetype.assign = (
    ".html" => "text/html",
    ".css"  => "text/css",
    ".json" => "application/json"
)

server.errorlog = "/var/log/lighttpd-error.log"
accesslog.filename = "/var/log/lighttpd-access.log"
```

### Module C: CGI Scripts

**Script 1 — System info** (`cgi-bin/system.sh`):

```bash
#!/bin/sh
echo "Content-Type: application/json"
echo ""

# CPU info
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
CPU_CORES=$(grep -c "processor" /proc/cpuinfo)

# Load average
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
LOAD1=$(echo $LOAD | awk '{print $1}')
LOAD5=$(echo $LOAD | awk '{print $2}')
LOAD15=$(echo $LOAD | awk '{print $3}')

# Memory
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_FREE=$(grep MemFree /proc/meminfo | awk '{print $2}')
MEM_USED=$((MEM_TOTAL - MEM_FREE))
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
  "cpu_model": "$CPU_MODEL",
  "cpu_cores": $CPU_CORES,
  "load_1": $LOAD1,
  "load_5": $LOAD5,
  "load_15": $LOAD15,
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
```

**Script 2 — Network info** (`cgi-bin/network.sh`):

```bash
#!/bin/sh
echo "Content-Type: application/json"
echo ""

# Lấy thông tin eth0
ETH_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
ETH_MAC=$(ip link show eth0 2>/dev/null | grep "link/ether" | awk '{print $2}')

# Đọc traffic stats từ /proc/net/dev
RX_BYTES=$(grep "eth0" /proc/net/dev | awk '{print $2}')
TX_BYTES=$(grep "eth0" /proc/net/dev | awk '{print $10}')
RX_MB=$(echo "$RX_BYTES 1048576" | awk '{printf "%.2f", $1/$2}')
TX_MB=$(echo "$TX_BYTES 1048576" | awk '{printf "%.2f", $1/$2}')

# Ping test ra gateway
PING_RESULT=$(ping -c 1 -W 1 10.0.2.2 > /dev/null 2>&1 && echo "ok" || echo "fail")

cat <<EOF
{
  "interface": "eth0",
  "ip": "${ETH_IP:-N/A}",
  "mac": "${ETH_MAC:-N/A}",
  "rx_mb": $RX_MB,
  "tx_mb": $TX_MB,
  "gateway_ping": "$PING_RESULT",
  "dns": "$(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}')"
}
EOF
```

**Script 3 — Security / Firewall log** (`cgi-bin/security.sh`):

```bash
#!/bin/sh
echo "Content-Type: application/json"
echo ""

LOG_FILE="/var/log/fw.log"

# Đọc 20 dòng log gần nhất
if [ -f "$LOG_FILE" ]; then
    ENTRIES=$(tail -20 "$LOG_FILE" | while IFS= read -r line; do
        # Parse dòng log dạng: Jan  1 00:00:00 kernel: [FW_DROP] IN=eth0 SRC=...
        TIME=$(echo "$line" | awk '{print $1, $2, $3}')
        SRC=$(echo "$line" | grep -o 'SRC=[^ ]*' | cut -d= -f2)
        DST=$(echo "$line" | grep -o 'DST=[^ ]*' | cut -d= -f2)
        PROTO=$(echo "$line" | grep -o 'PROTO=[^ ]*' | cut -d= -f2)
        DPT=$(echo "$line" | grep -o 'DPT=[^ ]*' | cut -d= -f2)
        echo "{\"time\":\"$TIME\",\"src\":\"${SRC:-?}\",\"dst\":\"${DST:-?}\",\"proto\":\"${PROTO:-?}\",\"port\":\"${DPT:-?}\"},"
    done | sed '$ s/,$//')
    COUNT=$(wc -l < "$LOG_FILE")
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
```

### Module D: HTML Dashboard

Tạo `html/index.html` — giao diện web tự động refresh mỗi 5 giây:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="refresh" content="5">
<title>MiniGuard Dashboard</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'Courier New', monospace;
    background: #0d1117;
    color: #c9d1d9;
    min-height: 100vh;
    padding: 20px;
  }
  header {
    border-bottom: 1px solid #21262d;
    padding-bottom: 16px;
    margin-bottom: 24px;
    display: flex;
    align-items: center;
    gap: 12px;
  }
  header h1 { font-size: 20px; color: #58a6ff; letter-spacing: 2px; }
  .badge {
    background: #1a7f37;
    color: #3fb950;
    font-size: 11px;
    padding: 2px 8px;
    border-radius: 10px;
    border: 1px solid #3fb950;
  }
  .tabs {
    display: flex;
    gap: 4px;
    margin-bottom: 20px;
    border-bottom: 1px solid #21262d;
  }
  .tab {
    padding: 8px 16px;
    cursor: pointer;
    font-size: 13px;
    color: #8b949e;
    border-bottom: 2px solid transparent;
    margin-bottom: -1px;
  }
  .tab.active { color: #58a6ff; border-bottom-color: #58a6ff; }
  .panel { display: none; }
  .panel.active { display: block; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin-bottom: 20px; }
  .card {
    background: #161b22;
    border: 1px solid #21262d;
    border-radius: 6px;
    padding: 16px;
  }
  .card .label { font-size: 11px; color: #8b949e; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }
  .card .value { font-size: 22px; color: #e6edf3; font-weight: bold; }
  .card .sub { font-size: 12px; color: #8b949e; margin-top: 4px; }
  .bar-wrap { background: #21262d; border-radius: 3px; height: 6px; margin-top: 8px; overflow: hidden; }
  .bar { height: 100%; border-radius: 3px; background: #58a6ff; transition: width 0.5s; }
  .bar.warn { background: #d29922; }
  .bar.danger { background: #f85149; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th { text-align: left; color: #8b949e; padding: 8px 12px; border-bottom: 1px solid #21262d; font-weight: normal; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; }
  td { padding: 8px 12px; border-bottom: 1px solid #161b22; }
  tr:hover td { background: #161b22; }
  .tag { font-size: 11px; padding: 2px 6px; border-radius: 4px; }
  .tag.drop { background: #3d1f1f; color: #f85149; border: 1px solid #f85149; }
  .tag.ok { background: #1a2e1a; color: #3fb950; border: 1px solid #3fb950; }
  .timestamp { font-size: 12px; color: #8b949e; text-align: right; }
  section h2 { font-size: 14px; color: #8b949e; margin-bottom: 12px; letter-spacing: 1px; }
</style>
</head>
<body>

<header>
  <h1>⬡ MINIGUARD</h1>
  <span class="badge">● ONLINE</span>
  <div style="margin-left:auto" class="timestamp" id="ts"></div>
</header>

<div class="tabs">
  <div class="tab active" onclick="show('sys',this)">System</div>
  <div class="tab" onclick="show('net',this)">Network</div>
  <div class="tab" onclick="show('sec',this)">Security</div>
</div>

<!-- System Panel -->
<div class="panel active" id="panel-sys">
  <div class="grid" id="sys-cards">
    <div class="card"><div class="label">Loading...</div></div>
  </div>
</div>

<!-- Network Panel -->
<div class="panel" id="panel-net">
  <div class="grid" id="net-cards">
    <div class="card"><div class="label">Loading...</div></div>
  </div>
</div>

<!-- Security Panel -->
<div class="panel" id="panel-sec">
  <div class="grid" id="sec-cards">
    <div class="card"><div class="label">Loading...</div></div>
  </div>
  <section>
    <h2>RECENT BLOCKED CONNECTIONS</h2>
    <table>
      <thead>
        <tr><th>Time</th><th>Source IP</th><th>Destination</th><th>Proto</th><th>Port</th><th>Action</th></tr>
      </thead>
      <tbody id="fw-table">
        <tr><td colspan="6" style="color:#8b949e;text-align:center">No events</td></tr>
      </tbody>
    </table>
  </section>
</div>

<script>
function show(panel, tab) {
  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.getElementById('panel-' + panel).classList.add('active');
  tab.classList.add('active');
}

function barClass(pct) {
  return pct > 80 ? 'bar danger' : pct > 60 ? 'bar warn' : 'bar';
}

function card(label, value, sub, pct) {
  const bar = pct !== undefined
    ? `<div class="bar-wrap"><div class="${barClass(pct)}" style="width:${pct}%"></div></div>`
    : '';
  return `<div class="card">
    <div class="label">${label}</div>
    <div class="value">${value}</div>
    ${sub ? `<div class="sub">${sub}</div>` : ''}
    ${bar}
  </div>`;
}

async function loadSystem() {
  try {
    const r = await fetch('/cgi-bin/system.sh');
    const d = await r.json();
    document.getElementById('sys-cards').innerHTML =
      card('Hostname', d.hostname) +
      card('CPU Load', d.load_1, `5m: ${d.load_5} · 15m: ${d.load_15}`, Math.round(d.load_1 * 100)) +
      card('Memory', d.mem_percent + '%', `${Math.round(d.mem_used_kb/1024)}MB / ${Math.round(d.mem_total_kb/1024)}MB`, d.mem_percent) +
      card('Uptime', `${d.uptime_h}h ${d.uptime_m}m`) +
      card('Processes', d.process_count) +
      card('Kernel', d.kernel, d.arch);
  } catch(e) {
    document.getElementById('sys-cards').innerHTML = '<div class="card"><div class="label" style="color:#f85149">Failed to load</div></div>';
  }
}

async function loadNetwork() {
  try {
    const r = await fetch('/cgi-bin/network.sh');
    const d = await r.json();
    document.getElementById('net-cards').innerHTML =
      card('IP Address', d.ip) +
      card('MAC', d.mac) +
      card('RX', d.rx_mb + ' MB', 'received') +
      card('TX', d.tx_mb + ' MB', 'transmitted') +
      card('Gateway', d.gateway_ping === 'ok' ? '✓ Reachable' : '✗ Down', d.gateway_ping === 'ok' ? '10.0.2.2' : 'check network') +
      card('DNS', d.dns || 'N/A');
  } catch(e) {}
}

async function loadSecurity() {
  try {
    const r = await fetch('/cgi-bin/security.sh');
    const d = await r.json();
    document.getElementById('sec-cards').innerHTML =
      card('Total Blocked', d.total_blocked, 'since boot') +
      card('Active Rules', d.active_rules, 'iptables rules');
    const tbody = document.getElementById('fw-table');
    if (d.recent_events && d.recent_events.length > 0) {
      tbody.innerHTML = d.recent_events.map(e =>
        `<tr>
          <td>${e.time}</td>
          <td style="color:#e6edf3">${e.src}</td>
          <td>${e.dst}</td>
          <td>${e.proto}</td>
          <td>${e.port}</td>
          <td><span class="tag drop">DROP</span></td>
        </tr>`
      ).join('');
    }
  } catch(e) {}
}

function updateTime() {
  const now = new Date();
  document.getElementById('ts').textContent = now.toLocaleTimeString();
}

// Load all data
loadSystem();
loadNetwork();
loadSecurity();
updateTime();
setInterval(loadSystem, 5000);
setInterval(loadNetwork, 5000);
setInterval(loadSecurity, 5000);
setInterval(updateTime, 1000);
</script>
</body>
</html>
```

### Module E: Firewall Setup Script

Tạo `board/miniguard/rootfs_overlay/etc/init.d/S40firewall`:

```bash
#!/bin/sh
# MiniGuard Firewall Init Script

LOG_FILE="/var/log/fw.log"

start() {
    echo "Starting MiniGuard firewall..."

    # Flush existing rules
    iptables -F
    iptables -X

    # Default policies
    iptables -P INPUT ACCEPT
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT

    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Allow SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    # Allow HTTP (dashboard)
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT

    # Allow ICMP (ping)
    iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/s -j ACCEPT

    # Log and drop everything else
    iptables -A INPUT -j LOG --log-prefix "[FW_DROP] " --log-level 4
    iptables -A INPUT -j DROP

    # Make sure log file exists
    touch "$LOG_FILE"

    echo "Firewall started."
}

stop() {
    echo "Stopping firewall..."
    iptables -F
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    echo "Firewall stopped."
}

case "$1" in
    start) start ;;
    stop)  stop  ;;
    restart) stop; start ;;
    *) echo "Usage: $0 {start|stop|restart}"; exit 1 ;;
esac
```

### Module F: Custom Buildroot Package

Tạo cấu trúc package:

```bash
mkdir -p package/miniguard-dashboard
```

**`package/miniguard-dashboard/Config.in`:**

```
config BR2_PACKAGE_MINIGUARD_DASHBOARD
    bool "miniguard-dashboard"
    depends on BR2_PACKAGE_LIGHTTPD
    help
      MiniGuard web dashboard: real-time system monitor
      with shell CGI scripts for embedded Linux systems.
      Includes system, network and security monitoring panels.
```

**`package/miniguard-dashboard/miniguard-dashboard.mk`:**

```makefile
################################################################################
#
# miniguard-dashboard
#
################################################################################

MINIGUARD_DASHBOARD_VERSION = 1.0
MINIGUARD_DASHBOARD_SITE    = $(TOPDIR)/../src/miniguard-dashboard
MINIGUARD_DASHBOARD_SITE_METHOD = local

define MINIGUARD_DASHBOARD_INSTALL_TARGET_CMDS
    # Install CGI scripts
    $(INSTALL) -d $(TARGET_DIR)/usr/share/miniguard/cgi-bin
    $(INSTALL) -m 0755 $(@D)/cgi-bin/system.sh   $(TARGET_DIR)/usr/share/miniguard/cgi-bin/
    $(INSTALL) -m 0755 $(@D)/cgi-bin/network.sh  $(TARGET_DIR)/usr/share/miniguard/cgi-bin/
    $(INSTALL) -m 0755 $(@D)/cgi-bin/security.sh $(TARGET_DIR)/usr/share/miniguard/cgi-bin/

    # Install HTML files
    $(INSTALL) -d $(TARGET_DIR)/usr/share/miniguard/html
    $(INSTALL) -m 0644 $(@D)/html/index.html $(TARGET_DIR)/usr/share/miniguard/html/

    # Install init script
    $(INSTALL) -d $(TARGET_DIR)/etc/init.d
    $(INSTALL) -m 0755 $(@D)/S50dashboard $(TARGET_DIR)/etc/init.d/
endef

$(eval $(generic-package))
```

**`src/miniguard-dashboard/S50dashboard`** (init script tự động start lighttpd):

```bash
#!/bin/sh

LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
PIDFILE="/var/run/lighttpd.pid"

start() {
    echo "Starting MiniGuard dashboard..."
    # Ensure log dir exists
    mkdir -p /var/log
    touch /var/log/fw.log

    # Link CGI scripts vào document root (lighttpd cần file trong cgi-bin dir)
    mkdir -p /usr/share/miniguard/html/cgi-bin
    ln -sf /usr/share/miniguard/cgi-bin/system.sh   /usr/share/miniguard/html/cgi-bin/
    ln -sf /usr/share/miniguard/cgi-bin/network.sh  /usr/share/miniguard/html/cgi-bin/
    ln -sf /usr/share/miniguard/cgi-bin/security.sh /usr/share/miniguard/html/cgi-bin/

    # Start lighttpd
    lighttpd -f $LIGHTTPD_CONF -D &
    echo $! > $PIDFILE
    echo "Dashboard running at http://$(hostname -I | awk '{print $1}'):80"
}

stop() {
    echo "Stopping dashboard..."
    if [ -f "$PIDFILE" ]; then
        kill $(cat $PIDFILE) 2>/dev/null
        rm -f $PIDFILE
    fi
}

case "$1" in
    start)   start ;;
    stop)    stop  ;;
    restart) stop; sleep 1; start ;;
    *)       echo "Usage: $0 {start|stop|restart}"; exit 1 ;;
esac
```

---

## 6. Tuần 3 — Tích hợp & Demo

**Mục tiêu cuối tuần:** Build cuối cùng hoàn chỉnh, demo được, báo cáo xong

### Ngày 1–2: Integration build

```bash
# Đảm bảo external tree được nhận diện
cat > Config.in << 'EOF'
source "$BR2_EXTERNAL_MINIGUARD_PATH/package/miniguard-dashboard/Config.in"
EOF

cat > external.mk << 'EOF'
include $(sort $(wildcard $(BR2_EXTERNAL_MINIGUARD_PATH)/package/*/*.mk))
EOF

cat > external.desc << 'EOF'
name: MINIGUARD
desc: MiniGuard Embedded Security Monitor
EOF

# Build với external tree
cd buildroot-2024.02
make BR2_EXTERNAL=../miniguard menuconfig
# Bật: Target packages → miniguard-dashboard

make -j$(nproc)
```

### Ngày 3: Script boot tiện lợi

Tạo `scripts/run.sh` để nhóm chỉ cần chạy 1 lệnh:

```bash
#!/bin/bash
# MiniGuard Quick Boot Script
BUILDROOT_DIR="./buildroot-2024.02"
IMAGES="$BUILDROOT_DIR/output/images"

echo "================================================"
echo "  MiniGuard Embedded Linux"
echo "  SSH:  ssh -p 2222 root@localhost"
echo "  Web:  http://localhost:8080"
echo "================================================"
echo ""

qemu-system-arm \
  -M vexpress-a9 \
  -cpu cortex-a9 \
  -m 256M \
  -kernel "$IMAGES/zImage" \
  -dtb "$IMAGES/vexpress-v2p-ca9.dtb" \
  -drive file="$IMAGES/rootfs.ext4",if=sd,format=raw \
  -append "root=/dev/mmcblk0 rw console=ttyAMA0,115200 quiet" \
  -nographic \
  -net nic,model=lan9118 \
  -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80

chmod +x scripts/run.sh
```

### Ngày 4–5: Hoàn thiện báo cáo

Báo cáo cần có các mục:

1. **Giới thiệu** — Embedded system là gì, tại sao dùng Buildroot
2. **Kiến trúc hệ thống** — sơ đồ, giải thích từng layer
3. **Quá trình build** — các bước cụ thể, screenshot
4. **Tính năng MiniGuard** — mô tả từng tính năng, ảnh chụp màn hình dashboard
5. **Custom package** — giải thích cơ chế `.mk` file, `Config.in`
6. **Kết quả đo lường** — boot time, RAM usage, rootfs size, số process
7. **Kết luận** — học được gì, hướng mở rộng

---

## 7. Chi tiết kỹ thuật từng module

### Tại sao dùng musl thay glibc?

glibc là thư viện C đầy đủ, phù hợp desktop nhưng nặng (~2MB). musl là thư viện C tối giản (~500KB), được thiết kế cho embedded. Với hệ thống có memory constraint như embedded, musl là lựa chọn đúng — đây là điểm kỹ thuật nhóm nên đề cập trong báo cáo và thuyết trình.

### Tại sao lighttpd thay nginx/apache?

- Apache: ~5MB, quá nặng
- nginx: ~1MB, phù hợp nhưng config phức tạp hơn với CGI
- lighttpd: ~400KB, nhẹ nhất, CGI config cực đơn giản, được dùng rộng rãi trong embedded Linux

### CGI shell script thay vì Python/Node?

Đây là quyết định đúng đắn nhất cho embedded: không cần runtime, không tốn RAM, BusyBox đã có `/bin/sh`. Python trên embedded thêm ~20MB, không cần thiết khi mọi thứ đều là đọc file từ `/proc`.

### iptables LOG target hoạt động thế nào?

Khi một packet bị DROP, kernel ghi vào kernel log (kbuf). syslogd của BusyBox đọc kernel log và ghi vào `/var/log/fw.log`. Script `security.sh` đọc file đó và trả về JSON cho dashboard. Đây là pipeline hoàn chỉnh không cần bất kỳ dependency nào ngoài BusyBox.

---

## 8. Kịch bản demo

Demo nên kéo dài khoảng 5–7 phút theo thứ tự sau:

**Bước 1 — Boot (30 giây)**
```
$ ./scripts/run.sh
```
Hệ thống boot, thấy kernel messages, login prompt hiện ra. Nói: *"Toàn bộ hệ thống này được build từ source bằng Buildroot, không phải cài từ ISO hay distro có sẵn."*

**Bước 2 — Chứng minh tính minimal (1 phút)**
```bash
# Trong QEMU
free -m          # RAM usage khi idle: ~15-20MB
df -h            # rootfs size: ~15MB
ps aux | wc -l   # số process: < 15
uname -a         # Linux miniguard, ARM
```
Nói: *"Toàn bộ hệ thống chỉ dùng 18MB RAM và 15MB disk — đây là đặc trưng của embedded Linux."*

**Bước 3 — Web Dashboard (2 phút)**
Mở browser, vào `http://localhost:8080`. Chuyển qua từng tab:
- System: CPU load, RAM usage, uptime
- Network: IP, traffic stats, ping status
- Security: firewall rules, blocked connections log

Trong lúc đó SSH vào và chạy `dd if=/dev/zero of=/dev/null` để tạo load, thấy CPU trên dashboard tăng lên realtime.

**Bước 4 — Custom Package (1 phút)**
Show file `.mk` và `Config.in`, giải thích: *"Toàn bộ dashboard này được đóng gói thành một Buildroot package chuẩn. Ai muốn tích hợp vào project khác chỉ cần copy thư mục package này vào."*

**Bước 5 — Firewall demo (1 phút)**
```bash
# Từ host, thử kết nối port không được phép
nc -z -w1 localhost 8888    # bị block
# Reload tab Security trên dashboard → thấy log entry mới xuất hiện
```

---

## 9. Tiêu chí đánh giá

### Tự chấm điểm

| Tiêu chí | Mức độ hoàn thành | Ghi chú |
|----------|-------------------|---------|
| Build thành công từ source | Bắt buộc | Chứng minh bằng `make` log |
| Boot trên QEMU | Bắt buộc | Video/screenshot |
| Kernel tùy chỉnh đúng mục đích | Quan trọng | Chỉ bật module cần thiết |
| Rootfs overlay | Quan trọng | Files tùy chỉnh trong `/etc` |
| Ứng dụng chạy được | Quan trọng | Dashboard mở được trên browser |
| Custom Buildroot package | Nâng cao | File `.mk` + `Config.in` đúng chuẩn |
| Báo cáo kỹ thuật | Quan trọng | Giải thích được mọi quyết định kỹ thuật |

### Câu hỏi phản biện thường gặp

**"Tại sao không dùng Raspberry Pi OS?"** → Raspberry Pi OS là distro đầy đủ ~2GB, không phải embedded system. MiniGuard build từ source, toàn bộ hệ thống 15MB, mọi thứ trong đó đều có lý do tồn tại.

**"Shell CGI có đủ mạnh không?"** → Đủ cho mục đích giám sát hệ thống. Dữ liệu từ `/proc` là file text, shell đọc và parse nhanh hơn Python cho task này vì không có overhead interpreter.

**"Có thể chạy trên phần cứng thật không?"** → Có. Chỉ cần thay `qemu_arm_vexpress_defconfig` bằng `raspberrypi3_defconfig` hoặc board tương ứng, rebuild là xong.

---

## 10. Cấu trúc thư mục dự án

```
miniguard/
├── buildroot-2024.02/          ← Buildroot source (không commit vào git)
├── board/
│   └── miniguard/
│       ├── rootfs_overlay/     ← Files đè lên rootfs
│       │   ├── etc/
│       │   │   ├── init.d/
│       │   │   │   └── S40firewall
│       │   │   └── lighttpd/
│       │   │       └── lighttpd.conf
│       │   └── var/log/        ← (empty, tạo khi boot)
│       ├── linux.config        ← Kernel config fragment
│       └── post-build.sh       ← Script chạy sau build
├── configs/
│   └── miniguard_defconfig     ← Buildroot defconfig đã lưu
├── package/
│   └── miniguard-dashboard/
│       ├── Config.in
│       └── miniguard-dashboard.mk
├── src/
│   └── miniguard-dashboard/    ← Source của custom package
│       ├── cgi-bin/
│       │   ├── system.sh
│       │   ├── network.sh
│       │   └── security.sh
│       ├── html/
│       │   └── index.html
│       └── S50dashboard        ← Init script
├── scripts/
│   ├── run.sh                  ← Boot QEMU
│   └── build.sh                ← Build wrapper
├── docs/
│   ├── report.md
│   └── screenshots/
├── Config.in                   ← External tree root
├── external.mk
├── external.desc
├── README.md
└── .gitignore
```

**`.gitignore`:**
```
buildroot-2024.02/
*.tar.gz
*.tar.bz2
output/
```

---

## 11. Lệnh tham khảo nhanh

```bash
# === BUILD ===
make qemu_arm_vexpress_defconfig     # load defconfig
make menuconfig                       # cấu hình Buildroot
make linux-menuconfig                 # cấu hình kernel
make -j$(nproc)                       # build toàn bộ
make savedefconfig                    # lưu config gọn lại

# === REBUILD ===
make lighttpd-rebuild                 # rebuild một package
make miniguard-dashboard-rebuild      # rebuild custom package
make linux-rebuild                    # rebuild kernel

# === BOOT ===
./scripts/run.sh                      # boot QEMU với port forward
ssh -p 2222 root@localhost            # SSH vào QEMU từ host

# === TRONG QEMU ===
/etc/init.d/S50dashboard start        # start dashboard thủ công
/etc/init.d/S40firewall restart       # restart firewall
iptables -L -n -v                     # xem firewall rules
cat /var/log/fw.log                   # xem firewall log
dmesg | grep "\[FW_DROP\]"            # xem kernel log firewall

# === DEBUG ===
tail -f build.log                     # theo dõi build log
make -j1 V=1 2>&1 | tee build-verbose.log   # build verbose
```

---

*MiniGuard — Custom Embedded Linux Security Monitor*  
*Môn: Lập Trình Linux · Buildroot 2024.02 · QEMU ARM vexpress-a9*
