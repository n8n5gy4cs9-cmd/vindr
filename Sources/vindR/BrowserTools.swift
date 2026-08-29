import Foundation
import SwiftUI
import WebKit

enum BrowserTool: String, CaseIterable, Identifiable {
    case console = "Console"
    case network = "Network"
    case application = "Application"
    case terminal = "Terminal"
    case processes = "Processes"

    var id: Self { self }
}

@MainActor
final class BrowserToolsModel: ObservableObject {
    @Published var selection = BrowserTool.console
    @Published var terminalPermission = false
    @Published var processPermission = false
    @Published var command = ""
    @Published private(set) var terminalOutput = ""
    @Published private(set) var terminalRunning = false
    @Published private(set) var processOutput = ""
    @Published private(set) var processLoading = false

    private var terminalProcess: Process?
    private var terminalPipe: Pipe?
    private var processTask: Task<Void, Never>?

    func runCommand() {
        let input = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard terminalPermission, !terminalRunning, !input.isEmpty else { return }

        terminalOutput += "$ \(input)\n"
        command = ""

        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", input]
        process.standardOutput = pipe
        process.standardError = pipe
        terminalProcess = process
        terminalPipe = pipe
        terminalRunning = true

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.appendTerminal(chunk)
            }
        }

        process.terminationHandler = { [weak self, weak pipe] process in
            pipe?.fileHandleForReading.readabilityHandler = nil
            let remainingData = pipe?.fileHandleForReading.readDataToEndOfFile() ?? Data()
            let remainingText = String(data: remainingData, encoding: .utf8) ?? ""
            Task { @MainActor [weak self] in
                self?.appendTerminal(remainingText)
                self?.appendTerminal("\n[exit \(process.terminationStatus)]\n")
                self?.terminalRunning = false
                self?.terminalProcess = nil
                self?.terminalPipe = nil
            }
        }

        do {
            try process.run()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            appendTerminal("[failed to start: \(error.localizedDescription)]\n")
            terminalRunning = false
            terminalProcess = nil
            terminalPipe = nil
        }
    }

    func stopCommand() {
        terminalProcess?.terminate()
    }

    func clearTerminal() {
        terminalOutput = ""
    }

    func disableTerminal() {
        stopCommand()
        terminalPermission = false
        command = ""
        terminalOutput = ""
    }

    func disableProcessInspection() {
        processTask?.cancel()
        processTask = nil
        processPermission = false
        processOutput = ""
        processLoading = false
    }

    func refreshProcesses() {
        guard processPermission, !processLoading else { return }
        processLoading = true
        processTask = Task {
            let result = await Task.detached(priority: .userInitiated) {
                Self.readProcesses()
            }.value
            guard !Task.isCancelled, processPermission else { return }
            processOutput = result
            processLoading = false
            processTask = nil
        }
    }

    private func appendTerminal(_ text: String) {
        guard terminalPermission else { return }
        terminalOutput += text
        if terminalOutput.count > 100_000 {
            terminalOutput.removeFirst(terminalOutput.count - 100_000)
        }
    }

    nonisolated private static func readProcesses() -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,pcpu=,pmem=,comm="]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                return "Process inspection failed (exit \(process.terminationStatus))."
            }
            return String(data: data, encoding: .utf8) ?? "Process output was not valid UTF-8."
        } catch {
            return "Process inspection failed: \(error.localizedDescription)"
        }
    }
}

struct BrowserToolsView: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tools: BrowserToolsModel
    var minimumWidth: CGFloat = 680
    var closeAction: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Tool", selection: $tools.selection) {
                    ForEach(BrowserTool.allCases) { tool in
                        Text(tool.rawValue).tag(tool)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 560)

                Spacer()
                Button("Done", action: close)
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.12), Color.cyan.opacity(0.09), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            Divider()

            Group {
                switch tools.selection {
                case .console:
                    ConsoleToolView(browser: browser, tab: browser.selectedTab)
                case .network:
                    NetworkToolView(browser: browser, tab: browser.selectedTab)
                case .application:
                    ApplicationToolView(browser: browser, tab: browser.selectedTab)
                case .terminal:
                    TerminalToolView(tools: tools)
                case .processes:
                    ProcessToolView(tools: tools)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: minimumWidth, minHeight: 440)
    }

    private func close() {
        if let closeAction {
            closeAction()
        } else {
            dismiss()
        }
    }
}

