import SwiftUI

struct BrowserHelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let shortcuts = [
        ("Open location", "⌘L"),
        ("Quick search", "⌘K"),
        ("Copy current URL", "⇧⌘C"),
        ("New tab", "⌘T"),
        ("Close tab", "⌘W"),
        ("Toggle Reader view", "⇧⌘R"),
        ("Developer Tools", "⌥⌘I"),
        ("Notes and Sketchpad", "⇧⌘N"),
        ("Settings", "⌘,"),
        ("Show or hide toolbar", "⇧⌘T")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("vindR Help")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    helpSection(
                        "Browse and Search",
                        "Enter a URL or search phrase in the top field, then press Return or click Go. The top bar also provides private-mode, navigation, reload, Copy URL, sidebar, toolbar, and new-tab controls."
                    )
                    helpSection(
                        "Tabs and Freezing",
                        "Create, select, and close tabs from the top tab row or move tabs into the sidebar from Settings. Background tabs release their web content after the configured interval and restore their last URL when selected."
                    )
                    helpSection(
                        "Privacy and Reading",
                        "Private mode uses non-persistent WebKit storage. Settings controls blocking, JavaScript, unrestricted browsing, dark-page styling, Reader behavior, and website-data clearing. vindR collects no telemetry."
                    )
                    helpSection(
                        "Local Tools",
                        "Notes and sketches save automatically on this Mac. Developer Tools provide opt-in Console, Network, Application, Terminal, and Process views. Terminal and process access require explicit session permission."
                    )
                    helpSection(
                        "Downloads",
                        "Choose a destination in the native save dialog. Download progress and completion appear in the tab/status row."
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Keyboard Shortcuts")
                            .font(.headline)
                        ForEach(shortcuts.indices, id: \.self) { index in
                            let shortcut = shortcuts[index]
                            HStack {
                                Text(shortcut.0)
                                Spacer()
                                Text(shortcut.1)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel(accessibleShortcut(shortcut.1))
                            }
                            Divider()
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 700, alignment: .leading)
            }
        }
        .frame(width: 720, height: 650)
    }

    private func helpSection(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.headline)
            Text(text)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func accessibleShortcut(_ shortcut: String) -> String {
        shortcut
            .replacingOccurrences(of: "⌘", with: "Command ")
            .replacingOccurrences(of: "⇧", with: "Shift ")
            .replacingOccurrences(of: "⌥", with: "Option ")
    }
}
