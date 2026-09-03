#!/bin/sh
set +e

PACKAGE="${1:-smart-utils}"

printf "\n\033[1;36m================================================================================\033[0m\n"
printf "\033[1;36m          Keenetic Entware OPKG Installer (snakelair/Keenetic)\033[0m\n"
printf "\033[1;36m================================================================================\033[0m\n\n"

# 1. Check Entware environment
if [ ! -d "/opt/bin" ] || [ ! -x "/opt/bin/opkg" ]; then
    printf "\033[1;31m[ERROR] Entware is not installed or /opt/bin/opkg not found!\033[0m\n"
    printf "Please set up Entware on your Keenetic router first.\n"
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

printf "\033[1;34m[*]\033[0m Detected router architecture: \033[1;37m%s\033[0m -> Entware feed: \033[1;32m%s\033[0m\n" "$ARCH" "$ENT_ARCH"

# 3. Configure OPKG repository feed
FEED_CONF="/opt/etc/opkg/keenetic.conf"
REPO_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}"

printf "\033[1;34m[*]\033[0m Configuring OPKG repository feed: \033[0;36m%s\033[0m...\n" "$REPO_URL"
mkdir -p /opt/etc/opkg
echo "src/gz keenetic-custom $REPO_URL" > "$FEED_CONF"

# 4. Auto-heal broken OPKG status database (clean old prerm & fix postinst)
rm -f /opt/lib/opkg/info/${PACKAGE}.prerm /opt/var/lib/opkg/info/${PACKAGE}.prerm 2>/dev/null || true

