import SwiftUI

struct ContentView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var webViewManager: WebViewManager
    @State private var selectedTab: WebViewManager.Tab = .home
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Main content area
                ZStack {
                    if networkMonitor.isConnected {
                        WebViewContainer(selectedTab: $selectedTab, showShareSheet: $showShareSheet)
                            .environmentObject(webViewManager)

                        // Loading overlay
                        if webViewManager.isLoading {
                            LoadingOverlay(progress: webViewManager.loadingProgress)
                                .transition(.opacity)
                        }
                    } else {
                        OfflineView()
                    }
                }

                // Native tab bar
                NativeTabBar(selectedTab: $selectedTab)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = webViewManager.currentURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NetworkMonitor())
            .environmentObject(WebViewManager())
    }
}
