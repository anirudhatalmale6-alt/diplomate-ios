import SwiftUI
import UserNotifications

@main
struct DiplomateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var webViewManager = WebViewManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkMonitor)
                .environmentObject(webViewManager)
                .preferredColorScheme(.light)
        }
    }
}
