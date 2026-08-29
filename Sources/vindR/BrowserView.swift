import SwiftUI
import WebKit

struct BrowserView: View {
    @EnvironmentObject private var browser: BrowserModel
    @FocusState private var addressFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !browser.toolbarHidden {
                ToolbarView(browser: browser, tab: browser.selectedTab, addressFocused: $addressFocused)
            } else {
                hiddenToolbarBar
            }
            if !browser.toolbarHidden || !browser.hideTabStripWithToolbar {
                TabStripView(browser: browser)
            }
            BrowserPage(browser: browser, tab: browser.selectedTab)
        }
        .tint(VindRTheme.accentCyan)
        .background(VindRTheme.windowGradient)
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

    private var hiddenToolbarBar: some View {
        HStack {
            Spacer()
            Button(action: { browser.toolbarHidden = false }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .buttonStyle(ChromeButtonStyle())
            .help("Show toolbar (Cmd-Shift-T)")
        }
        .padding(.horizontal, 10)
        .frame(height: 20)
        .background {
            ZStack {
                VindRTheme.toolbarGradient
                Rectangle().fill(.ultraThinMaterial).opacity(0.6)
            }
        }
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
        }
    }
}

private enum VindRTheme {
    static let bgDeep = Color(hex: "#050E2E")
    static let bgTab = Color(hex: "#0A1B4D")
    static let accentCyan = Color(hex: "#22F5C5")
    static let accentBlue = Color(hex: "#2DD4FF")
    static let accentBright = Color(hex: "#3A7BFF")
    static let text = Color(hex: "#F0F4FF")
    static let redLED = Color(hex: "#FF3B30")

    static var windowGradient: some View {
        ZStack {
            bgDeep
            RadialGradient(
                colors: [bgTab.opacity(0.8), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 800
            )
            RadialGradient(
                colors: [accentCyan.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 600
            )
        }
    }

    static var toolbarGradient: LinearGradient {
        LinearGradient(colors: [bgDeep, bgTab.opacity(0.9)], startPoint: .top, endPoint: .bottom)
    }

    static var tabStripGradient: LinearGradient {
        LinearGradient(colors: [bgTab, bgDeep], startPoint: .top, endPoint: .bottom)
    }

    static var capsuleGradient: LinearGradient {
        LinearGradient(colors: [bgTab, bgDeep], startPoint: .top, endPoint: .bottom)
    }

    static var activeTabGradient: LinearGradient {
        LinearGradient(colors: [bgTab.opacity(0.8), bgDeep], startPoint: .top, endPoint: .bottom)
    }

    static var activeTabBorderGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.10), Color.white.opacity(0.03)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cyanBlueGradient: LinearGradient {
        LinearGradient(colors: [accentCyan, accentBlue], startPoint: .leading, endPoint: .trailing)
    }

    static var borderGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

private struct TabStripView: View {
    @ObservedObject var browser: BrowserModel

    var body: some View {
        HStack(spacing: 3) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(browser.tabs) { tab in
                        TabItemView(browser: browser, tab: tab)
                    }
                }
            }
            Button(action: browser.newTab) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(ChromeButtonStyle())
            .help("New Tab (Cmd-T)")
        }
        .padding(.horizontal, 8)
        .frame(height: 32)
        .background {
            ZStack {
                VindRTheme.tabStripGradient
                Rectangle().fill(.ultraThinMaterial).opacity(0.4)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
        }
    }
}

