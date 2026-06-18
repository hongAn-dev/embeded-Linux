#!/bin/bash
# MiniGuard Boot Runner

WORKSPACE_DIR="/home/an/buildroot-local"
IMAGES_DIR="$WORKSPACE_DIR/buildroot/output/images"

echo "=================================================="
echo "  Booting MiniGuard on QEMU ARM (vexpress-a9)..."
echo "  Forwarded Ports:"
echo "    SSH:  localhost:2222"
echo "    Web:  http://localhost:8080"
echo "=================================================="

# Ensure host toolchain bin is in path for qemu if needed
export PATH="$WORKSPACE_DIR/buildroot/output/host/bin:$PATH"

# Run QEMU with port forwarding and console output redirect
qemu-system-arm \
  -M vexpress-a9 \
  -smp 1 \
  -m 256 \
  -kernel "$IMAGES_DIR/zImage" \
  -dtb "$IMAGES_DIR/vexpress-v2p-ca9.dtb" \
  -drive file="$IMAGES_DIR/rootfs.ext2,if=sd,format=raw" \
  -append "console=ttyAMA0,115200 rootwait root=/dev/mmcblk0" \
  -net nic,model=lan9118 \
  -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80,hostfwd=tcp::8888-:8888 \
  -nographic "$@"
