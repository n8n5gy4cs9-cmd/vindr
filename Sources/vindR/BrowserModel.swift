import AppKit
import Combine
import Foundation
import WebKit

struct ConsoleEntry: Identifiable {
    let id = UUID()
    let date = Date()
    let level: String
    let method: String
    let message: String

    init(level: String, method: String? = nil, message: String) {
        self.level = level
        self.method = method ?? level
        self.message = message
    }
}

struct ConsoleCaptureModules: Equatable {
    var messages: Bool
    var pageErrors: Bool
    var assertionsAndTraces: Bool
    var objectsAndTables: Bool
    var counters: Bool
    var timers: Bool
    var groups: Bool
    var performance: Bool
}

enum ConsoleLevelFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case logs = "Logs"
    case info = "Info"
    case warnings = "Warnings"
    case errors = "Errors"
    case debug = "Debug"

    var id: Self { self }

    func includes(_ entry: ConsoleEntry) -> Bool {
        switch self {
        case .all: return true
        case .logs: return ["log", "command", "result"].contains(entry.level)
        case .info: return entry.level == "info"
        case .warnings: return entry.level == "warn"
        case .errors: return entry.level == "error"
        case .debug: return entry.level == "debug"
        }
    }
}

struct NetworkEntry: Identifiable {
    let id = UUID()
    let date = Date()
    let method: String
    let url: String
    let status: Int
    let duration: Double
    let kind: String
}

struct StorageItem: Codable, Identifiable {
    var id: String { "\(key)\u{0}\(value)" }
    let key: String
    let value: String
}

struct ApplicationSnapshot: Codable {
    let origin: String
    let cookies: [StorageItem]
    let localStorage: [StorageItem]
    let sessionStorage: [StorageItem]
}

enum SearchEngine: String, CaseIterable, Identifiable {
    case duckDuckGo
    case google
    case bing

    var id: Self { self }

    var name: String {
        switch self {
        case .duckDuckGo: return "DuckDuckGo"
        case .google: return "Google"
        case .bing: return "Bing"
        }
    }

    func url(for query: String) -> URL? {
        let base: String
        switch self {
        case .duckDuckGo: base = "https://duckduckgo.com/"
        case .google: base = "https://www.google.com/search"
        case .bing: base = "https://www.bing.com/search"
        }
        var components = URLComponents(string: base)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}

@MainActor
final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    @Published var address: String
    @Published var title: String
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var readerEnabled = false
    @Published private(set) var consoleEntries: [ConsoleEntry] = []
    @Published private(set) var consoleCommandHistory: [String] = []
    @Published private(set) var networkEntries: [NetworkEntry] = []
    @Published private(set) var applicationSnapshot: ApplicationSnapshot?
    @Published private(set) var applicationError: String?
    @Published private(set) var applicationLoading = false
    @Published private(set) var webViewGeneration = 0

    weak var webView: WKWebView?
    private var retainedWebView: WKWebView?
    private var freezeTask: Task<Void, Never>?
    private var readerOriginalURL: URL?

    var isFrozen: Bool { retainedWebView == nil && title != "New Tab" }

    init(address: String = "https://duckduckgo.com", title: String = "New Tab") {
        self.address = address
        self.title = title
    }

    func retain(_ webView: WKWebView) {
        self.webView = webView
        retainedWebView = webView
    }

