import XCTest
@testable import Diplomate

final class DiplomateTests: XCTestCase {

    func testConstantsAppURL() {
        XCTAssertEqual(Constants.appURL, "https://master-tough-talks.base44.app")
    }

    func testConstantsBundleIdentifier() {
        XCTAssertEqual(Constants.bundleIdentifier, "com.diplomate.app")
    }

    func testNetworkMonitorInitialState() {
        let monitor = NetworkMonitor()
        // Should default to connected
        XCTAssertTrue(monitor.isConnected)
    }

    func testWebViewModelInitialState() {
        let viewModel = WebViewModel()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.estimatedProgress, 0.0)
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertFalse(viewModel.canGoBack)
        XCTAssertFalse(viewModel.canGoForward)
    }

    func testStoreManagerProductID() {
        XCTAssertEqual(StoreManager.fullAccessProductID, "com.diplomate.app.full_access")
    }

    func testStoreManagerInitialState() {
        let storeManager = StoreManager()
        XCTAssertFalse(storeManager.hasFullAccess)
        XCTAssertTrue(storeManager.products.isEmpty)
        XCTAssertTrue(storeManager.purchasedProductIDs.isEmpty)
    }

    func testWebViewScriptsNotEmpty() {
        XCTAssertFalse(WebViewScripts.hideBase44Branding.isEmpty)
        XCTAssertFalse(WebViewScripts.viewportAdapter.isEmpty)
        XCTAssertFalse(WebViewScripts.externalLinkHandler.isEmpty)
    }

    func testHideBase44ScriptContainsSelectors() {
        XCTAssertTrue(WebViewScripts.hideBase44Branding.contains("base44"))
        XCTAssertTrue(WebViewScripts.hideBase44Branding.contains("display"))
        XCTAssertTrue(WebViewScripts.hideBase44Branding.contains("MutationObserver"))
    }
}
