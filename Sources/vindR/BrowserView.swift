import SwiftUI
import WebKit

struct BrowserView: View {
    @EnvironmentObject private var browser: BrowserModel
    @FocusState private var addressFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            tabStrip
            Divider()
            if !browser.toolbarHidden {
                Toolbar(browser: browser, tab: browser.selectedTab, addressFocused: $addressFocused)
                Divider()
            }
            BrowserPage(browser: browser, tab: browser.selectedTab)
        }
        .tint(.cyan)
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(browser.selectedTab.title)
        .onReceive(NotificationCenter.default.publisher(for: BrowserNotice.focusLocation)) { _ in
            addressFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: BrowserNotice.quickSearch)) { _ in
            browser.selectedTab.address = ""
            addressFocused = true
        }
        .sheet(isPresented: $browser.toolsPresented) {
            BrowserToolsView(browser: browser, tools: browser.tools)
        }
        .sheet(isPresented: $browser.notesPresented) {
            BrowserNotesView(notes: browser.notes)
        }
        .sheet(isPresented: $browser.settingsPresented) {
            BrowserSettingsView(browser: browser)
        }
    }

    private var tabStrip: some View {
        HStack(spacing: 3) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(browser.tabs) { tab in
                        TabButton(browser: browser, tab: tab)
                    }
                }
            }
            Button(action: browser.newTab) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New Tab (Cmd-T)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(red: 10 / 255, green: 27 / 255, blue: 77 / 255))
    }
}

private struct TabButton: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: tab.isFrozen ? "snowflake" : (tab.isLoading ? "circle.dotted" : "globe"))
                .font(.system(size: tab.isFrozen ? 9 : 8, weight: .bold))
                .foregroundStyle(tab.isLoading ? Color.orange : (isSelected ? Color.cyan : Color.secondary))
            Button(action: { browser.select(tab) }) {
                Text(tab.title)
                    .lineLimit(1)
                    .frame(maxWidth: 150, alignment: .leading)
            }
            .buttonStyle(.plain)
            if browser.tabs.count > 1 {
                Button(action: { browser.close(tab) }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color(red: 0.08, green: 0.22, blue: 0.44) : Color(red: 26 / 255, green: 42 / 255, blue: 90 / 255))
        )
        .overlay(alignment: .bottom) {
            if isSelected {
                Rectangle().fill(Color(red: 34 / 255, green: 245 / 255, blue: 197 / 255)).frame(height: 2)
                    .padding(.horizontal, 7)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var isSelected: Bool { tab.id == browser.selectedTabID }
}

private struct Toolbar: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    let addressFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Button(action: { tab.webView?.goBack() }) { Image(systemName: "chevron.left") }
                .disabled(!tab.canGoBack)
            Button(action: { tab.webView?.goForward() }) { Image(systemName: "chevron.right") }
                .disabled(!tab.canGoForward)
            Button(action: stopOrReload) {
                Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
            }

            Button(action: browser.copyURL) { Image(systemName: "link") }
                .help("Copy URL (Cmd-Shift-C)")

            HStack(spacing: 6) {
                Image(systemName: tab.address.hasPrefix("https://") ? "lock.fill" : "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(tab.address.hasPrefix("https://") ? .green : .secondary)
                Image(systemName: "magnifyingglass.circle.fill")
                    .foregroundStyle(.orange)
                    .help(browser.searchEngine.name)
                TextField("Search or enter address", text: $tab.address)
                    .textFieldStyle(.plain)
                    .focused(addressFocused)
                    .onSubmit(browser.navigate)
                Button(action: browser.toggleReader) {
                    Image(systemName: tab.readerEnabled ? "doc.plaintext.fill" : "doc.plaintext")
                        .foregroundStyle(tab.readerEnabled ? .cyan : .secondary)
                }
                .disabled(!browser.javaScriptEnabled && !tab.readerEnabled)
                .help(tab.readerEnabled ? "Exit Reader View" : "Reader View")
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .frame(maxWidth: 720)
            .background(Color.black.opacity(0.24), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.10)))

            Button(action: browser.navigate) { Image(systemName: "arrow.right") }
                .keyboardShortcut(.return, modifiers: [])
                .help("Go")

            DownloadStatusView(downloads: browser.downloads)

            Menu {
                Toggle("Block ads and trackers", isOn: $browser.blockingEnabled)
                Toggle("Private session", isOn: $browser.privateMode)
                Toggle("Enable JavaScript", isOn: $browser.javaScriptEnabled)
                Divider()
                Toggle("Darken pages", isOn: $browser.darkModeEnabled)
            } label: {
                HStack(spacing: 5) {
                    Circle()
                        .fill(browser.privateMode ? Color.green : Color.red)
                        .frame(width: 7, height: 7)
                        .shadow(color: browser.privateMode ? .green : .red, radius: 4)
                    Text("PRIVATE")
                        .font(.system(size: 9, weight: .bold))
                    Image(systemName: browser.privateMode ? "lock.fill" : "lock.open")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.08), in: Capsule())
            }
            .menuStyle(.borderlessButton)
            .help(browser.privateMode ? "Privacy: private session" : "Privacy and appearance")

            Button(action: { browser.toolsPresented = true }) {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundStyle(.orange)
            }
            .help("Developer Tools (Cmd-Option-I)")

            Button(action: { browser.notesPresented = true }) {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(.pink)
            }
            .help("Notes (Cmd-Shift-N)")

            Button(action: { browser.settingsPresented = true }) {
                Image(systemName: "gearshape")
                    .foregroundStyle(.blue)
            }
            .help("Settings (Cmd-,)")

            Button(action: { browser.toolbarHidden = true }) { Image(systemName: "chevron.up") }
                .help("Hide toolbar (Cmd-Shift-T)")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    private func stopOrReload() {
        if tab.isLoading {
            tab.webView?.stopLoading()
        } else {
            tab.webView?.reload()
        }
    }
}

