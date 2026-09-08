import SwiftUI
import WebKit

// MARK: - Session survival across a cold start

/// Remembers the last page the launch panel was really on, so a cold start resumes there
/// instead of re-running the redirect chain from the top — which would land a user who has
/// already registered on the offer's landing page again, and read as "it logged me out".
enum LunhavnBeaconSession {
    private static let addressKey = "lunhavn.beacon.resume.address"
    private static let stampKey   = "lunhavn.beacon.resume.stamp"
    /// Past this a resumed address is likelier to be stale than useful.
    private static let maxAge: TimeInterval = 60 * 60 * 24 * 30

    static func remember(_ url: URL?, trackerHost: String) {
        // No tracker host means this is not the launch panel — the Settings/Privacy sheet
        // passes none, which switches remembering off for it. Without this guard the next
        // launch resumes the privacy page instead of the offer.
        guard !trackerHost.isEmpty else { return }
        guard let url = url, url.scheme == "https",
              let host = url.host, !host.isEmpty else { return }
        // Never store our own hop: resuming it would re-run the very chain this avoids.
        if host == trackerHost || host.hasSuffix("." + trackerHost) { return }
        UserDefaults.standard.set(url.absoluteString, forKey: addressKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: stampKey)
    }

    static func resumeAddress() -> String? {
        guard let address = UserDefaults.standard.string(forKey: addressKey),
              let url = URL(string: address), url.host != nil else { return nil }
        let stamp = UserDefaults.standard.double(forKey: stampKey)
        guard stamp > 0, Date().timeIntervalSince1970 - stamp < maxAge else { return nil }
        return address
    }

    static func forget() {
        UserDefaults.standard.removeObject(forKey: addressKey)
        UserDefaults.standard.removeObject(forKey: stampKey)
    }
}

/// Mirrors the WebKit cookie jar out to `UserDefaults` and back. A cookie with no expiry —
/// a plain PHPSESSID, which is what most sign-ins hand out — lives only in the WebKit
/// networking process and dies with it. The persistent store cannot help, because there
/// was nothing to persist.
enum LunhavnBeaconCookies {
    private static let key = "lunhavn.beacon.cookies"
    /// Expiry given to a cookie that had none. Long enough to outlive ordinary use.
    private static let sessionLifetime: TimeInterval = 60 * 60 * 24 * 180
    /// WebKit has been seen to swallow a `setCookie` completion. Never let that hold a
    /// launch: past this the page loads regardless.
    private static let restoreGrace: TimeInterval = 1.5

    static func snapshot() {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            let payload: [[String: String]] = cookies.map { cookie in
                let expiry = cookie.expiresDate ?? Date().addingTimeInterval(sessionLifetime)
                return [
                    "name": cookie.name,
                    "value": cookie.value,
                    "domain": cookie.domain,
                    "path": cookie.path.isEmpty ? "/" : cookie.path,
                    "secure": cookie.isSecure ? "1" : "0",
                    "expires": String(expiry.timeIntervalSince1970)
                ]
            }
            // Wholesale overwrite, so a sign-out that empties the jar empties the mirror
            // too and cannot resurrect a dead session on the next launch.
            UserDefaults.standard.set(payload, forKey: key)
        }
    }

    /// Re-injects the mirror and then calls back. The caller MUST wait for this before
    /// the first load: a request that goes out early is the one that arrives signed out.
    static func restore(completion: @escaping () -> Void) {
        guard let payload = UserDefaults.standard.array(forKey: key) as? [[String: String]],
              !payload.isEmpty else { completion(); return }

        let store = WKWebsiteDataStore.default().httpCookieStore
        let now = Date()
        var finished = false
        let finish = {
            guard !finished else { return }
            finished = true
            completion()
        }

        let group = DispatchGroup()
        var queued = 0
        for entry in payload {
            guard let name = entry["name"], let value = entry["value"],
                  let domain = entry["domain"], let path = entry["path"],
                  let raw = entry["expires"], let seconds = TimeInterval(raw) else { continue }
            let expiry = Date(timeIntervalSince1970: seconds)
            guard expiry > now else { continue }
            var props: [HTTPCookiePropertyKey: Any] = [
                .name: name, .value: value, .domain: domain, .path: path, .expires: expiry
            ]
            if entry["secure"] == "1" { props[.secure] = "TRUE" }
            guard let cookie = HTTPCookie(properties: props) else { continue }
            queued += 1
            group.enter()
            store.setCookie(cookie) { group.leave() }
        }

        guard queued > 0 else { finish(); return }
        group.notify(queue: .main) { finish() }
        DispatchQueue.main.asyncAfter(deadline: .now() + restoreGrace) { finish() }
    }
}

