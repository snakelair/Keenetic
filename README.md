# ⚡ Keenetic Entware OPKG Repository

Официальный публичный репозиторий пакетов **OPKG** для роутеров **Keenetic** с установленной средой **Entware**.

---

## 📦 Доступные пакеты в репозитории

### 1. 🛠️ `smart-utils` (v1.0.28)
**Универсальный веб-комбайн системного администрирования и управления роутером Keenetic:**
- **Двухпанельный файловый менеджер:** классический интерфейс в стиле Total Commander, горячие клавиши F3–F10, полноэкранный редактор конфигов с подсветкой синтаксиса, архиватор (tar.gz/zip), смена прав доступа (chmod) и Drag-and-Drop загрузка файлов прямо в браузер.
- **Два веб-терминала:**
  - **Терминал CLI:** прямое управление командной строкой KeeneticOS (`ndmc` / `(config)>`).
  - **Терминал SSH:** доступ к сессии Linux / Entware Shell (`/opt/bin/sh`, `/opt/bin/bash`) с полной поддержкой цветов и горячих клавиш.
- **Менеджер пакетов OPKG:** каталог репозиториев/фидов, каталог популярных репозиториев с живым поиском и описанием дочерних пакетов, установка, удаление, обновление пакетов и вывод логов в реальном времени.
- **Анализатор системы и CPU:** графики нагрузки процессора, ядер, памяти, Swap, дисков и сетевого трафика в реальном времени, а также интерактивная таблица процессов (`top`/`htop`) с сортировкой и управлением сигналами (SIGTERM/SIGKILL).
- **Резервное копирование и восстановление:** экспорт/импорт списка пакетов OPKG, создание и откат архивов конфигураций `/opt/etc/`.
- **Логирование:** безопасное логирование в оперативную память (RAM `/tmp/smart-utils.log`) без износа flash-накопителя.
- **Веб-интерфейс:** `http://192.168.1.1:8090` (или IP вашего роутера)
- [📘 **Руководство пользователя Smart-Utils (smart_utils_user_guide.md)**](smart_utils_user_guide.md)

---

### 2. ⚡ `smart-route` (v1.0.25)
**Системный сервис динамической многоинтерфейсной маршрутизации, бесшовного перехвата сбойных соединений (Failover Relay) и аппаратной разгрузки ядра (IPSet / NDM):**
- Автоматический выбор самого быстрого VPN-канала при сбоях и блокировках (Race/Sequential).
- Аппаратный оффлоад ядра Linux (0% нагрузки на процессор роутера).
- Поддержка списков исключений (.ru, .рф, банки, госуслуги) для прямого WAN-доступа.
- Встроенные ядра Sing-box, Xray, Shadowsocks, WireGuard.
- **Веб-интерфейс:** `http://192.168.1.1:8088`
- [📘 **Полное руководство пользователя Smart-Route (smart_route_user_guide.md)**](smart_route_user_guide.md)

---

### 3. 📷 `smart-photo` (v1.0.37)
**Персональный домашний фотосервер в стиле Google Photos прямо на роутере Keenetic для подключенных USB-накопителей:**
- Бесконечная лента фотохроники (Infinite Scroll) с быстрым отображением.
- Сканирование и просмотр фото и видео с подключенных по USB накопителей (флешки, HDD, SSD).
- Мгновенная генерация и кэширование миниатюр на лету.
- Полноэкранный просмотрщик (Lightbox) с зумом, слайд-шоу и просмотром EXIF-метаданных (камера, выдержка, диафрагма, GPS).
- Автоматическая группировка по датам, папкам и альбомам.
- **Веб-интерфейс:** `http://192.168.1.1:8089`
- [📷 **Руководство пользователя Smart-Photo (smart_photo_USER_GUIDE.md)**](smart_photo_USER_GUIDE.md)

---

## 🚀 Быстрая установка на роутер Keenetic

### 1. Автоматическая установка (в одну команду):

Подключитесь к роутеру по SSH и выполните:

```bash
# Установить Smart-Utils (Веб-панель, Терминалы, Файловый менеджер, OPKG):
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-utils

# Установить Smart-Route (Маршрутизация и обход блокировок):
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-route

# Установить Smart-Photo (Персональная фотогалерея на USB):
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
opkg install smart-utils
opkg install smart-route
opkg install smart-photo
```

---

## 🔄 Обновление пакетов

```bash
opkg update && opkg upgrade smart-utils smart-route smart-photo
```

---

## 🌐 Соответствие моделей Keenetic и архитектур

| Архитектура | Модели роутеров Keenetic |
| :--- | :--- |
| **`mipsel-3.4`** | Viva, Extra, Speedster, Giga (KN-1010/1011), Omni, Skipper, Air, Buddy |
| **`armv7-3.2`** | Hero (KN-1011/KN-1012), Titan (KN-1810), Giant (KN-2610), Ultra (KN-1810) |
| **`aarch64-3.10`** | Peak (KN-2710), Ultra (KN-1811), Titan (KN-1812), Hero 4G+ (KN-2311) |
| **`x86_64`** | x86 Entware / Виртуальные машины |
| **`mips-3.4`** | Keenetic MIPS Big-Endian |
