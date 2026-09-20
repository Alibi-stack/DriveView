import SwiftUI

@main
struct DriveViewApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var browser = BrowserStore()
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .environmentObject(browser)
                .environmentObject(router)
        }
    }
}
