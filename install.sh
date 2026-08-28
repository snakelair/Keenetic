#!/bin/sh
set -e

echo "================================================================================"
echo "          Smart-Route OPKG Installer for Keenetic Entware"
echo "================================================================================"
echo ""

# 1. Check Entware environment
if [ ! -d "/opt/bin" ] || [ ! -x "/opt/bin/opkg" ]; then
    echo "[ERROR] Entware is not installed or /opt/bin/opkg not found!"
    echo "Please set up Entware on your Keenetic router first."
    exit 1
fi

# 2. Detect CPU architecture
ARCH=$(uname -m)
ENT_ARCH=""

case "$ARCH" in
    mips|mipsel)
        ENT_ARCH="mipsel-3.4"
        ;;
    aarch64|arm64)
        ENT_ARCH="aarch64-3.10"
        ;;
    armv7*|arm)
        ENT_ARCH="armv7-3.2"
        ;;
    x86_64|amd64)
        ENT_ARCH="x86_64"
        ;;
    *)
        ENT_ARCH="mipsel-3.4"
        ;;
esac

echo "[*] Detected router architecture: $ARCH -> Entware feed: $ENT_ARCH"

# 3. Configure OPKG repository feed
FEED_CONF="/opt/etc/opkg/smartroute.conf"
REPO_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}"

echo "[*] Configuring OPKG repository feed: $REPO_URL..."
echo "src/gz smartroute $REPO_URL" > "$FEED_CONF"

# 4. Update and Install
echo "[*] Updating package lists..."
/opt/bin/opkg update

echo "[*] Installing smart-route..."
/opt/bin/opkg install smart-route

echo ""
echo "================================================================================"
echo " [OK] Smart-Route installed successfully!"
echo " Web UI is available at: http://$(uci get network.lan.ipaddr 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo '192.168.1.1'):8088"
echo "================================================================================"
