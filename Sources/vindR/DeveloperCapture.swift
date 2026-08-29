import Foundation
import WebKit

enum DeveloperCapture {
    static func install(
        in controller: WKUserContentController,
        tab: BrowserTab,
        consoleEnabled: Bool,
        consoleModules: ConsoleCaptureModules = ConsoleCaptureModules(
            messages: true,
            pageErrors: true,
            assertionsAndTraces: true,
            objectsAndTables: true,
            counters: true,
            timers: true,
            groups: true,
            performance: true
        ),
        networkEnabled: Bool
    ) {
        if consoleEnabled {
            controller.add(PageConsoleMessageHandler(tab: tab), name: PageConsoleCapture.handlerName)
            controller.addUserScript(
                WKUserScript(
                    source: PageConsoleCapture.script(modules: consoleModules),
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

final class PageConsoleMessageHandler: NSObject, WKScriptMessageHandler {
    weak var tab: BrowserTab?

    init(tab: BrowserTab) {
        self.tab = tab
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let payload = message.body as? [String: Any] else { return }
        let level = payload["level"] as? String ?? "log"
        let method = payload["method"] as? String ?? level
        let text = payload["message"] as? String ?? ""
        let clearsConsole = payload["clear"] as? Bool ?? false
        Task { @MainActor [weak tab] in
            if clearsConsole {
                tab?.clearConsole()
            }
            tab?.appendConsole(level: level, method: method, message: text)
        }
    }
}

enum PageConsoleCapture {
    static let handlerName = "vindRConsole"

    static func script(modules: ConsoleCaptureModules) -> String {
        #"""
        (() => {
          if (window.__vindRConsoleInstalled) return;
          window.__vindRConsoleInstalled = true;
          const enabled = {
            messages: \#(modules.messages),
            pageErrors: \#(modules.pageErrors),
            diagnostics: \#(modules.assertionsAndTraces),
            objects: \#(modules.objectsAndTables),
            counters: \#(modules.counters),
            timers: \#(modules.timers),
            groups: \#(modules.groups),
            performance: \#(modules.performance)
          };
          let groupDepth = 0;
          const counters = new Map();
          const timers = new Map();
          const methods = [
            'assert', 'clear', 'count', 'countReset', 'debug', 'dir', 'dirxml',
            'error', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log', 'table',
            'time', 'timeEnd', 'timeLog', 'timeStamp', 'trace', 'warn', 'profile', 'profileEnd'
          ];
          const originals = {};
          methods.forEach(method => {
            if (typeof console[method] === 'function') originals[method] = console[method].bind(console);
          });
          const render = value => {
            if (typeof value === 'string') return value;
            if (value === null) return 'null';
            if (value instanceof Error) return value.stack || value.message;
            if (typeof value === 'undefined') return 'undefined';
            if (typeof value === 'function') return value.toString();
            if (typeof value === 'symbol' || typeof value === 'bigint') return String(value);
            if (value instanceof Element) {
              const id = value.id ? `#${value.id}` : '';
              const classes = value.classList?.length ? `.${[...value.classList].join('.')}` : '';
              return `<${value.tagName.toLowerCase()}${id}${classes}>`;
            }
            try {
              const seen = new WeakSet();
              const json = JSON.stringify(value, (_key, nested) => {
                if (typeof nested === 'bigint') return `${nested}n`;
                if (typeof nested === 'object' && nested !== null) {
                  if (seen.has(nested)) return '[Circular]';
                  seen.add(nested);
                }
                return nested;
              });
              return typeof json === 'undefined' ? String(value) : json;
            } catch (_) { return String(value); }
          };
          const format = values => {
            if (!values.length) return '';
            if (typeof values[0] !== 'string') return values.map(render).join(' ');
            let index = 1;
            const text = values[0].replace(/%[sdifoOc%]/g, token => {
              if (token === '%%') return '%';
              if (index >= values.length) return token;
              const value = values[index++];
              if (token === '%c') return '';
              if (token === '%d' || token === '%i') return String(parseInt(value, 10));
              if (token === '%f') return String(parseFloat(value));
              return token === '%s' ? String(value) : render(value);
            });
            const rest = values.slice(index).map(render);
            return [text, ...rest].join(' ');
          };
          const post = (level, method, values, extra = {}) => {
            const indent = '  '.repeat(groupDepth);
            try {
              window.webkit.messageHandlers.vindRConsole.postMessage({
                level, method, message: indent + format(values), ...extra
              });
            } catch (_) {}
          };
          const replace = (method, callback) => {
            if (!originals[method]) return;
            console[method] = function(...values) {
              callback(values);
              return originals[method](...values);
            };
          };

          if (enabled.messages) {
            ['log', 'info', 'warn', 'error', 'debug'].forEach(method =>
              replace(method, values => post(method === 'warn' ? 'warn' : method, method, values))
            );
            replace('clear', () => post('info', 'clear', ['Console cleared'], { clear: true }));
          }
          if (enabled.diagnostics) {
            replace('assert', values => {
              if (!values[0]) post('error', 'assert', ['Assertion failed:', ...values.slice(1)]);
            });
            replace('trace', values => {
              const stack = new Error(format(values) || 'Trace').stack || 'Trace';
              post('debug', 'trace', [stack]);
            });
          }
          if (enabled.objects) {
            ['dir', 'dirxml', 'table'].forEach(method =>
              replace(method, values => post('log', method, values))
            );
          }
          if (enabled.counters) {
            replace('count', values => {
              const label = values.length ? String(values[0]) : 'default';
              const value = (counters.get(label) || 0) + 1;
              counters.set(label, value);
              post('info', 'count', [`${label}: ${value}`]);
            });
            replace('countReset', values => {
              const label = values.length ? String(values[0]) : 'default';
              counters.delete(label);
              post('info', 'countReset', [`${label}: 0`]);
            });
          }
          if (enabled.timers) {
            replace('time', values => {
              const label = values.length ? String(values[0]) : 'default';
              timers.set(label, performance.now());
            });
            replace('timeLog', values => {
              const label = values.length ? String(values[0]) : 'default';
              const started = timers.get(label);
              const elapsed = started == null ? 'timer does not exist' : `${(performance.now() - started).toFixed(3)} ms`;
              post('info', 'timeLog', [`${label}: ${elapsed}`, ...values.slice(1)]);
            });
            replace('timeEnd', values => {
              const label = values.length ? String(values[0]) : 'default';
              const started = timers.get(label);
              const elapsed = started == null ? 'timer does not exist' : `${(performance.now() - started).toFixed(3)} ms`;
              timers.delete(label);
              post('info', 'timeEnd', [`${label}: ${elapsed}`]);
            });
          }
          if (enabled.groups) {
            ['group', 'groupCollapsed'].forEach(method => replace(method, values => {
              post('log', method, values.length ? values : ['console group']);
              groupDepth += 1;
            }));
            replace('groupEnd', () => { groupDepth = Math.max(0, groupDepth - 1); });
          }
          if (enabled.performance) {
            ['profile', 'profileEnd', 'timeStamp'].forEach(method =>
              replace(method, values => post('info', method, values))
            );
          }
          if (enabled.pageErrors) {
            window.addEventListener('error', event => {
              const location = event.filename ? ` (${event.filename}:${event.lineno}:${event.colno})` : '';
              post('error', 'exception', [event.message + location]);
            });
            window.addEventListener('unhandledrejection', event => {
              post('error', 'rejection', ['Unhandled promise rejection:', event.reason]);
            });
          }
        })();
        """#
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