private struct DownloadStatusView: View {
    @ObservedObject var downloads: BrowserDownloadManager

    var body: some View {
        Button(action: downloads.clearStatus) {
            HStack(spacing: 4) {
                Image(systemName: downloads.activeCount > 0 ? "arrow.down.circle.fill" : "arrow.down.circle")
                    .foregroundStyle(statusColor)
                if downloads.activeCount > 0 {
                    Text("\(downloads.activeCount)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(statusColor)
                } else if let message = downloads.message {
                    Text(message)
                        .lineLimit(1)
                        .frame(maxWidth: 180)
                        .foregroundStyle(statusColor)
                }
            }
        }
        .buttonStyle(.borderless)
        .disabled(downloads.activeCount > 0)
        .help(downloads.message ?? "Downloads appear here")
    }

    private var statusColor: Color {
        switch downloads.state {
        case .idle: return .cyan
        case .downloading: return .orange
        case .succeeded: return .green
        case .failed: return .red
        }
    }
}

private struct BrowserPage: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab

    var body: some View {
        WebView(browser: browser, tab: tab)
            .id("\(tab.id.uuidString)-\(tab.webViewGeneration)")
    }
}

struct WebView: NSViewRepresentable {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab

    func makeCoordinator() -> Coordinator {
        Coordinator(browser: browser, tab: tab)
    }

    func makeNSView(context: Context) -> WKWebView {
        if let existing = tab.webView {
            existing.navigationDelegate = context.coordinator
            existing.uiDelegate = context.coordinator
            return existing
        }

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = browser.privateMode ? .nonPersistent() : .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = browser.javaScriptEnabled
        configuration.preferences.isFraudulentWebsiteWarningEnabled = !browser.unrestrictedBrowsing
        DeveloperCapture.install(
            in: configuration.userContentController,
            tab: tab,
            consoleEnabled: browser.consoleEnabled,
            networkEnabled: browser.networkInspectionEnabled
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        tab.retain(webView)
        if browser.blockingEnabled {
            ContentBlocker.install(in: webView) { loadInitialPage(in: webView) }
        } else {
            loadInitialPage(in: webView)
        }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    private func loadInitialPage(in webView: WKWebView) {
        guard let initialURL = URL(string: tab.address) else { return }
        webView.load(URLRequest(url: initialURL))
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let browser: BrowserModel
        private let tab: BrowserTab

        init(browser: BrowserModel, tab: BrowserTab) {
            self.browser = browser
            self.tab = tab
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { tab.sync(from: webView) }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            tab.sync(from: webView)
            browser.applyAppearance(to: webView)
            if browser.applicationInspectionEnabled {
                tab.refreshApplicationData()
            }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { tab.sync(from: webView) }
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { tab.sync(from: webView) }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { tab.recoverWebContent() }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(navigationAction.shouldPerformDownload ? .download : .allow)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            let disposition = (navigationResponse.response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Content-Disposition")?
                .lowercased()
            let isAttachment = disposition?.contains("attachment") == true
            if browser.networkInspectionEnabled,
               let url = navigationResponse.response.url?.absoluteString {
                let status = (navigationResponse.response as? HTTPURLResponse)?.statusCode ?? 0
                tab.appendNetwork(method: "GET", url: url, status: status, duration: 0, kind: "document")
            }
            decisionHandler(!navigationResponse.canShowMIMEType || isAttachment ? .download : .allow)
        }

        func webView(
            _ webView: WKWebView,
            navigationAction: WKNavigationAction,
            didBecome download: WKDownload
        ) {
            browser.downloads.begin(download)
        }

        func webView(
            _ webView: WKWebView,
            navigationResponse: WKNavigationResponse,
            didBecome download: WKDownload
        ) {
            browser.downloads.begin(download)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            let popupWebView = WKWebView(frame: .zero, configuration: configuration)
            browser.openTab(with: popupWebView, requestedURL: navigationAction.request.url)
            return popupWebView
        }

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            guard browser.unrestrictedBrowsing,
                  challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
                  let trust = challenge.protectionSpace.serverTrust else {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            completionHandler(.useCredential, URLCredential(trust: trust))
        }
    }
}
