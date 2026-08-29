import SwiftUI

struct BrowserSettingsView: View {
    @ObservedObject var browser: BrowserModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDataClear = false
    @State private var javaScriptSettingsPresented = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()

            Form {
                Section("Privacy") {
                    Toggle("Block known ads and trackers", isOn: $browser.blockingEnabled)
                    Toggle("Enable JavaScript", isOn: $browser.javaScriptEnabled)
                    Toggle("Unrestricted browsing", isOn: $browser.unrestrictedBrowsing)
                    Text("Allows HTTP, accepts invalid HTTPS certificates, and disables WebKit's fraudulent-site warning. Use only when you understand the risk.")
                        .font(.caption)
                        .foregroundStyle(browser.unrestrictedBrowsing ? .orange : .secondary)
                    Text("Private sessions are enabled from the toolbar and are never remembered.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Reading") {
                    Toggle("Darken web pages", isOn: $browser.darkModeEnabled)
                }

                Section("Browser Chrome") {
                    Toggle("Hide tab strip with toolbar", isOn: $browser.hideTabStripWithToolbar)
                    Text("When enabled, the toolbar hide button and Command-Shift-T hide both the address toolbar and tab strip.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Search") {
                    Picker("Search engine", selection: $browser.searchEngine) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.name).tag(engine)
                        }
                    }
                }

                Section("Performance") {
                    Picker("Freeze background tabs", selection: $browser.freezeMinutes) {
                        Text("After 1 minute").tag(1)
                        Text("After 5 minutes").tag(5)
                        Text("After 15 minutes").tag(15)
                        Text("After 30 minutes").tag(30)
                        Text("Never").tag(0)
                    }
                    Text("Frozen tabs release their web content and restore the last URL when selected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Developer Features") {
                    Toggle("JavaScript console", isOn: $browser.consoleEnabled)
                    Button("JavaScript Modules…") {
                        javaScriptSettingsPresented = true
                    }
                    Toggle("Network inspector", isOn: $browser.networkInspectionEnabled)
                    Toggle("Application storage inspector", isOn: $browser.applicationInspectionEnabled)
                    Text("Developer features are off by default. Console and network capture inject page hooks only while enabled; changing either setting reloads open tabs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Website Data") {
                    Button("Clear Website Data…", role: .destructive) {
                        confirmDataClear = true
                    }
                    .disabled(browser.dataClearing)

                    if browser.dataClearing {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Clearing website data…")
                        }
                    } else if let message = browser.dataClearMessage {
                        Label(message, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }

                    Text("Clears cookies, caches, local storage, and browsing data. Local notes and sketches are not affected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Keyboard Shortcuts") {
                    ShortcutHelpRow(action: "Open location", shortcut: "⌘L")
                    ShortcutHelpRow(action: "Quick search", shortcut: "⌘K")
                    ShortcutHelpRow(action: "Copy current URL", shortcut: "⇧⌘C")
                    ShortcutHelpRow(action: "New tab", shortcut: "⌘T")
                    ShortcutHelpRow(action: "Close tab", shortcut: "⌘W")
                    ShortcutHelpRow(action: "Toggle Reader view", shortcut: "⇧⌘R")
                    ShortcutHelpRow(action: "Developer Tools", shortcut: "⌥⌘I")
                    ShortcutHelpRow(action: "Notes and Sketchpad", shortcut: "⇧⌘N")
                    ShortcutHelpRow(action: "Settings", shortcut: "⌘,")
                    ShortcutHelpRow(action: "Show or hide browser chrome", shortcut: "⇧⌘T")
                    Text("This restores the address toolbar and, when configured above, the tab strip.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy Promise") {
                    Text("vindR has no telemetry. Notes remain on this Mac, and terminal and process access always start disabled.")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 560, height: 600)
        .alert("Clear all website data?", isPresented: $confirmDataClear) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Website Data", role: .destructive, action: browser.clearWebsiteData)
        } message: {
            Text("Websites will sign out and open tabs will reload. This cannot be undone.")
        }
        .sheet(isPresented: $javaScriptSettingsPresented) {
            JavaScriptSettingsView(browser: browser)
        }
    }
}

private struct ShortcutHelpRow: View {
    let action: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .accessibilityLabel(shortcutAccessibilityLabel)
        }
    }

    private var shortcutAccessibilityLabel: String {
        shortcut
            .replacingOccurrences(of: "⌘", with: "Command ")
            .replacingOccurrences(of: "⇧", with: "Shift ")
            .replacingOccurrences(of: "⌥", with: "Option ")
    }
}
