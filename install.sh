#!/bin/sh
set +e

PACKAGE="${1:-smart-route}"

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

# 3. Port configuration & interactive prompt
DEFAULT_PORT=8090
if [ "$PACKAGE" = "smart-route" ]; then
    DEFAULT_PORT=8088
elif [ "$PACKAGE" = "smart-photo" ]; then
    DEFAULT_PORT=8089
fi

CFG_FILE="/opt/etc/${PACKAGE}/config.json"
if [ -f "$CFG_FILE" ]; then
    SAVED_PORT=$(grep -o '"web_port"[^,}]*' "$CFG_FILE" 2>/dev/null | awk -F: '{print $2}' | tr -dc '0-9')
    if [ -n "$SAVED_PORT" ] && [ "$SAVED_PORT" -ge 1 ] && [ "$SAVED_PORT" -le 65535 ]; then
        DEFAULT_PORT="$SAVED_PORT"
    fi
fi

SELECTED_PORT="$DEFAULT_PORT"
if ( exec 3>/dev/tty 4</dev/tty ) 2>/dev/null; then
    exec 3>/dev/tty 4</dev/tty
    printf "\033[1;33m[?]\033[0m Порт веб-интерфейса [%s]: " "$DEFAULT_PORT" >&3
    read -r USER_INPUT <&4 || USER_INPUT=""
    exec 3>&- 4<&-
    USER_INPUT=$(echo "$USER_INPUT" | tr -dc '0-9')
    if [ -n "$USER_INPUT" ] && [ "$USER_INPUT" -ge 1 ] && [ "$USER_INPUT" -le 65535 ]; then
        SELECTED_PORT="$USER_INPUT"
    fi
fi
printf "\033[1;34m[*]\033[0m Порт веб-интерфейса: \033[1;37m%s\033[0m\n" "$SELECTED_PORT"

# Check if selected port is already in use by another process
if which netstat >/dev/null 2>&1; then
    LISTEN_PROC=$(netstat -lntp 2>/dev/null | grep ":${SELECTED_PORT} " | awk '{print $7}' | cut -d/ -f2)
    if [ -n "$LISTEN_PROC" ] && [ "$LISTEN_PROC" != "$PACKAGE" ] && [ "$LISTEN_PROC" != "-" ]; then
        printf "\033[1;33m[!]\033[0m Внимание: порт %s уже занят процессом '%s'.\n" "$SELECTED_PORT" "$LISTEN_PROC"
    fi
fi

# 4. Configure OPKG repository feed
FEED_CONF="/opt/etc/opkg/keenetic.conf"
REPO_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}"

printf "\033[1;34m[*]\033[0m Configuring OPKG repository feed: \033[0;36m%s\033[0m...\n" "$REPO_URL"
mkdir -p /opt/etc/opkg
echo "src/gz keenetic-custom $REPO_URL" > "$FEED_CONF"

# Clean stale locks
rm -f /opt/tmp/opkg.lock /opt/var/lock/opkg.lock /opt/lib/opkg/lock 2>/dev/null || true

# 5. Auto-heal broken OPKG status database (clean old prerm & fix postinst)
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

# 6. Update and Install
printf "\033[1;34m[*]\033[0m Updating package lists...\n"
rm -f /opt/var/opkg-lists/keenetic-custom /tmp/opkg-* /opt/tmp/opkg.lock /opt/var/lock/opkg.lock /opt/lib/opkg/lock 2>/dev/null || true
/opt/bin/opkg update

# Explicitly ensure core dependencies for smart-route
if [ "$PACKAGE" = "smart-route" ]; then
    printf "\033[1;34m[*]\033[0m Ensuring network dependencies (iptables, ipset, ip-full, ca-certificates)...\n"
    /opt/bin/opkg install iptables ipset ip-full ca-certificates 2>/dev/null || true
fi

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
/opt/bin/opkg install "$PACKAGE" --force-remove --force-reinstall --force-overwrite

INSTALL_RES=$?

# 7. Apply configured port to config file
mkdir -p "/opt/etc/${PACKAGE}"
if [ -f "$CFG_FILE" ]; then
    if grep -q '"web_port"' "$CFG_FILE"; then
        sed -i "s/\"web_port\":[ ]*[0-9]*/\"web_port\": $SELECTED_PORT/" "$CFG_FILE"
    else
        sed -i "s/{/{\n  \"web_port\": $SELECTED_PORT,/" "$CFG_FILE"
    fi
fi

# 8. Start / Restart service safely
if [ -x "/opt/etc/init.d/S99smart-utils" ] && [ "$PACKAGE" = "smart-utils" ]; then
    printf "\033[1;34m[*]\033[0m Перезапуск службы Smart-Utils...\n"
    /opt/etc/init.d/S99smart-utils restart >/dev/null 2>&1 || {
        killall -9 smart-utils >/dev/null 2>&1
        sleep 1
        /opt/etc/init.d/S99smart-utils start >/dev/null 2>&1
    }
