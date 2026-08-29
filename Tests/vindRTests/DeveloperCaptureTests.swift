import WebKit
import XCTest
@testable import vindR

@MainActor
final class DeveloperCaptureTests: XCTestCase {
    func testDisabledCaptureInstallsNoScripts() {
        let controller = WKUserContentController()

        DeveloperCapture.install(
            in: controller,
            tab: BrowserTab(),
            consoleEnabled: false,
            networkEnabled: false
        )

        XCTAssertTrue(controller.userScripts.isEmpty)
    }

    func testCaptureInstallsOnlyEnabledFeatures() {
        let consoleOnly = WKUserContentController()
        DeveloperCapture.install(
            in: consoleOnly,
            tab: BrowserTab(),
            consoleEnabled: true,
            networkEnabled: false
        )
        XCTAssertEqual(consoleOnly.userScripts.count, 1)

        let allCapture = WKUserContentController()
        DeveloperCapture.install(
            in: allCapture,
            tab: BrowserTab(),
            consoleEnabled: true,
            networkEnabled: true
        )
        XCTAssertEqual(allCapture.userScripts.count, 2)
    }

    func testConsoleLevelFilters() {
        let error = ConsoleEntry(level: "error", message: "broken")
        let warning = ConsoleEntry(level: "warn", message: "careful")
        let debug = ConsoleEntry(level: "debug", message: "details")

        XCTAssertTrue(ConsoleLevelFilter.errors.includes(error))
        XCTAssertFalse(ConsoleLevelFilter.errors.includes(warning))
        XCTAssertTrue(ConsoleLevelFilter.warnings.includes(warning))
        XCTAssertTrue(ConsoleLevelFilter.debug.includes(debug))
        XCTAssertTrue(ConsoleLevelFilter.all.includes(error))
    }

    func testConsoleCapturesAcrossNavigationAndEvaluatesCommands() async throws {
        let configuration = WKWebViewConfiguration()
        let tab = BrowserTab(address: "about:blank")
        DeveloperCapture.install(
            in: configuration.userContentController,
            tab: tab,
            consoleEnabled: true,
            networkEnabled: false
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        tab.retain(webView)

        let firstNavigation = NavigationWaiter(description: "first page")
        webView.navigationDelegate = firstNavigation
        webView.loadHTMLString("<script>console.warn('first-page')</script>", baseURL: nil)
        await fulfillment(of: [firstNavigation.expectation], timeout: 3)
        try await waitUntil { tab.consoleEntries.contains { $0.message == "first-page" } }

        let secondNavigation = NavigationWaiter(description: "second page")
        webView.navigationDelegate = secondNavigation
        webView.loadHTMLString("<script>console.error('second-page')</script>", baseURL: nil)
        await fulfillment(of: [secondNavigation.expectation], timeout: 3)
        try await waitUntil { tab.consoleEntries.contains { $0.message == "second-page" } }

        tab.evaluateConsoleCommand("1 + 2")
        try await waitUntil {
            tab.consoleEntries.contains { $0.level == "result" && $0.message == "3" }
        }

        XCTAssertTrue(tab.consoleEntries.contains { $0.level == "warn" && $0.message == "first-page" })
        XCTAssertTrue(tab.consoleEntries.contains { $0.level == "error" && $0.message == "second-page" })
    }

    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTFail("Timed out waiting for console event")
    }
}

private final class NavigationWaiter: NSObject, WKNavigationDelegate {
    let expectation: XCTestExpectation

    init(description: String) {
        expectation = XCTestExpectation(description: description)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        expectation.fulfill()
    }
}
