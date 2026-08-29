import SwiftUI

struct JavaScriptSettingsView: View {
    @ObservedObject var browser: BrowserModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("JavaScript Modules")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()

            Form {
                Section("Runtime") {
                    Toggle("Enable page JavaScript", isOn: $browser.javaScriptEnabled)
                    Toggle("Enable JavaScript console", isOn: $browser.consoleEnabled)
                    Toggle("Allow console command evaluation", isOn: $browser.consoleEvaluationEnabled)
                        .disabled(!browser.consoleEnabled)
                }

                Section("Native Page Dialogs") {
                    Toggle("alert()", isOn: $browser.javaScriptAlertEnabled)
                    Toggle("confirm()", isOn: $browser.javaScriptConfirmEnabled)
                    Toggle("prompt()", isOn: $browser.javaScriptPromptEnabled)
                    Text("Disabled alerts are acknowledged silently. Disabled confirmations return false, and disabled prompts return null.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Console Capture Modules") {
                    Toggle("Messages: log, info, warn, error, debug, clear", isOn: $browser.consoleMessagesEnabled)
                    Toggle("Page errors and rejected promises", isOn: $browser.consolePageErrorsEnabled)
                    Toggle("Diagnostics: assert and trace", isOn: $browser.consoleDiagnosticsEnabled)
                    Toggle("Objects: dir, dirxml, and table", isOn: $browser.consoleObjectsEnabled)
                    Toggle("Counters: count and countReset", isOn: $browser.consoleCountersEnabled)
                    Toggle("Timers: time, timeLog, and timeEnd", isOn: $browser.consoleTimersEnabled)
                    Toggle("Groups: group, groupCollapsed, and groupEnd", isOn: $browser.consoleGroupsEnabled)
                    Toggle("Performance: profile, profileEnd, and timeStamp", isOn: $browser.consolePerformanceEnabled)
                }

                Section("Behavior") {
                    Text("All settings persist. Changing a capture module reloads open tabs only when console capture is active, so disabled modules inject no hooks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 580, height: 610)
    }
}
