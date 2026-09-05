# ⚡ Snakelair Keenetic Entware OPKG Repository

**Snakelair Keenetic Entware OPKG Repository** — репозиторий пакетов **OPKG** для роутеров **Keenetic** с установленной средой **Entware**.

---

## 📦 Доступные пакеты в репозитории

### 1. 🛠️ `smart-utils` (v1.0.29)
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

### 2. ⚡ `smart-route` (v1.0.32)
**Системный сервис динамической многоинтерфейсной маршрутизации, бесшовного перехвата сбойных соединений (Failover Relay) и аппаратной разгрузки ядра (IPSet / NDM):**
- Автоматический выбор самого быстрого VPN-канала при сбоях и блокировках (Race/Sequential).
- Аппаратный оффлоад ядра Linux (0% нагрузки на процессор роутера).
- Поддержка списков исключений (.ru, .рф, банки, госуслуги) для прямого WAN-доступа.
- Встроенные ядра Sing-box, Xray, Shadowsocks, WireGuard.
- **Веб-интерфейс:** `http://192.168.1.1:8088`
- [📘 **Полное руководство пользователя Smart-Route (smart_route_user_guide.md)**](smart_route_user_guide.md)

---

### 3. 📷 `smart-photo` (v1.0.39)
**Персональный домашний фотосервер в стиле Google Photos прямо на роутере Keenetic для подключенных USB-накопителей:**
- Бесконечная лента фотохроники (Infinite Scroll) с быстрым отображением.
- Сканирование и просмотр фото и видео с подключенных по USB накопителей (флешки, HDD, SSD).
- Мгновенная генерация и кэширование миниатюр на лету.
- Полноэкранный просмотрщик (Lightbox) с зумом, слайд-шоу и просмотром EXIF-метаданных (камера, выдержка, диафрагма, GPS).
- Автоматическая группировка по датам, папкам и альбомам.
- **Веб-интерфейс:** `http://192.168.1.1:8089`
- [📷 **Руководство пользователя Smart-Photo (smart_photo_USER_GUIDE.md)**](smart_photo_USER_GUIDE.md)

---

### 4. 🛡️ `smart-vpn` (v1.0.27)
**Единый веб-центр управления всеми типами VPN-соединений и антицензурными ядрами для роутеров Keenetic:**
- **Родные туннели KeeneticOS:** WireGuard, SSTP, OpenVPN, IPsec с асинхронным опросом и кэшированием статусов.
- **Поддержка AmneziaWG (AWG 2.0 / 3.0):** полное управление обфускацией (Jc, Jmin/Jmax, S1-S4, H1-H4), пресеты «Анти-ТСПУ» и вычисление публичных ключей Curve25519.
- **Стелс-протокол QuakeLive-VPN:** игровой VPN на базе id Tech 3 NetChan со скорбордом игроков, защитой от зондирования и генерацией токенов.
- **Подсистема Sing-Box:** визуальный конструктор с 7 вкладками (VLESS Reality, ShadowTLS v3, Trojan), CPU Watchdog и валидатор конфигураций.
- **Развертывание на VPS по SSH:** автоматическая настройка удаленного сервера в один клик с выбором веб-порта.
- **Веб-интерфейс:** `http://192.168.1.1:8091` (или IP вашего роутера)
- [🛡️ **Руководство пользователя Smart-VPN (USER_GUIDE.md)**](https://github.com/snakelair/SmartVpn/blob/main/USER_GUIDE.md)

---

### 5. 🎮 `ql-vpn` (v1.0.65)
**Высокоскоростной стелс-туннель нового поколения на базе протокола id Tech 3 NetChan (Quake Live):**
- **100% маскировка сетевого трафика:** пакеты неотличимы от реального сетевого мультиплеера Quake Live, устойчивы к анализу ТСПУ и сигнатурным блокировкам DPI.
- **Поддержка платформ:** Linux VPS (сервер / шлюз) и Windows (клиент с системным треем и GUI).
- **Сверхнизкий пинг:** прямое UDP-туннелирование, аппаратное шифрование AES-128-GCM и ChaCha20-Poly1305.
- **Автономный веб-центр управления:** веб-интерфейс (:8092) для мониторинга игроков, генерации токенов `qlvpn://`, замера задержки и управления маршрутизацией.
- **Встроенная система самообновления:** автоматическое обновление бинарника и службы в один клик прямо из веб-интерфейса.
- **Веб-интерфейс:** `https://<ip-сервера>:8092`
- [🎮 **Руководство пользователя QuakeLive-VPN (ql_vpn_user_guide.md)**](ql_vpn_user_guide.md) — установка, архитектура и детальная карта файлов на VPS

---

## 🚀 Быстрая установка

### 1. Автоматическая установка (в одну команду):

Подключитесь к роутеру (или VPS) по SSH и выполните:

```bash
# Установить Smart-Utils (Веб-панель, Терминалы, Файловый менеджер, OPKG):
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-utils

# Установить Smart-Route (Маршрутизация и обход блокировок):
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-route

# Установить Smart-Photo (Персональная фотогалерея на USB):
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-photo

# Установить Smart-VPN (WireGuard, AWG, Sing-box, QuakeLive-VPN на роутер):
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-vpn

# Установить QuakeLive-VPN Server (на Linux VPS / удаленный сервер):
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install-qlvpn.sh | bash
# или через универсальный установщик:
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s ql-vpn
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
opkg install smart-vpn
```

---

## 🔄 Обновление пакетов

```bash
opkg update && opkg upgrade smart-utils smart-route smart-photo smart-vpn
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


---

## 💬 Сообщество и обратная связь

- 📢 **Telegram-канал и обновления:** [t.me/KeeneticSmartUtils](https://t.me/KeeneticSmartUtils)
- 💬 **Тема обсуждения на форуме Keenetic:** [Приложения Smart-Utils, Smart-Route, Smart-Photo](https://forum.keenetic.ru/topic/30698-%D0%BF%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D1%8F-smart-utils-smart-route-smart-photo-snakelair-keenetic-entware-opkg-repository/)
- 💻 **Исходный код Smart-Utils:** [github.com/snakelair/SmartUtils](https://github.com/snakelair/SmartUtils)

