# Changelog

All notable changes to the SmartRoute project will be documented in this file.

## [1.0.159] - 2026-09-20 - Автоматическое исправление кодировки CP1251 (Mojibake) и отображение названий политик в карточках блокировок
- **Автоматическое исправление кракозябр кодировки (Mojibake Recovery)**:
  - Реализован модуль автоматического восстановления кодировки `FixMojibake` на базе стандартной библиотеки Go (`internal/config/mojibake.go`) и в Web UI (`app.js`).
  - Устранено искажение русских названий (например, «Р”РµС‚Рё» автоматически преобразуется обратно в «Дети», «[/СЂС„/]» в «[/рф/]», поврежденные названия DNS-фильтров возвращаются в исходный вид).
  - Модуль автоматически проверяет и восстанавливает кодировку при чтении и сохранении конфигурации `config.json`, в профилях блокировок, списках доменов, апстримах и фильтрах DNS.
  - В HTTP-заголовки ответов API добавлен обязательный параметр `Content-Type: application/json; charset=utf-8`.
- **Отображение названий политик в карточках блокировки**:
  - В заголовок карточки набора правил блокировки добавлен аккуратный бейдж с реальным названием политики KeeneticOS (например, «Политика: Дети»).
  - В модальном окне редактирования набора имя и описание автоматически очищаются от поврежденных символов кодировки.

## [1.0.158] - 2026-09-20 - Исправление вёрстки карточек метрик на главном дашборде
- **Восстановление сетки дашборда (`index.html`)**:
  - Закрыт тег `div.metric-card` для блока «Аптайм и Память», предотвращая ошибочное вложение карточки «L4 Conntrack Watcher».
  - Восстановлена корректная 5-колоночная сетка метрик (`.metrics-grid`) и правильное размещение блоков «Быстрый тест маршрута (Probe)» и «Последние добавленные маршруты» на всю ширину страницы.

## [1.0.157] - 2026-09-20 - Полное удаление функционала обхода блокировок ТСПУ на WAN (Zapret / ByeDPI Desync)
- **Полная ликвидация компонентов обхода ТСПУ/DPI на WAN**:
  - Удалены файлы движка активного вмешательства: `internal/engine/desync.go`, `internal/engine/desync_linux.go`, `internal/engine/desync_test.go`, `internal/engine/nfqueue_linux.go`, `internal/engine/nfqueue_other.go`.
  - Из `internal/engine/proxy.go` удалены `DesyncManager`, `NFQueueInterceptor`, вызовы `tryDesync`, Fast-Path десинхронизации и функции `isYouTubeTarget()`, `isKnownDPITarget()`.
  - Устранена блокировка UDP/QUIC 443 из правил iptables (`applyQUICBlockRules`) и менеджера маршрутизации.
- **Очистка конфигурации и REST API**:
  - Из `internal/config/config.go` удалены параметры `DPIBypassEnabled`, `DPIStrategy`, `DPIFakeTTL`, `DPIBlockQUIC`, `DPIBypassMethods`, `DPIBypassDelayMs`.
  - Удалены эндпоинты `/api/desync`, `/api/desync/clear`, `/api/diagnostics/dpi-test` из `internal/api/router.go`, `handler_routes.go`, `handler_diagnostics.go`, `handler_service.go`.
- **Очистка встроенного веб-интерфейса (Web UI)**:
  - Из `index.html` удалены карточка метрик WAN Desync, кнопка переключения таблицы сессий, блок настроек обхода блокировок ТСПУ и модальное окно тестирования DPI.
  - Из `app.js` и `style.css` вырезаны все обработчики, селекторы стратегий, методы диагностики и CSS-стили карточек обхода.
- **Унифицированный прозрачный Failover**:
  - Все соединения (включая YouTube) следуют единому правилу: при сбое на WAN (TCP RST, таймаут, заглушка провайдера) соединение бесшовно спасается и направляется в резервный VPN-интерфейс.

