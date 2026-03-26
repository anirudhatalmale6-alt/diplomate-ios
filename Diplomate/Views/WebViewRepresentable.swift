import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Enable inline media playback
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Data store for cookie persistence
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        // User content controller for JS injection
        let contentController = WKUserContentController()

        // Inject CSS/JS to hide Base44 branding
        let hideBase44Script = WKUserScript(
            source: WebViewScripts.hideBase44Branding,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(hideBase44Script)

        // Inject viewport adapter
        let viewportScript = WKUserScript(
            source: WebViewScripts.viewportAdapter,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(viewportScript)

        // Inject external link handler
        let externalLinkScript = WKUserScript(
            source: WebViewScripts.externalLinkHandler,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(externalLinkScript)

        // Message handler for external links
        contentController.add(context.coordinator, name: "openExternal")

        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        // Pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1)
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(WebViewCoordinator.handleRefresh(_:)),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refreshControl

        // KVO observers for progress and loading
        context.coordinator.observeWebView(webView)

        // Store reference in viewModel
        viewModel.webView = webView

        // Load the app
        if let url = URL(string: Constants.appURL) {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed — viewModel drives state
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: WebViewCoordinator) {
        coordinator.removeObservers()
    }
}