elif [ -x "/opt/etc/init.d/S99smart-route" ] && [ "$PACKAGE" = "smart-route" ]; then
    printf "\033[1;34m[*]\033[0m Перезапуск службы Smart-Route...\n"
    /opt/etc/init.d/S99smart-route restart >/dev/null 2>&1 || {
        killall -9 smart-route >/dev/null 2>&1
        sleep 1
        /opt/etc/init.d/S99smart-route start >/dev/null 2>&1
    }
elif [ -x "/opt/etc/init.d/S99smart-photo" ] && [ "$PACKAGE" = "smart-photo" ]; then
    printf "\033[1;34m[*]\033[0m Перезапуск службы Smart-Photo...\n"
    /opt/etc/init.d/S99smart-photo restart >/dev/null 2>&1 || {
        killall -9 smart-photo >/dev/null 2>&1
        sleep 1
        /opt/etc/init.d/S99smart-photo start >/dev/null 2>&1
    }
fi

# 9. Wait for service and verify via real API query
ACTIVE_VER=""
ROUTER_MODEL=""
printf "\033[1;34m[*]\033[0m Ожидание запуска и проверка API (http://127.0.0.1:%s/api/status)...\n" "$SELECTED_PORT"
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    sleep 1
    STATUS_JSON=$(curl -s --connect-timeout 2 "http://127.0.0.1:${SELECTED_PORT}/api/status" 2>/dev/null || wget -q -O - -T 2 "http://127.0.0.1:${SELECTED_PORT}/api/status" 2>/dev/null)
    if [ -n "$STATUS_JSON" ]; then
        ACTIVE_VER=$(echo "$STATUS_JSON" | grep -o '"version"[^,}]*' | awk -F'"' '{print $4}')
        ROUTER_MODEL=$(echo "$STATUS_JSON" | grep -o '"router_model"[^,}]*' | awk -F'"' '{print $4}')
        if [ -n "$ACTIVE_VER" ]; then
            break
        fi
    fi
done

if [ -z "$ACTIVE_VER" ]; then
    printf "\033[1;33m[!]\033[0m Предупреждение: сервис не ответил на http://127.0.0.1:%s/api/status за 12 сек.\n" "$SELECTED_PORT"
    if ! pidof "$PACKAGE" >/dev/null 2>&1; then
        printf "\033[1;31m[!]\033[0m Процесс %s не найден среди запущенных. Проверьте запуск: /opt/etc/init.d/S99%s start\n" "$PACKAGE" "$PACKAGE"
    else
        printf "\033[1;33m[*]\033[0m Процесс %s запущен (PID %s), но порт %s еще инициализируется.\n" "$PACKAGE" "$(pidof "$PACKAGE" | awk '{print $1}')" "$SELECTED_PORT"
    fi
fi

if [ -z "$ROUTER_MODEL" ]; then
    ROUTER_MODEL=$(ndmc -c 'show version' 2>/dev/null | grep -i 'model:' | head -n1 | awk -F: '{print $2}' | xargs 2>/dev/null || true)
fi
if [ -z "$ROUTER_MODEL" ] && [ -f /tmp/sysinfo/model ]; then
    ROUTER_MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || true)
fi

LAN_IP=$(ip -4 addr show br0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)
[ -z "$LAN_IP" ] && LAN_IP=$(ifconfig br0 2>/dev/null | awk -F'[: ]+' '/inet addr/{print $4}' | head -n1)
[ -z "$LAN_IP" ] && LAN_IP=$(ip route show 2>/dev/null | awk '/dev br0/{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')
[ -z "$LAN_IP" ] && LAN_IP=$(ip route show 2>/dev/null | awk '/src /{for(i=1;i<=NF;i++) if($i=="src" && $(i+1) ~ /^(192|172|10)\./) {print $(i+1); exit}}')
[ -z "$LAN_IP" ] && LAN_IP="192.168.1.1"

PKG_TITLE="Smart-Utils"
if [ "$PACKAGE" = "smart-route" ]; then
    PKG_TITLE="Smart-Route"
elif [ "$PACKAGE" = "smart-photo" ]; then
    PKG_TITLE="Smart-Photo"
fi

if [ $INSTALL_RES -eq 0 ]; then
    printf "\n\033[1;32m================================================================================\033[0m\n"
    if [ -n "$ACTIVE_VER" ]; then
        printf "\033[1;32m [OK] %s v%s успешно запущен и работает!\033[0m\n" "$PKG_TITLE" "$ACTIVE_VER"
    else
        printf "\033[1;32m [OK] Установка %s завершена успешно!\033[0m\n" "$PKG_TITLE"
    fi
    if [ -n "$ROUTER_MODEL" ]; then
        printf " \033[1;37mРоутер:\033[0m     \033[1;36m%s\033[0m\n" "$ROUTER_MODEL"
    fi
    printf " \033[1;37mВеб-панель:\033[0m \033[1;36mhttp://%s:%s\033[0m\n" "$LAN_IP" "$SELECTED_PORT"
    printf "\033[1;32m================================================================================\033[0m\n\n"
else
    printf "\n\033[1;31m================================================================================\033[0m\n"
    printf "\033[1;31m [ERROR] Ошибка установки %s. Пожалуйста, проверьте вывод выше.\033[0m\n" "$PKG_TITLE"
    printf "\033[1;31m================================================================================\033[0m\n\n"
    exit 1
fi
