#!/bin/bash
# MiniGuard Build Wrapper Script
set -e

WORKSPACE_DIR="/home/an/buildroot-local"
BUILDROOT_DIR="$WORKSPACE_DIR/buildroot"
EXTERNAL_DIR="$WORKSPACE_DIR/miniguard"

echo "Configuring Buildroot with external tree: $EXTERNAL_DIR"
cd "$BUILDROOT_DIR"

# Run make with external tree
make BR2_EXTERNAL="$EXTERNAL_DIR" "$@"
