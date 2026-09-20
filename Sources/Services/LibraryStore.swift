import Combine
import Foundation

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var items: [LibraryItem] = []

    private let defaults: UserDefaults
    private let storageKey = "driveview.library.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(title: String, pageURL: URL, mediaURL: URL? = nil) {
        if let index = items.firstIndex(where: {
            $0.pageURL == pageURL && $0.mediaURL == mediaURL
        }) {
            let existing = items.remove(at: index)
            items.insert(existing, at: 0)
        } else {
            items.insert(
                LibraryItem(title: title, pageURL: pageURL, mediaURL: mediaURL),
                at: 0
            )
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            items.remove(at: index)
        }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    func updateProgress(for id: UUID, position: Double, duration: Double?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].lastPosition = position
        items[index].duration = duration
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LibraryItem].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