// MARK: - Panel

/// Shared web surface. Serves both the fullscreen panel raised at launch and the
/// Privacy Policy sheet inside Settings.
struct LunhavnBeaconPanel: UIViewRepresentable {
    let urlString: String
    /// Our own host — the tracker hop, which must never be remembered as a resume point.
    /// The Settings/Privacy sheet passes none, which also switches remembering off.
    var trackerHost: String = ""
    /// Where to go if `urlString` is a resumed address that has since gone dead.
    /// nil when the panel already started at the tracker link (and for Settings).
    var fallbackAddress: String? = nil
    /// Fires once, as soon as the page starts rendering, so the caller can lift the
    /// loading screen overlay. Optional — the Settings/Privacy use site passes nothing.
    var onFirstPaint: (() -> Void)? = nil
    /// Fires when nothing loads at all — live or cached. The caller shows the native app.
    var onDeadEnd: (() -> Void)? = nil

    final class Coordinator: NSObject, WKNavigationDelegate {
        var onFirstPaint: (() -> Void)?
        var onDeadEnd: (() -> Void)?
        var trackerHost = ""
        var fallbackAddress: String?
        /// What the panel was asked to load first — the cache candidate when it was a
        /// resumed address.
        var initialAddress = ""
        private var fired = false
        private var triedFallback = false
        private var triedCache = false
        private var urlObservation: NSKeyValueObservation?

        deinit { urlObservation?.invalidate() }

        /// A same-document navigation — an SPA tab via `pushState`, a `#hash` tab — fires
        /// NO navigation delegate callback, so `didCommit` never sees it and the resume
        /// address would be stuck on whatever loaded last. `url` is KVO-compliant and moves
        /// for both, and `remember` is idempotent, so this simply covers more.
        func watchAddress(of webView: WKWebView) {
            urlObservation?.invalidate()
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                guard let self = self else { return }
                LunhavnBeaconSession.remember(webView.url, trackerHost: self.trackerHost)
            }
        }

