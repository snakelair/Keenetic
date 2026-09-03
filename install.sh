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
mkdir -p /opt/etc/opkg
echo "src/gz keenetic-custom $REPO_URL" > "$FEED_CONF"

# 4. Auto-heal broken OPKG status database and CRLF line endings
echo "[*] Sanitizing and healing package manager scripts..."
for INFO_DIR in /opt/lib/opkg/info /opt/var/lib/opkg/info; do
    if [ -d "$INFO_DIR" ]; then
        for F in "$INFO_DIR"/*; do
            if [ -f "$F" ]; then
                tr -d '\r' < "$F" > "$F.tmp" 2>/dev/null && mv "$F.tmp" "$F" 2>/dev/null || true
            fi
        done
        # Ensure any pre-existing scripts for target package are valid no-ops so old broken prerm/postinst never block upgrade
        for SCRIPT in "$INFO_DIR/${PACKAGE}.prerm" "$INFO_DIR/${PACKAGE}.postinst" "$INFO_DIR/${PACKAGE}.preinst" "$INFO_DIR/${PACKAGE}.postrm"; do
            if [ -f "$SCRIPT" ]; then
                printf '#!/bin/sh\nexit 0\n' > "$SCRIPT"
                chmod +x "$SCRIPT" 2>/dev/null || true
            fi
        done
    fi
done

for STAT_FILE in /opt/lib/opkg/status /opt/var/lib/opkg/status; do
    if [ -f "$STAT_FILE" ]; then
        INFO_DIR="$(dirname "$STAT_FILE")/info"
        mkdir -p "$INFO_DIR"
        awk '/^Package: /{pkg=$2} /^Status: / && ($0 ~ /unpacked/ || $0 ~ /half-configured/ || $0 ~ /half-installed/) {print pkg}' "$STAT_FILE" | while read -r BROKEN_PKG; do
            if [ -n "$BROKEN_PKG" ]; then
                for EXT in postinst prerm preinst postrm; do
                    P="$INFO_DIR/${BROKEN_PKG}.${EXT}"
                    printf '#!/bin/sh\nexit 0\n' > "$P"
                    chmod +x "$P" 2>/dev/null || true
                done
            fi
        done
        /opt/bin/opkg configure >/dev/null 2>&1 || true
    fi
done

# 5. Update and Install
echo "[*] Updating package lists..."
/opt/bin/opkg update

# Explicitly install/verify core runtime dependencies so they are not orphaned
if [ "$PACKAGE" = "smart-route" ]; then
    echo "[*] Ensuring network dependencies (iptables, ipset, ip-full, ca-certificates)..."
    /opt/bin/opkg install iptables ipset ip-full ca-certificates 2>/dev/null || true
fi

echo "[*] Installing/upgrading package: $PACKAGE..."
/opt/bin/opkg install "$PACKAGE" --force-reinstall --force-overwrite 2>/dev/null || /opt/bin/opkg install "$PACKAGE" || /opt/bin/opkg upgrade "$PACKAGE"

# 6. Post-install verify and start service
if [ -x "/opt/etc/init.d/S99smart-utils" ] && [ "$PACKAGE" = "smart-utils" ]; then
    ( sleep 1; /opt/etc/init.d/S99smart-utils restart >/dev/null 2>&1 || /opt/etc/init.d/S99smart-utils start >/dev/null 2>&1 ) >/dev/null 2>&1 &
elif [ -x "/opt/etc/init.d/S99smart-route" ] && [ "$PACKAGE" = "smart-route" ]; then
    ( sleep 1; /opt/etc/init.d/S99smart-route restart >/dev/null 2>&1 || /opt/etc/init.d/S99smart-route start >/dev/null 2>&1 ) >/dev/null 2>&1 &
elif [ -x "/opt/etc/init.d/S99smart-photo" ] && [ "$PACKAGE" = "smart-photo" ]; then
    ( sleep 1; /opt/etc/init.d/S99smart-photo restart >/dev/null 2>&1 || /opt/etc/init.d/S99smart-photo start >/dev/null 2>&1 ) >/dev/null 2>&1 &
fi

LAN_IP=$(ip -4 addr show br0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)
[ -z "$LAN_IP" ] && LAN_IP=$(ifconfig br0 2>/dev/null | awk -F'[: ]+' '/inet addr/{print $4}' | head -n1)
[ -z "$LAN_IP" ] && LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo '192.168.1.1')
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
