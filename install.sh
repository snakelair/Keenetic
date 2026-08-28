#!/bin/sh
set -e

PACKAGE="${1:-smart-utils}"

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
mkdir -p /opt/etc/opkg
echo "src/gz keenetic-custom $REPO_URL" > "$FEED_CONF"

# 4. Update and Install
echo "[*] Updating package lists..."
/opt/bin/opkg update

echo "[*] Installing/upgrading package: $PACKAGE..."
/opt/bin/opkg install "$PACKAGE" --force-reinstall 2>/dev/null || /opt/bin/opkg install "$PACKAGE" || /opt/bin/opkg upgrade "$PACKAGE"

# 5. Start / Restart service safely (detached in background so remote shell / SSH doesn't hang)
if [ -x "/opt/etc/init.d/S99smart-utils" ] && [ "$PACKAGE" = "smart-utils" ]; then
    ( sleep 1; /opt/etc/init.d/S99smart-utils restart >/dev/null 2>&1 || /opt/etc/init.d/S99smart-utils start >/dev/null 2>&1 ) >/dev/null 2>&1 &
elif [ -x "/opt/etc/init.d/S99smart-route" ] && [ "$PACKAGE" = "smart-route" ]; then
    ( sleep 1; /opt/etc/init.d/S99smart-route restart >/dev/null 2>&1 || /opt/etc/init.d/S99smart-route start >/dev/null 2>&1 ) >/dev/null 2>&1 &
elif [ -x "/opt/etc/init.d/S99smart-photo" ] && [ "$PACKAGE" = "smart-photo" ]; then
    ( sleep 1; /opt/etc/init.d/S99smart-photo restart >/dev/null 2>&1 || /opt/etc/init.d/S99smart-photo start >/dev/null 2>&1 ) >/dev/null 2>&1 &
fi


LAN_IP=$(ip -4 addr show br0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)
[ -z "$LAN_IP" ] && LAN_IP=$(ifconfig br0 2>/dev/null | awk -F'[: ]+' '/inet addr/{print $4}' | head -n1)
[ -z "$LAN_IP" ] && LAN_IP=$(ip route show 2>/dev/null | awk '/dev br0/{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')
[ -z "$LAN_IP" ] && LAN_IP=$(ip route show 2>/dev/null | awk '/src /{for(i=1;i<=NF;i++) if($i=="src" && $(i+1) ~ /^(192|172|10)\./) {print $(i+1); exit}}')
[ -z "$LAN_IP" ] && LAN_IP="192.168.1.1"

echo ""
echo "================================================================================"
echo " [OK] Installation of $PACKAGE completed successfully!"
if [ "$PACKAGE" = "smart-utils" ]; then
    echo " Smart-Utils Web UI: http://${LAN_IP}:8090"
elif [ "$PACKAGE" = "smart-route" ]; then
    echo " Smart-Route Web UI: http://${LAN_IP}:8088"
elif [ "$PACKAGE" = "smart-photo" ]; then
    echo " Smart-Photo Web UI: http://${LAN_IP}:8089"
fi
echo "================================================================================"