    func scheduleFreeze(after seconds: UInt64 = 300) {
        freezeTask?.cancel()
        freezeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.releaseWebView()
        }
    }

    func cancelFreeze() {
        freezeTask?.cancel()
        freezeTask = nil
    }

    func releaseWebView() {
        if let recoveryURL = readerOriginalURL ?? webView?.url {
            address = recoveryURL.absoluteString
        }
        readerEnabled = false
        readerOriginalURL = nil
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView = nil
        retainedWebView = nil
        canGoBack = false
        canGoForward = false
        isLoading = false
        webViewGeneration += 1
    }

    func recoverWebContent() {
        releaseWebView()
    }

    func sync(from webView: WKWebView) {
        if !readerEnabled {
            address = webView.url?.absoluteString ?? address
        }
        title = webView.title ?? title
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }

    func appendConsole(level: String, method: String? = nil, message: String) {
        consoleEntries.append(ConsoleEntry(level: level, method: method, message: message))
        if consoleEntries.count > 500 {
            consoleEntries.removeFirst(consoleEntries.count - 500)
        }
    }

    func clearConsole() {
        consoleEntries.removeAll()
    }

    func evaluateConsoleCommand(_ command: String) {
        let input = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        appendConsole(level: "command", message: input)
        consoleCommandHistory.removeAll { $0 == input }
        consoleCommandHistory.append(input)
        if consoleCommandHistory.count > 100 {
            consoleCommandHistory.removeFirst(consoleCommandHistory.count - 100)
        }

        guard let webView else {
            appendConsole(level: "error", message: "No active page context")
            return
        }
        webView.evaluateJavaScript(input) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.appendConsole(level: "error", message: error.localizedDescription)
                } else {
                    self.appendConsole(level: "result", message: Self.renderJavaScriptResult(result))
                }
            }
        }
    }

    func appendNetwork(method: String, url: String, status: Int, duration: Double, kind: String) {
        networkEntries.append(
            NetworkEntry(method: method, url: url, status: status, duration: duration, kind: kind)
        )
        if networkEntries.count > 1_000 {
            networkEntries.removeFirst(networkEntries.count - 1_000)
        }
    }

    func clearNetwork() {
        networkEntries.removeAll()
    }

    func refreshApplicationData() {
        guard let webView else {
            applicationError = "No active page context"
            return
        }
        applicationLoading = true
        applicationError = nil
        let script = #"""
        (() => {
          const readStorage = storage => {
            try { return Object.keys(storage).sort().map(key => ({ key, value: storage.getItem(key) ?? '' })); }
            catch (_) { return []; }
          };
          const cookies = document.cookie ? document.cookie.split(';').map(value => {
            const separator = value.indexOf('=');
            return separator < 0
              ? { key: value.trim(), value: '' }
              : { key: value.slice(0, separator).trim(), value: value.slice(separator + 1) };
          }) : [];
          return JSON.stringify({
            origin: location.origin,
            cookies,
            localStorage: readStorage(localStorage),
            sessionStorage: readStorage(sessionStorage)
          });
        })()
        """#
        webView.evaluateJavaScript(script) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.applicationLoading = false
                if let error {
                    self.applicationError = error.localizedDescription
                    return
                }
                guard let json = result as? String,
                      let data = json.data(using: .utf8) else {
                    self.applicationError = "The page returned no application data"
                    return
                }
                do {
                    self.applicationSnapshot = try JSONDecoder().decode(ApplicationSnapshot.self, from: data)
                } catch {
                    self.applicationError = "Could not decode application data: \(error.localizedDescription)"
                }
            }
        }
    }

    private static func renderJavaScriptResult(_ result: Any?) -> String {
        guard let result else { return "undefined" }
        if let object = result as? NSObject,
           JSONSerialization.isValidJSONObject(object),
           let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return String(describing: result)
    }

    func enterReader() {
        guard let webView, !readerEnabled else { return }
        readerOriginalURL = webView.url
        let extraction = #"""
        (() => {
          const source = document.querySelector('article, main, [role="main"]');
          if (!source) return null;
          const copy = source.cloneNode(true);
          copy.querySelectorAll('script, style, iframe, object, embed, link, nav, form, button, noscript').forEach(node => node.remove());
          copy.querySelectorAll('*').forEach(node => {
            [...node.attributes].forEach(attribute => {
              if (attribute.name.startsWith('on') || attribute.name === 'style' ||
                  (attribute.name === 'href' && attribute.value.trim().toLowerCase().startsWith('javascript:'))) {
                node.removeAttribute(attribute.name);
              }
            });
          });
          return { title: document.title, content: copy.innerHTML };
        })()
        """#

        webView.evaluateJavaScript(extraction) { [weak self, weak webView] result, _ in
            guard let self, let webView,
                  let article = result as? [String: Any],
                  let content = article["content"] as? String else { return }
            let title = (article["title"] as? String) ?? self.title
            let html = Self.readerHTML(title: title, content: content)
            self.readerEnabled = true
            webView.loadHTMLString(html, baseURL: self.readerOriginalURL)
        }
    }

    func leaveReader() {
        guard readerEnabled, let originalURL = readerOriginalURL else { return }
        readerEnabled = false
        readerOriginalURL = nil
        webView?.load(URLRequest(url: originalURL))
    }

    private static func readerHTML(title: String, content: String) -> String {
        let safeTitle = title
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return """
        <!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
        <title>\(safeTitle)</title><style>
        :root { color-scheme: light dark; } body { max-width: 740px; margin: 48px auto; padding: 0 28px 80px;
        font: 19px/1.7 -apple-system, system-ui, sans-serif; color: #202124; background: #f7f4ed; }
        h1,h2,h3 { line-height: 1.2; } img,video { max-width: 100%; height: auto; } a { color: #1769aa; }
        @media (prefers-color-scheme: dark) { body { color: #ddd; background: #171717; } a { color: #74b9f5; } }
        </style></head><body><h1>\(safeTitle)</h1>\(content)</body></html>
        """
    }
}

@MainActor
final class BrowserModel: ObservableObject {
    @Published private(set) var tabs: [BrowserTab]
    @Published var selectedTabID: UUID
    @Published var toolbarHidden = false
    @Published var hideTabStripWithToolbar = true {
        didSet { UserDefaults.standard.set(hideTabStripWithToolbar, forKey: "hideTabStripWithToolbar") }
    }
    @Published var blockingEnabled = true {
        didSet {
            UserDefaults.standard.set(blockingEnabled, forKey: "blockingEnabled")
            resetAllWebViews()
        }
    }
    @Published var privateMode = false { didSet { resetAllWebViews() } }
    @Published var javaScriptEnabled = true {
        didSet {
            UserDefaults.standard.set(javaScriptEnabled, forKey: "javaScriptEnabled")
            resetAllWebViews()
        }
    }
    @Published var unrestrictedBrowsing = false {
        didSet {
            UserDefaults.standard.set(unrestrictedBrowsing, forKey: "unrestrictedBrowsing")
            resetAllWebViews()
        }
    }
    @Published var consoleEnabled = false {
        didSet {
            UserDefaults.standard.set(consoleEnabled, forKey: "consoleEnabled")
            resetAllWebViews()
        }
    }
    @Published var consoleEvaluationEnabled = true {
        didSet { UserDefaults.standard.set(consoleEvaluationEnabled, forKey: "consoleEvaluationEnabled") }
    }
    @Published var consoleMessagesEnabled = true {
        didSet { persistConsoleCapture(consoleMessagesEnabled, key: "consoleMessagesEnabled") }
    }
    @Published var consolePageErrorsEnabled = true {
        didSet { persistConsoleCapture(consolePageErrorsEnabled, key: "consolePageErrorsEnabled") }
    }
    @Published var consoleDiagnosticsEnabled = true {
        didSet { persistConsoleCapture(consoleDiagnosticsEnabled, key: "consoleDiagnosticsEnabled") }
    }
    @Published var consoleObjectsEnabled = true {
        didSet { persistConsoleCapture(consoleObjectsEnabled, key: "consoleObjectsEnabled") }
    }
    @Published var consoleCountersEnabled = true {
        didSet { persistConsoleCapture(consoleCountersEnabled, key: "consoleCountersEnabled") }
    }
    @Published var consoleTimersEnabled = true {
        didSet { persistConsoleCapture(consoleTimersEnabled, key: "consoleTimersEnabled") }
    }
    @Published var consoleGroupsEnabled = true {
        didSet { persistConsoleCapture(consoleGroupsEnabled, key: "consoleGroupsEnabled") }
    }
    @Published var consolePerformanceEnabled = true {
        didSet { persistConsoleCapture(consolePerformanceEnabled, key: "consolePerformanceEnabled") }
    }
    @Published var javaScriptAlertEnabled = true {
        didSet { UserDefaults.standard.set(javaScriptAlertEnabled, forKey: "javaScriptAlertEnabled") }
    }
    @Published var javaScriptConfirmEnabled = true {
        didSet { UserDefaults.standard.set(javaScriptConfirmEnabled, forKey: "javaScriptConfirmEnabled") }
    }
    @Published var javaScriptPromptEnabled = true {
        didSet { UserDefaults.standard.set(javaScriptPromptEnabled, forKey: "javaScriptPromptEnabled") }
    }
    @Published var networkInspectionEnabled = false {
        didSet {
            UserDefaults.standard.set(networkInspectionEnabled, forKey: "networkInspectionEnabled")
            resetAllWebViews()
        }
    }
    @Published var applicationInspectionEnabled = false {
        didSet {
            UserDefaults.standard.set(applicationInspectionEnabled, forKey: "applicationInspectionEnabled")
        }
    }
    @Published var darkModeEnabled = false {
        didSet {
            UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled")
            applyDarkMode()
        }
    }
    @Published var searchEngine = SearchEngine.duckDuckGo {
        didSet { UserDefaults.standard.set(searchEngine.rawValue, forKey: "searchEngine") }
    }
    @Published var freezeMinutes = 5 {
        didSet {
            UserDefaults.standard.set(freezeMinutes, forKey: "freezeMinutes")
            rescheduleBackgroundFreezes()
        }
    }
    @Published var toolsPresented = false
    @Published var notesPresented = false
    @Published var settingsPresented = false
    @Published private(set) var dataClearing = false
    @Published private(set) var dataClearMessage: String?
    let tools = BrowserToolsModel()
    let notes = BrowserNotesModel()
    let downloads = BrowserDownloadManager()

    init() {
        let firstTab = BrowserTab()
        tabs = [firstTab]
        selectedTabID = firstTab.id

        let defaults = UserDefaults.standard
        hideTabStripWithToolbar = defaults.value(default: true, forKey: "hideTabStripWithToolbar")
        if defaults.object(forKey: "blockingEnabled") != nil {
            blockingEnabled = defaults.bool(forKey: "blockingEnabled")
        }
        if defaults.object(forKey: "javaScriptEnabled") != nil {
            javaScriptEnabled = defaults.bool(forKey: "javaScriptEnabled")
        }
        if defaults.object(forKey: "unrestrictedBrowsing") != nil {
            unrestrictedBrowsing = defaults.bool(forKey: "unrestrictedBrowsing")
        }
        if defaults.object(forKey: "consoleEnabled") != nil {
            consoleEnabled = defaults.bool(forKey: "consoleEnabled")
        }
        consoleEvaluationEnabled = defaults.value(default: true, forKey: "consoleEvaluationEnabled")
        consoleMessagesEnabled = defaults.value(default: true, forKey: "consoleMessagesEnabled")
        consolePageErrorsEnabled = defaults.value(default: true, forKey: "consolePageErrorsEnabled")
        consoleDiagnosticsEnabled = defaults.value(default: true, forKey: "consoleDiagnosticsEnabled")
        consoleObjectsEnabled = defaults.value(default: true, forKey: "consoleObjectsEnabled")
        consoleCountersEnabled = defaults.value(default: true, forKey: "consoleCountersEnabled")
        consoleTimersEnabled = defaults.value(default: true, forKey: "consoleTimersEnabled")
        consoleGroupsEnabled = defaults.value(default: true, forKey: "consoleGroupsEnabled")
        consolePerformanceEnabled = defaults.value(default: true, forKey: "consolePerformanceEnabled")
        javaScriptAlertEnabled = defaults.value(default: true, forKey: "javaScriptAlertEnabled")
        javaScriptConfirmEnabled = defaults.value(default: true, forKey: "javaScriptConfirmEnabled")
        javaScriptPromptEnabled = defaults.value(default: true, forKey: "javaScriptPromptEnabled")
        if defaults.object(forKey: "networkInspectionEnabled") != nil {
            networkInspectionEnabled = defaults.bool(forKey: "networkInspectionEnabled")
        }
        if defaults.object(forKey: "applicationInspectionEnabled") != nil {
            applicationInspectionEnabled = defaults.bool(forKey: "applicationInspectionEnabled")
        }
        if defaults.object(forKey: "darkModeEnabled") != nil {
            darkModeEnabled = defaults.bool(forKey: "darkModeEnabled")
        }
        if let value = defaults.string(forKey: "searchEngine"),
           let engine = SearchEngine(rawValue: value) {
            searchEngine = engine
        }
        if defaults.object(forKey: "freezeMinutes") != nil {
            let storedMinutes = defaults.integer(forKey: "freezeMinutes")
            if [0, 1, 5, 15, 30].contains(storedMinutes) {
                freezeMinutes = storedMinutes
            }
        }
    }

    var selectedTab: BrowserTab {
        tabs.first(where: { $0.id == selectedTabID }) ?? tabs[0]
    }

    var consoleCaptureModules: ConsoleCaptureModules {
        ConsoleCaptureModules(
            messages: consoleMessagesEnabled,
            pageErrors: consolePageErrorsEnabled,
            assertionsAndTraces: consoleDiagnosticsEnabled,
            objectsAndTables: consoleObjectsEnabled,
            counters: consoleCountersEnabled,
            timers: consoleTimersEnabled,
            groups: consoleGroupsEnabled,
            performance: consolePerformanceEnabled
        )
    }

    func navigate() {
        let tab = selectedTab
        let input = tab.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        let target: URL?
        if input.contains(" ") || (!input.contains(".") && !input.contains(":")) {
            target = searchEngine.url(for: input)
        } else {
            target = URL(string: input.contains("://") ? input : "https://\(input)")
        }

        guard let target else { return }
        if tab.readerEnabled {
            tab.leaveReader()
        }
        tab.webView?.load(URLRequest(url: target))
    }

    func newTab() {
        scheduleFreeze(selectedTab)
        let tab = BrowserTab()
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func openTab(with webView: WKWebView, requestedURL: URL?) {
        scheduleFreeze(selectedTab)
        let address = requestedURL?.absoluteString ?? "about:blank"
        let tab = BrowserTab(address: address)
        tab.retain(webView)
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func select(_ tab: BrowserTab) {
        guard tab.id != selectedTabID else { return }
        scheduleFreeze(selectedTab)
        tab.cancelFreeze()
        selectedTabID = tab.id
    }

    func close(_ tab: BrowserTab) {
        guard tabs.count > 1 else { return }
        let index = tabs.firstIndex(where: { $0.id == tab.id }) ?? 0
        tab.cancelFreeze()
        tab.releaseWebView()
        tabs.removeAll { $0.id == tab.id }
        if selectedTabID == tab.id {
            let replacement = tabs[min(index, tabs.count - 1)]
            replacement.cancelFreeze()
            selectedTabID = replacement.id
        }
    }

    func copyURL() {
        let value = selectedTab.webView?.url?.absoluteString ?? selectedTab.address
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    func toggleReader() {
        selectedTab.readerEnabled ? selectedTab.leaveReader() : selectedTab.enterReader()
    }

    func applyAppearance(to webView: WKWebView) {
        let script: String
        if darkModeEnabled {
            script = #"""
            (() => {
              let style = document.getElementById('vindr-dark-mode');
              if (!style) { style = document.createElement('style'); style.id = 'vindr-dark-mode'; document.documentElement.appendChild(style); }
              style.textContent = 'html { color-scheme: dark !important; background: #171717 !important; filter: invert(0.9) hue-rotate(180deg) !important; } img, video, picture, canvas, iframe { filter: invert(1) hue-rotate(180deg) !important; }';
            })()
            """#
        } else {
            script = "document.getElementById('vindr-dark-mode')?.remove()"
        }
        webView.evaluateJavaScript(script)
    }

    func clearWebsiteData() {
        guard !dataClearing else { return }
        dataClearing = true
        dataClearMessage = nil

        var stores: [WKWebsiteDataStore] = [.default()]
        for tab in tabs {
            let store = tab.webView?.configuration.websiteDataStore
            if let store, !stores.contains(where: { $0 === store }) {
                stores.append(store)
            }
        }

        let group = DispatchGroup()
        for store in stores {
            group.enter()
            store.removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: .distantPast
            ) {
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.resetAllWebViews()
            self.dataClearing = false
            self.dataClearMessage = "Cookies, caches, history, and other website data were cleared."
        }
    }

    private func applyDarkMode() {
        for tab in tabs {
            if let webView = tab.webView {
                applyAppearance(to: webView)
            }
        }
    }

    private func scheduleFreeze(_ tab: BrowserTab) {
        guard freezeMinutes > 0 else {
            tab.cancelFreeze()
            return
        }
        tab.scheduleFreeze(after: UInt64(freezeMinutes * 60))
    }

    private func rescheduleBackgroundFreezes() {
        for tab in tabs {
            tab.cancelFreeze()
            if tab.id != selectedTabID {
                scheduleFreeze(tab)
            }
        }
    }

    private func resetAllWebViews() {
        for tab in tabs {
            tab.recoverWebContent()
        }
    }

    private func persistConsoleCapture(_ value: Bool, key: String) {
        UserDefaults.standard.set(value, forKey: key)
        if consoleEnabled {
            resetAllWebViews()
        }
    }
}

private extension UserDefaults {
    func value(default defaultValue: Bool, forKey key: String) -> Bool {
        object(forKey: key) == nil ? defaultValue : bool(forKey: key)
    }
}

enum BrowserNotice {
    static let focusLocation = Notification.Name("vindR.focusLocation")
    static let quickSearch = Notification.Name("vindR.quickSearch")

    static func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}
