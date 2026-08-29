import AppKit
import Combine
import Foundation
import WebKit

enum BrowserDownloadState {
    case idle
    case downloading
    case succeeded
    case failed
}

@MainActor
final class BrowserDownloadManager: NSObject, ObservableObject, WKDownloadDelegate {
    @Published private(set) var activeCount = 0
    @Published private(set) var state = BrowserDownloadState.idle
    @Published private(set) var message: String?

    private var filenames: [ObjectIdentifier: String] = [:]

    func begin(_ download: WKDownload) {
        download.delegate = self
    }

    func clearStatus() {
        guard activeCount == 0 else { return }
        state = .idle
        message = nil
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.title = "Save Download"
        panel.prompt = "Download"

        panel.begin { [weak self] modalResponse in
            guard let self else {
                completionHandler(nil)
                return
            }
            guard modalResponse == .OK, let destination = panel.url else {
                self.state = .idle
                self.message = "Download canceled"
                completionHandler(nil)
                return
            }

            self.filenames[ObjectIdentifier(download)] = destination.lastPathComponent
            self.activeCount += 1
            self.state = .downloading
            self.message = "Downloading \(destination.lastPathComponent)…"
            completionHandler(destination)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        let filename = finish(download) ?? "file"
        state = activeCount == 0 ? .succeeded : .downloading
        message = activeCount == 0
            ? "Saved \(filename)"
            : "Saved \(filename) · \(activeCount) remaining"
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let filename = finish(download)
        state = .failed
        if let filename {
            message = "Failed \(filename): \(error.localizedDescription)"
        } else {
            message = "Download failed: \(error.localizedDescription)"
        }
    }

    private func finish(_ download: WKDownload) -> String? {
        let filename = filenames.removeValue(forKey: ObjectIdentifier(download))
        if filename != nil {
            activeCount = max(0, activeCount - 1)
        }
        return filename
    }
}