## [1.0.156] - 2026-09-20 - Оптимизация структуры проекта и модульная архитектура
- **Единый источник правды версий (Single Source of Truth)**:
  - Создан корневой файл `VERSION` с номером версии.
  - Скрипты сборки (`build.bat`, `build_all.bat`, `build.ps1`, `package/entware/build_ipk.sh`) переведены на автоматическое считывание версии из файла `VERSION`.
  - Устранена необходимость ручной синхронизации версии в скриптах при релизах.
- **Архивация истории релизов (Changelog Archiving)**:
  - Архивные версии v1.0.0 — v1.0.145 вынесены в `CHANGELOG_ARCHIVE.md`, размер активного `CHANGELOG.md` снижен на 96% (с 277 КБ до ~10 КБ).
  - Уменьшен размер встроенного веб-бандла и потребление памяти.
- **Очистка репозитория**:
  - Удален устаревший файл-дубликат `smart_route_user_guide.md`.
  - Настроены правила игнорирования служебных файлов, временных логов и бинарников (`.aiignore`, `.cursorignore`).
- **Модуляризация REST API**:
  - Монолитный файл `internal/api/handler.go` (88 КБ, 2820 строк) разделен на логические модули: `handler_service.go`, `handler_routes.go`, `handler_interfaces.go`, `handler_dns.go`, `handler_update.go`.
- **Оптимизация проектной документации**:
  - Актуализированы регламенты разработки и оптимизирован сборочный процесс.

## [1.0.155] - 2026-09-19 - Защита Anycast IP от VPN-перехвата и восстановление YouTube RU на WAN
- **Изоляция разделяемых Anycast IP Google (`IsSharedAnycastIP`)**:
  - Диапазоны Google Anycast (`142.250.0.0/15`, `172.217.0.0/16`, `172.253.0.0/16`, `173.194.0.0/16`, `74.125.0.0/16`, `209.85.128.0/17`, `216.58.192.0/19`, `216.239.32.0/19`, `64.233.160.0/19`, `108.177.0.0/17`, `66.102.0.0/20`, `66.249.64.0/19`, `72.14.192.0/18`) полностью исключены из добавления в аппаратные таблицы маршрутизации (`table 4096`, `ndm.AddRoute`, `BatchAddRoutes`, `CommitWarmUpBatch`) и ipset VPN (`sr_<vpn>`).
  - Устранена первопричина переключения региона YouTube на DE и зависания видео (HTTP 403 Forbidden): Anycast IP больше не перехватываются ядром на уровне L3 в немецкий туннель WireGuard (`nwg0`), а динамически распределяются демоном по реальному SNI (L7).
  - Сервисы AI (Gemini, Antigravity) маршрутизируются в VPN по SNI (`generativelanguage.googleapis.com`, `antigravity-pa.googleapis.com`), тогда как YouTube и Google Video одновременно обслуживаются на WAN с Desync без конфликтов.
- **Строгая фиксация YouTube на WAN (`isYouTubeTarget`)**:
  - В `rescueConnection` и `triggerDynamicFailoverRoute` полностью заблокирован аварийный перевод доменов YouTube (`youtube.com`, `*.googlevideo.com`, `ytimg.com`, `ggpht.com`, `youtu.be`) в VPN-интерфейсы. YouTube всегда обслуживается на прямом канале WAN с сохранением локального региона RU и российских кэширующих серверов GGC.
- **Очистка заблокированных маршрутов (`CleanAnycastRoutes`)**:
  - При старте службы реализована автоматическая очистка ранее сохраненных Anycast-маршрутов из конфигурации Keenetic (`no ip route ...`) и ipset `sr_<iface>`.
- **Оптимизация Desync на WAN**:
  - Таймаут проверки Desync в `tryDesync` увеличен до 2500 мс с автоматическим фоллбэком на альтернативный метод при задержках или сбросах CDN.
- **Унификация failover для YouTube**:
  - Убрана вся YouTube-специфичная защита из `rescueConnection` и `triggerDynamicFailoverRoute`. YouTube следует стандартному flow: WAN fail → VPN, как любой другой сервис. Десинк (если включён) работает как для всех known DPI targets.
  - Защита `IsSharedAnycastIP` (запрет добавления Google Anycast IP в ipset/NDM) сохранена — это архитектурный fix, предотвращающий массовый перехват всего Google-трафика на L3.

