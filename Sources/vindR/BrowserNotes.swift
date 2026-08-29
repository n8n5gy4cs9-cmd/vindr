import Foundation
import SwiftUI

struct SketchPoint: Codable {
    let x: Double
    let y: Double

    var point: CGPoint { CGPoint(x: x, y: y) }
}

struct SketchStroke: Codable, Identifiable {
    let id: UUID
    var points: [SketchPoint]

    init(id: UUID = UUID(), points: [SketchPoint] = []) {
        self.id = id
        self.points = points
    }
}

private struct NotesDocument: Codable {
    var text: String
    var strokes: [SketchStroke]
}

@MainActor
final class BrowserNotesModel: ObservableObject {
    @Published var text: String {
        didSet { scheduleSave() }
    }
    @Published private(set) var strokes: [SketchStroke] {
        didSet { scheduleSave() }
    }

    private var saveTask: Task<Void, Never>?
    private let fileURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = support.appendingPathComponent("vindR", isDirectory: true)
            .appendingPathComponent("Notes.json")

        if let data = try? Data(contentsOf: fileURL),
           let document = try? JSONDecoder().decode(NotesDocument.self, from: data) {
            text = document.text
            strokes = document.strokes
        } else {
            text = ""
            strokes = []
        }
    }

    func beginStroke(at point: CGPoint) {
        strokes.append(SketchStroke(points: [SketchPoint(x: point.x, y: point.y)]))
    }

    func continueStroke(at point: CGPoint) {
        guard !strokes.isEmpty else {
            beginStroke(at: point)
            return
        }
        strokes[strokes.count - 1].points.append(SketchPoint(x: point.x, y: point.y))
    }

    func undoStroke() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
    }

    func clearSketch() {
        strokes.removeAll()
    }

    func flush() {
        saveTask?.cancel()
        saveTask = nil
        Self.save(text: text, strokes: strokes, to: fileURL)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let text = text
        let strokes = strokes
        let fileURL = fileURL
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await Task.detached(priority: .utility) {
                Self.save(text: text, strokes: strokes, to: fileURL)
            }.value
        }
    }

    nonisolated private static func save(text: String, strokes: [SketchStroke], to fileURL: URL) {
        let document = NotesDocument(text: text, strokes: strokes)
        guard let data = try? JSONEncoder().encode(document) else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Notes stay in memory if local storage is temporarily unavailable.
        }
    }
}

struct BrowserNotesView: View {
    @ObservedObject var notes: BrowserNotesModel
    @Environment(\.dismiss) private var dismiss
    @State private var selection = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Notes", selection: $selection) {
                    Text("Text").tag(0)
                    Text("Sketch").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                Spacer()
                Text("Stored only on this Mac")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()

            if selection == 0 {
                TextEditor(text: $notes.text)
                    .font(.system(.body, design: .rounded))
                    .padding(8)
                    .accessibilityLabel("Local text notes")
            } else {
                SketchpadView(notes: notes)
            }
        }
        .frame(minWidth: 680, minHeight: 460)
        .onDisappear(perform: notes.flush)
    }
}

private struct SketchpadView: View {
    @ObservedObject var notes: BrowserNotesModel
    @State private var drawing = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Draw with the pointer")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Undo", action: notes.undoStroke)
                    .disabled(notes.strokes.isEmpty)
                Button("Clear", role: .destructive, action: notes.clearSketch)
                    .disabled(notes.strokes.isEmpty)
            }
            .padding(10)
            Divider()

            GeometryReader { geometry in
                Canvas { context, size in
                    for stroke in notes.strokes where stroke.points.count > 1 {
                        var path = Path()
                        let first = denormalize(stroke.points[0].point, in: size)
                        path.move(to: first)
                        for point in stroke.points.dropFirst() {
                            path.addLine(to: denormalize(point.point, in: size))
                        }
                        context.stroke(
                            path,
                            with: .color(.primary),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .contentShape(Rectangle())
                .background(Color.primary.opacity(0.035))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let normalized = normalize(value.location, in: geometry.size)
                            if !drawing {
                                drawing = true
                                notes.beginStroke(at: normalized)
                            } else {
                                notes.continueStroke(at: normalized)
                            }
                        }
                        .onEnded { _ in
                            drawing = false
                        }
                )
            }
        }
    }

    private func normalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width > 0 ? point.x / size.width : 0,
            y: size.height > 0 ? point.y / size.height : 0
        )
    }

    private func denormalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}
