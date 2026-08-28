#!/bin/sh
set -e

PACKAGE="${1:-smart-route}"

echo "================================================================================"
echo "          Keenetic Entware OPKG Installer (snakelair/Keenetic)"
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
FEED_CONF="/opt/etc/opkg/keenetic.conf"
REPO_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}"

echo "[*] Configuring OPKG repository feed: $REPO_URL..."
echo "src/gz keenetic-custom $REPO_URL" > "$FEED_CONF"

# 4. Update and Install
echo "[*] Updating package lists..."
/opt/bin/opkg update

echo "[*] Installing package: $PACKAGE..."
/opt/bin/opkg install "$PACKAGE"

LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo '192.168.1.1')

echo ""
echo "================================================================================"
echo " [OK] Installation completed successfully!"
if [ "$PACKAGE" = "smart-photo" ]; then
    echo " Smart-Photo Web UI: http://${LAN_IP}:8089"
elif [ "$PACKAGE" = "smart-route" ]; then
    echo " Smart-Route Web UI: http://${LAN_IP}:8088"
else
    echo " Package $PACKAGE is installed and ready."
fi
echo "================================================================================"
