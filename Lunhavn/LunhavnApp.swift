import SwiftUI

@main
struct LunhavnApp: App {
    @State private var engine = GameEngine()
    @Environment(\.scenePhase) private var scenePhase
    @State private var started = false

    var body: some Scene {
        WindowGroup {
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
    }
}
