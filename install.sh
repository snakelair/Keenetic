#!/bin/sh
set +e

# Ensure Entware paths are prioritized in PATH (crucial for finding /opt/bin/wget before /bin/wget)
export PATH="/opt/bin:/opt/sbin:$PATH"
export SMART_INSTALLER=1

PACKAGE="${1:-}"

# Special handling for uninstallation / removal
if [ "$PACKAGE" = "uninstall" ] || [ "$PACKAGE" = "remove" ] || [ "$PACKAGE" = "purge" ] || [ "$PACKAGE" = "delete" ]; then
    shift 2>/dev/null || true
    SCRIPT_DIR="$(dirname "$0")"
    if [ -f "${SCRIPT_DIR}/uninstall.sh" ]; then
        exec sh "${SCRIPT_DIR}/uninstall.sh" "$@"
    else
        curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/uninstall.sh | sh -s -- "$@"
        exit $?
    fi
fi

# Special handling for ql-vpn (QuakeLive-VPN Server for Linux VPS)
if [ "$PACKAGE" = "ql-vpn" ] || [ "$PACKAGE" = "qlvpn" ]; then
    printf "\033[1;34m[*]\033[0m Запуск установщика QuakeLive-VPN Server (Linux VPS)...\n"
    SCRIPT_DIR="$(dirname "$0")"
    if [ -f "${SCRIPT_DIR}/install-qlvpn.sh" ]; then
        exec bash "${SCRIPT_DIR}/install-qlvpn.sh" "$@"
    else
        curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install-qlvpn.sh | bash -s -- "$@"
        exit $?
    fi
fi

# Interactive menu if no package specified
if [ -z "$PACKAGE" ]; then
    if ( exec 3>/dev/tty 4</dev/tty ) 2>/dev/null; then
        exec 3>/dev/tty 4</dev/tty
        printf "\n\033[1;36m================================================================================\033[0m\n" >&3
        printf "\033[1;36m          Keenetic Entware Installer (snakelair/Keenetic)\033[0m\n" >&3
        printf "\033[1;36m================================================================================\033[0m\n\n" >&3
        printf "\033[1;37mВыберите компонент для установки:\033[0m\n" >&3
        printf "  \033[1;36m1\033[0m) \033[1;32mSmart-Utils\033[0m (Веб-панель управления, Терминалы CLI/SSH, Файловый менеджер, OPKG)\n" >&3
        printf "  \033[1;36m2\033[0m) \033[1;32mSmart-Route\033[0m (Служба динамической маршрутизации и обхода блокировок)\n" >&3
        printf "  \033[1;36m3\033[0m) \033[1;32mSmart-Photo\033[0m (Персональный фотосервер в стиле Google Photos для USB)\n" >&3
        printf "  \033[1;36m4\033[0m) \033[1;32mSmart-VPN\033[0m   (Управление VPN-соединениями на роутере)\n" >&3
        printf "  \033[1;36m5\033[0m) \033[1;32mQuakeLive-VPN Server\033[0m (Служба QL-VPN на Linux VPS)\n" >&3
        printf "  \033[1;33m0\033[0m) Отмена\n\n" >&3

        printf "\033[1;33m[?]\033[0m Введите номер пункта [1-5]: " >&3
        read -r CHOICE <&4 || CHOICE=""
        exec 3>&- 4<&-

        case "$CHOICE" in
            1) PACKAGE="smart-utils" ;;
            2) PACKAGE="smart-route" ;;
            3) PACKAGE="smart-photo" ;;
            4) PACKAGE="smart-vpn" ;;
            5)
                printf "\033[1;34m[*]\033[0m Запуск установщика QuakeLive-VPN Server (Linux VPS)...\n"
                SCRIPT_DIR="$(dirname "$0")"
                if [ -f "${SCRIPT_DIR}/install-qlvpn.sh" ]; then
                    exec bash "${SCRIPT_DIR}/install-qlvpn.sh" "$@"
                else
                    curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install-qlvpn.sh | bash -s -- "$@"
                    exit $?
                fi
                ;;
            *)
                printf "\n\033[1;33m[!] Отменено пользователем.\033[0m\n\n"
                exit 0
                ;;
        esac
    else
        PACKAGE="smart-utils"
    fi
