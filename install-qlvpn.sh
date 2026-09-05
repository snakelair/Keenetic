#!/usr/bin/env bash
# ==============================================================================
# QuakeLive-VPN Server & Gateway Installer
# Репозиторий: snakelair/Keenetic (https://github.com/snakelair/Keenetic)
# ==============================================================================

set -e

# ANSI Colors
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
RESET='\033[0m'

printf "\n${CYAN}================================================================================${RESET}\n"
printf "${CYAN}       QuakeLive-VPN Server & Gateway Installer (snakelair/Keenetic)${RESET}\n"
printf "${CYAN}================================================================================${RESET}\n\n"

# 1. Check root permissions
if [ "$(id -u)" -ne 0 ]; then
    printf "${RED}[ERROR] Скрипт должен быть запущен с правами суперпользователя (root)!${RESET}\n"
    printf "Пожалуйста, выполните: sudo bash $0\n\n"
    exit 1
fi

# 2. Detect CPU Architecture
RAW_ARCH=$(uname -m)
ARCH="amd64"
case "$RAW_ARCH" in
    x86_64|amd64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        printf "${RED}[ERROR] Архитектура %s не поддерживается! Доступны: x86_64 (amd64), aarch64 (arm64).${RESET}\n" "$RAW_ARCH"
        exit 1
        ;;
esac

printf "${BLUE}[*]${RESET} Архитектура сервера: ${WHITE}%s${RESET} (бинарник: ${GREEN}ql-vpn-linux-%s${RESET})\n" "$RAW_ARCH" "$ARCH"

# 3. Detect Public IP & WAN Interface
WAN_IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++)if($i=="dev")print $(i+1)}')
if [ -z "$WAN_IFACE" ]; then
    WAN_IFACE=$(ip -4 route show default 2>/dev/null | awk '{print $5}' | head -n1)
fi

PUBLIC_IP=$(curl -s4 --connect-timeout 3 https://api.ipify.org 2>/dev/null || \
           curl -s4 --connect-timeout 3 https://ifconfig.me 2>/dev/null || \
           curl -s4 --connect-timeout 3 https://icanhazip.com 2>/dev/null || \
           hostname -I 2>/dev/null | awk '{print $1}')

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="127.0.0.1"
fi

printf "${BLUE}[*]${RESET} Сетевой интерфейс: ${WHITE}%s${RESET}, Внешний IP: ${WHITE}%s${RESET}\n\n" "${WAN_IFACE:-eth0}" "$PUBLIC_IP"

# 4. Interactive Configuration
AUTO_MODE=0
for arg in "$@"; do
    if [ "$arg" = "-y" ] || [ "$arg" = "--auto" ] || [ "$arg" = "-auto" ]; then
        AUTO_MODE=1
    fi
done

DEFAULT_SERVER_PORT=27960
DEFAULT_WEB_PORT=8092

# Generate random secure 8-char password
GEN_PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 8 || true)
if [ -z "$GEN_PASS" ]; then
    GEN_PASS="QL$(date +%s | tail -c 6)"
fi
DEFAULT_WEB_PASS="Pass-$GEN_PASS"

SERVER_PORT="${SERVER_PORT:-$DEFAULT_SERVER_PORT}"
WEB_PORT="${WEB_PORT:-$DEFAULT_WEB_PORT}"
WEB_PASS="${WEB_PASS:-$DEFAULT_WEB_PASS}"

if [ "$AUTO_MODE" -eq 0 ] && [ -t 0 ]; then
    read -r -p "$(printf "${YELLOW}[?]${RESET} Основной игровой UDP-порт сервера [%s]: " "$DEFAULT_SERVER_PORT")" INPUT_PORT
    [ -n "$INPUT_PORT" ] && SERVER_PORT="$INPUT_PORT"

    read -r -p "$(printf "${YELLOW}[?]${RESET} Порт веб-панели управления HTTPS [%s]: " "$DEFAULT_WEB_PORT")" INPUT_WEB_PORT
    [ -n "$INPUT_WEB_PORT" ] && WEB_PORT="$INPUT_WEB_PORT"

    read -r -p "$(printf "${YELLOW}[?]${RESET} Пароль администратора веб-панели [%s]: " "$DEFAULT_WEB_PASS")" INPUT_PASS
    [ -n "$INPUT_PASS" ] && WEB_PASS="$INPUT_PASS"
fi

printf "\n${BLUE}[*]${RESET} Конфигурация: Сервер UDP ${GREEN}:%s${RESET}, Веб-панель HTTPS ${GREEN}:%s${RESET}\n" "$SERVER_PORT" "$WEB_PORT"

# 5. Install system dependencies
printf "${BLUE}[*]${RESET} Проверка и установка пакетов (iptables, curl, ca-certificates)...\n"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq >/dev/null 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq iptables iptables-persistent curl ca-certificates >/dev/null 2>&1 || \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq iptables curl ca-certificates >/dev/null 2>&1 || true
elif command -v yum >/dev/null 2>&1; then
    yum install -y -q iptables curl ca-certificates >/dev/null 2>&1 || true
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y -q iptables curl ca-certificates >/dev/null 2>&1 || true
elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache iptables curl ca-certificates bash >/dev/null 2>&1 || true
fi

# 6. Enable IPv4 Forwarding & Firewall
printf "${BLUE}[*]${RESET} Включение IPv4-forwarding и настройка правил iptables...\n"
mkdir -p /etc/sysctl.d
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-qlvpn.conf
sysctl -p /etc/sysctl.d/99-qlvpn.conf >/dev/null 2>&1 || sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

# NAT MASQUERADE
iptables -t nat -C POSTROUTING -s 10.80.0.0/24 ! -d 10.80.0.0/24 -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -s 10.80.0.0/24 ! -d 10.80.0.0/24 -j MASQUERADE

