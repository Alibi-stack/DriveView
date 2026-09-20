import Combine
import Foundation

@MainActor
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [BrowserTabSession] = []
    @Published var selectedID: UUID?
    private var tabCancellables: [UUID: AnyCancellable] = [:]

    var selectedTab: BrowserTabSession? {
        tabs.first(where: { $0.id == selectedID })
    }

    init() {
        addTab()
    }

    @discardableResult
    func addTab(url: URL? = nil) -> BrowserTabSession {
        let tab = BrowserTabSession()
        tabs.append(tab)
        tabCancellables[tab.id] = tab.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        selectedID = tab.id
        let destination = url ?? URL(string: "https://www.google.com")!
        tab.load(destination)
        return tab
    }

    func close(_ tab: BrowserTabSession) {
        guard tabs.count > 1 else { return }
        let index = tabs.firstIndex(where: { $0.id == tab.id })
        tabs.removeAll(where: { $0.id == tab.id })
        tabCancellables[tab.id] = nil
        if selectedID == tab.id {
            selectedID = tabs[min(index ?? 0, tabs.count - 1)].id
        }
    }
}
