import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedSection) {
            HomeView()
                .tabItem { Label("Главная", systemImage: "house") }
                .tag(AppRouter.Section.home)

            BrowserView()
                .tabItem { Label("Браузер", systemImage: "safari") }
                .tag(AppRouter.Section.browser)

            LibraryView()
                .tabItem { Label("Библиотека", systemImage: "rectangle.stack") }
                .tag(AppRouter.Section.library)

            MirrorView()
                .tabItem { Label("Экран", systemImage: "rectangle.on.rectangle") }
                .tag(AppRouter.Section.mirror)

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
                .tag(AppRouter.Section.settings)
        }
        .tint(.red)
    }
}
