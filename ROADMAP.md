# Роадмап: видео на экране CarPlay

Целевая юзер-стори: пользователь подключается к CarPlay своей машины и
либо (а) видит на экране машины зеркало своего телефона, либо (б) отдаёт
машине конкретный видео-поток. Ниже — факты платформы, которые определяют
форму этого роадмапа, и сами фазы.

## Факты платформы (проверено на сентябрь 2026, iOS 26/27)

1. **Полного зеркалирования произвольного UI приложения на CarPlay не
   существует.** CarPlay — не универсальный внешний дисплей. Почти весь UI
   рендерится системными шаблонами (`CPListTemplate`, `CPGridTemplate`,
   `CPNowPlayingTemplate` и т.д.), и **`WKWebView` в CarPlay не встраивается
   вообще** — то есть встроенный браузер на машинный экран попасть не
   может даже теоретически.

2. **Видео на CarPlay — отдельная, недавняя категория (`Video`, iOS 26+).**
   Позиционируется Apple как «browse and watch their favorite content»
   (каталог конкретного контента), не как generic screen mirroring.
   Ограничения одинаковы для всех приложений категории и не обходятся:
   - работает **только на парковке** (следит сама ОС по данным скорости
     из головного устройства, отключается для всех, не только водителя);
   - требует **entitlement от Apple** (запрос:
     <https://developer.apple.com/contact/carplay/>) — по use-case,
     заявку могут не одобрить;
   - требует **поддержки со стороны самой машины/магнитолы**
     («video in car» — не все головные устройства это умеют).

3. **AirPlay-путь работает уже сегодня, без всякого entitlement.** Если
   играть видео через `AVPlayer` и выбрать машину в AirPlay-пикере — при
   поддержке video-in-car машина покажет именно этот видеопоток. Это
   именно «поток», не «экран», и в проекте уже подключено:
   [Sources/Player/PlayerScreen.swift](Sources/Player/PlayerScreen.swift)
   через `AVRoutePickerView`.

4. **Связка сцены `CPTemplateApplicationSceneSessionRoleApplication` +
   `CPTemplateApplicationSceneDelegate`** — единственный подтверждённый
   способ подключиться к CarPlay вообще (в т.ч. Video). Предыдущая версия
   кода использовала несуществующую роль `UIWindowSceneSessionRoleCarPlay`
   и `UIWindowSceneDelegate` — такая сцена не подключилась бы, даже получив
   entitlement. Исправлено в
   [Sources/CarPlay/CarPlaySceneDelegate.swift](Sources/CarPlay/CarPlaySceneDelegate.swift).

5. **Video-сёрфейс (куда рисовать сам видеокадр/AVPlayerLayer) —
   технически ещё не подтверждён из первоисточника.** Есть косвенные
   свидетельства, что после `didConnect` видео-категории приложение
   получает доп. окно/поверхность поверх шаблонов, но точный API не
   вычитан из официального CarPlay Developer Guide (PDF слишком большой
   для автоматической выгрузки). **Не писать код под угаданный API** —
   сверяться с
   <https://developer.apple.com/download/files/CarPlay-Developer-Guide.pdf>
   и WWDC25 сессией 216 при реализации Фазы 3.

6. **CarPlay Simulator сейчас физически сломан в Xcode 27 (DeviceHub) на
   публичных сборках macOS — это баг Apple, не наша ошибка.** DeviceHub
   (замена Simulator.app) содержит CarPlay-плагин, но он гейтится
   internal-only entitlements (`com.apple.internal.carplay.iap` и т.д.),
   которых нет на публичных машинах — пункт CarPlay не появляется в UI
   вообще, не серый, не задизейбленный, а просто отсутствует. Заведённый
   баг: <https://github.com/feedback-assistant/reports/issues/842>
   (FB24785359), без ответа Apple на момент проверки (сентябрь 2026).
   Старый отдельный `CarPlay Simulator.app` (из "Additional Tools for
   Xcode") тоже не спасает — он работает только с реальным iPhone по USB,
   с симулятором не связывается. **Вывод: проверить реальное подключение
   `CPTemplateApplicationSceneDelegate` сейчас можно только на настоящем
   iPhone** — либо через `CarPlay Simulator.app` + iPhone по USB (эмулирует
   машину), либо сразу в реальной машине/магнитоле с CarPlay. Смысла биться
   в DeviceHub дальше нет, ждём фикса от Apple или делаем на реальном
   устройстве.

## Фаза 0 — проверить AirPlay-путь на реальном железе (сделать первым)

Собрать текущий билд, включить видео в `PlayerScreen`, нажать AirPlay-кнопку
рядом с машиной, поддерживающей video-in-car (или хотя бы Apple TV — чтобы
подтвердить, что маршрутизация в принципе работает). Статус: **не сделано**,
нужно железо/машина — это на стороне пользователя, агент проверить не может.

## Фаза 1 — довести AirPlay-путь до продакшна (не требует Apple)

- [x] Проверено, что `AVRoutePickerView` уже настроен с
      `prioritizesVideoDevices = true`.
- [ ] Обработка `AVAudioSession.routeChangeNotification` — авто-пауза/резюм
      при подключении/отключении маршрута, статус «на экране авто» в UI.
- [ ] `UIBackgroundModes: audio` в
      [Sources/Resources/Info.plist](Sources/Resources/Info.plist) — сейчас
      отсутствует, нужен для стабильного AirPlay-видео при сворачивании.
- [ ] Прогон на нескольких головных устройствах (потолок вне контроля кода).

## Фаза 2 — базовое подключение к CarPlay (шаблоны, без видео)

- [x] Исправлена роль сцены и делегат
      ([Sources/CarPlay/CarPlaySceneDelegate.swift](Sources/CarPlay/CarPlaySceneDelegate.swift)).
- [x] `AppEnvironment` — общая точка доступа к `LibraryStore` для SwiftUI и
      CarPlay-сцены ([Sources/App/AppEnvironment.swift](Sources/App/AppEnvironment.swift)).
- [x] **Собрано реально в Xcode 27 (`xcodegen generate` + `xcodebuild`, оба
      таргета, симулятор).** Попутно нашлись и починены два независимых
      бага:
      - в исходном `Info.plist` отсутствовал `CFBundleExecutable` — из-за
        этого сборка вообще не устанавливалась на симулятор/устройство
        (`missing or invalid CFBundleExecutable`), никак не связано с
        CarPlay, баг с первого прототипа;
      - в `BroadcastExtension/SampleHandler.swift` использовался
        несуществующий `CIImageRepresentationOption.lossyCompressionQuality`
        — не компилировалось. Поправлено на ключ ImageIO
        `kCGImageDestinationLossyCompressionQuality`.
      После фиксов оба таргета (`DriveView`, `DriveViewBroadcastExtension`)
      собираются и устанавливаются на симулятор без ошибок.
- [x] Временно смёрджил `CarPlayScene.fragment.plist` в `Info.plist`,
      собрал и установил — приложение с этой конфигурацией устанавливается
      и запускается нормально. Затем откатил обратно до фрагмента (как и
      задумано — не декларировать CarPlay-роль в сборке до реального
      entitlement).
- [ ] **Не проверено: реальное подключение к CarPlay Simulator (I/O →
      External Displays → CarPlay в Simulator.app) и вызов
      `templateApplicationScene(_:didConnect:)`.** Среда сборки — headless
      macOS без доступа к оконному серверу (нет GUI, `osascript`/System
      Events не видит процесс Simulator). Это последний шаг, который может
      сделать только тот, у кого есть реальный Xcode с экраном: смёрджить
      `CarPlayScene.fragment.plist` в `Info.plist` (как я делал временно),
      собрать на симулятор, открыть CarPlay-дисплей и убедиться, что
      появляется список DriveView.

## Фаза 3 — реальное видео на экране CarPlay (нужен entitlement)

- [ ] Подать заявку на entitlement (Video, можно вместе с Audio) —
      бизнес-шаг пользователя, не блокирует инженерку.
- [ ] Найти в CarPlay Developer Guide / WWDC25 216 точный API получения
      видео-поверхности внутри `CPTemplateApplicationSceneDelegate`.
- [ ] Подключить туда `AVPlayer` (переиспользовать логику из
      [Sources/Player/PlayerScreen.swift](Sources/Player/PlayerScreen.swift)).
- [ ] Обработать состояние парковки (пауза при движении).

## Фаза 4 — зеркалирование экрана (ReplayKit) как отдельный источник

Пайплайн уже есть и технически сделан аккуратно:
[BroadcastExtension/SampleHandler.swift](BroadcastExtension/SampleHandler.swift),
[Shared/MirrorShared.swift](Shared/MirrorShared.swift),
[Sources/Mirror/](Sources/Mirror) — захват экрана, JPEG, App Group,
превью в приложении. Работает независимо от CarPlay уже сегодня.

- [ ] H.264/VideoToolbox вместо JPEG-кадров.
- [ ] Системный звук + A/V sync.
- [ ] Адаптивный битрейт.
- [ ] Подключить как источник к CarPlay-видео-сёрфейсу из Фазы 3, когда тот
      появится — единственная точка интеграции: `CarPlaySceneDelegate`
      берёт кадр из `MirrorFrameStore` вместо/вместе с `AVPlayer`.
- [ ] **Отдельный риск, не инженерный**: категория Video описана Apple как
      «browse and watch content», не как generic screen mirroring. Заявку
      на entitlement стоит формулировать вокруг конкретного видео-контента
      (Фаза 3), а зеркалирование экрана — как fallback для источников без
      прямого медиапотока, а не как основной питч.

## Фаза 5 — источник контента и продакшн

- [ ] Решить: скрейпер любых сайтов (юридический риск, сложнее с ревью)
      vs явный ввод собственного потока (своя камера/регистратор/сервер) —
      как флагманский сценарий для CarPlay.
- [ ] Тесты, CI, закоммиченный `.xcodeproj` или CI на `xcodegen generate`.
- [ ] Решение по дистрибуции (App Store вряд ли легко пропустит генерик-
      скрейпер чужих потоков — рассмотреть TestFlight/ad-hoc).

## Источники

- <https://developer.apple.com/carplay/>
- <https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements>
- <https://developer.apple.com/documentation/carplay/cptemplateapplicationscenedelegate>
- <https://mergescreens.com/blogs/apple-carplay/carplay-video-ios-26>
- <https://www.createwithswift.com/creating-carplay-apps-within-a-swiftui-app-lifecyle/>