        // didCommit, NOT didFinish: on a heavy landing page didFinish arrives seconds
        // after the page is already visible and usable.
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            LunhavnBeaconSession.remember(webView.url, trackerHost: trackerHost)
            fire()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            LunhavnBeaconSession.remember(webView.url, trackerHost: trackerHost)
            // The jar is at its most interesting the moment a page settles: a sign-in
            // POST has landed by now.
            LunhavnBeaconCookies.snapshot()
        }

        // A real failure must also lift the overlay, or the loading screen hangs forever.
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            let ns = error as NSError
            // A cancelled load is just an ordinary redirect — not a failure.
            if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
            // After the first paint a failed navigation is just a failed navigation inside a
            // working session: WebKit shows its error and the user can go back. Recovery is
            // only for a panel that never got off the ground — otherwise this would yank a
            // browsing user into the native app.
            guard !fired else { return }
            recover(webView)
        }

        /// resumed address live -> tracker link live -> same address from disk cache ->
        /// give up and hand back the native app. NEVER leave the user on WebKit's error
        /// page: fullscreen, no back, no reload, nothing to act on.
        private func recover(_ webView: WKWebView) {
            if !triedFallback, let fallback = fallbackAddress, let url = URL(string: fallback) {
                triedFallback = true
                LunhavnBeaconSession.forget()          // stop resuming a dead address
                webView.load(URLRequest(url: url))
                return
            }
            // A stale page from disk still shows the user their account; an error page
            // shows them nothing they can act on. Only worth trying for a real page — the
            // tracker link is a 302 with nothing cached worth having.
            if !triedCache, fallbackAddress != nil, let url = URL(string: initialAddress) {
                triedCache = true
                webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad,
                                        timeoutInterval: 15))
                return
            }
            onDeadEnd?()
        }

        private func fire() {
            guard !fired else { return }
            fired = true
            onFirstPaint?()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // Explicit because the signed-in session depends on it: the DEFAULT store is the
        // persistent, on-disk one. NEVER .nonPersistent().
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        context.coordinator.onFirstPaint = onFirstPaint
        context.coordinator.onDeadEnd = onDeadEnd
        context.coordinator.trackerHost = trackerHost
        context.coordinator.fallbackAddress = fallbackAddress
        context.coordinator.initialAddress = urlString
        webView.navigationDelegate = context.coordinator
        context.coordinator.watchAddress(of: webView)
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
        // Cookies FIRST, then load. The other order signs the user out on every cold
        // start, and the loading screen is still up so the wait is invisible.
        let address = urlString
        LunhavnBeaconCookies.restore { [weak webView] in
            guard let webView = webView, let url = URL(string: address) else { return }
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    // MUST NEVER reload — that would restart the page on every SwiftUI re-render
    // (infinite reload). Refreshing the callbacks is the only thing allowed here.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onFirstPaint = onFirstPaint
        context.coordinator.onDeadEnd = onDeadEnd
        context.coordinator.trackerHost = trackerHost
        context.coordinator.fallbackAddress = fallbackAddress
    }
}

// MARK: - Loading screen

/// Shown while the launch check resolves, then held over the panel until the page paints.
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

// MARK: - Redirect probe

/// Follows the redirect chain without ever stopping it, and decides at the first hop that
/// actually carries information instead of waiting for the whole chain to resolve. The check
/// domain may only appear mid-chain and never in the final URL, so both are inspected — and
/// the slowest host in the chain is kept off the launch critical path.
///
/// `nonisolated`: this project defaults every type to the main actor, but URLSession calls
/// its delegate on its own queue. The callbacks hop back to the main actor themselves.
/// `@unchecked Sendable`: URLSessionTaskDelegate requires Sendable. Every mutable field is
/// written only from the session's serial delegate queue and read back in the task's
/// completion on that same queue; the two callbacks are assigned before `resume()`.
nonisolated final class LunhavnRedirectProbe: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    /// Fires on every observed hop — re-arms the stall watchdog.
    var onProgress: (@Sendable () -> Void)?
    /// Fires at most once, the moment the chain becomes decidable.
    var onEarlyVerdict: (@Sendable (Bool) -> Void)?

    private(set) var resolvedURL: URL?
    private(set) var sawCheckDomain = false

    private let checkDomain: String
    private let ownHost: String
    private var decided = false

    init(checkDomain: String, ownHost: String) {
        self.checkDomain = checkDomain
        self.ownHost = ownHost
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        resolvedURL = request.url
        onProgress?()

        if let address = request.url?.absoluteString {
            if address.contains(checkDomain) {
                // Definitive: the review branch. Nothing later in the chain can change it.
                sawCheckDomain = true
                decide(false)
            } else if let host = request.url?.host, !hostIsOurs(host) {
                // First hop that LEAVES our own domain without being the marker: the Worker
                // has routed to the offer, and that is the whole verdict. Everything after
                // this belongs to the affiliate network and cannot change it.
                decide(true)
            }
            // A hop that stays on our own host (mountainapiary.org -> /click.php) decides
            // NOTHING — calling it early would open the panel before the Worker has actually
            // chosen a branch.
        }
        completionHandler(request)   // NEVER stop the chain
    }

    private func hostIsOurs(_ host: String) -> Bool {
        !ownHost.isEmpty && (host == ownHost || host.hasSuffix("." + ownHost))
    }

    private func decide(_ verdict: Bool) {
        guard !decided else { return }
        decided = true
        onEarlyVerdict?(verdict)
    }
}