## [1.0.154] - 2026-09-19 - Автоматический подбор эффективного TTL (Auto-Sweep) для Варианта В в диагностике
- **Автоматический параллельный перебор и подбор эффективного TTL для Варианта В** (`internal/engine/desync.go`):
  - В диагностический модуль `TestDPIMethods` добавлен интеллектуальный Auto-Sweep: при сбое базового TTL сервис автоматически выполняет параллельный опрос диапазона альтернативных хопов (1..8) с быстрым таймаутом.
  - Найдена причина таймаута при фиксированном `TTL=4`: пакет застревал на границе оператора (Drop/Stall), тогда как при `TTL=3` успешно достигается десинхронизация ТСПУ (RTT ~60 мс) с получением `ServerHello`.
  - При обнаружении рабочего значения TTL метод автоматически маркируется как `Вариант В: L3 Raw Fake-TTL (Подобран TTL=X)`, а параметр `optimal_fake_ttl` передается в веб-интерфейс для сохранения в конфигурацию роутера одним кликом.
  - Безопасный дефолтный хоп в `internal/engine/proxy.go` скорректирован на 3.

## [1.0.153] - 2026-09-19 - Интеграция OOB-защиты в Вариант В и исправление привязки default-интерфейса
- **Интеграция Out-Of-Band защиты в Вариант В** (`internal/engine/desync.go`, `internal/engine/proxy.go`):
  - Стратегия Fake-TTL дополнена механизмом `SendDesyncMultiSplitWithOOB`: фейковый пакет с точными `seq`/`ack` теперь подкрепляется микро-сплитом и OOB-байтом, предотвращая склеивание реальных сегментов ТСПУ.
  - В тесте диагностики `TestDPIMethods` для Варианта В включена OOB-десинхронизация.
- **Исправление привязки сырых сокетов к псевдо-интерфейсу default** (`internal/engine/desync_linux.go`, `internal/engine/desync.go`):
  - Исключена передача строки `"default"` в системный вызов `SO_BINDTODEVICE` и команду `traceroute -i`, вызывавшая ошибку `ENODEV` (No such device) при выполнении системных проверок.

## [1.0.152] - 2026-09-19 - Точная синхронизация SEQ/ACK через TCP_REPAIR для Варианта В и диагностика YouTube
- **Точная синхронизация TCP SEQ и ACK через TCP_REPAIR для Fake-TTL (Вариант В, выключен по умолчанию)** (`internal/engine/desync_linux.go`, `internal/engine/proxy.go`):
  - Реализовано мгновенное извлечение реальных номеров последовательности `seq` и подтверждения `ack` из сокета ядра Linux через `TCP_REPAIR` (`TCP_REPAIR_QUEUE`, `TCP_QUEUE_SEQ`) без накладных расходов.
  - Устранена проблема отправки фейковых пакетов с фиктивным SEQ (1000), приводящая к отбрасыванию пакетов ТСПУ.
  - По умолчанию сохранена активная стратегия **Вариант Б (L7 Multi-Split + OOB)**.
- **Диагностика воспроизведения YouTube и изоляция сбоев ТСПУ**:
  - Выявлено, что ТСПУ на магистралях РФ применяет глубокую сборку TCP-сегментов (TCP reassembly) к доменам CDN YouTube (`googlevideo.com`), блокируя любые пользовательские микро-сплиты.
  - Устранено зависание и падение соединений из-за рассогласования региональных токенов CDN (RU на веб-странице vs DE при перехвате в VPN).

## [1.0.151] - 2026-09-19 - Защита Anycast-подсетей Google от супернет-агрегации и изоляция YouTube на WAN
- **Изоляция Anycast-подсетей Google от супернет-агрегации** (`internal/routing/manager.go`):
  - Добавлена функция `isSharedAnycastIP` для исключения разделяемых подсетей Google (`142.250.0.0/15`, `172.217.0.0/16` и др.) из автоматической агрегации в суперсети `/21`, `/22`, `/23` и `/24`.
  - Предотвращен захват адресов YouTube (`142.251.150.4` - `142.251.157.4`) макро-маршрутами при разрешении доменов Google AI (Gemini, DeepMind), гарантируя строгое разделение: YouTube идет через прямой WAN (RU) с Desync, а Gemini маршрутизируется в VPN по точечным `/32` адресам.

