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
    RAW_ARCH=$(grep -E "^arch[[:space:]]+" /opt/etc/opkg.conf 2>/dev/null | grep -v "all" | sort -k3 -n | tail -1 | awk '{print $2}' | sed 's/_kn$//')
    case "$RAW_ARCH" in
        aarch64*|arm64*)     ENT_ARCH="aarch64-3.10" ;;
        armv7*|arm*)         ENT_ARCH="armv7-3.2" ;;
        mipsel*|mipselsf*)   ENT_ARCH="mipsel-3.4" ;;
        x86_64*|amd64*|x86*) ENT_ARCH="x86_64" ;;
        mips*)               ENT_ARCH="mips-3.4" ;;
    esac
fi

if [ -z "$ENT_ARCH" ]; then
    ARCH=$(uname -m 2>/dev/null || echo "mips")
    case "$ARCH" in
        aarch64|arm64) ENT_ARCH="aarch64-3.10" ;;
        armv7*|arm*)   ENT_ARCH="armv7-3.2" ;;
        x86_64|amd64)  ENT_ARCH="x86_64" ;;
        mips|mipsel)   ENT_ARCH="mipsel-3.4" ;;
        *)             ENT_ARCH="mipsel-3.4" ;;
    esac
fi

echo "[*] Detected CPU / Entware architecture: $ENT_ARCH"

# 3. Ensure HTTPS / SSL support for OPKG
echo "[*] Ensuring HTTPS / SSL support for OPKG package manager..."
if ! which wget-ssl >/dev/null 2>&1 && ! which curl >/dev/null 2>&1; then
    echo "[*] Installing ca-certificates and wget-ssl for secure downloads..."
    /opt/bin/opkg update >/dev/null 2>&1 || true
    /opt/bin/opkg install ca-certificates wget-ssl >/dev/null 2>&1 || true
fi

# Fix wget symlink to GNU wget-ssl if available
if [ -f "/opt/libexec/wget-ssl" ]; then
    ln -sf /opt/libexec/wget-ssl /opt/bin/wget 2>/dev/null || true
    ln -sf /opt/libexec/wget-ssl /opt/usr/bin/wget 2>/dev/null || true
fi

# 4. Configure snakelair/Keenetic OPKG repository feed
# Clean old/conflicting keenetic feed entries from opkg.conf and old lists
if [ -f "/opt/etc/opkg.conf" ]; then
    sed -i '/keenetic/d' /opt/etc/opkg.conf 2>/dev/null || true
fi
rm -f /opt/etc/opkg/keenetic*.conf /opt/etc/opkg/custom*.conf 2>/dev/null || true
rm -f /opt/var/opkg-lists/keenetic* /opt/var/opkg-lists/custom* 2>/dev/null || true

REPO_CONF="/opt/etc/opkg/keenetic.conf"
mkdir -p /opt/etc/opkg
echo "src/gz keenetic https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}" > "$REPO_CONF"

echo "[*] Configuring OPKG repository feed: https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}..."

# 5. Update package lists
echo "[*] Updating package lists..."
/opt/bin/opkg update || true

# 6. Install or upgrade requested package
echo "[*] Installing package: ${PACKAGE}..."
if ! /opt/bin/opkg install --force-reinstall "${PACKAGE}"; then
    echo "[*] Direct repository install fallback..."
    IPK_NAME=$(curl -sSL "https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}/Packages" 2>/dev/null | grep -A 10 "Package: ${PACKAGE}" | grep "Filename:" | head -1 | awk '{print $2}')
    if [ -n "$IPK_NAME" ]; then
        IPK_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}/${IPK_NAME}"
        echo "[*] Downloading direct package from: $IPK_URL..."
        if which curl >/dev/null 2>&1; then
            curl -sSL "$IPK_URL" -o "/tmp/${IPK_NAME}"
        else
            wget -q -O "/tmp/${IPK_NAME}" "$IPK_URL"
        fi
        /opt/bin/opkg install --force-reinstall --force-depends "/tmp/${IPK_NAME}"
        rm -f "/tmp/${IPK_NAME}"
    fi
fi

LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo '192.168.1.1')

echo ""
echo "================================================================================"
echo " [OK] Installation completed successfully!"
if [ "$PACKAGE" = "smart-photo" ]; then
    echo " Smart-Photo Web UI: http://${LAN_IP}:8089"
elif [ "$PACKAGE" = "smart-route" ]; then
    echo " Smart-Route Web UI: http://${LAN_IP}:8088"
elif [ "$PACKAGE" = "smart-utils" ]; then
    echo " Smart-Utils Web UI: http://${LAN_IP}:8087"
fi
echo "================================================================================"
