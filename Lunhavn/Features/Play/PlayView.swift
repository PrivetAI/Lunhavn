import SwiftUI

struct PlayView: View {
    @Bindable var engine: GameEngine

    var body: some View {
        ZStack {
            CoastlineSceneView(engine: engine)
                .ignoresSafeArea()

            VStack(spacing: Tokens.spaceS) {
                topHUD
                Spacer()
                bottomControls
                    .padding(.bottom, 80)
            }
            .padding(.horizontal, Tokens.spaceM)
            .padding(.top, 4)
        }
        .onAppear { engine.setSceneActive(true) }
        .onDisappear { engine.setSceneActive(false) }
    }

    private var topHUD: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            VStack(spacing: Tokens.spaceS) {
                HStack(alignment: .top) {
                    TopCurrencyBar(engine: engine, currencies: [.gold, .oil])
                    Spacer()
                    WeatherChip(weather: engine.weather)
                }
                HStack(spacing: 8) {
                    InfoChip(icon: "chart.line.uptrend.xyaxis", text: "Stage \(engine.currentStage)")
                    InfoChip(icon: "sailboat.fill", text: "\(activeShips) in bay")
                    if engine.stats.idleGoldPerSecond > 0 {
                        InfoChip(icon: "circle.hexagongrid.fill", text: NumberFormat.rate(engine.stats.idleGoldPerSecond))
                    }
                    Spacer()
                }
            }
        }
    }

    private var activeShips: Int {
        engine.ships.filter { $0.alive && !$0.arrived }.count
    }

    private var bottomControls: some View {
        VStack(spacing: Tokens.spaceS) {
            if engine.stats.hasSecondSpotlight {
                Button {
                    Haptics.tap()
                    engine.state.secondSpotlightOn.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: engine.state.secondSpotlightOn ? "rays" : "circle.slash")
                        Text(engine.state.secondSpotlightOn ? "Second Spotlight On" : "Second Spotlight Off")
                            .font(.lunBody(13).weight(.semibold))
                    }
                    .foregroundStyle(engine.state.secondSpotlightOn ? Tokens.ink : Tokens.textSecondary)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Capsule().fill(engine.state.secondSpotlightOn ? Tokens.brass : Tokens.panel.opacity(0.9)))
                    .overlay(Capsule().strokeBorder(Tokens.brass.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Text("Drag to sweep the light. Lead each ship to its matching berth.")
                .font(.lunBody(12))
                .foregroundStyle(Tokens.textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(Tokens.ink.opacity(0.5)))
        }
    }
}

struct WeatherChip: View {
    let weather: WeatherState

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: weather.kind.icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(weather.kind.label).font(.lunBody(13).weight(.semibold)).foregroundStyle(Tokens.textPrimary)
                Text(weather.isNight ? "Night tide" : "Day tide").font(.lunBody(10)).foregroundStyle(Tokens.textMuted)
            }
        }
        .padding(.horizontal, 11).padding(.vertical, 6)
        .background(Capsule().fill(Tokens.panel.opacity(0.85)))
        .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
    }

    private var color: Color {
        switch weather.kind {
        case .clear: return Color(hex: 0x9FC6FF)
        case .fog: return Tokens.textSecondary
        case .storm: return Tokens.hazard
        case .calm: return Tokens.safe
        }
    }
}

struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(text).font(.lunBody(12).weight(.semibold))
        }
        .foregroundStyle(Tokens.textSecondary)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(Tokens.ink.opacity(0.45)))
    }
}
