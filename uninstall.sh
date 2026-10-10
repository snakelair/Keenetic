#!/bin/sh
# ==============================================================================
# Snakelair Keenetic Ecosystem & VPS Packages Uninstaller
# Репозиторий: snakelair/Keenetic (https://github.com/snakelair/Keenetic)
# ==============================================================================

set +e

# ANSI Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

TARGET="${1:-}"
[ "$TARGET" = "uninstall" ] || [ "$TARGET" = "remove" ] || [ "$TARGET" = "purge" ] && TARGET="${2:-}"

# Header Banner
printf "\n${CYAN}================================================================================${RESET}\n"
printf "${CYAN}    Snakelair Keenetic Packages & Services Full Uninstaller${RESET}\n"
printf "${CYAN}================================================================================${RESET}\n\n"

export PATH="/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# Helper Functions
force_kill_target() {
    NAME="$1"
    
    # 1. Standard killall
    killall "$NAME" >/dev/null 2>&1 || true
    killall -9 "$NAME" >/dev/null 2>&1 || true
    /opt/bin/killall -9 "$NAME" >/dev/null 2>&1 || true
    /opt/sbin/killall -9 "$NAME" >/dev/null 2>&1 || true

    # 2. Kill by pidof
    for pid in $(pidof "$NAME" 2>/dev/null) $(/opt/bin/pidof "$NAME" 2>/dev/null); do
        if [ -n "$pid" ] && [ "$pid" != "$$" ]; then
            kill -9 "$pid" >/dev/null 2>&1 || true
        fi
    done

    # 3. Direct inspection of /proc to kill processes by comm and cmdline
    for pdir in /proc/[0-9]*; do
        pid="${pdir#/proc/}"
        if [ "$pid" != "$$" ] && [ -d "$pdir" ]; then
            comm=$(cat "$pdir/comm" 2>/dev/null || true)
            case "$comm" in
                "$NAME"|*"$NAME"*)
                    kill -9 "$pid" >/dev/null 2>&1 || true
                    ;;
                *)
                    cmdline=$(tr '\0' ' ' < "$pdir/cmdline" 2>/dev/null || true)
                    case "$cmdline" in
                        *"$NAME"*)
                            case "$cmdline" in
                                *"uninstall.sh"*|*"sh -s"*|*"grep"*) ;;
                                *) kill -9 "$pid" >/dev/null 2>&1 || true ;;
                            esac
                            ;;
                    esac
                    ;;
            esac
        fi
    done
}

kill_port_listeners() {
    PORTS="$@"
    for port in $PORTS; do
        [ -z "$port" ] && continue
        # Find PID via netstat
        if command -v netstat >/dev/null 2>&1; then
            pids=$(netstat -tlpn 2>/dev/null | grep -E ":${port}[[:space:]]" | awk '{print $7}' | cut -d'/' -f1 | tr -dc '0-9 ')
            for pid in $pids; do
                if [ -n "$pid" ] && [ "$pid" != "$$" ]; then
                    kill -9 "$pid" >/dev/null 2>&1 || true
                fi
            done
        fi
        # Fallback via fuser
        if command -v fuser >/dev/null 2>&1; then
            fuser -k -9 "${port}/tcp" >/dev/null 2>&1 || true
            fuser -k -9 "${port}/udp" >/dev/null 2>&1 || true
        fi
    done
}