private struct TabItemView: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(VindRTheme.accentBlue.opacity(isSelected ? 1 : 0.3))
                .frame(width: 6, height: 6)
            Button(action: { browser.select(tab) }) {
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(Color.white.opacity(isSelected ? 1 : 0.6))
                    .lineLimit(1)
                    .frame(maxWidth: 150, alignment: .leading)
            }
            .buttonStyle(.plain)
            if browser.tabs.count > 1 {
                Button(action: { browser.close(tab) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            isSelected
                ? VindRTheme.activeTabGradient
                : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isSelected
                        ? VindRTheme.activeTabBorderGradient
                        : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        }
        .overlay(alignment: .bottom) {
            if isSelected {
                Rectangle()
                    .fill(VindRTheme.cyanBlueGradient)
                    .frame(height: 2)
                    .shadow(color: VindRTheme.accentCyan.opacity(0.6), radius: 6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var isSelected: Bool { tab.id == browser.selectedTabID }
}

private struct ToolbarView: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    let addressFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 10) {
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
                    .font(.system(size: 10))
                    .foregroundStyle(tab.address.hasPrefix("https://") ? VindRTheme.accentBlue : Color.gray)
                TextField("Search or enter address", text: $tab.address)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(VindRTheme.text)
                    .focused(addressFocused)
                    .onSubmit(browser.navigate)
                Button(action: {
                    tab.address = ""
                    addressFocused.wrappedValue = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.gray)
                }
                .buttonStyle(.plain)
                .opacity(tab.address.isEmpty ? 0 : 1)
                Button(action: browser.toggleReader) {
                    Image(systemName: "doc.richtext")
                        .foregroundStyle(tab.readerEnabled ? VindRTheme.accentCyan : Color.gray)
                }
                .buttonStyle(.plain)
                .disabled(!browser.javaScriptEnabled && !tab.readerEnabled)
                .help(tab.readerEnabled ? "Exit Reader View" : "Reader View")
            }
            .padding(.horizontal, 12)
            .frame(height: 28)
            .frame(maxWidth: 720)
            .background(VindRTheme.capsuleGradient, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(VindRTheme.borderGradient, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
            .shadow(
                color: addressFocused.wrappedValue ? VindRTheme.accentCyan.opacity(0.15) : .clear,
                radius: 8
            )

            Button(action: browser.navigate) { Image(systemName: "arrow.right") }
                .keyboardShortcut(.return, modifiers: [])
                .help("Go")

            DownloadStatusView(downloads: browser.downloads)

            Button(action: { browser.privateMode.toggle() }) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(privateStatusColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: privateStatusColor.opacity(0.8), radius: 8)
                        .shadow(color: privateStatusColor, radius: 3)
                        .scaleEffect(ledPulsing ? 1.08 : 0.92)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: ledPulsing)
                    Text("PRIVATE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(browser.privateMode ? VindRTheme.accentCyan : Color.white.opacity(0.7))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .frame(width: 76, height: 24)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.black.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(privateBorderGradient, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Private: nonPersistent")
            .onAppear { ledPulsing = true }

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
        .buttonStyle(ChromeButtonStyle())
        .padding(.horizontal, 10)
        // Native macOS traffic lights remain visible via .hiddenTitleBar.
        .padding(.leading, 76)
        .frame(height: 36)
        .background {
            ZStack {
                VindRTheme.toolbarGradient
                Rectangle().fill(.ultraThinMaterial).opacity(0.6)
            }
        }
    }

    @State private var ledPulsing = false

    private var privateStatusColor: Color {
        browser.privateMode ? VindRTheme.accentCyan : VindRTheme.redLED
    }

    private var privateBorderGradient: LinearGradient {
        LinearGradient(
            colors: browser.privateMode
                ? [VindRTheme.accentCyan.opacity(0.8), VindRTheme.accentBlue.opacity(0.8)]
                : [Color.white.opacity(0.1), Color.white.opacity(0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func stopOrReload() {
        if tab.isLoading {
            tab.webView?.stopLoading()
        } else {
            tab.webView?.reload()
        }
    }
}

private struct ChromeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ChromeButtonBody(configuration: configuration)
    }
}

private struct ChromeButtonBody: View {
    let configuration: ChromeButtonStyle.Configuration
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.8))
            .frame(width: 24, height: 22)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [Color.white.opacity(0.15), Color.white.opacity(0.08)]
                        : [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(isHovered ? 0.08 : 0), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            .shadow(color: VindRTheme.accentCyan.opacity(isHovered ? 0.2 : 0), radius: 4)
            .onHover { isHovered = $0 }
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
        .padding(.horizontal, 6)
        .frame(minWidth: 24, minHeight: 22)
        .background(VindRTheme.capsuleGradient, in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(VindRTheme.borderGradient, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
        .shadow(color: statusColor.opacity(0.25), radius: 4)
        .buttonStyle(.plain)
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
            .background(Color(hex: "#1A1A1A"))
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
        configuration.applicationNameForUserAgent = "vindR/0.1"
        configuration.websiteDataStore = browser.privateMode ? .nonPersistent() : .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = browser.javaScriptEnabled
        configuration.preferences.isFraudulentWebsiteWarningEnabled = !browser.unrestrictedBrowsing
        DeveloperCapture.install(
            in: configuration.userContentController,
            tab: tab,
            consoleEnabled: browser.consoleEnabled,
            consoleModules: browser.consoleCaptureModules,
            networkEnabled: browser.networkInspectionEnabled
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.underPageBackgroundColor = NSColor(red: 26 / 255, green: 26 / 255, blue: 26 / 255, alpha: 1)
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
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            guard browser.javaScriptAlertEnabled else {
                completionHandler()
                return
            }
            JavaScriptDialogPresenter.showAlert(message: message, in: webView, completion: completionHandler)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            guard browser.javaScriptConfirmEnabled else {
                completionHandler(false)
                return
            }
            JavaScriptDialogPresenter.showConfirm(message: message, in: webView, completion: completionHandler)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            guard browser.javaScriptPromptEnabled else {
                completionHandler(nil)
                return
            }
            JavaScriptDialogPresenter.showPrompt(
                message: prompt,
                defaultText: defaultText,
                in: webView,
                completion: completionHandler
            )
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
