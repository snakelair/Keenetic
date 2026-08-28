# ⚡ Keenetic Entware OPKG Repository

Официальный публичный репозиторий пакетов **OPKG** для роутеров **Keenetic** с установленной средой **Entware**.

---

## 📦 Доступные пакеты в репозитории

### 1. 📷 `smart-photo` (v1.0.27)
Персональный домашний фотосервер в стиле **Google Photos** прямо на роутере Keenetic:
- Бесконечная лента фотохроники (Infinite Scroll) с быстрым отображением.
- Сканирование и просмотр фото с подключенных по USB накопителей (флешки, HDD, SSD).
- Мгновенная генерация и кэширование миниатюр на лету.
- Полноэкранный просмотрщик (Lightbox) с зумом, слайд-шоу и просмотром EXIF-метаданных (камера, выдержка, диафрагма, GPS).
- Автоматическая группировка по датам, папкам и альбомам.
- Встроенная веб-панель: `http://192.168.1.1:8089`

### 2. ⚡ `smart-route` (v1.0.20)
Системный сервис динамической многоинтерфейсной маршрутизации и прозрачного отказоустойчивого проксирования для Keenetic:
- Автоматический выбор самого быстрого интернет-канала и прокси.
- Встроенная веб-панель: `http://192.168.1.1:8088`

### 3. 🛠️ `smart-utils`
Многофункциональный веб-центр администрирования и утилит для Keenetic:
- Встроенный веб-терминал (Web SSH / TTY).
- Двухпанельный файловый менеджер в стиле Total Commander.
- Управление пакетами OPKG и автодиагностика системы.
- Встроенная веб-панель: `http://192.168.1.1:8087`

---

## 🚀 Быстрая установка на роутер Keenetic

### 1. Автоматическая установка (в одну команду):

Подключитесь к роутеру по SSH и выполните:

```bash
# Установить Smart-Photo:
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-photo

# Или установить Smart-Route:
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-route

# Или установить Smart-Utils:
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-utils
```

---

### 2. Ручное подключение репозитория OPKG:

Создайте конфигурационный файл репозитория в `/opt/etc/opkg/keenetic.conf`:

```bash
ARCH=$(uname -m | sed 's/mips/mipsel-3.4/' | sed 's/aarch64/aarch64-3.10/' | sed 's/armv7l/armv7-3.2/')
echo "src/gz keenetic https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ARCH}" > /opt/etc/opkg/keenetic.conf

# Обновите список пакетов и установите нужный сервис:
opkg update
opkg install smart-photo
opkg install smart-route
opkg install smart-utils
```

---

## 🔄 Обновление пакетов

```bash
opkg update && opkg upgrade smart-photo smart-route smart-utils
```

---

## 🌐 Таблица совместимости моделей Keenetic

| Архитектура | Модели роутеров Keenetic |
| :--- | :--- |
| **`mipsel-3.4`** | Viva, Extra, Speedster, Giga (KN-1010/1011), Omni, Skipper, Air, Buddy |
| **`armv7-3.2`** | Hero (KN-1011/KN-1012), Titan (KN-1810), Giant (KN-2610), Ultra (KN-1810) |
| **`aarch64-3.10`** | Peak (KN-2710), Ultra (KN-1811), Titan (KN-1812), Hero 4G+ (KN-2311) |
| **`x86_64`** | x86 Entware / Виртуальные машины |