private struct ConsoleToolView: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    @State private var levelFilter = ConsoleLevelFilter.all
    @State private var search = ""
    @State private var command = ""
    @State private var historyOffset = 0
    @State private var javaScriptSettingsPresented = false

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        if !browser.consoleEnabled {
            permissionView(
                icon: "chevron.left.forwardslash.chevron.right",
                title: "JavaScript console is off",
                warning: "Enable it to capture page messages and evaluate JavaScript. The setting persists, including across reloads and redirects; enabling it reloads open tabs once.",
                button: "Enable Console"
            ) {
                browser.consoleEnabled = true
            }
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Toggle("Console", isOn: $browser.consoleEnabled)
                        .toggleStyle(.switch)
                        .fixedSize()
                    Button(action: { javaScriptSettingsPresented = true }) {
                        Image(systemName: "switch.2")
                    }
                    .help("JavaScript Modules")
                    Picker("Level", selection: $levelFilter) {
                        ForEach(ConsoleLevelFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 110)
                    TextField("Filter messages", text: $search)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 220)
                    Spacer()
                    Text("\(filteredEntries.count) / \(tab.consoleEntries.count)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Button("Clear", action: tab.clearConsole)
                        .disabled(tab.consoleEntries.isEmpty)
                }
                .padding(10)
                Divider()

                if filteredEntries.isEmpty {
                    toolPlaceholder(
                        icon: "text.bubble",
                        title: tab.consoleEntries.isEmpty ? "Console is listening" : "No matching messages",
                        detail: tab.consoleEntries.isEmpty
                            ? "Page messages and JavaScript results will remain here across reloads and redirects."
                            : "Change the level or text filter to see other entries."
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(filteredEntries) { entry in
                                ConsoleEntryRow(entry: entry, time: Self.timeFormatter.string(from: entry.date))
                            }
                        }
                        .padding()
                    }
                }

                Divider()
                HStack(spacing: 7) {
                    Text("›")
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(.cyan)
                    TextField("JavaScript expression", text: $command)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit(runCommand)
                        .disabled(!browser.consoleEvaluationEnabled)
                    Button(action: previousCommand) { Image(systemName: "chevron.up") }
                        .help("Previous command")
                        .disabled(tab.consoleCommandHistory.isEmpty)
                    Button(action: nextCommand) { Image(systemName: "chevron.down") }
                        .help("Next command")
                        .disabled(historyOffset == 0)
                    Button("Run", action: runCommand)
                        .keyboardShortcut(.return, modifiers: .command)
                        .disabled(
                            !browser.consoleEvaluationEnabled
                                || command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                }
                .padding(10)
                .background(Color.cyan.opacity(0.04))
            }
            .sheet(isPresented: $javaScriptSettingsPresented) {
                JavaScriptSettingsView(browser: browser)
            }
        }
    }

    private var filteredEntries: [ConsoleEntry] {
        tab.consoleEntries.filter { entry in
            levelFilter.includes(entry)
                && (search.isEmpty || entry.message.localizedCaseInsensitiveContains(search))
        }
    }

    private func runCommand() {
        guard browser.consoleEvaluationEnabled else { return }
        let input = command
        command = ""
        historyOffset = 0
        tab.evaluateConsoleCommand(input)
    }

    private func previousCommand() {
        historyOffset = min(tab.consoleCommandHistory.count, historyOffset + 1)
        command = tab.consoleCommandHistory[tab.consoleCommandHistory.count - historyOffset]
    }

    private func nextCommand() {
        guard historyOffset > 0 else { return }
        historyOffset -= 1
        command = historyOffset == 0
            ? ""
            : tab.consoleCommandHistory[tab.consoleCommandHistory.count - historyOffset]
    }
}

