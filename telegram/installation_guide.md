# 🛠 Шпаргалка по командам и установке пакетов Keenetic Entware

---

### 1️⃣ Установка Smart-Utils
Центр управления роутером (Файловый менеджер, Web-терминал, OPKG, Мониторинг, Бэкапы):
```bash
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-utils
```
*Порт по умолчанию:* `8090` (можно изменить при установке)

---

### 2️⃣ Установка Smart-Route
Утилита управления маршрутизацией, списками обхода и туннелями:
```bash
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-route
```
*Порт по умолчанию:* `8088`

---

### 3️⃣ Установка Smart-Photo
Сервис резервного копирования фотографий и медиафайлов:
```bash
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-photo
```
*Порт по умолчанию:* `8089`

---

### ⚙️ Управление службой через SSH:
```bash
# Статус службы
/opt/etc/init.d/S99smart-utils status

# Перезапуск
/opt/etc/init.d/S99smart-utils restart

# Остановка / Запуск
/opt/etc/init.d/S99smart-utils stop
/opt/etc/init.d/S99smart-utils start

# Просмотр логов в реальном времени
tail -f /tmp/smart-utils.log
```

---

### 🚑 Восстановление при ошибках OPKG:
Если база OPKG была повреждена сторонними пакетами:
```bash
rm -f /opt/tmp/opkg.lock /opt/var/lock/opkg.lock /opt/lib/opkg/lock
opkg update
opkg configure
```
