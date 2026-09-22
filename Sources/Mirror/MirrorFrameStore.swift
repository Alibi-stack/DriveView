import Combine
import Foundation
import UIKit

@MainActor
final class MirrorFrameStore: ObservableObject {
    @Published private(set) var frame: UIImage?
    @Published private(set) var status: MirrorStatus?
    @Published private(set) var isReceiving = false
    @Published private(set) var appGroupAvailable = MirrorShared.containerURL != nil

    private var timer: AnyCancellable?
    private var lastFrameModificationDate: Date?

    init() {
        timer = Timer.publish(every: 1.0 / 15.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        guard let frameURL = MirrorShared.frameURL else {
            appGroupAvailable = false
            isReceiving = false
            return
        }
        appGroupAvailable = true

        if let values = try? frameURL.resourceValues(forKeys: [.contentModificationDateKey]),
           let modificationDate = values.contentModificationDate,
           modificationDate != lastFrameModificationDate,
           let data = try? Data(contentsOf: frameURL, options: [.mappedIfSafe]),
           let image = UIImage(data: data) {
            lastFrameModificationDate = modificationDate
            frame = image
        }

        if let statusURL = MirrorShared.statusURL,
           let data = try? Data(contentsOf: statusURL),
           let decoded = try? PropertyListDecoder().decode(MirrorStatus.self, from: data) {
            status = decoded
            isReceiving = Date().timeIntervalSince(decoded.updatedAt) < 2.5
        } else {
            isReceiving = false
        }
    }
}