private struct ConsoleEntryRow: View {
    let entry: ConsoleEntry
    let time: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(time)
                .foregroundStyle(.cyan.opacity(0.72))
            Text(label)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .frame(width: 74, alignment: .leading)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(color.opacity(0.13))
                .clipShape(Capsule())
            Text(entry.message)
                .textSelection(.enabled)
                .foregroundStyle(entry.level == "error" ? Color.red : .primary)
        }
        .font(.system(.caption, design: .monospaced))
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var label: String {
        switch entry.level {
        case "command": return "INPUT"
        case "result": return "RESULT"
        default: return entry.method.uppercased()
        }
    }

    private var color: Color {
        switch entry.level {
        case "error": return .red
        case "warn": return .orange
        case "debug": return .blue
        case "info": return .purple
        case "command": return .cyan
        case "result": return .green
        default: return .primary
        }
    }
}

private struct NetworkToolView: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    @State private var search = ""

    var body: some View {
        if !browser.networkInspectionEnabled {
            permissionView(
                icon: "network",
                title: "Network inspector is off",
                warning: "Enable it to record document, fetch, XHR, script, stylesheet, image, and other page requests. Capture persists across reloads and redirects.",
                button: "Enable Network Inspector"
            ) {
                browser.networkInspectionEnabled = true
            }
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Toggle("Network", isOn: $browser.networkInspectionEnabled)
                        .toggleStyle(.switch)
                        .fixedSize()
                    TextField("Filter URL, method, type, or status", text: $search)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                    Spacer()
                    Text("\(filteredEntries.count) / \(tab.networkEntries.count) requests")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Button("Clear", action: tab.clearNetwork)
                        .disabled(tab.networkEntries.isEmpty)
                }
                .padding(10)
                Divider()

                if filteredEntries.isEmpty {
                    toolPlaceholder(
                        icon: "arrow.left.arrow.right",
                        title: tab.networkEntries.isEmpty ? "Network capture is listening" : "No matching requests",
                        detail: "Reload the page to capture its initial document and resources."
                    )
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            NetworkHeaderRow()
                            Divider()
                            ForEach(filteredEntries) { entry in
                                NetworkEntryRow(entry: entry)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }

    private var filteredEntries: [NetworkEntry] {
        guard !search.isEmpty else { return tab.networkEntries }
        return tab.networkEntries.filter { entry in
            [entry.method, entry.url, entry.kind, String(entry.status)]
                .contains { $0.localizedCaseInsensitiveContains(search) }
        }
    }
}

private struct NetworkHeaderRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("STATUS").frame(width: 54, alignment: .trailing)
            Text("METHOD").frame(width: 54, alignment: .leading)
            Text("TYPE").frame(width: 84, alignment: .leading)
            Text("TIME").frame(width: 68, alignment: .trailing)
            Text("URL").frame(minWidth: 420, alignment: .leading)
        }
        .font(.system(.caption, design: .monospaced, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
    }
}

private struct NetworkEntryRow: View {
    let entry: NetworkEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.status == 0 ? "—" : String(entry.status))
                .foregroundStyle(statusColor)
                .frame(width: 54, alignment: .trailing)
            Text(entry.method).foregroundStyle(.cyan).frame(width: 54, alignment: .leading)
            Text(entry.kind).foregroundStyle(.purple).frame(width: 84, alignment: .leading).lineLimit(1)
            Text(entry.duration == 0 ? "—" : String(format: "%.0f ms", entry.duration))
                .foregroundStyle(.secondary)
                .frame(width: 68, alignment: .trailing)
            Text(entry.url).frame(minWidth: 420, alignment: .leading).lineLimit(1)
        }
        .font(.system(.caption, design: .monospaced))
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(statusColor.opacity(entry.status >= 400 ? 0.08 : 0.025))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var statusColor: Color {
        switch entry.status {
        case 200..<300: return .green
        case 300..<400: return .orange
        case 400...: return .red
        default: return .secondary
        }
    }
}

