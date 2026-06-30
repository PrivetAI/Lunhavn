import SwiftUI

struct LaunchRouterView: View {
    @Bindable var engine: GameEngine
    @StateObject private var launchGate = LaunchGateController()

    var body: some View {
        Group {
            switch launchGate.phase {
            case .resolving, .remoteWebShell:
                if let url = LaunchGateConfiguration.remoteGateURL {
                    LaunchWebView(gate: launchGate, startURL: url)
                } else {
                    RootView(engine: engine)
                }
            case .nativeApp:
                RootView(engine: engine)
            }
        }
    }
}