fi

printf "\n\033[1;36m================================================================================\033[0m\n"
printf "\033[1;36m          Keenetic Entware OPKG Installer (snakelair/Keenetic)\033[0m\n"
printf "\033[1;36m================================================================================\033[0m\n\n"

# 1. Check Entware environment (for Keenetic router OPKG packages)
if [ ! -d "/opt/bin" ] || [ ! -x "/opt/bin/opkg" ]; then
    printf "\033[1;31m[ERROR] Entware не установлена или /opt/bin/opkg не найден!\033[0m\n"
    printf "Для установки пакетов роутера (smart-utils, smart-route, smart-photo, smart-vpn) требуется среда Entware.\n"
    printf "Если вы хотите установить сервер QuakeLive-VPN на VPS, выполните:\n"
    printf "  curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install-qlvpn.sh | bash\n\n"
    exit 1
fi

# 2. Detect CPU architecture & compatible Entware feed
RAW_ARCH=$(uname -m 2>/dev/null || echo "unknown")
ENT_ARCH=""

# Level 1: Check native OPKG architecture support (highest accuracy)
OPKG_ARCH=""
if [ -x "/opt/bin/opkg" ]; then
    OPKG_ARCH=$(/opt/bin/opkg print-architecture 2>/dev/null | grep -v "all" | sort -k3 -n | tail -1 | awk '{print $2}' | sed 's/_kn$//')
fi
if [ -z "$OPKG_ARCH" ] && [ -f "/opt/etc/opkg.conf" ]; then
    OPKG_ARCH=$(grep -E "^arch[[:space:]]+" /opt/etc/opkg.conf 2>/dev/null | grep -v "all" | sort -k3 -n | tail -1 | awk '{print $2}' | sed 's/_kn$//')
fi

if [ -n "$OPKG_ARCH" ]; then
    case "$OPKG_ARCH" in
        mipsel*|mipselsf*)   ENT_ARCH="mipsel-3.4" ;;
        mips*)               ENT_ARCH="mips-3.4" ;;
        aarch64*|arm64*)     ENT_ARCH="aarch64-3.10" ;;
        armv7*|arm*)         ENT_ARCH="armv7-3.2" ;;
        x86_64*|amd64*|x86*) ENT_ARCH="x86_64" ;;
    esac
fi

