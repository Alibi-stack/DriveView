import Foundation

enum MirrorShared {
    static let appGroup = "group.com.alibistack.driveview"
    static let broadcastExtensionBundleID = "com.alibistack.driveview.broadcast"

    static let frameFileName = "mirror-frame.jpg"
    static let statusFileName = "mirror-status.plist"

    static let longEdgeKey = "mirror.longEdge"
    static let framesPerSecondKey = "mirror.framesPerSecond"
    static let jpegQualityKey = "mirror.jpegQuality"

    static let defaultLongEdge = 1280
    static let defaultFramesPerSecond = 15
    static let defaultJPEGQuality = 0.72

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )
    }

    static var frameURL: URL? {
        containerURL?.appendingPathComponent(frameFileName)
    }

    static var statusURL: URL? {
        containerURL?.appendingPathComponent(statusFileName)
    }
}

struct MirrorStatus: Codable {
    var updatedAt: Date
    var width: Int
    var height: Int
    var framesPerSecond: Int
}

