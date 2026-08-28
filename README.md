# ⚡ Keenetic Entware OPKG Repository

Официальный публичный репозиторий пакетов **OPKG** для роутеров **Keenetic** с установленной средой **Entware**.

---

## 📦 Доступные пакеты в репозитории

### 1. ⚡ `smart-route` (v1.0.13)
Системный сервис динамической многоинтерфейсной маршрутизации, бесшовного перехвата сбойных соединений (Failover Relay) и аппаратной разгрузки ядра (IPSet / NDM):
- Автоматический выбор самого быстрого VPN-канала при сбоях и блокировках (Race/Sequential).
- Аппаратный оффлоад ядра Linux (0% нагрузки на процессор роутера).
- Поддержка списков исключений (.ru, .рф, банки, госуслуги) для прямого WAN-доступа.
- Встроенная веб-панель управления: `http://192.168.1.1:8088` (или IP вашего роутера).
- [📘 **Полное руководство пользователя и схемы работы (smart_route_user_guide.md)**](smart_route_user_guide.md)

### 2. 📷 `smart-photo` (v1.0.2)
Персональный домашний фотосервер в стиле **Google Photos** прямо на роутере Keenetic для подключенных USB-накопителей:
- Бесконечная лента фотохроники (Infinite Scroll) с быстрым отображением.
- Сканирование и просмотр фото с подключенных по USB накопителей (флешки, HDD, SSD).
- Мгновенная генерация и кэширование миниатюр на лету.
- Полноэкранный просмотрщик (Lightbox) с зумом, слайд-шоу и просмотром EXIF-метаданных (камера, выдержка, диафрагма, GPS).
- Автоматическая группировка по датам, папкам и альбомам.
- Встроенная веб-панель: `http://192.168.1.1:8089`
- [📷 **Руководство пользователя Smart-Photo (smart_photo_USER_GUIDE.md)**](smart_photo_USER_GUIDE.md)

---

## 🚀 Быстрая установка на роутер Keenetic

### 1. Автоматическая установка (в одну команду):

Подключитесь к роутеру по SSH и выполните:

```bash
# Установить Smart-Route:
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-route

# Или установить Smart-Photo:
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-photo
```

---

### 2. Ручное подключение репозитория OPKG:

Создайте конфигурационный файл репозитория в `/opt/etc/opkg/keenetic.conf`:

```bash
ARCH=$(uname -m | sed 's/mips/mipsel-3.4/' | sed 's/aarch64/aarch64-3.10/' | sed 's/armv7l/armv7-3.2/')
echo "src/gz keenetic-custom https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ARCH}" > /opt/etc/opkg/keenetic.conf

# Обновите список пакетов и установите нужные сервисы:
opkg update
opkg install smart-route
opkg install smart-photo
```

---

## 🔄 Обновление пакетов

```bash
opkg update && opkg upgrade smart-route smart-photo
```

---

## 🌐 Соответствие моделей Keenetic и архитектур

| Архитектура | Модели роутеров Keenetic |
| :--- | :--- |
| **`mipsel-3.4`** | Viva, Extra, Speedster, Giga (KN-1010/1011), Omni, Skipper, Air, Buddy |
| **`armv7-3.2`** | Hero (KN-1011/KN-1012), Titan (KN-1810), Giant (KN-2610), Ultra (KN-1810) |
| **`aarch64-3.10`** | Peak (KN-2710), Ultra (KN-1811), Titan (KN-1812), Hero 4G+ (KN-2311) |
| **`x86_64`** | x86 Entware / Виртуальные машины |
