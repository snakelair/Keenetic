# 📷 Smart-Photo for Keenetic Entware

[![Build & Publish OPKG Packages](https://github.com/snakelair/SmartPhoto/actions/workflows/deploy-packages.yml/badge.svg)](https://github.com/snakelair/SmartPhoto/actions)
[![Release](https://img.shields.io/badge/release-v1.0.27-blue.svg)](https://github.com/snakelair/SmartPhoto/releases)
[![Keenetic Entware](https://img.shields.io/badge/Keenetic-Entware-38d39f.svg)](https://github.com/snakelair/Keenetic)

**Smart-Photo** — это легковесный, быстрый персональный фотосервер в стиле **Google Photos**, созданный специально для роутеров **Keenetic** с USB-портом и средой **Entware** (а также для Linux и Windows).

Сервис автоматически индексирует фотографии с подключенного USB-накопителя (флешки, внешнего жесткого диска или SSD), формирует бесконечную фотоленту по датам, налету генерирует и кэширует миниатюры, извлекает подробные EXIF-данные и предоставляет современный веб-интерфейс в тёмной теме (Glassmorphism).

---

## 🌟 Основные возможности

- 📸 **Google Photos-стиль фотоленты**:
  - Бесконечная плавная прокрутка (Infinite Scroll) с подгрузкой на лету без зависания браузера.
  - Липкие заголовки с группировкой по дням ("Сегодня", "Вчера", "28 августа 2026").
  - Адаптивная сетка фотокарточек с ленивой загрузкой миниатюр.
- 🔍 **Полноэкранный просмотрщик (Lightbox)**:
  - Плавное масштабирование (зум колёсиком мыши или кнопками) и панорамирование.
  - Поворот снимка на 90° в один клик.
  - Режим автоматического слайд-шоу с таймером.
  - Подробная панель **EXIF-информации**: камера, объектив, выдержка, диафрагма, ISO, фокусное расстояние и прямая ссылка на карту OpenStreetMap при наличии GPS-координат.
  - Полное управление с клавиатуры (стрелки, пробел, Esc, I, +, -) и поддержка свайпов на смартфонах и планшетах.
- ⚡ **Умное кэширование и генерация миниатюр**:
  - Быстрый алгоритм ресайза на чистом Go без CGO (`CGO_ENABLED=0`).
  - Размещение кэша на выбор: прямо на USB-накопителе в `.smartphoto/thumbs` или в системной папке `/opt/var/cache/smart-photo`.
  - Двухуровневый кэш (быстрая RAM LRU память + диск).
- 🛡️ **Бережное отношение к ресурсам роутера**:
  - Настраиваемое ограничение фоновых потоков (по умолчанию 2 потока) предотвращает перегрев и проседание скорости интернета на Keenetic.
  - Хранение журнала событий в оперативной памяти (RAM кольцевой буфер) — нулевой износ flash-памяти роутера.
- 📁 **Альбомы, папки и избранное**:
  - Навигация по оригинальной структуре папок на флешке.
  - Отметка любимых фото звёздочкой в отдельный раздел «Избранное».
  - Поиск по имени файла, папке, модели камеры и годам.
- 🩺 **Встроенная диагностика и управление**:
  - Просмотр занятого места на диске и размера кэша.
  - Автоопределение подключенных USB-устройств (`/tmp/mnt/...`).

---

## 🚀 Быстрая установка на роутер Keenetic

### 1. Автоматическая установка через OPKG (в 1 команду):

Подключитесь к роутеру по SSH и выполните:

```bash
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh -s smart-photo
```

После завершения установки веб-интерфейс будет доступен по адресу:
👉 **`http://192.168.1.1:8089`** (или IP вашего роутера).

---

### 2. Ручное подключение через репозиторий OPKG:

```bash
# 1. Добавьте репозиторий snakelair/Keenetic в Entware:
ARCH=$(uname -m | sed 's/mips/mipsel-3.4/' | sed 's/aarch64/aarch64-3.10/' | sed 's/armv7l/armv7-3.2/')
echo "src/gz keenetic-custom https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/${ARCH}" > /opt/etc/opkg/keenetic.conf

# 2. Обновите список пакетов и установите:
opkg update
opkg install smart-photo
```

---

## 🌐 Совместимость с моделями Keenetic

| Архитектура | Поддерживаемые модели роутеров |
| :--- | :--- |
| **`mipsel-3.4`** | Keenetic Viva, Extra, Speedster, Giga (KN-1010/1011), Omni, Skipper, Air, Buddy |
| **`armv7-3.2`** | Keenetic Hero (KN-1011/KN-1012), Titan (KN-1810), Giant (KN-2610), Ultra (KN-1810) |
| **`aarch64-3.10`** | Keenetic Peak (KN-2710), Ultra (KN-1811), Titan (KN-1812), Hero 4G+ (KN-2311) |
| **`x86_64`** | Виртуальные машины Keenetic / Entware x86 |

---

## 🛠️ Сборка и разработка

Smart-Photo написан на Go и содержит готовые Windows-скрипты:

- `run.bat` — быстрый запуск на Windows (веб-панель на `http://localhost:8089`).
- `build.bat` — интерактивное меню компиляции для всех архитектур.
- `build_all.bat` — сборка всех бинарников в папку `dist/`.
- `deploy_to_router.bat` — сборка и заливка на роутер в 1 клик по SSH.
- `push_keenetic_repo.bat` — сборка пакетов `.ipk`, обновление репозитория `snakelair/Keenetic` и автоматический push.
- `git_menu.bat` / `git_push.bat` — управление Git репозиторием `snakelair/SmartPhoto`.

---

## 📜 Лицензия

MIT License © 2026 snakelair