private struct ApplicationToolView: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    @State private var search = ""

    var body: some View {
        Group {
            if !browser.applicationInspectionEnabled {
                permissionView(
                    icon: "externaldrive.connected.to.line.below",
                    title: "Application inspector is off",
                    warning: "Enable it to inspect this page's script-visible cookies, local storage, and session storage on demand.",
                    button: "Enable Application Inspector"
                ) {
                    browser.applicationInspectionEnabled = true
                    tab.refreshApplicationData()
                }
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Toggle("Application", isOn: $browser.applicationInspectionEnabled)
                            .toggleStyle(.switch)
                            .fixedSize()
                        TextField("Filter keys or values", text: $search)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 260)
                        Spacer()
                        if let origin = tab.applicationSnapshot?.origin {
                            Text(origin).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Button(action: tab.refreshApplicationData) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(tab.applicationLoading)
                    }
                    .padding(10)
                    Divider()

                    if tab.applicationLoading {
                        ProgressView("Reading page storage…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = tab.applicationError {
                        toolPlaceholder(icon: "exclamationmark.triangle", title: "Application data unavailable", detail: error)
                    } else if let snapshot = tab.applicationSnapshot {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                StorageSection(title: "Cookies", detail: "Script-visible only", items: snapshot.cookies, search: search, color: .orange)
                                StorageSection(title: "Local Storage", detail: "Persists for this origin", items: snapshot.localStorage, search: search, color: .purple)
                                StorageSection(title: "Session Storage", detail: "Lives for this tab session", items: snapshot.sessionStorage, search: search, color: .cyan)
                            }
                            .padding()
                        }
                    } else {
                        toolPlaceholder(icon: "shippingbox", title: "No application snapshot", detail: "Click Refresh to read page storage.")
                    }
                }
            }
        }
        .onAppear {
            if browser.applicationInspectionEnabled, tab.applicationSnapshot == nil {
                tab.refreshApplicationData()
            }
        }
    }
}

private struct StorageSection: View {
    let title: String
    let detail: String
    let items: [StorageItem]
    let search: String
    let color: Color

    private var visibleItems: [StorageItem] {
        guard !search.isEmpty else { return items }
        return items.filter {
            $0.key.localizedCaseInsensitiveContains(search)
                || $0.value.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.headline).foregroundStyle(color)
                Text(detail).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(visibleItems.count)").foregroundStyle(.secondary).monospacedDigit()
            }
            if visibleItems.isEmpty {
                Text(items.isEmpty ? "No data" : "No matches")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(visibleItems) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Text(item.key)
                            .fontWeight(.semibold)
                            .foregroundStyle(color)
                            .frame(width: 190, alignment: .leading)
                        Text(item.value)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .padding(7)
                    .background(color.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
    }
}

private struct TerminalToolView: View {
    @ObservedObject var tools: BrowserToolsModel