## [1.0.150] - 2026-09-19 - Расширение пресета AI Services (Gemini, DeepMind, Antigravity)
- **Интеграция Gemini, DeepMind и Antigravity в системный пресет AI Services** (`internal/config/config.go`, `internal/engine/domain_resolver.go`):
  - В базовый список `AI Services (ChatGPT, Claude, Gemini, Antigravity)` добавлены официальные домены и API-эндпоинты экосистемы Google AI: `gemini.google.com`, `gemini.google`, `aistudio.google.com`, `ai.studio`, `ai.google.dev`, `generativelanguage.googleapis.com`, `deepmind.com`, `deepmind.google`, `notebooklm.google`, `jules.google`, `labs.google`, `alkalicore-pa.clients6.google.com`, `alkalimakersuite-pa.clients6.google.com` и др.
  - Включены все сервисы разработки Google Antigravity: `antigravity-pa.googleapis.com`, `antigravity.googleapis.com`, `antigravity.google`, `antigravity-unleash.goog`, `gemini-api-docs-mcp.dev` и подсеть `216.239.32.0/24`.
  - В `domain_resolver.go` добавлен авто-дискавери критических сопутствующих поддоменов для запросов к Gemini, DeepMind и Antigravity.

## [1.0.149] - 2026-09-19 - Полноценный L3/L4 NFQUEUE Fake-TTL инжектор и оптимизация YouTube Fast-Path
- **Полноценный L3/L4 NFQUEUE Fake-TTL инжектор (Вариант В, выключен по умолчанию)** (`internal/engine/nfqueue_linux.go`):
  - Реализован чистый Go-драйвер Netfilter Queue поверх Netlink (`syscall.AF_NETLINK`, subsystem `NFNL_SUBSYS_QUEUE`) без внешних CGO/libnetfilter_queue зависимостей.
  - Перехват исходящих пакетов ClientHello с флагом `NF_ACCEPT`, чтение реальных 32-битных TCP `seq` и `ack` из сессии ядра и генерация Fake-TTL TCP-пакетов с точными номерами последовательности.
  - По умолчанию активен **Вариант Б (L7 Multi-Split + OOB)**.
- **Оптимизация обхода блокировок и ускорение YouTube** (`internal/dns/`, `internal/engine/proxy.go`):
  - **DNS Filter AAAA**: автоматическая фильтрация AAAA-записей (IPv6) для исключения зависаний браузеров на таймаутах Happy Eyeballs при отсутствии глобального IPv6 у провайдера.
  - **Desync Fast-Path для известных DPI-целей**: мгновенная активация десинхронизации (0 мс ожидания) для `youtube.com`, `googlevideo.com`, `discord.com`, `instagram.com` и др., минуя холостой таймаут прямого WAN.
  - **Адаптивный таймаут Desync**: увеличен таймаут проверки ответа до 1500 мс и сокращен период отрицательного кэширования сбойных хостов до 5 минут с автоматическим пробитием кэша для известных DPI-сервисов.

## [1.0.148] - 2026-09-19 - Мультистратегия обхода ТСПУ на WAN и диагностический инструментарий
- **3 стратегии обхода WAN DPI (Desync)** (`internal/config/config.go`, `internal/engine/`):
  - **Вариант А (Классический)**: сплит ClientHello по границе TLS-записи (`tlsrec`) и фрагментация SNI.
  - **Вариант Б (Продвинутый L7 Multi-Split + OOB, по умолчанию)**: микро-сплит TLS-хендшейка на 4 сегмента (1 байт `0x16` + 4 байта заголовка + середина SNI + остаток payload) с инъекцией Out-Of-Band (`MSG_OOB`) байта для рассинхронизации автоматов ТСПУ.
  - **Вариант В (L3/L4 Raw Packet Injection + Fake-TTL)**: отправка поддельного пакета с заниженным TTL (автоопределение расстояния до ТСПУ через Traceroute/Auto-TTL) для отравления стейта цензора.
