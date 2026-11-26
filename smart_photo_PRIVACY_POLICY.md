# Политика конфиденциальности Smart Photo (SmartPhotoSync) / Privacy Policy

**Дата вступления в силу / Effective date:** 2026-11-26  
**Приложение / Application:** Smart Photo (`com.smartphoto.sync`)  
**Разработчик / Developer:** SmartPhoto Project (`snakelair`)  

---

## 🇷🇺 Русская версия

### 1. Общие положения
**Smart Photo** — автономная галерея и клиент синхронизации с персональным фотосервером пользователя (SmartPhoto Server на базе Keenetic Entware, Linux или Windows). Приложение разработано по принципу **Offline-First** и уважает вашу приватность: разработчик не собирает, не хранит на своих серверах, не продаёт и не передаёт третьим лицам ваши фотографии, видеозаписи, персональные данные или аналитику.

### 2. Какие данные обрабатываются и где они хранятся
Все данные обрабатываются **локально на вашем устройстве** или передаются **напрямую на ваш собственный сервер SmartPhoto**, указанный вами в настройках:

- **Фотографии, видео и метаданные (EXIF/GPS)**:
  - Приложение запрашивает доступ к медиафайлам (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`, `ACCESS_MEDIA_LOCATION` или `READ_EXTERNAL_STORAGE` на старых версиях Android) исключительно для отображения локальной галереи, чтения EXIF-сведений (камера, объектив, параметры съёмки, геолокация) и синхронизации выбранных вами папок с вашим личным сервером.
  - Файлы передаются напрямую между вашим смартфоном и указанным вами сервером. Промежуточные серверы разработчика отсутствуют.
- **Локальный ИИ-поиск и распознавание лиц**:
  - Обнаружение лиц и векторный поиск (Google ML Kit Face Detection, ONNX Runtime / SCRFD / ArcFace / MobileCLIP) выполняются **полностью на устройстве**.
  - Создаваемые числовые векторы (эмбеддинги) хранятся в локальной базе данных приложения (Room) и не передаются разработчику.
  - Выгрузка ИИ-индексов на ваш личный сервер SmartPhoto происходит только при вашем явном согласии / действии в настройках.
- **Камера (`CAMERA`)**:
  - Используется исключительно для сканирования QR-кода при быстром сопряжении с вашим сервером SmartPhoto. Видеопоток камеры не записывается и никуда не отправляется.
- **Параметры подключения и учётные данные**:
  - URL сервера, `Sync Token`, имя устройства и правила синхронизации хранятся локально в `DataStore` и исключены из облачного автобэкапа Android (`allowBackup` с явным исключением баз и настроек в `backup_rules.xml` и `data_extraction_rules.xml`).
- **Облачный PIN-код сопряжения (опционально)**:
  - Если вы вручную выбираете вход по 6-значному Cloud PIN, приложение обращается к публичному брокеру сообщений `ntfy.sh` исключительно для получения временных параметров подключения, опубликованных вашим сервером. При использовании QR-кода или ручного URL брокер `ntfy.sh` не используется.

### 3. Реклама, трекеры и сторонние SDK
- В приложении **нет рекламы**, аналитических SDK (Google Analytics, Firebase Analytics, Crashlytics и т.п.) и рекламных идентификаторов.
- Встроенные библиотеки (Coil, Media3 ExoPlayer, Retrofit, Room, ZXing, ONNX Runtime, ML Kit) не используются разработчиком для отслеживания пользователей.

### 4. Удаление данных и контроль пользователя
- Вы в любой момент можете удалить локальные данные приложения через настройки Android («Очистить данные» или удаление приложения).
- При удалении медиафайлов в приложении всегда отображается явный диалог подтверждения с выбором области: «Только с устройства», «Только с сервера» или «Отовсюду».

### 5. Контакты
По вопросам конфиденциальности и работы приложения обращайтесь:
- GitHub Issues: https://github.com/snakelair/Keenetic/issues
- Email разработчика: `snakelair@yandex.ru`

---

## 🇬🇧 English Version

### 1. Overview
**Smart Photo** (`com.smartphoto.sync`) is an offline-first photo & video gallery and synchronization client for your personal self-hosted SmartPhoto server (Keenetic Entware, Linux, or Windows). The developer does **not** collect, store on developer-controlled servers, sell, or share your photos, videos, biometric data, or personal information with third parties.

### 2. Data Processed and Where It Is Stored
All processing happens **locally on your device** or directly between your device and **your own self-hosted server**:

- **Photos, Videos, and EXIF/GPS Metadata**:
  - Media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`, `ACCESS_MEDIA_LOCATION`, or `READ_EXTERNAL_STORAGE` on older Android versions) are used strictly to display your local gallery, inspect EXIF metadata (camera, lens, exposure, GPS coordinates), and back up user-selected folders to your personal server with SHA-256 integrity verification.
- **On-Device AI Face Clustering & Vector Search**:
  - Face detection, face clustering, and semantic vector search (Google ML Kit Face Detection, ONNX Runtime / SCRFD / ArcFace / MobileCLIP) run **100% locally on your device**.
  - Generated embeddings are stored in the app's local Room database and are never sent to the developer. Syncing AI indices to your personal server occurs only with your own server connection and action.
- **Camera (`CAMERA`)**:
  - Used exclusively to scan a QR code when pairing with your SmartPhoto server. No camera images or video are recorded or transmitted.
- **Credentials & Settings**:
  - Server URLs, Sync Tokens, device name, and sync preferences are stored locally in Android `DataStore` and explicitly excluded from Android cloud backup (`backup_rules.xml` and `data_extraction_rules.xml`).
- **Optional 6-Digit Cloud PIN Pairing**:
  - Only when you explicitly choose 6-digit Cloud PIN pairing, the app queries the `ntfy.sh` message broker to retrieve temporary pairing details published by your own server. QR code and manual URL pairing connect directly without any third-party broker.

### 3. Ads, Analytics, and Tracking
- Smart Photo contains **no ads**, **no analytics**, and **no tracking SDKs**.

### 4. Data Retention & Deletion
- You maintain full control over your media and settings. Uninstalling the app or clearing app storage removes all local databases, AI indices, and tokens from your device.
- Media deletion always requires explicit user confirmation (Device only, Server only, or Everywhere).

### 5. Contact
- GitHub Issues: https://github.com/snakelair/Keenetic/issues
- Developer Email: `snakelair@yandex.ru`