    var body: some View {
        if !tools.terminalPermission {
            permissionView(
                icon: "terminal",
                title: "Shell access is off",
                warning: "Commands run through /bin/zsh with your macOS user privileges. They can change or delete files and access data available to vindR.",
                button: "Allow for This Session"
            ) {
                tools.terminalPermission = true
            }
        } else {
            VStack(spacing: 0) {
                HStack {
                    Label("Commands run with your user privileges", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("Clear", action: tools.clearTerminal)
                    Button("Disable", action: tools.disableTerminal)
                }
                .padding(10)
                Divider()

                ScrollView {
                    TerminalOutputView(output: tools.terminalOutput)
                }
                .background(Color.black.opacity(0.035))

                Divider()
                HStack {
                    TextField("Shell command", text: $tools.command)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(tools.runCommand)
                        .disabled(tools.terminalRunning)
                    if tools.terminalRunning {
                        Button("Stop", action: tools.stopCommand)
                    } else {
                        Button("Run", action: tools.runCommand)
                            .keyboardShortcut(.return, modifiers: .command)
                            .disabled(tools.command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding()
            }
        }
    }
}

private struct ProcessToolView: View {
    @ObservedObject var tools: BrowserToolsModel

    var body: some View {
        if !tools.processPermission {
            permissionView(
                icon: "list.bullet.rectangle",
                title: "Process inspection is off",
                warning: "The process list can reveal application names and command paths. It is read only and is never stored or transmitted.",
                button: "Allow for This Session"
            ) {
                tools.processPermission = true
                tools.refreshProcesses()
            }
        } else {
            VStack(spacing: 0) {
                HStack {
                    Label("Live process snapshot", systemImage: "waveform.path.ecg")
                        .foregroundStyle(.purple)
                    Spacer()
                    Button("Disable", action: tools.disableProcessInspection)
                    Button(action: tools.refreshProcesses) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(tools.processLoading)
                }
                .padding(10)
                Divider()
                ScrollView([.horizontal, .vertical]) {
                    ProcessSnapshotView(output: tools.processOutput)
                }
                if tools.processLoading {
                    ProgressView()
                        .padding(.bottom, 8)
                }
            }
        }
    }
}

private struct TerminalOutputView: View {
    let output: String

    private var lines: [String] {
        let text = output.isEmpty ? "Enter a command below." : output
        let withoutANSI = text.replacingOccurrences(
            of: "\u{001B}\\[[0-9;]*[A-Za-z]",
            with: "",
            options: .regularExpression
        )
        return withoutANSI.components(separatedBy: .newlines)
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 3) {
            ForEach(Array(lines.enumerated()), id: \.offset) { item in
                Text(item.element.isEmpty ? " " : item.element)
                    .foregroundStyle(color(for: item.element))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func color(for line: String) -> Color {
        let lowercased = line.lowercased()
        if line.hasPrefix("$ ") { return .cyan }
        if line.hasPrefix("[exit 0]") { return .green }
        if lowercased.contains("error") || lowercased.contains("failed") || line.hasPrefix("[exit ") { return .red }
        if lowercased.contains("warning") { return .orange }
        return .primary
    }
}

private struct ProcessSnapshotView: View {
    let output: String

    private struct Row: Identifiable {
        let id: Int
        let pid: String
        let cpu: String
        let memory: String
        let command: String
    }

    private var rows: [Row] {
        output.split(separator: "\n").enumerated().compactMap { index, line in
            let columns = line.split(maxSplits: 3, whereSeparator: \.isWhitespace)
            guard columns.count == 4 else { return nil }
            return Row(
                id: index,
                pid: String(columns[0]),
                cpu: String(columns[1]),
                memory: String(columns[2]),
                command: String(columns[3])
            )
        }
    }

    var body: some View {
        if output.isEmpty {
            Text("No process data yet.")
                .foregroundStyle(.secondary)
                .padding()
        } else if rows.isEmpty {
            Text(output)
                .foregroundStyle(.red)
                .font(.system(.caption, design: .monospaced))
                .padding()
        } else {
            LazyVStack(alignment: .leading, spacing: 2) {
                processRow(pid: "PID", cpu: "CPU %", memory: "MEM %", command: "COMMAND", header: true)
                Divider()
                ForEach(rows) { row in
                    processRow(pid: row.pid, cpu: row.cpu, memory: row.memory, command: row.command)
                        .background(row.id.isMultiple(of: 2) ? Color.purple.opacity(0.045) : Color.clear)
                }
            }
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .padding()
        }
    }

    private func processRow(
        pid: String,
        cpu: String,
        memory: String,
        command: String,
        header: Bool = false
    ) -> some View {
        HStack(spacing: 14) {
            Text(pid).foregroundStyle(header ? Color.secondary : .cyan).frame(width: 58, alignment: .trailing)
            Text(cpu).foregroundStyle(header ? Color.secondary : usageColor(cpu)).frame(width: 58, alignment: .trailing)
            Text(memory).foregroundStyle(header ? Color.secondary : .purple).frame(width: 58, alignment: .trailing)
            Text(command).foregroundStyle(header ? Color.secondary : .primary).frame(minWidth: 360, alignment: .leading)
        }
        .fontWeight(header ? .semibold : .regular)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
    }

    private func usageColor(_ value: String) -> Color {
        let usage = Double(value) ?? 0
        if usage >= 50 { return .red }
        if usage >= 10 { return .orange }
        return .green
    }
}

private func permissionView(
    icon: String,
    title: String,
    warning: String,
    button: String,
    action: @escaping () -> Void
) -> some View {
    VStack(spacing: 14) {
        Image(systemName: icon)
            .font(.system(size: 36))
            .foregroundStyle(.secondary)
        Text(title)
            .font(.title2)
        Text(warning)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 480)
        Button(button, action: action)
            .keyboardShortcut(.defaultAction)
    }
    .padding(36)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

private func toolPlaceholder(icon: String, title: String, detail: String) -> some View {
    VStack(spacing: 12) {
        Image(systemName: icon)
            .font(.system(size: 32))
            .foregroundStyle(.secondary)
        Text(title)
            .font(.headline)
        Text(detail)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 480)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