stop_and_clean_service() {
    PKG_NAME="$1"
    INIT_SCRIPT="/opt/etc/init.d/S99${PKG_NAME}"
    
    printf "${BLUE}[*]${RESET} Остановка и удаление службы ${WHITE}%s${RESET}...\n" "$PKG_NAME"

    # Stop via init script first (graceful)
    if [ -f "$INIT_SCRIPT" ]; then
        sh "$INIT_SCRIPT" stop >/dev/null 2>&1 || true
        sh "$INIT_SCRIPT" kill >/dev/null 2>&1 || true
    fi

    # Aggressive force-kill by process name and comm/cmdline
    force_kill_target "$PKG_NAME"

    # Specific cleanups for smart-route
    if [ "$PKG_NAME" = "smart-route" ]; then
        printf "${BLUE}[*]${RESET} Очистка правил маршрутизации iptables и таблиц ipset...\n"
        kill_port_listeners 8002 8088 10880 10853

        # Netfilter jump hooks
        iptables -t nat -D PREROUTING -j SMART_ROUTE_PREROUTING 2>/dev/null || true
        iptables -t nat -D POSTROUTING -j SMART_ROUTE_POSTROUTING 2>/dev/null || true
        iptables -t mangle -D PREROUTING -j SMART_ROUTE_MANGLE 2>/dev/null || true
        iptables -t filter -D FORWARD -j SMART_ROUTE_FORWARD 2>/dev/null || true

        # Custom chains flush & delete
        iptables -t nat -F SMART_ROUTE_PREROUTING 2>/dev/null || true
        iptables -t nat -X SMART_ROUTE_PREROUTING 2>/dev/null || true
        iptables -t nat -F SMART_ROUTE_POSTROUTING 2>/dev/null || true
        iptables -t nat -X SMART_ROUTE_POSTROUTING 2>/dev/null || true
        iptables -t mangle -F SMART_ROUTE_MANGLE 2>/dev/null || true
        iptables -t mangle -X SMART_ROUTE_MANGLE 2>/dev/null || true
        iptables -t filter -F SMART_ROUTE_FORWARD 2>/dev/null || true
        iptables -t filter -X SMART_ROUTE_FORWARD 2>/dev/null || true

        # Legacy redirects & divert
        iptables -t nat -D PREROUTING -p tcp -m multiport --dports 80,443 -j REDIRECT --to-ports 10880 2>/dev/null || true
        iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 10853 2>/dev/null || true
        iptables -t mangle -F SR_DIVERT 2>/dev/null || true
        iptables -t mangle -D PREROUTING -j SR_DIVERT 2>/dev/null || true
        iptables -t mangle -X SR_DIVERT 2>/dev/null || true

        # Policy routing rules & tables
        for t in 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142; do
            ip rule del lookup "$t" 2>/dev/null || true
            ip route flush table "$t" 2>/dev/null || true
        done
        ip route flush table 254 proto 188 2>/dev/null || true
        for t in $(ip rule show 2>/dev/null | awk '/lookup/ {print $NF}'); do
            case "$t" in
                4[0-9][0-9][0-9])
                    ip route flush table "$t" proto 188 2>/dev/null || true
                    ;;
            esac
        done

        # Flush and destroy ipsets
        for SET in $(ipset list -n 2>/dev/null | grep -E '^sr_|^sr_blk_'); do
            ipset flush "$SET" 2>/dev/null || true
            ipset destroy "$SET" 2>/dev/null || true
        done
    elif [ "$PKG_NAME" = "smart-utils" ]; then
        kill_port_listeners 8001 8090
    elif [ "$PKG_NAME" = "smart-photo" ]; then
        kill_port_listeners 8089
    elif [ "$PKG_NAME" = "smart-vpn" ]; then
        kill_port_listeners 8091
        force_kill_target sing-box
        force_kill_target awg
    elif [ "$PKG_NAME" = "smart-nvr" ]; then
        kill_port_listeners 8095
    fi

    # OPKG Remove
    if [ -x "/opt/bin/opkg" ] || command -v opkg >/dev/null 2>&1; then
        printf "${BLUE}[*]${RESET} Удаление пакета OPKG ${WHITE}%s${RESET}...\n" "$PKG_NAME"
        opkg remove "$PKG_NAME" --force-remove --force-depends >/dev/null 2>&1 || true
        /opt/bin/opkg remove "$PKG_NAME" --force-remove --force-depends >/dev/null 2>&1 || true
        rm -f /opt/lib/opkg/info/${PKG_NAME}.* /opt/var/lib/opkg/info/${PKG_NAME}.* 2>/dev/null || true
    fi

    # Final kill pass
    force_kill_target "$PKG_NAME"

    # Remove binary executables
    rm -f "/opt/bin/${PKG_NAME}" "/opt/sbin/${PKG_NAME}" "/opt/usr/bin/${PKG_NAME}" "/usr/local/bin/${PKG_NAME}" 2>/dev/null || true

    # Remove files, configs, init scripts, and logs
    rm -f "$INIT_SCRIPT" "/opt/etc/init.d/K01${PKG_NAME}" "/opt/etc/init.d/*${PKG_NAME}*" 2>/dev/null || true
    rm -rf "/opt/etc/${PKG_NAME}" "/opt/var/cache/${PKG_NAME}" "/opt/var/run/${PKG_NAME}.pid" "/opt/var/run/${PKG_NAME}" 2>/dev/null || true
    rm -f "/tmp/${PKG_NAME}.log" "/opt/var/log/${PKG_NAME}.log" 2>/dev/null || true

    # Verify process termination
    sleep 1
    REMAINING=$(pidof "$PKG_NAME" 2>/dev/null || /opt/bin/pidof "$PKG_NAME" 2>/dev/null || true)
    if [ -n "$REMAINING" ]; then
        for rpid in $REMAINING; do
            kill -9 "$rpid" 2>/dev/null || true
        done
        printf "${YELLOW}[!]${RESET} Принудительно завершен зависший процесс %s (PID: %s)\n" "$PKG_NAME" "$REMAINING"
    fi

    printf "${GREEN}[OK]${RESET} %s полностью удален и служба остановлена!\n\n" "$PKG_NAME"
}