- **Блокировка QUIC / HTTP3** (`internal/routing/iptables.go`, `internal/routing/manager.go`):
  - Автоматическая блокировка UDP 443 (`REJECT --reject-with icmp-port-unreachable`) в цепочках `FORWARD` и `OUTPUT` для принудительного отката браузеров на TCP (где работает Desync).
- **Интерактивная диагностика ТСПУ и эффективности обхода** (`internal/engine/desync.go`, `internal/api/`, Web UI):
  - Определение присутствия ТСПУ (сброс TCP RST vs тайм-аут/молчаливый дроп).
  - Автоматическое определение хопа ТСПУ (Auto-TTL hop distance).
  - Параллельное тестирование Direct WAN, Classic, Variant B, Variant C с замером времени ответа и вердиктом достаточной стратегии.
  - Модальное окно диагностики и быстрое применение рекомендованной стратегии в 1 клик.

## [1.0.147] - 2026-09-19 - Бесшовный Zero-Downtime рестарт службы и защита от DNS Sinkhole
- **Бесшовный перезапуск службы без сброса маршрутов (Zero-Downtime Restart)** (`internal/routing/manager.go`):
  - В методе `Stop()` исключено полное удаление статических маршрутов из Keenetic NDM (`FlushAllSRRoutes`), что устраняет 30-секундный блэкаут при перезапуске демона или обновлении бинарника.
  - На старте (`Start()`) добавлена мгновенная предварительная загрузка подсетей списков (CIDR Deepmind, Telegram и др.) и уже имеющихся маршрутов Keenetic в `ipset sr_<iface>` до включения правил перехвата `iptables REDIRECT`.
  - Трафик к активным сервисам продолжает идти по аппаратным маршрутам через VPN с нулевой секунды старта без попадания в очередь прокси.
- **Декларативная синхронизация маршрутов Keenetic NDM** (`internal/routing/keenetic_ndm.go`):
  - Метод `BatchAddRoutes` переведен на дифференциальную сверку (reconciliation): существующие корректные маршруты больше не удаляются перед компиляцией, добавляются только новые и удаляются только устаревшие.
- **Защита от некорректных адресов и DNS Sinkhole (0.0.0.0)** (`internal/routing/manager.go`, `internal/engine/domain_resolver.go`):
  - Добавлена строгая фильтрация адресов `isBogusIP`: заблокировано попадание `0.0.0.0`, `127.0.0.1`, loopback и multicast в маршруты ядра и таблицы NDM.
  - Добавлена автоматическая очистка некорректных маршрутов `0.0.0.0` из Keenetic NDM при старте (`CleanBogusRoutes`).

## [1.0.146] - 2026-09-19 - Устранение утечки WAN при прогреве NDM и расширение СМИ
- **Устранение утечки WAN при перезапуске роутера / сервиса** (`internal/routing/manager.go`):
  - Исправлена рассинхронизация между Netfilter `ipset` и таблицей Keenetic NDM: добавление адресов в `sr_<iface>` отложено до момента фактической компиляции и инъекции маршрутов в ядро Keenetic (`CommitWarmUpBatch`).
  - Во время прогрева списков после старта трафик к доменам списков (Deepmind, AI и др.) гарантированно перехватывается прозрачным прокси и направляется в VPN через `rescueConnection`, исключая утечку на российский WAN и ошибку Geo-IP.
- **Расширение списка «СМИ и Новости»** (`internal/config/config.go`, `internal/engine/domain_resolver.go`):
  - Добавлены CDN-поддомены BBC: `ichef.bbci.co.uk`, `nav.files.bbci.co.uk`, `sounds.files.bbci.co.uk`.
  - Добавлены активные зеркала: `theins.info`, `meduzapro.io`, `dw.de`, `learngerman.dw.com`, `svobodanews.com`, `rferl.org`.

---

> Более ранняя история изменений вынесена в [CHANGELOG_ARCHIVE.md](./CHANGELOG_ARCHIVE.md) (версии v1.0.0 — v1.0.145).
