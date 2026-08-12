import SwiftUI
import WebKit

/// Shared web surface. Serves both the fullscreen panel raised at launch and the
/// Privacy Policy sheet inside Settings.
struct LunhavnBeaconPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        // REQUIRED, not optional: the frame extends under the home indicator and this is what
        // insets scrollable content back out of it. NEVER .never.
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        // Opaque + solid bg keeps the safe-area band clean (no white flash).
        webView.isOpaque = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        // The branch presenting this runs in the dark scheme so the status bar glyphs turn
        // white. Pin the page back to light so that trait never reaches the site as
        // prefers-color-scheme: dark.
        webView.overrideUserInterfaceStyle = .light
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    // MUST stay empty — reloading here would restart the page on every SwiftUI re-render.
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// Shown while the launch check resolves.
struct LunhavnBeaconLoadingScreen: View {
    @State private var sweep = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0A1430), Tokens.ink],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(colors: [
                                Tokens.glow.opacity(sweep ? 0.5 : 0.18),
                                Color.clear
                            ], center: .center, startRadius: 6, endRadius: 96)
                        )
                        .frame(width: 190, height: 190)

                    Capsule()
                        .fill(LinearGradient(colors: [Tokens.woodLight, Tokens.wood],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 34, height: 96)
                        .offset(y: 22)

                    Circle()
                        .fill(LinearGradient(colors: [Tokens.brassBright, Tokens.brass],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 30, height: 30)
                        .offset(y: -34)
                        .shadow(color: Tokens.glow.opacity(sweep ? 0.9 : 0.3), radius: 14)
                }
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: sweep)

                Text("Lunhavn")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Tokens.textPrimary)

                Text("Trimming the lamp...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Tokens.textSecondary)
            }
        }
        .onAppear { sweep = true }
    }
}

/// Watches the whole redirect chain — the check domain may only appear mid-chain and never in
/// the final URL, so both are inspected. The chain is never stopped.
final class LunhavnRedirectProbe: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) { self.checkDomain = checkDomain }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request) // never stop the chain
    }
}