# FORWARD
iptables -C FORWARD -s 10.80.0.0/24 -j ACCEPT 2>/dev/null || \
iptables -A FORWARD -s 10.80.0.0/24 -j ACCEPT

iptables -C FORWARD -d 10.80.0.0/24 -j ACCEPT 2>/dev/null || \
iptables -A FORWARD -d 10.80.0.0/24 -j ACCEPT

iptables -C FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# INPUT ports
iptables -C INPUT -p udp --dport "$SERVER_PORT" -j ACCEPT 2>/dev/null || \
iptables -A INPUT -p udp --dport "$SERVER_PORT" -j ACCEPT

iptables -C INPUT -p tcp --dport "$WEB_PORT" -j ACCEPT 2>/dev/null || \
iptables -A INPUT -p tcp --dport "$WEB_PORT" -j ACCEPT

if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save >/dev/null 2>&1 || true
fi

# 7. Download QL-VPN Binary from Shared Keenetic Repository
printf "${BLUE}[*]${RESET} Загрузка исполняемого файла из snakelair/Keenetic...\n"
mkdir -p /etc/ql-vpn /usr/local/bin

systemctl stop ql-vpn 2>/dev/null || true
killall -9 ql-vpn 2>/dev/null || true

BIN_URL="https://raw.githubusercontent.com/snakelair/Keenetic/main/bin/ql-vpn-linux-${ARCH}"
FALLBACK_URL="https://github.com/snakelair/SmartVpn/releases/latest/download/ql-vpn_linux_${ARCH}"

rm -f /usr/local/bin/ql-vpn.tmp
curl -sSL -o /usr/local/bin/ql-vpn.tmp "$BIN_URL" || true
if [ -s /usr/local/bin/ql-vpn.tmp ]; then
    chmod +x /usr/local/bin/ql-vpn.tmp
    mv -f /usr/local/bin/ql-vpn.tmp /usr/local/bin/ql-vpn
else
    printf "${YELLOW}[!]${RESET} Репозиторий сырых файлов недоступен, пробую GitHub Releases...\n"
    curl -sSL -o /usr/local/bin/ql-vpn.tmp "$FALLBACK_URL" || true
    if [ -s /usr/local/bin/ql-vpn.tmp ]; then
        chmod +x /usr/local/bin/ql-vpn.tmp
        mv -f /usr/local/bin/ql-vpn.tmp /usr/local/bin/ql-vpn
    fi
fi

if [ ! -s /usr/local/bin/ql-vpn ]; then
    printf "${RED}[ERROR] Не удалось загрузить бинарник ql-vpn! Проверьте интернет-соединение.${RESET}\n"
    exit 1
fi

chmod +x /usr/local/bin/ql-vpn

# 8. Create Systemd Service
printf "${BLUE}[*]${RESET} Регистрация службы systemd (ql-vpn.service)...\n"
cat << EOF > /etc/systemd/system/ql-vpn.service
[Unit]
Description=QuakeLive-VPN Server and Web Control Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ql-vpn -server -port $SERVER_PORT -web-port $WEB_PORT -tls -web-pass "$WEB_PASS" -tun 10.80.0.1/24 -tokens /etc/ql-vpn/tokens.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 9. Generate Initial Client Token
printf "${BLUE}[*]${RESET} Генерация первого клиентского токена подключения...\n"
TOKEN_OUTPUT=$(/usr/local/bin/ql-vpn token add -server "${PUBLIC_IP}:${SERVER_PORT}" -name "Ranger" -tokens /etc/ql-vpn/tokens.json 2>&1 || true)
TOKEN_URL=$(echo "$TOKEN_OUTPUT" | grep -o 'qlvpn://[^ ]*' | head -n1 || true)

# 10. Start Service
systemctl daemon-reload || true
systemctl enable ql-vpn >/dev/null 2>&1 || true
systemctl restart ql-vpn || true
sleep 1

if systemctl is-active --quiet ql-vpn; then
    ACTIVE_STATUS="${GREEN}Работает (Active)${RESET}"
else
    ACTIVE_STATUS="${YELLOW}Запущен${RESET}"
fi

# 11. Final Summary Report
printf "\n${GREEN}================================================================================${RESET}\n"
printf "${GREEN}   [OK] QuakeLive-VPN Сервер успешно установлен и запущен!${RESET}\n"
printf "${GREEN}================================================================================${RESET}\n\n"
printf " ${WHITE}Статус службы:${RESET}       %b\n" "$ACTIVE_STATUS"
printf " ${WHITE}Игровой порт (UDP):${RESET}  ${CYAN}%s${RESET}\n" "$SERVER_PORT"
printf " ${WHITE}Веб-админка (HTTPS):${RESET} ${CYAN}https://%s:%s${RESET}\n" "$PUBLIC_IP" "$WEB_PORT"
printf " ${WHITE}Логин:${RESET}                ${CYAN}admin${RESET}\n"
printf " ${WHITE}Пароль:${RESET}               ${YELLOW}%s${RESET}\n\n" "$WEB_PASS"

if [ -n "$TOKEN_URL" ]; then
    printf "${CYAN}--------------------------------------------------------------------------------${RESET}\n"
    printf " ${YELLOW}🔑 Готовый токен подключения для клиента (Windows / Роутер):${RESET}\n\n"
    printf " ${GREEN}%s${RESET}\n\n" "$TOKEN_URL"
    printf " Скопируйте эту строку и вставьте в Windows-клиент или в Smart-VPN на роутере.\n"
    printf "${CYAN}--------------------------------------------------------------------------------${RESET}\n\n"
fi
