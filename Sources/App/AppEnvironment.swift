import Foundation

/// Общая точка доступа к данным приложения.
///
/// SwiftUI-экраны получают `LibraryStore`/`BrowserStore` через
/// `.environmentObject`, но CarPlay-сцена (`Sources/CarPlay`) — это
/// отдельный UIKit-мир вне SwiftUI Environment и не видит его. Оба мира
/// должны читать один и тот же экземпляр `LibraryStore`, поэтому он создаётся
/// один раз здесь, а не внутри `DriveViewApp`.
@MainActor
enum AppEnvironment {
    static let library = LibraryStore()
    static let browser = BrowserStore()
}
