import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    @ObservedObject var session: BrowserTabSession

    func makeUIView(context: Context) -> WKWebView {
        session.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