uninstall_qlvpn() {
    printf "${BLUE}[*]${RESET} Полное удаление QuakeLive-VPN Server (Linux VPS)...\n"
    
    # Stop & disable systemd service
    if command -v systemctl >/dev/null 2>&1; then
        systemctl stop ql-vpn >/dev/null 2>&1 || true
        systemctl disable ql-vpn >/dev/null 2>&1 || true
    fi
    killall -9 ql-vpn 2>/dev/null || true

    # Remove firewall rules
    iptables -t nat -D POSTROUTING -s 10.80.0.0/24 ! -d 10.80.0.0/24 -j MASQUERADE 2>/dev/null || true
    iptables -D FORWARD -s 10.80.0.0/24 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -d 10.80.0.0/24 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    iptables -D INPUT -p udp --dport 27960 -j ACCEPT 2>/dev/null || true
    iptables -D INPUT -p tcp --dport 8092 -j ACCEPT 2>/dev/null || true
    if command -v netfilter-persistent >/dev/null 2>&1; then
        netfilter-persistent save >/dev/null 2>&1 || true
    fi

    # Remove files
    rm -f /usr/local/bin/ql-vpn /etc/systemd/system/ql-vpn.service /etc/sysctl.d/99-qlvpn.conf
    rm -rf /etc/ql-vpn

    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload >/dev/null 2>&1 || true
    fi

    printf "${GREEN}[OK]${RESET} QuakeLive-VPN Server полностью удален с сервера!\n\n"
}

remove_repo_feed() {
    printf "${BLUE}[*]${RESET} Удаление репозитория Snakelair Keenetic из OPKG...\n"
    rm -f /opt/etc/opkg/snakelair.conf /opt/etc/opkg/keenetic.conf
    rm -f /opt/var/opkg-lists/snakelair /opt/var/opkg-lists/keenetic-custom
    if [ -x "/opt/bin/opkg" ]; then
        /opt/bin/opkg update >/dev/null 2>&1 || true
    fi
    printf "${GREEN}[OK]${RESET} Репозиторий snakelair.conf удален и кэш списков обновлен.\n\n"
}

# Interactive Menu if no target specified
if [ -z "$TARGET" ]; then
    if ( exec 3>/dev/tty 4</dev/tty ) 2>/dev/null; then
        exec 3>/dev/tty 4</dev/tty
        printf "${WHITE}Выберите компонент для полного удаления:${RESET}\n" >&3
        printf "  ${CYAN}1${RESET}) Smart-Utils (Веб-панель управления, Терминалы, Файловый менеджер)\n" >&3
        printf "  ${CYAN}2${RESET}) Smart-Route (Служба динамической маршрутизации и обхода блокировок)\n" >&3
        printf "  ${CYAN}3${RESET}) Smart-Photo (Персональный фотосервер на USB)\n" >&3
        printf "  ${CYAN}4${RESET}) Smart-VPN (Управление VPN-соединениями на роутере)\n" >&3
        printf "  ${CYAN}5${RESET}) QuakeLive-VPN Server (Служба QL-VPN на Linux VPS)\n" >&3
        printf "  ${CYAN}6${RESET}) Удалить только репозиторий OPKG (snakelair.conf)\n" >&3
        printf "  ${RED}7${RESET}) ${RED}Удалить ВСЕ пакеты Snakelair и репозиторий OPKG${RESET}\n" >&3
        printf "  ${YELLOW}0${RESET}) Отмена\n\n" >&3

        printf "${YELLOW}[?]${RESET} Введите номер пункта [0-7]: " >&3
        read -r CHOICE <&4 || CHOICE=""
        exec 3>&- 4<&-

        case "$CHOICE" in
            1) TARGET="smart-utils" ;;
            2) TARGET="smart-route" ;;
            3) TARGET="smart-photo" ;;
            4) TARGET="smart-vpn" ;;
            5) TARGET="ql-vpn" ;;
            6) TARGET="repo" ;;
            7) TARGET="all" ;;
            *)
                printf "\n${YELLOW}[!]${RESET} Отменено пользователем.\n\n"
                exit 0
                ;;
        esac
    else
        TARGET="all"
    fi
fi

# Execute Removal
case "$TARGET" in
    smart-utils)
        stop_and_clean_service "smart-utils"
        ;;
    smart-route)
        stop_and_clean_service "smart-route"
        ;;
    smart-photo)
        stop_and_clean_service "smart-photo"
        ;;
    smart-vpn)
        stop_and_clean_service "smart-vpn"
        ;;
    ql-vpn|qlvpn)
        uninstall_qlvpn
        ;;
    repo|feed)
        remove_repo_feed
        ;;
    all|full|purge)
        printf "${YELLOW}[!]${RESET} Запуск полного удаления всех компонентов экосистемы Snakelair...\n\n"
        stop_and_clean_service "smart-utils"
        stop_and_clean_service "smart-route"
        stop_and_clean_service "smart-photo"
        stop_and_clean_service "smart-vpn"
        remove_repo_feed
        if [ -f "/usr/local/bin/ql-vpn" ] || [ -f "/etc/systemd/system/ql-vpn.service" ]; then
            uninstall_qlvpn
        fi
        printf "${GREEN}================================================================================${RESET}\n"
        printf "${GREEN}   [OK] Все пакеты, конфигурации и репозиторий успешно удалены!${RESET}\n"
        printf "${GREEN}================================================================================${RESET}\n\n"
        ;;
    *)
        printf "${RED}[ERROR] Неизвестный пакет: %s${RESET}\n" "$TARGET"
        printf "Доступные варианты: smart-utils, smart-route, smart-photo, smart-vpn, ql-vpn, repo, all\n\n"
        exit 1
        ;;
esac
