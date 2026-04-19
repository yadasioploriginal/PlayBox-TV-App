import SwiftUI
import WebKit

class WebViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var errorMessage: String? = nil

    let primaryURL = "https://stare.playboxtv.pl.eu.org/app"
    let fallbackURLs = [
        "https://tv.yadasiopl.pl.eu.org/app",
        "https://pbtv.netlify.app/app"
    ]

    var currentFallbackIndex = -1 // -1 means primary
    weak var webView: WKWebView?

    var currentURL: String {
        if currentFallbackIndex < 0 {
            return primaryURL
        } else if currentFallbackIndex < fallbackURLs.count {
            return fallbackURLs[currentFallbackIndex]
        }
        return primaryURL
    }

    func retryLoading() {
        errorMessage = nil
        isLoading = true
        currentFallbackIndex = -1
        loadCurrentURL()
    }

    func tryNextFallback() {
        currentFallbackIndex += 1
        if currentFallbackIndex < fallbackURLs.count {
            print("[PlayBoxTV] Trying fallback #\(currentFallbackIndex + 1): \(currentURL)")
            loadCurrentURL()
        } else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Nie udało się połączyć z żadnym serwerem. Sprawdź połączenie internetowe."
            }
        }
    }

    func loadCurrentURL() {
        guard let url = URL(string: currentURL) else { return }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        webView?.load(request)
    }
}

struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true

        if #available(iOS 15.4, *) {
            config.preferences.isElementFullscreenEnabled = true
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false

        // Allow all media autoplay
        webView.configuration.preferences.javaScriptEnabled = true

        viewModel.webView = webView

        // Load primary URL
        if let url = URL(string: viewModel.primaryURL) {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No dynamic updates needed
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let viewModel: WebViewModel

        init(viewModel: WebViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("[PlayBoxTV] Successfully loaded: \(webView.url?.absoluteString ?? "unknown")")
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
                self.viewModel.errorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[PlayBoxTV] Failed to load: \(error.localizedDescription)")
            handleError(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[PlayBoxTV] Provisional navigation failed: \(error.localizedDescription)")
            handleError(error)
        }

        private func handleError(_ error: Error) {
            let nsError = error as NSError
            // Skip cancellation errors (user navigated away)
            if nsError.code == NSURLErrorCancelled { return }

            viewModel.tryNextFallback()
        }

        // Handle target="_blank" links
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        // Handle JavaScript alerts
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            completionHandler()
        }
    }
}
