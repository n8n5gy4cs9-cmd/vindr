import WebKit

enum ContentBlocker {
    private static let identifier = "vindR.basicBlocker.v1"
    private static let rules = #"""
    [{"trigger":{"url-filter":"^https?://([^/]+\\.)?(doubleclick\\.net|googlesyndication\\.com|google-analytics\\.com|googletagmanager\\.com|adnxs\\.com|scorecardresearch\\.com|taboola\\.com|outbrain\\.com)/"},"action":{"type":"block"}}]
    """#

    static func install(in webView: WKWebView, completion: @escaping () -> Void) {
        guard let store = WKContentRuleListStore.default() else {
            completion()
            return
        }

        store.lookUpContentRuleList(forIdentifier: identifier) { existing, _ in
            if let existing {
                finish(existing, in: webView, completion: completion)
                return
            }

            store.compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: rules
            ) { compiled, _ in
                finish(compiled, in: webView, completion: completion)
            }
        }
    }

    private static func finish(
        _ ruleList: WKContentRuleList?,
        in webView: WKWebView,
        completion: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            if let ruleList {
                webView.configuration.userContentController.add(ruleList)
            }
            completion()
        }
    }
}
