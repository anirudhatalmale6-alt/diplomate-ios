import Foundation
import WebKit
import Combine

class WebViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0.0
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false

    weak var webView: WKWebView?

    func retry() {
        showError = false
        errorMessage = ""
        if let webView = webView {
            if let url = webView.url {
                webView.load(URLRequest(url: url))
            } else if let url = URL(string: Constants.appURL) {
                webView.load(URLRequest(url: url))
            }
        }
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }
}
