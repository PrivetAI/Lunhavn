import SwiftUI

struct RootView: View {
    @Bindable var engine: GameEngine
    @State private var tab: AppTab = .play
    @State private var moreRoute: MoreRoute?

    var body: some View {
        ZStack {
            if engine.state.tutorialDone {
                mainShell
            } else {
                OnboardingView(engine: engine)
                    .transition(.opacity)
            }
            ToastOverlay(engine: engine)
        }
        .animation(.easeInOut(duration: 0.4), value: engine.state.tutorialDone)
        .sheet(item: Binding(get: { engine.idleReport }, set: { _ in engine.dismissIdleReport() })) { report in
            IdleSummaryView(report: report) { engine.dismissIdleReport() }
        }
        .fullScreenCover(item: $moreRoute) { route in
            moreDestination(route)
        }
    }

    private var mainShell: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .play: PlayView(engine: engine)
                case .upgrades: UpgradesView(engine: engine)
                case .keepers: KeepersView(engine: engine)
                case .voyages: VoyagesView(engine: engine)
                case .more: MoreView(engine: engine, onOpen: { moreRoute = $0 })
                }
            }
            .transition(.opacity)

            LunTabBar(selection: $tab)
                .padding(.bottom, 4)
        }
    }

    @ViewBuilder
    private func moreDestination(_ route: MoreRoute) -> some View {
        switch route {
        case .cosmetics: CosmeticsView(engine: engine) { moreRoute = nil }
        case .prestige: PrestigeView(engine: engine) { moreRoute = nil }
        case .achievements: AchievementsView(engine: engine) { moreRoute = nil }
        case .statistics: StatisticsView(engine: engine) { moreRoute = nil }
        case .settings: SettingsView(engine: engine) { moreRoute = nil }
        }
    }
}

struct ToastOverlay: View {
    @Bindable var engine: GameEngine

    var body: some View {
        VStack {
            if let toast = engine.activeToast {
                HStack(spacing: 8) {
                    Image(systemName: toast.icon).foregroundStyle(toast.color)
                    Text(toast.text).font(.lunBody(14).weight(.semibold)).foregroundStyle(Tokens.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Capsule().fill(Tokens.panel.opacity(0.96)))
                .overlay(Capsule().strokeBorder(toast.color.opacity(0.5), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .id(toast.id)
                .task(id: toast.id) {
                    try? await Task.sleep(nanoseconds: 2_400_000_000)
                    withAnimation(.easeInOut) {
                        if engine.activeToast?.id == toast.id { engine.activeToast = nil }
                    }
                }
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: engine.activeToast?.id)
        .allowsHitTesting(false)
    }
}
