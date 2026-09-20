import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var browser: BrowserStore
    @EnvironmentObject private var router: AppRouter
    @State private var playerRequest: PlayerRequest?

    var body: some View {
        NavigationStack {
            List {
                ForEach(library.items) { item in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.title).font(.headline).lineLimit(2)
                        Text(item.pageURL.host ?? item.pageURL.absoluteString)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let duration = item.duration, duration > 0 {
                            ProgressView(value: min(item.lastPosition / duration, 1))
                        }

                        HStack {
                            if let mediaURL = item.mediaURL {
                                Button(item.lastPosition > 0 ? "Продолжить" : "Смотреть") {
                                    playerRequest = PlayerRequest(
                                        url: mediaURL,
                                        title: item.title,
                                        libraryItemID: item.id,
                                        startPosition: item.lastPosition
                                    )
                                }
                            }
                            Button("Открыть страницу") {
                                browser.addTab(url: item.pageURL)
                                router.selectedSection = .browser
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 5)
                }
                .onDelete(perform: library.remove)
            }
            .overlay {
                if library.items.isEmpty {
                    ContentUnavailableView(
                        "Библиотека пуста",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("Сохраняйте страницы и найденные видео из браузера.")
                    )
                }
            }
            .navigationTitle("Библиотека")
            .fullScreenCover(item: $playerRequest) { PlayerScreen(request: $0) }
        }
    }
}
