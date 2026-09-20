import Combine
import Foundation
import WebKit

@MainActor
final class BrowserTabSession: NSObject, ObservableObject, Identifiable {
    let id = UUID()

    @Published var title = "Новая вкладка"
    @Published var displayURL = ""
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var mediaCandidates: [MediaCandidate] = []

    private(set) var webView: WKWebView!
    private var messageProxy: WeakScriptMessageHandler?

    override init() {
        super.init()
        configureWebView()
    }

    func load(_ url: URL) {
        webView.load(URLRequest(url: url))
    }

    func goBack() { webView.goBack() }
    func goForward() { webView.goForward() }
    func reload() { webView.reload() }

    private func configureWebView() {
        let controller = WKUserContentController()
        controller.addUserScript(WKUserScript(
            source: Self.mediaDiscoveryScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        ))
        let proxy = WeakScriptMessageHandler(delegate: self)
        messageProxy = proxy
        controller.add(proxy, name: "mediaFound")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .onDrag
    }

    private func updateState() {
        title = webView.title?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? webView.url?.host
            ?? "Новая вкладка"
        displayURL = webView.url?.absoluteString ?? ""
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }

    private func addCandidate(urlString: String, title: String?, type: String?) {
        guard let url = URL(string: urlString),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        else { return }

        let kind: MediaCandidate.Kind
        if type == "hls" || url.pathExtension.lowercased() == "m3u8" {
            kind = .hls
        } else if type == "mp4" || url.pathExtension.lowercased() == "mp4" {
            kind = .mp4
        } else {
            kind = .htmlVideo
        }

        guard !mediaCandidates.contains(where: { $0.url == url }) else { return }
        mediaCandidates.append(MediaCandidate(
            url: url,
            title: title?.nilIfEmpty ?? self.title,
            kind: kind
        ))
    }

    private static let mediaDiscoveryScript = #"""
    (() => {
      const sent = new Set();
      const send = (url, type) => {
        if (!url || sent.has(url) || !/^https?:/i.test(url)) return;
        sent.add(url);
        window.webkit.messageHandlers.mediaFound.postMessage({
          url: url,
          type: type,
          title: document.title || location.hostname
        });
      };
      const scan = () => {
        document.querySelectorAll('video').forEach(video => {
          send(video.currentSrc || video.src, 'video');
          video.querySelectorAll('source').forEach(source => send(source.src, 'video'));
        });
        performance.getEntriesByType('resource').forEach(entry => {
          const clean = entry.name.split('?')[0].toLowerCase();
          if (clean.endsWith('.m3u8')) send(entry.name, 'hls');
          if (clean.endsWith('.mp4')) send(entry.name, 'mp4');
        });
      };
      scan();
      new MutationObserver(scan).observe(document.documentElement, {
        subtree: true, childList: true, attributes: true,
        attributeFilter: ['src']
      });
      setInterval(scan, 2500);
    })();
    """#
}

extension BrowserTabSession: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Task { @MainActor in
            mediaCandidates.removeAll()
            updateState()
        }
    }

    nonisolated func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Task { @MainActor in updateState() }
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in updateState() }
    }

    nonisolated func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        Task { @MainActor in updateState() }
    }
}

extension BrowserTabSession: WKScriptMessageHandler {
    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "mediaFound",
              let body = message.body as? [String: Any],
              let url = body["url"] as? String
        else { return }

        let title = body["title"] as? String
        let type = body["type"] as? String
        Task { @MainActor in
            addCandidate(urlString: url, title: title, type: type)
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