for STAT_FILE in /opt/lib/opkg/status /opt/var/lib/opkg/status; do
    if [ -f "$STAT_FILE" ]; then
        INFO_DIR="$(dirname "$STAT_FILE")/info"
        mkdir -p "$INFO_DIR"
        chmod 777 "$INFO_DIR" 2>/dev/null || true
        rm -f "$INFO_DIR/${PACKAGE}.prerm" 2>/dev/null || true

        for SCRIPT in "$INFO_DIR"/*.prerm; do
            if [ -f "$SCRIPT" ]; then
                printf '#!/bin/sh\nexit 0\n' > "$SCRIPT"
                chmod 777 "$SCRIPT" 2>/dev/null || true
            fi
        done
        for SCRIPT in "$INFO_DIR"/*.postinst "$INFO_DIR"/*.preinst "$INFO_DIR"/*.postrm; do
            if [ -f "$SCRIPT" ]; then
                chmod 777 "$SCRIPT" 2>/dev/null || true
                if [ ! -s "$SCRIPT" ]; then
                    printf '#!/bin/sh\nexit 0\n' > "$SCRIPT"
                    chmod 777 "$SCRIPT" 2>/dev/null || true
                fi
            fi
        done
        awk '/^Package: /{pkg=$2} /^Status: / && ($0 ~ /unpacked/ || $0 ~ /half-configured/ || $0 ~ /half-installed/) {print pkg}' "$STAT_FILE" | while read -r BROKEN_PKG; do
            if [ -n "$BROKEN_PKG" ]; then
                POSTINST="$INFO_DIR/${BROKEN_PKG}.postinst"
                if [ ! -f "$POSTINST" ]; then
                    printf '#!/bin/sh\nexit 0\n' > "$POSTINST"
                    chmod 777 "$POSTINST" 2>/dev/null || true
                fi
            fi
        done
        /opt/bin/opkg configure >/dev/null 2>&1 || true
    fi
done

# 5. Update and Install
printf "\033[1;34m[*]\033[0m Updating package lists...\n"
/opt/bin/opkg update

# Re-clean and ensure prerm is removed before install
rm -f /opt/lib/opkg/info/${PACKAGE}.prerm /opt/var/lib/opkg/info/${PACKAGE}.prerm 2>/dev/null || true

for STAT_FILE in /opt/lib/opkg/status /opt/var/lib/opkg/status; do
    if [ -f "$STAT_FILE" ]; then
        INFO_DIR="$(dirname "$STAT_FILE")/info"
        chmod 777 "$INFO_DIR" 2>/dev/null || true
        rm -f "$INFO_DIR/${PACKAGE}.prerm" 2>/dev/null || true

        for SCRIPT in "$INFO_DIR"/*.prerm; do
            if [ -f "$SCRIPT" ]; then
                printf '#!/bin/sh\nexit 0\n' > "$SCRIPT"
                chmod 777 "$SCRIPT" 2>/dev/null || true
            fi
        done
        for SCRIPT in "$INFO_DIR"/*.postinst "$INFO_DIR"/*.preinst "$INFO_DIR"/*.postrm; do
            if [ -f "$SCRIPT" ]; then
                chmod 777 "$SCRIPT" 2>/dev/null || true
                if [ ! -s "$SCRIPT" ]; then
                    printf '#!/bin/sh\nexit 0\n' > "$SCRIPT"
                    chmod 777 "$SCRIPT" 2>/dev/null || true
                fi
            fi
        done
        awk '/^Package: /{pkg=$2} /^Status: / && ($0 ~ /unpacked/ || $0 ~ /half-configured/ || $0 ~ /half-installed/) {print pkg}' "$STAT_FILE" | while read -r BROKEN_PKG; do
            if [ -n "$BROKEN_PKG" ]; then
                POSTINST="$INFO_DIR/${BROKEN_PKG}.postinst"
                if [ ! -f "$POSTINST" ]; then
                    printf '#!/bin/sh\nexit 0\n' > "$POSTINST"
                    chmod 777 "$POSTINST" 2>/dev/null || true
                fi
            fi
        done
        /opt/bin/opkg configure >/dev/null 2>&1 || true
    fi
done

printf "\033[1;34m[*]\033[0m Installing/upgrading package: \033[1;37m%s\033[0m...\n" "$PACKAGE"
/opt/bin/opkg remove "$PACKAGE" --force-remove --force-depends >/dev/null 2>&1 || true
/opt/bin/opkg install "$PACKAGE" --force-remove --force-reinstall --force-overwrite 2>/dev/null || \
/opt/bin/opkg upgrade "$PACKAGE" --force-remove --force-overwrite 2>/dev/null || \
/opt/bin/opkg install "$PACKAGE" --force-remove 2>/dev/null || \
/opt/bin/opkg install "$PACKAGE"

INSTALL_RES=$?

# 6. Start / Restart service safely
if [ -x "/opt/etc/init.d/S99smart-utils" ] && [ "$PACKAGE" = "smart-utils" ]; then
    printf "\033[1;34m[*]\033[0m Restarting Smart-Utils service...\n"
    /opt/etc/init.d/S99smart-utils restart >/dev/null 2>&1 || {
        killall -9 smart-utils >/dev/null 2>&1
        sleep 1
        /opt/etc/init.d/S99smart-utils start >/dev/null 2>&1
    }
elif [ -x "/opt/etc/init.d/S99smart-route" ] && [ "$PACKAGE" = "smart-route" ]; then
    printf "\033[1;34m[*]\033[0m Restarting Smart-Route service...\n"
    /opt/etc/init.d/S99smart-route restart >/dev/null 2>&1 || /opt/etc/init.d/S99smart-route start >/dev/null 2>&1
elif [ -x "/opt/etc/init.d/S99smart-photo" ] && [ "$PACKAGE" = "smart-photo" ]; then
    printf "\033[1;34m[*]\033[0m Restarting Smart-Photo service...\n"
    /opt/etc/init.d/S99smart-photo restart >/dev/null 2>&1 || /opt/etc/init.d/S99smart-photo start >/dev/null 2>&1
fi


LAN_IP=$(ip -4 addr show br0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)
[ -z "$LAN_IP" ] && LAN_IP=$(ifconfig br0 2>/dev/null | awk -F'[: ]+' '/inet addr/{print $4}' | head -n1)
[ -z "$LAN_IP" ] && LAN_IP=$(ip route show 2>/dev/null | awk '/dev br0/{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')
[ -z "$LAN_IP" ] && LAN_IP=$(ip route show 2>/dev/null | awk '/src /{for(i=1;i<=NF;i++) if($i=="src" && $(i+1) ~ /^(192|172|10)\./) {print $(i+1); exit}}')
[ -z "$LAN_IP" ] && LAN_IP="192.168.1.1"

if [ $INSTALL_RES -eq 0 ]; then
    printf "\n\033[1;32m================================================================================\033[0m\n"
    printf "\033[1;32m [OK] Installation of %s completed successfully!\033[0m\n" "$PACKAGE"
    if [ "$PACKAGE" = "smart-utils" ]; then
        printf " \033[1;37mSmart-Utils Web UI:\033[0m \033[1;36mhttp://%s:8090\033[0m\n" "$LAN_IP"
    elif [ "$PACKAGE" = "smart-route" ]; then
        printf " \033[1;37mSmart-Route Web UI:\033[0m \033[1;36mhttp://%s:8088\033[0m\n" "$LAN_IP"
    elif [ "$PACKAGE" = "smart-photo" ]; then
        printf " \033[1;37mSmart-Photo Web UI:\033[0m \033[1;36mhttp://%s:8089\033[0m\n" "$LAN_IP"
    fi
    printf "\033[1;32m================================================================================\033[0m\n\n"
else
    printf "\n\033[1;31m================================================================================\033[0m\n"
    printf "\033[1;31m [ERROR] Installation of %s encountered an issue. Please check output above.\033[0m\n" "$PACKAGE"
    printf "\033[1;31m================================================================================\033[0m\n\n"
    exit 1
fi
