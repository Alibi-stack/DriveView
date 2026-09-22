import SwiftUI

@main
struct DriveViewApp: App {
    @StateObject private var library = AppEnvironment.library
    @StateObject private var browser = AppEnvironment.browser
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
