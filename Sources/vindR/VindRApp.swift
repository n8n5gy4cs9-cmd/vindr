import AppKit
import SwiftUI

enum DeveloperToolsWindow {
    static let id = "developer-tools"
}

@main
struct VindRApp: App {
    @StateObject private var browser = BrowserModel()

    init() {
        if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let icon = NSImage(contentsOf: url) {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    var body: some Scene {
        WindowGroup {
            BrowserView()
                .environmentObject(browser)
                .frame(minWidth: 640, minHeight: 420)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1280, height: 800)
        .windowStyle(.hiddenTitleBar)
        .commands {
            BrowserCommands(browser: browser)
        }

        Window("Developer Tools", id: DeveloperToolsWindow.id) {
            BrowserToolsView(browser: browser, tools: browser.tools)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 900, height: 650)
    }
}

private struct BrowserCommands: Commands {
    @ObservedObject var browser: BrowserModel
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandMenu("Browser") {
            Button("Open Location") { BrowserNotice.post(BrowserNotice.focusLocation) }
                .keyboardShortcut("l", modifiers: .command)
            Button("Quick Search") { BrowserNotice.post(BrowserNotice.quickSearch) }
                .keyboardShortcut("k", modifiers: .command)
            Button("Copy URL") { browser.copyURL() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            Divider()
            Button("New Tab") { browser.newTab() }
                .keyboardShortcut("t", modifiers: .command)
            Button("Close Tab") { browser.close(browser.selectedTab) }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(browser.tabs.count == 1)
            Button(browser.selectedTab.readerEnabled ? "Exit Reader View" : "Reader View") {
                browser.toggleReader()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            Divider()
            Button("Developer Tools") { openDeveloperTools() }
                .keyboardShortcut("i", modifiers: [.command, .option])
            Menu("Open Developer Tools In") {
                ForEach(DeveloperToolsPresentation.allCases) { presentation in
                    Button(presentation.name) {
                        openDeveloperTools(presentation)
                    }
                }
            }
            Button("Notes and Sketchpad") { browser.notesPresented = true }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            Button("Settings…") { browser.settingsPresented = true }
                .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button(browser.toolbarHidden ? "Show Toolbar" : "Hide Toolbar") {
                browser.toolbarHidden.toggle()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
        }
    }

    private func openDeveloperTools(_ presentation: DeveloperToolsPresentation? = nil) {
        browser.prepareDeveloperTools(presentation)
        if browser.developerToolsPresentation == .window {
            openWindow(id: DeveloperToolsWindow.id)
        }
    }
}
