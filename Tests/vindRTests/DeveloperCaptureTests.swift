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

    func testSelectiveConsoleModulesInstallOnlyTheirHooks() async throws {
        let configuration = WKWebViewConfiguration()
        let tab = BrowserTab(address: "about:blank")
        DeveloperCapture.install(
            in: configuration.userContentController,
            tab: tab,
            consoleEnabled: true,
            consoleModules: ConsoleCaptureModules(
                messages: false,
                pageErrors: false,
                assertionsAndTraces: false,
                objectsAndTables: false,
                counters: true,
                timers: false,
                groups: false,
                performance: false
            ),
            networkEnabled: false
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        tab.retain(webView)

        let navigation = NavigationWaiter(description: "selective console modules")
        webView.navigationDelegate = navigation
        webView.loadHTMLString("<script>console.log('hidden'); console.count('visible')</script>", baseURL: nil)
        await fulfillment(of: [navigation.expectation], timeout: 3)
        try await waitUntil { tab.consoleEntries.contains { $0.method == "count" } }

        XCTAssertFalse(tab.consoleEntries.contains { $0.message.contains("hidden") })
        XCTAssertTrue(tab.consoleEntries.contains { $0.method == "count" && $0.message == "visible: 1" })
    }

    func testCompleteStandardConsoleAPICapture() async throws {
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

        let navigation = NavigationWaiter(description: "complete console API")
        webView.navigationDelegate = navigation
        webView.loadHTMLString(
            #"""
            <body><script>
            console.clear();
            console.log('log'); console.info('info'); console.warn('warn');
            console.error('error'); console.debug('debug');
            console.assert(false, 'assertion'); console.trace('trace');
            console.dir({answer: 42}); console.dirxml(document.body); console.table([{answer: 42}]);
            console.count('counter'); console.countReset('counter');
            console.time('timer'); console.timeLog('timer', 'lap'); console.timeEnd('timer');
            console.group('group'); console.log('nested'); console.groupEnd();
            </script></body>
            """#,
            baseURL: nil
        )
        await fulfillment(of: [navigation.expectation], timeout: 3)
        let expectedMethods: Set<String> = [
            "clear", "log", "info", "warn", "error", "debug", "assert", "trace",
            "dir", "dirxml", "table", "count", "countReset", "timeLog", "timeEnd", "group"
        ]
        try await waitUntil { expectedMethods.isSubset(of: Set(tab.consoleEntries.map(\.method))) }

        XCTAssertTrue(expectedMethods.isSubset(of: Set(tab.consoleEntries.map(\.method))))
        XCTAssertTrue(tab.consoleEntries.contains { $0.message == "  nested" })
    }

    func testCoordinatorExposesAllJavaScriptDialogCallbacks() {
        let coordinator = WebView.Coordinator(browser: BrowserModel(), tab: BrowserTab())

        XCTAssertTrue(coordinator.responds(to: #selector(WKUIDelegate.webView(
            _:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:
        ))))
        XCTAssertTrue(coordinator.responds(to: #selector(WKUIDelegate.webView(
            _:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:
        ))))
        XCTAssertTrue(coordinator.responds(to: #selector(WKUIDelegate.webView(
            _:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:
        ))))
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
