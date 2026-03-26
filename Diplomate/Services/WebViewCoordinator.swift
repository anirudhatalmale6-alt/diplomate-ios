import Foundation
import WebKit
import SafariServices
import UIKit

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    var viewModel: WebViewModel
    private var progressObservation: NSKeyValueObservation?
    private var loadingObservation: NSKeyValueObservation?
    private var canGoBackObservation: NSKeyValueObservation?
    private var canGoForwardObservation: NSKeyValueObservation?

    init(viewModel: WebViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    // MARK: - KVO

    func observeWebView(_ webView: WKWebView) {
        progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.viewModel.estimatedProgress = webView.estimatedProgress
            }
        }
        loadingObservation = webView.observe(\.isLoading, options: .new) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.viewModel.isLoading = webView.isLoading
            }
        }
        canGoBackObservation = webView.observe(\.canGoBack, options: .new) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.viewModel.canGoBack = webView.canGoBack
            }
        }
        canGoForwardObservation = webView.observe(\.canGoForward, options: .new) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.viewModel.canGoForward = webView.canGoForward
            }
        }
    }

    func removeObservers() {
        progressObservation?.invalidate()
        loadingObservation?.invalidate()
        canGoBackObservation?.invalidate()
        canGoForwardObservation?.invalidate()
    }

    // MARK: - Pull to Refresh

    @objc func handleRefresh(_ sender: UIRefreshControl) {
        viewModel.webView?.reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            sender.endRefreshing()
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        viewModel.showError = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewModel.showError = false

        // Re-inject hide script after each navigation
        webView.evaluateJavaScript(WebViewScripts.hideBase44Branding, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString

        // Allow navigation within the Base44 app domain
        if urlString.contains("base44.app") || urlString.starts(with: "about:") {
            decisionHandler(.allow)
            return
        }

        // Open external URLs in Safari
        if navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    private func handleNavigationError(_ error: Error) {
        let nsError = error as NSError
        // Ignore cancelled navigations
        if nsError.code == NSURLErrorCancelled {
            return
        }
        DispatchQueue.main.async {
            self.viewModel.showError = true
            self.viewModel.errorMessage = self.userFriendlyError(nsError)
        }
    }

    private func userFriendlyError(_ error: NSError) -> String {
        switch error.code {
        case NSURLErrorNotConnectedToInternet:
            return "No internet connection. Please check your network settings."
        case NSURLErrorTimedOut:
            return "The request timed out. Please try again."
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return "Unable to reach the server. Please try again later."
        case NSURLErrorNetworkConnectionLost:
            return "The network connection was lost. Please try again."
        default:
            return "Something went wrong. Please try again."
        }
    }

    // MARK: - WKUIDelegate (JavaScript Alerts/Confirms/Prompts)

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        guard let viewController = webView.findViewController() else {
            completionHandler()
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        viewController.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let viewController = webView.findViewController() else {
            completionHandler(false)
            return
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        viewController.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        guard let viewController = webView.findViewController() else {
            completionHandler(nil)
            return
        }
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        viewController.present(alert, animated: true)
    }

    // Handle target="_blank" links
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            if url.absoluteString.contains("base44.app") {
                webView.load(navigationAction.request)
            } else {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if message.name == "openExternal", let urlString = message.body as? String,
           let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - UIView Extension

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        }
        return nil
    }
}
