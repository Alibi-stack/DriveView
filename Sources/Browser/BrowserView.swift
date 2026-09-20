import SwiftUI

struct BrowserView: View {
    @EnvironmentObject private var browser: BrowserStore
    @EnvironmentObject private var library: LibraryStore

    @State private var address = ""
    @State private var showTabs = false
    @State private var showMedia = false
    @State private var playerRequest: PlayerRequest?

    var body: some View {
        NavigationStack {
            Group {
                if let tab = browser.selectedTab {
                    WebViewContainer(session: tab)
                        .ignoresSafeArea(edges: .bottom)
                        .onChange(of: tab.displayURL) { _, newValue in address = newValue }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) { addressBar }
            .safeAreaInset(edge: .bottom, spacing: 0) { browserToolbar }
            .navigationTitle("Браузер")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showTabs) { TabsView() }
            .sheet(isPresented: $showMedia) { mediaSheet }
            .fullScreenCover(item: $playerRequest) { PlayerScreen(request: $0) }
        }
    }

    private var addressBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Поиск или адрес", text: $address)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.webSearch)
                .submitLabel(.go)
                .onSubmit { openAddress() }
            if browser.selectedTab?.isLoading == true {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(.bar)
    }

    private var browserToolbar: some View {
        HStack {
            Button { browser.selectedTab?.goBack() } label: {
                Image(systemName: "chevron.backward")
            }
            .disabled(browser.selectedTab?.canGoBack != true)

            Spacer()
            Button { browser.selectedTab?.goForward() } label: {
                Image(systemName: "chevron.forward")
            }
            .disabled(browser.selectedTab?.canGoForward != true)

            Spacer()
            Button { browser.selectedTab?.reload() } label: {
                Image(systemName: "arrow.clockwise")
            }

            Spacer()
            Button { saveCurrentPage() } label: {
                Image(systemName: "bookmark")
            }
            .disabled(browser.selectedTab?.webView.url == nil)

            Spacer()
            Button { showMedia = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "play.rectangle")
                    if let count = browser.selectedTab?.mediaCandidates.count, count > 0 {
                        Text("\(count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.red, in: Circle())
                            .offset(x: 8, y: -8)
                    }
                }
            }

            Spacer()
            Button { showTabs = true } label: {
                Image(systemName: "square.on.square")
            }
        }
        .font(.title3)
        .padding(.horizontal, 24)
        .frame(height: 48)
        .background(.bar)
    }

    private var mediaSheet: some View {
        NavigationStack {
            List(browser.selectedTab?.mediaCandidates ?? []) { candidate in
                VStack(alignment: .leading, spacing: 5) {
                    Text(candidate.title).lineLimit(2)
                    Text(candidate.kind.rawValue + " · " + candidate.url.hostDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Смотреть") {
                            let request = PlayerRequest(url: candidate.url, title: candidate.title)
                            showMedia = false
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                playerRequest = request
                            }
                        }
                        Spacer()
                        Button("Сохранить") {
                            guard let pageURL = browser.selectedTab?.webView.url else { return }
                            library.add(
                                title: candidate.title,
                                pageURL: pageURL,
                                mediaURL: candidate.url
                            )
                        }
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            }
            .overlay {
                if browser.selectedTab?.mediaCandidates.isEmpty != false {
                    ContentUnavailableView(
                        "Видео пока не найдено",
                        systemImage: "play.slash",
                        description: Text("Запустите видео на странице и повторите поиск.")
                    )
                }
            }
            .navigationTitle("Видео на странице")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { showMedia = false }
                }
            }
        }
    }

    private func openAddress() {
        guard let url = AddressResolver.resolve(address) else { return }
        browser.selectedTab?.load(url)
    }

    private func saveCurrentPage() {
        guard let tab = browser.selectedTab, let url = tab.webView.url else { return }
        library.add(title: tab.title, pageURL: url)
    }
}

private extension URL {
    var hostDisplay: String { host ?? absoluteString }
}
