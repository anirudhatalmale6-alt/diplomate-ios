import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    @EnvironmentObject var webViewManager: WebViewManager
    @Binding var selectedTab: WebViewManager.Tab
    @Binding var showShareSheet: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Enable JavaScript
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        // Add user script to inject CSS for safe area handling and hide web nav if needed
        let userScript = WKUserScript(
            source: Self.injectedCSS + Self.injectedJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)

        // Add message handler for share action
        config.userContentController.add(context.coordinator, name: "shareHandler")
        config.userContentController.add(context.coordinator, name: "navigationHandler")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1)
        webView.scrollView.backgroundColor = UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1)

        // Pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1)
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        // KVO observers
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)

        context.coordinator.webView = webView

        // Load initial URL
        let request = URLRequest(url: webViewManager.baseURL, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Handle tab changes - navigate to appropriate page
        // Only navigate if user tapped a tab (coordinator tracks this)
        if context.coordinator.pendingTabNavigation != selectedTab {
            context.coordinator.pendingTabNavigation = selectedTab
            navigateToTab(selectedTab, webView: webView)
        }
    }

    private func navigateToTab(_ tab: WebViewManager.Tab, webView: WKWebView) {
        let baseURLString = webViewManager.baseURL.absoluteString
        var targetURL: String

        switch tab {
        case .home:
            targetURL = baseURLString
        case .scenarios:
            // Navigate to scenarios section via JavaScript or URL
            targetURL = baseURLString
            // Use JS to scroll to or navigate to scenarios section
            webView.evaluateJavaScript(
                "if(document.querySelector('[href*=\"scenari\"]')) { document.querySelector('[href*=\"scenari\"]').click(); } else { window.scrollTo({top: 0, behavior: 'smooth'}); }",
                completionHandler: nil
            )
            return
        case .profile:
            targetURL = baseURLString
            webView.evaluateJavaScript(
                "if(document.querySelector('[href*=\"profile\"]') || document.querySelector('[href*=\"account\"]')) { (document.querySelector('[href*=\"profile\"]') || document.querySelector('[href*=\"account\"]')).click(); } else { window.scrollTo({top: 0, behavior: 'smooth'}); }",
                completionHandler: nil
            )
            return
        }

        if let url = URL(string: targetURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    // Injected CSS to handle safe areas and match app theme
    private static var injectedCSS: String {
        """
        (function() {
            var style = document.createElement('style');
            style.textContent = `
                body {
                    -webkit-touch-callout: none;
                    -webkit-tap-highlight-color: rgba(124, 58, 237, 0.2);
                    padding-bottom: env(safe-area-inset-bottom, 0px) !important;
                }
                ::-webkit-scrollbar {
                    display: none;
                }
                /* Smooth scrolling */
                * {
                    -webkit-overflow-scrolling: touch;
                }
            `;
            document.head.appendChild(style);
        })();
        """
    }

    // Injected JavaScript for native bridge
    private static var injectedJS: String {
        """
        (function() {
            // Expose share function to web content
            window.nativeShare = function(text, url) {
                window.webkit.messageHandlers.shareHandler.postMessage({text: text, url: url});
            };

            // Track navigation changes
            var pushState = history.pushState;
            history.pushState = function() {
                pushState.apply(history, arguments);
                window.webkit.messageHandlers.navigationHandler.postMessage({url: window.location.href});
            };
            window.addEventListener('popstate', function() {
                window.webkit.messageHandlers.navigationHandler.postMessage({url: window.location.href});
            });
        })();
        """
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        var webView: WKWebView?
        var pendingTabNavigation: WebViewManager.Tab = .home

        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        deinit {
            webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
            webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
            webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack))
            webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward))
            webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
            webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        }

        // MARK: - KVO
        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            guard let webView = object as? WKWebView else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch keyPath {
                case #keyPath(WKWebView.estimatedProgress):
                    self.parent.webViewManager.loadingProgress = webView.estimatedProgress
                case #keyPath(WKWebView.isLoading):
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.parent.webViewManager.isLoading = webView.isLoading
                    }
                case #keyPath(WKWebView.canGoBack):
                    self.parent.webViewManager.canGoBack = webView.canGoBack
                case #keyPath(WKWebView.canGoForward):
                    self.parent.webViewManager.canGoForward = webView.canGoForward
                case #keyPath(WKWebView.url):
                    self.parent.webViewManager.currentURL = webView.url
                case #keyPath(WKWebView.title):
                    self.parent.webViewManager.pageTitle = webView.title ?? ""
                default:
                    break
                }
            }
        }

        // MARK: - Pull to Refresh
        @objc func handleRefresh(_ sender: UIRefreshControl) {
            HapticManager.impact(.light)
            webView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                sender.endRefreshing()
            }
        }

        // MARK: - WKNavigationDelegate
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.webViewManager.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.parent.webViewManager.isLoading = false
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.webViewManager.isLoading = false
            }
            HapticManager.notification(.error)
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

            // Open external links in Safari
            let baseHost = parent.webViewManager.baseURL.host ?? ""
            if let host = url.host, !host.contains(baseHost) && !host.contains("base44") {
                // Check for common external domains
                if url.scheme == "mailto" || url.scheme == "tel" {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
                if navigationAction.navigationType == .linkActivated {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }

        // MARK: - WKUIDelegate
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // Handle target="_blank" links
            if navigationAction.targetFrame == nil || !(navigationAction.targetFrame?.isMainFrame ?? false) {
                webView.load(navigationAction.request)
            }
            return nil
        }

        // Handle JavaScript alerts
        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                completionHandler()
                return
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            rootVC.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                completionHandler(false)
                return
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            rootVC.present(alert, animated: true)
        }

        // MARK: - WKScriptMessageHandler
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "shareHandler":
                HapticManager.impact(.medium)
                DispatchQueue.main.async {
                    self.parent.showShareSheet = true
                }
            case "navigationHandler":
                if let body = message.body as? [String: Any],
                   let urlString = body["url"] as? String,
                   let url = URL(string: urlString) {
                    DispatchQueue.main.async {
                        self.parent.webViewManager.currentURL = url
                    }
                }
            default:
                break
            }
        }
    }
}
