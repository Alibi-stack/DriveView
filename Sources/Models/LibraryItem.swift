import Foundation

struct LibraryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var pageURL: URL
    var mediaURL: URL?
    var createdAt: Date
    var lastPosition: Double
    var duration: Double?

    init(
        id: UUID = UUID(),
        title: String,
        pageURL: URL,
        mediaURL: URL? = nil,
        createdAt: Date = .now,
        lastPosition: Double = 0,
        duration: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.pageURL = pageURL
        self.mediaURL = mediaURL
        self.createdAt = createdAt
        self.lastPosition = lastPosition
        self.duration = duration
    }
}

struct MediaCandidate: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let kind: Kind

    enum Kind: String {
        case htmlVideo = "Видео"
        case hls = "HLS"
        case mp4 = "MP4"
    }
}

