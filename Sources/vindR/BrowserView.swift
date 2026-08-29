import SwiftUI
import WebKit

struct BrowserView: View {
    @EnvironmentObject private var browser: BrowserModel
    @FocusState private var addressFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !browser.toolbarHidden {
                TopBarView(browser: browser, tab: browser.selectedTab, addressFocused: $addressFocused)
            } else {
                hiddenToolbarBar
            }
            if (!browser.toolbarHidden || !browser.hideTabStripWithToolbar) && !browser.tabsInSidebar {
                TabStripView(browser: browser)
            }
            MainWorkspaceView(browser: browser)
        }
        .tint(VindRTheme.accentCyan)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .sheet(isPresented: $browser.javaScriptSettingsPresented) {
            JavaScriptSettingsView(browser: browser)
        }
        .sheet(isPresented: $browser.helpPresented) {
            BrowserHelpView()
        }
    }

    private var hiddenToolbarBar: some View {
        HStack {
            Text("vindR")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.45))
            Spacer()
            Button(action: { browser.toolbarHidden = false }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .buttonStyle(ChromeButtonStyle())
            .help("Show toolbar (Cmd-Shift-T)")
        }
        .padding(.leading, 76)
        .padding(.trailing, 10)
        .frame(height: 20)
        .background {
            ZStack {
                VindRTheme.chromeTop
                    .ignoresSafeArea(edges: .top)
                VindRTheme.toolbarGradient
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
    static let chromeTop = Color(red: 52 / 255, green: 59 / 255, blue: 83 / 255)
    static let chromeMiddle = Color(red: 44 / 255, green: 51 / 255, blue: 76 / 255)
    static let chromeBottom = Color(red: 34 / 255, green: 42 / 255, blue: 68 / 255)
    static let sidebarTop = Color(red: 24 / 255, green: 37 / 255, blue: 70 / 255)
    static let sidebarMiddle = Color(red: 18 / 255, green: 28 / 255, blue: 59 / 255)
    static let sidebarHighlight = Color(red: 24 / 255, green: 46 / 255, blue: 65 / 255)
    static let tabBar = Color(red: 22 / 255, green: 33 / 255, blue: 56 / 255)
    static let tabActive = Color(red: 44 / 255, green: 50 / 255, blue: 74 / 255)
    static let tabActiveBorder = Color(red: 70 / 255, green: 74 / 255, blue: 95 / 255)
    static let tabInactiveText = Color(red: 122 / 255, green: 125 / 255, blue: 140 / 255)

    static var windowGradient: some View {
        ZStack {
            bgDeep
            RadialGradient(
                colors: [bgTab.opacity(0.8), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 800
            )
            RadialGradient(
                colors: [accentCyan.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 600
            )
        }
    }

    static var toolbarGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: chromeTop, location: 0),
                .init(color: chromeMiddle, location: 0.5),
                .init(color: chromeBottom, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var tabStripGradient: LinearGradient {
        LinearGradient(colors: [bgTab, bgDeep], startPoint: .top, endPoint: .bottom)
    }

    static var capsuleGradient: LinearGradient {
        LinearGradient(colors: [bgTab, bgDeep], startPoint: .top, endPoint: .bottom)
    }

    static var activeTabGradient: LinearGradient {
        LinearGradient(colors: [tabActive, tabActive], startPoint: .top, endPoint: .bottom)
    }

    static var cardGradient: LinearGradient {
        LinearGradient(colors: [bgTab, bgDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var activeTabBorderGradient: LinearGradient {
        LinearGradient(
            colors: [tabActiveBorder, tabActiveBorder],
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
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(browser.tabs) { tab in
                        TabItemView(browser: browser, tab: tab)
                    }
                }
            }

            Spacer(minLength: 8)

            if browser.downloads.activeCount > 0 || browser.downloads.message != nil {
                DownloadStatusView(downloads: browser.downloads)
            }
            if browser.showFreezeStatus, let deadline = browser.nextFreezeDeadline {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    FreezeStatusPill(deadline: deadline, now: context.date)
                }
            }
            if browser.showJavaScriptStatus {
                Menu {
                    Toggle("Enable page JavaScript", isOn: $browser.javaScriptEnabled)
                    Toggle("Enable JavaScript console", isOn: $browser.consoleEnabled)
                    Divider()
                    Button("JavaScript Settings…") {
                        browser.javaScriptSettingsPresented = true
                    }
                } label: {
                    StatusPill(
                        text: browser.javaScriptEnabled ? "JS: ON" : "JS: OFF",
                        color: browser.javaScriptEnabled ? VindRTheme.accentBlue : Color.white.opacity(0.35)
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background {
            VindRTheme.tabBar
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
        }
    }
}

private struct FreezeStatusPill: View {
    let deadline: Date
    let now: Date

    var body: some View {
        let remaining = max(0, Int(deadline.timeIntervalSince(now).rounded(.up)))
        StatusPill(
            text: String(format: "Freezing in %d:%02d", remaining / 60, remaining % 60),
            color: VindRTheme.accentCyan,
            icon: "pause.fill"
        )
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 7, weight: .bold))
            }
            Text(text)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .frame(height: 21)
        .background(color.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.38), lineWidth: 1))
    }
}

private struct TabItemView: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isSelected ? VindRTheme.tabActiveBorder : VindRTheme.tabInactiveText)
                .frame(width: 6, height: 6)
            Button(action: { browser.select(tab) }) {
                Text(tab.title)
                    .font(.system(size: browser.chromeFontSize, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.white : VindRTheme.tabInactiveText)
                    .lineLimit(1)
                    .frame(maxWidth: 150, alignment: .leading)
            }
            .buttonStyle(.plain)
            if browser.tabs.count > 1 {
                Button(action: { browser.close(tab) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(isSelected ? VindRTheme.tabActiveBorder : VindRTheme.tabInactiveText)
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
                : LinearGradient(colors: [VindRTheme.tabBar, VindRTheme.tabBar], startPoint: .top, endPoint: .bottom),
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
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var isSelected: Bool { tab.id == browser.selectedTabID }
}

private struct TopBarView: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    let addressFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 8) {
            privatePill

            HStack(spacing: 5) {
                Button(action: { tab.webView?.goBack() }) { Image(systemName: "chevron.left") }
                    .disabled(!tab.canGoBack)
                    .help("Back")
                Button(action: { tab.webView?.goForward() }) { Image(systemName: "chevron.right") }
                    .disabled(!tab.canGoForward)
                    .help("Forward")
                Button(action: stopOrReload) {
                    Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
                }
                .help(tab.isLoading ? "Stop" : "Reload")
                Button(action: browser.copyURL) { Image(systemName: "link") }
                    .help("Copy URL (Cmd-Shift-C)")
            }
            .buttonStyle(ChromeButtonStyle())

            addressCapsule

            Button("Go", action: browser.navigate)
                .font(.system(size: browser.chromeFontSize, weight: .semibold))
                .buttonStyle(TopBarTextButtonStyle())
                .keyboardShortcut(.return, modifiers: [])
                .help("Go")

            Button(action: { browser.sidebarVisible.toggle() }) {
                Image(systemName: browser.sidebarVisible ? "sidebar.left" : "sidebar.right")
            }
            .buttonStyle(ChromeButtonStyle())
            .help(browser.sidebarVisible ? "Close sidebar" : "Open sidebar")

            Button(action: { browser.toolbarHidden = true }) {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(ChromeButtonStyle())
            .help("Hide toolbar and expand workspace (Cmd-Shift-T)")

            Button(action: browser.newTab) {
                Image(systemName: "plus")
            }
            .buttonStyle(ChromeButtonStyle())
            .help("New Tab (Cmd-T)")
        }
        // Native macOS traffic lights remain visible via .hiddenTitleBar.
        .padding(.leading, 76)
        .padding(.trailing, 12)
        .frame(height: browser.toolbarHeight)
        .background {
            ZStack {
                VindRTheme.chromeTop
                    .ignoresSafeArea(edges: .top)
                VindRTheme.toolbarGradient
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
    }

    @State private var ledPulsing = false

    private var privatePill: some View {
        Button(action: { browser.privateMode.toggle() }) {
            HStack(spacing: 7) {
                Circle()
                    .fill(privateStatusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: privateStatusColor.opacity(0.8), radius: 8)
                    .scaleEffect(ledPulsing ? 1.08 : 0.92)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: ledPulsing)
                Text(browser.privateMode ? "Private" : "Personal")
                    .font(.system(size: browser.chromeFontSize, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(privateBorderGradient, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help("Switch between private and persistent website storage")
        .onAppear { ledPulsing = true }
    }

    private var addressCapsule: some View {
        HStack(spacing: 7) {
            Image(systemName: tab.address.hasPrefix("https://") ? "lock.fill" : "magnifyingglass")
                .font(.system(size: 9))
                .foregroundStyle(tab.address.hasPrefix("https://") ? VindRTheme.accentBlue : Color.white.opacity(0.42))
            TextField("Search or enter address", text: $tab.address)
                .textFieldStyle(.plain)
                .font(.system(size: browser.chromeFontSize))
                .foregroundStyle(Color.white.opacity(0.72))
                .focused(addressFocused)
                .onSubmit(browser.navigate)
            if !tab.address.isEmpty {
                Button(action: {
                    tab.address = ""
                    addressFocused.wrappedValue = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.white.opacity(0.34))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: min(36, max(28, browser.toolbarHeight - 18)))
        .background(VindRTheme.capsuleGradient, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(VindRTheme.borderGradient, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
        .shadow(color: addressFocused.wrappedValue ? VindRTheme.accentCyan.opacity(0.15) : .clear, radius: 8)
    }

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

private struct TopBarTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white.opacity(0.82))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [Color.white.opacity(0.15), Color.white.opacity(0.08)]
                        : [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
    }
}

private struct MainWorkspaceView: View {
    @ObservedObject var browser: BrowserModel

    var body: some View {
        HStack(spacing: 0) {
            if browser.sidebarVisible {
                WorkspaceSidebarView(browser: browser)
                    .frame(width: 220)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1)
            }

            HSplitView {
                BrowserPage(browser: browser, tab: browser.selectedTab)
                    .frame(minWidth: 320)

                if browser.toolsSidePanelPresented {
                    BrowserToolsView(
                        browser: browser,
                        tools: browser.tools,
                        minimumWidth: 480,
                        closeAction: { browser.toolsSidePanelPresented = false }
                    )
                    .frame(idealWidth: 560, maxWidth: 720)
                }
            }
        }
        .background {
            ZStack {
                VindRTheme.cardGradient
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.3), radius: 6)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}

private struct WorkspaceSidebarView: View {
    @ObservedObject var browser: BrowserModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if browser.tabsInSidebar {
                HStack {
                    sidebarHeading("TABS")
                    Spacer()
                    Button(action: browser.newTab) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(ChromeButtonStyle())
                    .help("New Tab (Cmd-T)")
                }

                ScrollView {
                    VStack(spacing: 3) {
                        ForEach(browser.tabs) { tab in
                            SidebarTabRow(browser: browser, tab: tab)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }

            sidebarHeading("TOOLS")
                .padding(.top, browser.tabsInSidebar ? 8 : 0)

            SidebarCardButton(
                title: "Notes / sketchpad",
                detail: "Stored locally on this Mac",
                icon: "square.and.pencil",
                fontSize: browser.chromeFontSize,
                action: { browser.notesPresented = true }
            )
            SidebarCardButton(
                title: "Developer tools",
                detail: browser.developerToolsPresentation.name,
                icon: "wrench.and.screwdriver",
                fontSize: browser.chromeFontSize,
                action: openDeveloperTools
            )
            SidebarCardButton(
                title: "Settings",
                detail: "Appearance, privacy and shortcuts",
                icon: "gearshape",
                fontSize: browser.chromeFontSize,
                action: { browser.settingsPresented = true }
            )
            SidebarCardButton(
                title: "Help",
                detail: "User guide and keyboard shortcuts",
                icon: "questionmark.circle",
                fontSize: browser.chromeFontSize,
                action: { browser.helpPresented = true }
            )

            Spacer(minLength: 12)
        }
        .padding(12)
        .background {
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: VindRTheme.sidebarTop, location: 0),
                        .init(color: VindRTheme.sidebarMiddle, location: 0.5),
                        .init(color: VindRTheme.tabBar, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    colors: [VindRTheme.sidebarHighlight, .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 240
                )
            }
        }
    }

    private func sidebarHeading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: max(8, browser.chromeFontSize - 2), weight: .medium, design: .monospaced))
            .tracking(1.5)
            .foregroundStyle(Color.white.opacity(0.32))
            .padding(.horizontal, 7)
            .padding(.vertical, 9)
    }

    private func openDeveloperTools() {
        browser.prepareDeveloperTools()
        if browser.developerToolsPresentation == .window {
            openWindow(id: DeveloperToolsWindow.id)
        }
    }
}

private struct SidebarTabRow: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isSelected ? VindRTheme.tabActiveBorder : VindRTheme.tabInactiveText)
                .frame(width: 6, height: 6)
            Button(action: { browser.select(tab) }) {
                Text(tab.title)
                    .font(.system(size: browser.chromeFontSize, weight: isSelected ? .medium : .regular))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            if browser.tabs.count > 1 {
                Button(action: { browser.close(tab) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(isSelected ? Color.white : VindRTheme.tabInactiveText)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(isSelected ? VindRTheme.tabActive : VindRTheme.tabBar, in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? VindRTheme.tabActiveBorder : .clear, lineWidth: 1))
    }

    private var isSelected: Bool { tab.id == browser.selectedTabID }
}

private struct SidebarCardButton: View {
    let title: String
    let detail: String
    let icon: String
    let fontSize: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: fontSize))
                    .foregroundStyle(VindRTheme.accentBlue.opacity(0.75))
                    .frame(width: 14)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                    Text(detail)
                        .font(.system(size: max(8, fontSize - 2)))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
            .background {
                ZStack {
                    VindRTheme.cardGradient
                    RoundedRectangle(cornerRadius: 7).fill(.ultraThinMaterial).opacity(0.45)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.3), radius: 6)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 7)
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
            .background(VindRTheme.windowGradient)
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
        webView.underPageBackgroundColor = NSColor(red: 5 / 255, green: 14 / 255, blue: 46 / 255, alpha: 1)
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