# Level 2: Check active Entware repository feed URLs in /opt/etc/opkg.conf
if [ -z "$ENT_ARCH" ]; then
    CONF_FEEDS=$(grep -E "bin\.entware\.net" /opt/etc/opkg.conf /opt/etc/opkg/*.conf 2>/dev/null)
    if echo "$CONF_FEEDS" | grep -qE "mipsel"; then
        ENT_ARCH="mipsel-3.4"
    elif echo "$CONF_FEEDS" | grep -qE "mipssf|mips-"; then
        ENT_ARCH="mips-3.4"
    elif echo "$CONF_FEEDS" | grep -qE "aarch64"; then
        ENT_ARCH="aarch64-3.10"
    elif echo "$CONF_FEEDS" | grep -qE "armv7"; then
        ENT_ARCH="armv7-3.2"
    elif echo "$CONF_FEEDS" | grep -qE "x86"; then
        ENT_ARCH="x86_64"
    fi
fi

# Level 3: Fallback via uname -m and endianness check
if [ -z "$ENT_ARCH" ]; then
    case "$RAW_ARCH" in
        mipsel)
            ENT_ARCH="mipsel-3.4"
            ;;
        mips)
            # Differentiate MIPS Big-Endian from MIPSEL Little-Endian
            IS_LE=""
            if grep -qiE "MT762|RT3883|RT6856|MediaTek|Ralink|Little Endian" /proc/cpuinfo 2>/dev/null; then
                IS_LE=1
            elif lscpu 2>/dev/null | grep -qi "Little Endian"; then
                IS_LE=1
            elif [ -f "/opt/bin/opkg" ] && (od -An -j 5 -N 1 -b /opt/bin/opkg 2>/dev/null | grep -q "001"); then
                IS_LE=1
            fi

            if [ "$IS_LE" = "1" ]; then
                ENT_ARCH="mipsel-3.4"
            else
                ENT_ARCH="mips-3.4"
            fi
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

[ -z "$ENT_ARCH" ] && ENT_ARCH="mipsel-3.4"

printf "\033[1;34m[*]\033[0m Detected router architecture: \033[1;37m%s\033[0m -> Entware feed: \033[1;32m%s\033[0m\n" "$RAW_ARCH" "$ENT_ARCH"

# 3. Port configuration & interactive prompt
DEFAULT_PORT=8001
PKG_TITLE="Smart-Utils"
if [ "$PACKAGE" = "smart-route" ]; then
    DEFAULT_PORT=8088
    PKG_TITLE="Smart-Route"
elif [ "$PACKAGE" = "smart-photo" ]; then
    DEFAULT_PORT=8089
    PKG_TITLE="Smart-Photo"
elif [ "$PACKAGE" = "smart-vpn" ]; then
    DEFAULT_PORT=8091
    PKG_TITLE="Smart-VPN"
elif [ "$PACKAGE" = "smart-nvr" ] || [ "$PACKAGE" = "smartnvr" ]; then
    DEFAULT_PORT=8095
    PKG_TITLE="SmartNVR"
fi

CFG_FILE="/opt/etc/${PACKAGE}/config.json"
if [ -f "$CFG_FILE" ]; then
    SAVED_PORT=$(grep -o '"web_port"[^,}]*' "$CFG_FILE" 2>/dev/null | awk -F: '{print $2}' | tr -dc '0-9')
    if [ -n "$SAVED_PORT" ] && [ "$SAVED_PORT" -ge 1 ] && [ "$SAVED_PORT" -le 65535 ]; then
        DEFAULT_PORT="$SAVED_PORT"
    fi
fi

# Helper to check if a TCP port is currently listening
is_port_in_use() {
    CHECK_P="$1"
    [ -z "$CHECK_P" ] && return 1

    # Check via netstat
    if command -v netstat >/dev/null 2>&1; then
        if netstat -lnt 2>/dev/null | grep -E "[: ]${CHECK_P}[[:space:]]+" | grep -qi "LISTEN"; then
            return 0
        fi
    fi

    # Check via ss
    if command -v ss >/dev/null 2>&1; then
        if ss -lnt 2>/dev/null | grep -E "[: ]${CHECK_P}[[:space:]]+" | grep -qi "LISTEN"; then
            return 0
        fi
    fi

    # Check directly via /proc/net/tcp and tcp6 (hex port check)
    HEX_PORT=$(printf "%04X" "$CHECK_P" 2>/dev/null)
    if [ -n "$HEX_PORT" ]; then
        if grep -qi ":${HEX_PORT} [0-9A-F]*:0000 0A" /proc/net/tcp /proc/net/tcp6 2>/dev/null; then
            return 0
        fi
    fi

    return 1
}

# Find first available port starting from given port
find_free_port() {
    START_P="$1"
    C_PORT="$START_P"
    while [ "$C_PORT" -le 65535 ]; do
        if ! is_port_in_use "$C_PORT"; then
            echo "$C_PORT"
            return 0
        fi
        C_PORT=$((C_PORT + 1))
    done
    echo "$START_P"
}

# If the current service is already running on DEFAULT_PORT, it's considered safe for upgrade
IS_OUR_SERVICE=0
if [ -f "/opt/etc/init.d/S99${PACKAGE}" ]; then
    if pidof "$PACKAGE" >/dev/null 2>&1 || [ -n "$SAVED_PORT" ]; then
        IS_OUR_SERVICE=1
    fi
fi

if is_port_in_use "$DEFAULT_PORT" && [ "$IS_OUR_SERVICE" -ne 1 ]; then
    printf "\033[1;33m[!] Порт %s уже занят другим приложением на роутере.\033[0m\n" "$DEFAULT_PORT"
    FREE_PORT=$(find_free_port "$DEFAULT_PORT")
    printf "\033[1;34m[*] Рекомендуемый свободный порт: \033[1;32m%s\033[0m\n" "$FREE_PORT"
    DEFAULT_PORT="$FREE_PORT"
fi

SELECTED_PORT="$DEFAULT_PORT"
if ( exec 3>/dev/tty 4</dev/tty ) 2>/dev/null; then
    exec 3>/dev/tty 4</dev/tty
    while true; do
        printf "\033[1;33m[?]\033[0m Порт веб-интерфейса [%s]: " "$DEFAULT_PORT" >&3
        read -r USER_INPUT <&4 || USER_INPUT=""
        USER_INPUT=$(echo "$USER_INPUT" | tr -dc '0-9')
        if [ -z "$USER_INPUT" ]; then
            SELECTED_PORT="$DEFAULT_PORT"
        elif [ "$USER_INPUT" -ge 1 ] && [ "$USER_INPUT" -le 65535 ]; then
            SELECTED_PORT="$USER_INPUT"
        fi

        # Validate entered port for conflicts
        if [ "$SELECTED_PORT" != "$SAVED_PORT" ] && is_port_in_use "$SELECTED_PORT"; then
            printf "\033[1;31m[!] Внимание: порт %s уже прослушивается другим процессом!\033[0m\n" "$SELECTED_PORT" >&3
            SUGG_PORT=$(find_free_port "$SELECTED_PORT")
            printf "\033[1;33m[?] Выберите другой свободный порт (например, %s): \033[0m\n" "$SUGG_PORT" >&3
            DEFAULT_PORT="$SUGG_PORT"
        else
            break
        fi
    done
    exec 3>&- 4<&-
fi
printf "\033[1;34m[*]\033[0m Порт веб-интерфейса: \033[1;37m%s\033[0m\n" "$SELECTED_PORT"

# 4. Ensure HTTPS / SSL support for OPKG
# BusyBox wget built into Keenetic firmware does not support HTTPS (wget: not an http or ftp url).
# Standard Entware feed (bin.entware.net) runs on HTTP, allowing us to bootstrap wget-ssl & certificates first.
NEED_SSL=0
if [ ! -x "/opt/bin/wget" ] || ! /opt/bin/wget --version 2>&1 | grep -qi "GNU Wget"; then
    NEED_SSL=1
fi

if [ $NEED_SSL -eq 1 ]; then
    printf "\033[1;34m[*]\033[0m Обеспечение поддержки HTTPS (установка wget-ssl и ca-certificates)...\n"
    /opt/bin/opkg update >/dev/null 2>&1 || true
    /opt/bin/opkg install wget-ssl ca-certificates ca-bundle >/dev/null 2>&1 || true
    if [ -x "/opt/bin/wget" ]; then
        if ! grep -q "wget_cmd" /opt/etc/opkg.conf 2>/dev/null; then
            echo "option wget_cmd /opt/bin/wget" >> /opt/etc/opkg.conf 2>/dev/null || true
        fi
    fi
fi

# 5. Configure OPKG repository feed
FEED_CONF="/opt/etc/opkg/snakelair.conf"
REPO_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ENT_ARCH}"

printf "\033[1;34m[*]\033[0m Configuring OPKG repository feed: \033[0;36m%s\033[0m...\n" "$REPO_URL"
mkdir -p /opt/etc/opkg
rm -f /opt/etc/opkg/keenetic.conf /opt/var/opkg-lists/keenetic-custom 2>/dev/null || true
echo "src/gz snakelair $REPO_URL" > "$FEED_CONF"

# Clean stale locks
rm -f /opt/tmp/opkg.lock /opt/var/lock/opkg.lock /opt/lib/opkg/lock 2>/dev/null || true

# 6. Auto-heal broken OPKG status database (clean old prerm & fix postinst)
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

# 7. Update package lists
printf "\033[1;34m[*]\033[0m Updating package lists...\n"
rm -f /opt/var/opkg-lists/snakelair /opt/var/opkg-lists/keenetic-custom /tmp/opkg-* /opt/tmp/opkg.lock /opt/var/lock/opkg.lock /opt/lib/opkg/lock 2>/dev/null || true
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

# Backup existing config to prevent loss across remove/reinstall
CFG_BACKUP=""
if [ -f "$CFG_FILE" ]; then
    CFG_BACKUP="/tmp/${PACKAGE}_cfg_bak_$$.json"
    cp -a "$CFG_FILE" "$CFG_BACKUP" 2>/dev/null || true
fi

# Stop and terminate any running instance of the service before installing new files
if [ -f "/opt/etc/init.d/S99${PACKAGE}" ]; then
    sh "/opt/etc/init.d/S99${PACKAGE}" stop >/dev/null 2>&1 || true
    sh "/opt/etc/init.d/S99${PACKAGE}" kill >/dev/null 2>&1 || true
fi
for pid in $(pidof "$PACKAGE" 2>/dev/null) $(/opt/bin/pidof "$PACKAGE" 2>/dev/null); do
    kill -9 "$pid" 2>/dev/null || true
done
killall -9 "$PACKAGE" >/dev/null 2>&1 || true
/opt/bin/killall -9 "$PACKAGE" >/dev/null 2>&1 || true

printf "\033[1;34m[*]\033[0m Installing/upgrading package: \033[1;37m%s\033[0m...\n" "$PACKAGE"
/opt/bin/opkg remove "$PACKAGE" --force-remove --force-depends >/dev/null 2>&1 || true
/opt/bin/opkg install "$PACKAGE" --force-remove --force-reinstall --force-overwrite 2>/dev/null || \
/opt/bin/opkg upgrade "$PACKAGE" --force-remove --force-overwrite 2>/dev/null || \
/opt/bin/opkg install "$PACKAGE" --force-remove --force-reinstall --force-overwrite

INSTALL_RES=$?

if [ $INSTALL_RES -ne 0 ]; then
    rm -f "$CFG_BACKUP" 2>/dev/null || true
    printf "\n\033[1;31m================================================================================\033[0m\n"
    printf "\033[1;31m [ERROR] Ошибка установки %s. Пожалуйста, проверьте вывод выше.\033[0m\n" "$PKG_TITLE"
    printf "\033[1;31m================================================================================\033[0m\n\n"
    exit 1
fi

# 8. Apply configured port to config file
# Restore backup if opkg removed it
if [ ! -f "$CFG_FILE" ] && [ -n "$CFG_BACKUP" ] && [ -f "$CFG_BACKUP" ]; then
    cp -a "$CFG_BACKUP" "$CFG_FILE" 2>/dev/null || true
fi
rm -f "$CFG_BACKUP" 2>/dev/null || true

mkdir -p "/opt/etc/${PACKAGE}"
if [ ! -f "$CFG_FILE" ]; then
    printf '{\n  "web_port": %s\n}\n' "$SELECTED_PORT" > "$CFG_FILE"
elif grep -q '"web_port"' "$CFG_FILE"; then
    sed -i -E "s/\"web_port\"[[:space:]]*:[[:space:]]*[0-9]+/\"web_port\": $SELECTED_PORT/" "$CFG_FILE"
else
    sed -i "s/{/{\n  \"web_port\": $SELECTED_PORT,/" "$CFG_FILE"
fi

# 9. Start / Restart service safely
chmod +x /opt/etc/init.d/* /opt/bin/* 2>/dev/null || true
sleep 1

if [ -f "/opt/etc/init.d/S99smart-utils" ] && [ "$PACKAGE" = "smart-utils" ]; then
    printf "\033[1;34m[*]\033[0m Перезапуск службы Smart-Utils...\n"
    sh /opt/etc/init.d/S99smart-utils stop >/dev/null 2>&1 || true
    for pid in $(pidof smart-utils 2>/dev/null) $(/opt/bin/pidof smart-utils 2>/dev/null); do kill -9 "$pid" 2>/dev/null || true; done
    killall -9 smart-utils >/dev/null 2>&1 || true
    /opt/bin/killall -9 smart-utils >/dev/null 2>&1 || true
    sleep 1
    sh /opt/etc/init.d/S99smart-utils start >/dev/null 2>&1
elif [ -f "/opt/etc/init.d/S99smart-route" ] && [ "$PACKAGE" = "smart-route" ]; then
    printf "\033[1;34m[*]\033[0m Перезапуск службы Smart-Route...\n"
    sh /opt/etc/init.d/S99smart-route stop >/dev/null 2>&1 || true
    for pid in $(pidof smart-route 2>/dev/null) $(/opt/bin/pidof smart-route 2>/dev/null); do kill -9 "$pid" 2>/dev/null || true; done
    killall -9 smart-route >/dev/null 2>&1 || true
    /opt/bin/killall -9 smart-route >/dev/null 2>&1 || true
    sleep 1
    sh /opt/etc/init.d/S99smart-route start >/dev/null 2>&1
elif [ -f "/opt/etc/init.d/S99smart-photo" ] && [ "$PACKAGE" = "smart-photo" ]; then
    printf "\033[1;34m[*]\033[0m Перезапуск службы Smart-Photo...\n"
    sh /opt/etc/init.d/S99smart-photo stop >/dev/null 2>&1 || true
    for pid in $(pidof smart-photo 2>/dev/null) $(/opt/bin/pidof smart-photo 2>/dev/null); do kill -9 "$pid" 2>/dev/null || true; done
    killall -9 smart-photo >/dev/null 2>&1 || true
    /opt/bin/killall -9 smart-photo >/dev/null 2>&1 || true
    sleep 1
    sh /opt/etc/init.d/S99smart-photo start >/dev/null 2>&1
elif [ -f "/opt/etc/init.d/S99smart-vpn" ] && [ "$PACKAGE" = "smart-vpn" ]; then
    printf "\033[1;34m[*]\033[0m Перезапуск службы Smart-VPN...\n"
    sh /opt/etc/init.d/S99smart-vpn stop >/dev/null 2>&1 || true
    for pid in $(pidof smart-vpn 2>/dev/null) $(/opt/bin/pidof smart-vpn 2>/dev/null); do kill -9 "$pid" 2>/dev/null || true; done
    killall -9 smart-vpn >/dev/null 2>&1 || true
    /opt/bin/killall -9 smart-vpn >/dev/null 2>&1 || true
    sleep 1
    sh /opt/etc/init.d/S99smart-vpn start >/dev/null 2>&1
fi

# 10. Wait for service and verify via real API query
ACTIVE_VER=""
ROUTER_MODEL=""
printf "\033[1;34m[*]\033[0m Ожидание запуска и проверка API (http://127.0.0.1:%s/api/status)...\n" "$SELECTED_PORT"

CAN_CURL=0
if command -v curl >/dev/null 2>&1; then
    if curl --version >/dev/null 2>&1; then
        CAN_CURL=1
    fi
fi

for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    sleep 1
    STATUS_JSON=""
    if [ $CAN_CURL -eq 1 ]; then
        STATUS_JSON=$(curl -s --connect-timeout 2 "http://127.0.0.1:${SELECTED_PORT}/api/status" 2>/dev/null || true)
    fi
    if [ -z "$STATUS_JSON" ]; then
        STATUS_JSON=$(wget -q -O - -T 2 "http://127.0.0.1:${SELECTED_PORT}/api/status" 2>/dev/null || true)
    fi
    if [ -n "$STATUS_JSON" ]; then
        ACTIVE_VER=$(echo "$STATUS_JSON" | grep -o '"version"[^,}]*' | awk -F'"' '{print $4}')
        ROUTER_MODEL=$(echo "$STATUS_JSON" | grep -o '"router_model"[^,}]*' | awk -F'"' '{print $4}')
        if [ -n "$ACTIVE_VER" ]; then
            break
        fi
    fi
done

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
