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

# 4. Auto-heal broken OPKG status database (missing postinst / prerm permissions)
for STAT_FILE in /opt/lib/opkg/status /opt/var/lib/opkg/status; do
    if [ -f "$STAT_FILE" ]; then
        INFO_DIR="$(dirname "$STAT_FILE")/info"
        mkdir -p "$INFO_DIR"
        chmod 755 "$INFO_DIR"/* 2>/dev/null || true
        for SCRIPT in "$INFO_DIR"/*.prerm "$INFO_DIR"/*.postinst "$INFO_DIR"/*.preinst "$INFO_DIR"/*.postrm; do
            if [ -f "$SCRIPT" ]; then
                chmod 755 "$SCRIPT" 2>/dev/null || true
                if [ ! -s "$SCRIPT" ]; then
                    printf '#!/bin/sh\nexit 0\n' > "$SCRIPT"
                    chmod 755 "$SCRIPT" 2>/dev/null || true
                fi
            fi
        done
        awk '/^Package: /{pkg=$2} /^Status: / && ($0 ~ /unpacked/ || $0 ~ /half-configured/ || $0 ~ /half-installed/) {print pkg}' "$STAT_FILE" | while read -r BROKEN_PKG; do
            if [ -n "$BROKEN_PKG" ]; then
                POSTINST="$INFO_DIR/${BROKEN_PKG}.postinst"
                if [ ! -f "$POSTINST" ]; then
                    printf '#!/bin/sh\nexit 0\n' > "$POSTINST"
                    chmod 755 "$POSTINST" 2>/dev/null || true
                fi
            fi
        done
        /opt/bin/opkg configure >/dev/null 2>&1 || true
    fi
done

# 5. Update and Install
echo "[*] Updating package lists..."
/opt/bin/opkg update

# Re-run heal after update if needed
for STAT_FILE in /opt/lib/opkg/status /opt/var/lib/opkg/status; do
    if [ -f "$STAT_FILE" ]; then
        INFO_DIR="$(dirname "$STAT_FILE")/info"
        chmod 755 "$INFO_DIR"/* 2>/dev/null || true
        for SCRIPT in "$INFO_DIR"/*.prerm "$INFO_DIR"/*.postinst "$INFO_DIR"/*.preinst "$INFO_DIR"/*.postrm; do
            if [ -f "$SCRIPT" ]; then
                chmod 755 "$SCRIPT" 2>/dev/null || true
                if [ ! -s "$SCRIPT" ]; then
                    printf '#!/bin/sh\nexit 0\n' > "$SCRIPT"
                    chmod 755 "$SCRIPT" 2>/dev/null || true
                fi
            fi
        done
        awk '/^Package: /{pkg=$2} /^Status: / && ($0 ~ /unpacked/ || $0 ~ /half-configured/ || $0 ~ /half-installed/) {print pkg}' "$STAT_FILE" | while read -r BROKEN_PKG; do
            if [ -n "$BROKEN_PKG" ]; then
                POSTINST="$INFO_DIR/${BROKEN_PKG}.postinst"
                if [ ! -f "$POSTINST" ]; then
                    printf '#!/bin/sh\nexit 0\n' > "$POSTINST"
                    chmod 755 "$POSTINST" 2>/dev/null || true
                fi
            fi
        done
        /opt/bin/opkg configure >/dev/null 2>&1 || true
    fi
done

echo "[*] Installing/upgrading package: $PACKAGE..."
/opt/bin/opkg install "$PACKAGE" --force-remove --force-reinstall --force-overwrite 2>/dev/null || \
/opt/bin/opkg upgrade "$PACKAGE" --force-remove --force-overwrite 2>/dev/null || \
/opt/bin/opkg install "$PACKAGE" --force-remove 2>/dev/null || \
/opt/bin/opkg install "$PACKAGE"


# 6. Start / Restart service safely (detached in background so remote shell / SSH doesn't hang)

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
