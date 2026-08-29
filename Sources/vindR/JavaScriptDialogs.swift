import AppKit
import WebKit

enum JavaScriptDialogPresenter {
    static func showAlert(message: String, in webView: WKWebView, completion: @escaping () -> Void) {
        let alert = makeAlert(title: "JavaScript Alert", message: message, webView: webView)
        alert.addButton(withTitle: "OK")
        present(alert, in: webView) { _ in completion() }
    }

    static func showConfirm(message: String, in webView: WKWebView, completion: @escaping (Bool) -> Void) {
        showConfirmation(title: "JavaScript Confirmation", message: message, in: webView, completion: completion)
    }

    private static func showConfirmation(
        title: String,
        message: String,
        in webView: WKWebView,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = makeAlert(title: title, message: message, webView: webView)
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        present(alert, in: webView) { response in completion(response == .alertFirstButtonReturn) }
    }

    static func showPrompt(
        message: String,
        defaultText: String?,
        in webView: WKWebView,
        completion: @escaping (String?) -> Void
    ) {
        let alert = makeAlert(title: "JavaScript Prompt", message: message, webView: webView)
        let field = NSTextField(string: defaultText ?? "")
        field.placeholderString = "Enter a value"
        field.frame = NSRect(x: 0, y: 0, width: 320, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        present(alert, in: webView) { response in
            completion(response == .alertFirstButtonReturn ? field.stringValue : nil)
        }
    }

    private static func makeAlert(title: String, message: String, webView: WKWebView) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        if let host = webView.url?.host, !host.isEmpty {
            alert.informativeText += "\n\nFrom \(host)"
        }
        return alert
    }

    private static func present(
        _ alert: NSAlert,
        in webView: WKWebView,
        completion: @escaping (NSApplication.ModalResponse) -> Void
    ) {
        if let window = webView.window {
            alert.beginSheetModal(for: window, completionHandler: completion)
        } else {
            completion(alert.runModal())
        }
    }
}
