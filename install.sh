#!/bin/sh
set -e

PACKAGE="${1:-smart-photo}"

echo "================================================================================"
echo "          Keenetic Entware OPKG Installer (snakelair/Keenetic)"
echo "================================================================================"
echo ""

# 1. Check Entware
if [ ! -d "/opt/bin" ] || [ ! -x "/opt/bin/opkg" ]; then
    echo "[ERROR] Entware is not installed or /opt/bin/opkg not found!"
    echo "Please configure Entware on your Keenetic USB drive first."
    exit 1
fi

# 2. Detect CPU Architecture
ENT_ARCH=""
if [ -f "/opt/etc/opkg.conf" ]; then
    ENT_ARCH=$(grep -E "^arch[[:space:]]+" /opt/etc/opkg.conf 2>/dev/null | grep -v "all" | sort -k3 -n | tail -1 | awk '{print $2}')
fi

if [ -z "$ENT_ARCH" ]; then
    ARCH=$(uname -m)
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
fi

echo "[*] Detected CPU / Entware architecture: $ENT_ARCH"

# 3. Ensure HTTPS / SSL support for OPKG
echo "[*] Ensuring HTTPS / SSL support for OPKG package manager..."
/opt/bin/opkg install wget-ssl ca-certificates ca-bundle >/dev/null 2>&1 || true

# 4. Configure Feed
FEED_CONF="/opt/etc/opkg/keenetic.conf"
REPO_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}"

echo "[*] Configuring OPKG repository feed: $REPO_URL..."
echo "src/gz keenetic-custom $REPO_URL" > "$FEED_CONF"

# 5. Update and Install
echo "[*] Updating package index..."
if /opt/bin/opkg update; then
    echo "[*] Installing package: $PACKAGE..."
    /opt/bin/opkg install "$PACKAGE"
else
    echo ""
    echo "[WARN] 'opkg update' encountered an issue with HTTPS feed."
    echo "[*] Falling back to direct package installation via curl..."
    
    PKG_LIST_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}/Packages"
    IPK_FILE=$(curl -sSL "$PKG_LIST_URL" | grep -A 10 "Package: ${PACKAGE}" | grep "Filename:" | head -1 | awk '{print $2}')
    
    if [ -z "$IPK_FILE" ]; then
        echo "[ERROR] Could not determine package filename for $PACKAGE on architecture $ENT_ARCH"
        exit 1
    fi
    
    IPK_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}/${IPK_FILE}"
    echo "[*] Downloading: $IPK_URL..."
    curl -sSL -o "/tmp/${IPK_FILE}" "$IPK_URL"
    
    echo "[*] Installing /tmp/${IPK_FILE}..."
    /opt/bin/opkg install "/tmp/${IPK_FILE}"
    rm -f "/tmp/${IPK_FILE}"
fi

LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo '192.168.1.1')

echo ""
echo "================================================================================"
echo " [OK] Installation completed successfully!"
if [ "$PACKAGE" = "smart-photo" ]; then
    echo " Smart-Photo Web UI: http://${LAN_IP}:8089"
elif [ "$PACKAGE" = "smart-route" ]; then
    echo " Smart-Route Web UI: http://${LAN_IP}:8088"
fi
echo "================================================================================"
