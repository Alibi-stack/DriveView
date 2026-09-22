import CarPlay

/// Точка входа CarPlay.
///
/// Важно: CarPlay-сцены подключаются через роль
/// `CPTemplateApplicationSceneSessionRoleApplication` и делегат, конформящий
/// `CPTemplateApplicationSceneDelegate` — а не через произвольную
/// `UIWindowSceneDelegate` и самодельную роль вроде
/// `UIWindowSceneSessionRoleCarPlay` (такой роли не существует в CarPlay
/// framework; предыдущая версия этого файла не подключилась бы вообще, даже
/// после выдачи entitlement). Подробности и источники — в ROADMAP.md.
///
/// Экран CarPlay не может отрендерить произвольный `UIView`/`WKWebView` —
/// только системные шаблоны (`CPListTemplate`, `CPGridTemplate` и т.д.).
/// Здесь строится минимальный список из библиотеки как первый проверяемый
/// шаг: подключение к CarPlay Simulator и показ списка — без входа в тему
/// видео-поверхности, для которой пока не подтверждён точный API (см.
/// TODO ниже и ROADMAP.md, раздел «Video-сёрфейс»).
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var refreshTimer: Timer?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        render()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.render() }
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        refreshTimer?.invalidate()
        refreshTimer = nil
        self.interfaceController = nil
    }

    private func render() {
        let listItems = AppEnvironment.library.items.prefix(12).map { item -> CPListItem in
            let listItem = CPListItem(text: item.title, detailText: item.pageURL.host)
            // TODO: после подтверждения API видео-поверхности CarPlay Video
            // (CarPlay Developer Guide / WWDC25 сессия 216) — сюда должен
            // прийти либо запуск AVPlayer на видео-сёрфейсе CarPlay, либо (для
            // зеркалирования) кадр из Mirror/MirrorFrameStore. Пока — заглушка,
            // чтобы не гадать ещё раз с непроверенным API.
            listItem.handler = { _, completion in completion() }
            return listItem
        }

        let section = CPListSection(items: listItems)
        let template = CPListTemplate(title: "DriveView", sections: [section])
        interfaceController?.setRootTemplate(template, animated: true, completion: nil)
    }
}
