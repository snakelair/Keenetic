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

# Helper Functions
stop_and_clean_service() {
    PKG_NAME="$1"
    INIT_SCRIPT="/opt/etc/init.d/S99${PKG_NAME}"
    
    printf "${BLUE}[*]${RESET} Остановка и удаление службы ${WHITE}%s${RESET}...\n" "$PKG_NAME"

    if [ -x "$INIT_SCRIPT" ]; then
        "$INIT_SCRIPT" stop >/dev/null 2>&1 || true
    fi
    killall -9 "$PKG_NAME" >/dev/null 2>&1 || true

    # Specific cleanups for smart-route
    if [ "$PKG_NAME" = "smart-route" ]; then
        printf "${BLUE}[*]${RESET} Очистка правил маршрутизации iptables и таблиц ipset...\n"
        iptables -t nat -D PREROUTING -p tcp -m multiport --dports 80,443 -j REDIRECT --to-ports 10880 2>/dev/null || true
        iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 10853 2>/dev/null || true
        iptables -t mangle -F SR_DIVERT 2>/dev/null || true
        iptables -t mangle -D PREROUTING -j SR_DIVERT 2>/dev/null || true
        iptables -t mangle -X SR_DIVERT 2>/dev/null || true
        
        # Flush ipsets
        for SET in $(ipset list -n 2>/dev/null | grep -E '^sr_'); do
            ipset flush "$SET" 2>/dev/null || true
            ipset destroy "$SET" 2>/dev/null || true
        done
    fi

    # Specific cleanups for smart-vpn
    if [ "$PKG_NAME" = "smart-vpn" ]; then
        killall -9 sing-box awg 2>/dev/null || true
    fi

    # OPKG Remove
    if [ -x "/opt/bin/opkg" ]; then
        printf "${BLUE}[*]${RESET} Удаление пакета OPKG ${WHITE}%s${RESET}...\n" "$PKG_NAME"
        /opt/bin/opkg remove "$PKG_NAME" --force-remove --force-depends >/dev/null 2>&1 || true
        rm -f /opt/lib/opkg/info/${PKG_NAME}.* /opt/var/lib/opkg/info/${PKG_NAME}.* 2>/dev/null || true
    fi

    # Remove files, configs, init scripts, and logs
    rm -f "$INIT_SCRIPT" "/opt/etc/init.d/K01${PKG_NAME}" 2>/dev/null || true
    rm -rf "/opt/etc/${PKG_NAME}" "/opt/var/cache/${PKG_NAME}" "/opt/var/run/${PKG_NAME}.pid" 2>/dev/null || true
    rm -f "/tmp/${PKG_NAME}.log" "/opt/var/log/${PKG_NAME}.log" 2>/dev/null || true

    printf "${GREEN}[OK]${RESET} %s полностью удален!\n\n" "$PKG_NAME"
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
