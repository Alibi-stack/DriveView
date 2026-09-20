import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var browser: BrowserStore
    @EnvironmentObject private var router: AppRouter
    @State private var playerRequest: PlayerRequest?

    private var resumable: [LibraryItem] {
        library.items.filter { $0.mediaURL != nil && $0.lastPosition > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if !resumable.isEmpty {
                        Text("Продолжить").font(.title2.bold())
                        ForEach(resumable.prefix(5)) { item in
                            Button {
                                guard let url = item.mediaURL else { return }
                                playerRequest = PlayerRequest(
                                    url: url,
                                    title: item.title,
                                    libraryItemID: item.id,
                                    startPosition: item.lastPosition
                                )
                            } label: {
                                HStack {
                                    Image(systemName: "play.circle.fill").font(.largeTitle)
                                    VStack(alignment: .leading) {
                                        Text(item.title).lineLimit(2)
                                        Text("С \(format(item.lastPosition))")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Недавно сохранено").font(.title2.bold())
                    ForEach(library.items.prefix(8)) { item in
                        Button {
                            if let url = item.mediaURL {
                                playerRequest = PlayerRequest(
                                    url: url,
                                    title: item.title,
                                    libraryItemID: item.id,
                                    startPosition: item.lastPosition
                                )
                            } else {
                                browser.addTab(url: item.pageURL)
                                router.selectedSection = .browser
                            }
                        } label: {
                            HStack {
                                Image(systemName: item.mediaURL == nil ? "link" : "play.rectangle")
                                    .foregroundStyle(.red)
                                Text(item.title).lineLimit(2)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .overlay {
                if library.items.isEmpty {
                    ContentUnavailableView(
                        "Начните с браузера",
                        systemImage: "safari",
                        description: Text("Откройте сайт и сохраните страницу или найденное видео.")
                    )
                }
            }
            .navigationTitle("DriveView")
            .fullScreenCover(item: $playerRequest) { PlayerScreen(request: $0) }
        }
    }

    private func format(_ seconds: Double) -> String {
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
