import SwiftUI
import WebKit

struct LeetCodeLoginView: UIViewRepresentable {
    let prefillUsername: String
    let onSessionDetected: (String, String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(prefillUsername: prefillUsername, onSessionDetected: onSessionDetected)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: "https://leetcode.com/accounts/login/") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let prefillUsername: String
        let onSessionDetected: (String, String) -> Void
        private var didDetect = false

        init(prefillUsername: String, onSessionDetected: @escaping (String, String) -> Void) {
            self.prefillUsername = prefillUsername
            self.onSessionDetected = onSessionDetected
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }

            // Pre-fill the username field when the login page loads.
            if url.absoluteString.contains("accounts/login") {
                if !prefillUsername.isEmpty {
                    let escaped = prefillUsername.replacingOccurrences(of: "\\", with: "\\\\")
                                                 .replacingOccurrences(of: "'", with: "\\'")
                    // LeetCode's login page is a React SPA. Two problems to solve:
                    // 1. Timing: didFinish fires when HTML loads, but React mounts
                    //    components asynchronously — the field may not exist yet.
                    //    Retry every 200ms for up to 2 seconds.
                    // 2. React controlled input: direct .value assignment is suppressed
                    //    by React. Use the native HTMLInputElement prototype setter +
                    //    an 'input' event so React's onChange handler updates its state.
                    //    This is the same technique Playwright's fill() uses internally.
                    let js = """
                        (function fill(retries) {
                            var el = document.querySelector('#id_login');
                            if (!el) {
                                if (retries > 0) setTimeout(function() { fill(retries - 1); }, 200);
                                return;
                            }
                            var setter = Object.getOwnPropertyDescriptor(
                                window.HTMLInputElement.prototype, 'value').set;
                            setter.call(el, '\(escaped)');
                            el.dispatchEvent(new Event('input', { bubbles: true }));
                        })(10);
                    """
                    webView.evaluateJavaScript(js, completionHandler: nil)
                }
                return
            }

            // Navigated away from login page — successful login redirect.
            // Check for the session and CSRF cookies.
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                let session = cookies.first(where: { $0.name == "LEETCODE_SESSION" })?.value ?? ""
                let csrf    = cookies.first(where: { $0.name == "csrftoken" })?.value ?? ""
                guard !session.isEmpty, !csrf.isEmpty else { return }
                DispatchQueue.main.async {
                    guard !self.didDetect else { return }
                    self.didDetect = true
                    self.onSessionDetected(session, csrf)
                }
            }
        }
    }
}

struct LeetCodeLoginSheet: View {
    @AppStorage("username", store: .appGroup) private var username = ""
    @Environment(\.dismiss) private var dismiss
    let onLoginSuccess: () -> Void

    var body: some View {
        NavigationStack {
            LeetCodeLoginView(prefillUsername: username) { session, csrf in
                KeychainService.store(session,  key: KeychainService.sessionKey)
                KeychainService.store(csrf,     key: KeychainService.csrfKey)
                KeychainService.store(username, key: KeychainService.authenticatedUsernameKey)
                onLoginSuccess()
                dismiss()
            }
            .ignoresSafeArea()
            .navigationTitle("Sign in to LeetCode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
