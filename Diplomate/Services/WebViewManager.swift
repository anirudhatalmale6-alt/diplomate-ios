import Foundation
import WebKit
import Combine

class WebViewManager: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var currentURL: URL?
    @Published var pageTitle: String = ""
    @Published var loadingProgress: Double = 0.0

    let baseURL = URL(string: "https://master-tough-talks.base44.app")!

    // Determine which tab is active based on URL
    var currentTab: Tab {
        guard let url = currentURL else { return .home }
        let path = url.path.lowercased()
        if path.contains("scenario") || path.contains("scenari") {
            return .scenarios
        } else if path.contains("profile") || path.contains("account") || path.contains("settings") {
            return .profile
        }
        return .home
    }

    enum Tab: String, CaseIterable {
        case home = "Home"
        case scenarios = "Scenari"
        case profile = "Profilo"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .scenarios: return "text.bubble.fill"
            case .profile: return "person.fill"
            }
        }
    }
}
