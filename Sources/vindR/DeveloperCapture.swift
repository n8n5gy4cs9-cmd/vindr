import Foundation
import WebKit

enum DeveloperCapture {
    static func install(
        in controller: WKUserContentController,
        tab: BrowserTab,
        consoleEnabled: Bool,
        networkEnabled: Bool
    ) {
        if consoleEnabled {
            controller.add(PageConsoleMessageHandler(tab: tab), name: PageConsoleCapture.handlerName)
            controller.addUserScript(
                WKUserScript(
                    source: PageConsoleCapture.script,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: false
                )
            )
        }

        if networkEnabled {
            controller.add(PageNetworkMessageHandler(tab: tab), name: PageNetworkCapture.handlerName)
            controller.addUserScript(
                WKUserScript(
                    source: PageNetworkCapture.script,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: false
                )
            )
        }
    }
}

final class PageNetworkMessageHandler: NSObject, WKScriptMessageHandler {
    weak var tab: BrowserTab?

    init(tab: BrowserTab) {
        self.tab = tab
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let payload = message.body as? [String: Any],
              let url = payload["url"] as? String else { return }
        let method = payload["method"] as? String ?? "GET"
        let status = (payload["status"] as? NSNumber)?.intValue ?? 0
        let duration = (payload["duration"] as? NSNumber)?.doubleValue ?? 0
        let kind = payload["kind"] as? String ?? "resource"
        Task { @MainActor [weak tab] in
            tab?.appendNetwork(method: method, url: url, status: status, duration: duration, kind: kind)
        }
    }
}

enum PageNetworkCapture {
    static let handlerName = "vindRNetwork"
    static let script = #"""
    (() => {
      if (window.__vindRNetworkInstalled) return;
      window.__vindRNetworkInstalled = true;
      const post = payload => {
        try { window.webkit.messageHandlers.vindRNetwork.postMessage(payload); } catch (_) {}
      };

      const originalFetch = window.fetch;
      if (originalFetch) {
        window.fetch = function(input, init = {}) {
          const started = performance.now();
          const method = String(init.method || input?.method || 'GET').toUpperCase();
          const url = String(input?.url || input);
          return originalFetch.apply(this, arguments).then(response => {
            post({ method, url: response.url || url, status: response.status,
                   duration: performance.now() - started, kind: 'fetch' });
            return response;
          }, error => {
            post({ method, url, status: 0, duration: performance.now() - started, kind: 'fetch' });
            throw error;
          });
        };
      }

      const originalOpen = XMLHttpRequest.prototype.open;
      const originalSend = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.open = function(method, url) {
        this.__vindRRequest = { method: String(method).toUpperCase(), url: String(url) };
        return originalOpen.apply(this, arguments);
      };
      XMLHttpRequest.prototype.send = function() {
        const request = this.__vindRRequest || { method: 'GET', url: '' };
        const started = performance.now();
        this.addEventListener('loadend', () => {
          post({ method: request.method, url: this.responseURL || request.url, status: this.status,
                 duration: performance.now() - started, kind: 'xhr' });
        }, { once: true });
        return originalSend.apply(this, arguments);
      };

      try {
        new PerformanceObserver(list => {
          list.getEntries().forEach(entry => {
            const kind = entry.initiatorType || 'resource';
            if (kind === 'fetch' || kind === 'xmlhttprequest') return;
            post({ method: 'GET', url: entry.name, status: entry.responseStatus || 0,
                   duration: entry.duration || 0, kind });
          });
        }).observe({ type: 'resource', buffered: true });
      } catch (_) {}
    })();
    """#
}
