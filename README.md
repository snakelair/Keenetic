# ⚡ Keenetic Entware OPKG Repository

Официальный публичный репозиторий пакетов **OPKG** для роутеров **Keenetic** с установленной средой **Entware**.

---

## 📦 Доступные пакеты

- **`smart-route`** (v1.0.11) — системный сервис динамической многоинтерфейсной маршрутизации и отказоустойчивого релея с встроенной веб-панелью управления (:8088).

---

## 📖 Документация и Руководство пользователя

- [📘 Полное руководство пользователя и Архитектура со схемами (smart_route_user_guide.md)](smart_route_user_guide.md)
- [📗 User Guide / Краткое руководство (USER_GUIDE.md)](USER_GUIDE.md)

---

## 🚀 Быстрая установка на роутер Keenetic

### 1. Автоматическая установка (в одну команду):

Подключитесь к роутеру по SSH и выполните:

```bash
curl -sSL https://raw.githubusercontent.com/snakelair/Keenetic/main/install.sh | sh
```

---

### 2. Ручное подключение репозитория OPKG:

Создайте конфигурационный файл репозитория в `/opt/etc/opkg/smartroute.conf`:

```bash
# Определите архитектуру вашего роутера (например: mipsel-3.4, aarch64-3.10, armv7-3.2)
echo "src/gz smartroute https://raw.githubusercontent.com/snakelair/Keenetic/main/entware/$(uname -m | sed 's/mips/mipsel-3.4/' | sed 's/aarch64/aarch64-3.10/' | sed 's/armv7l/armv7-3.2/')" > /opt/etc/opkg/smartroute.conf

# Обновите список пакетов и установите
opkg update
opkg install smart-route
```

---

## 🔄 Обновление пакета

При выходе новых версий обновление выполняется стандартной командой OPKG:

```bash
opkg update && opkg upgrade smart-route
```

---

## 🌐 Соответствие моделей Keenetic и архитектур

| Архитектура | Модели роутеров Keenetic |
| :--- | :--- |
| **`mipsel-3.4`** | Viva, Extra, Speedster, Giga (KN-1010/1011), Omni, Skipper, Air, Buddy |
| **`armv7-3.2`** | Hero (KN-1011/KN-1012), Titan (KN-1810), Giant (KN-2610), Ultra (KN-1810) |
| **`aarch64-3.10`** | Peak (KN-2710), Ultra (KN-1811), Titan (KN-1812), Hero 4G+ (KN-2311) |
| **`x86_64`** | x86 Entware / Виртуальные машины |
