import Foundation

struct PlayerRequest: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
    let libraryItemID: UUID?
    let startPosition: Double

    init(url: URL, title: String, libraryItemID: UUID? = nil, startPosition: Double = 0) {
        self.url = url
        self.title = title
        self.libraryItemID = libraryItemID
        self.startPosition = startPosition
    }
}

