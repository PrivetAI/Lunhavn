import SwiftUI

struct StatisticsView: View {
    @Bindable var engine: GameEngine
    let onClose: () -> Void

    var body: some View {
        let _ = engine.version
        let s = engine.state.stats
        return CoverScreen(engine: engine, title: "Statistics", subtitle: "A lifetime by the lamp", onClose: onClose) {
            ScrollView {
                VStack(spacing: Tokens.spaceM) {
                    chartPanel(s)
                    LunPanel {
                        VStack(spacing: 11) {
                            LunStatRow(label: "Ships guided home", value: Double(s.shipsGuided).compactString, icon: "sailboat.fill")
                            LunStatRow(label: "Ships sorted correctly", value: Double(s.shipsSorted).compactString, icon: "arrow.triangle.branch")
                            LunStatRow(label: "Ships wrecked", value: Double(s.wrecks).compactString, icon: "exclamationmark.triangle.fill", tint: Tokens.hazard)
                            LunStatRow(label: "Mines detonated", value: Double(s.minesDetonated).compactString, icon: "burst.fill", tint: Tokens.hazard)
                            LunStatRow(label: "Mines dodged", value: Double(s.minesDodged).compactString, icon: "shield.lefthalf.filled", tint: Tokens.safe)
                            LunStatRow(label: "Storms weathered", value: Double(s.stormsWeathered).compactString, icon: "cloud.bolt.fill")
                        }
                    }
                    LunPanel {
                        VStack(spacing: 11) {
                            LunStatRow(label: "Total gold earned", value: s.totalGold.compactString, icon: "circle.hexagongrid.fill", tint: Tokens.brassBright)
                            LunStatRow(label: "Lighthouse relights", value: Double(s.prestiges).compactString, icon: "arrow.triangle.2.circlepath")
                            LunStatRow(label: "Lifetime Lumens", value: engine.state.lifetimeLumens.compactString, icon: "sparkles")
                            LunStatRow(label: "Offline collections", value: Double(s.idleCollections).compactString, icon: "moon.zzz.fill")
                            LunStatRow(label: "Daily challenges", value: Double(s.dailyCompletions).compactString, icon: "calendar")
                            LunStatRow(label: "Time idle", value: formatTime(s.idleSeconds), icon: "hourglass")
                        }
                    }
                }
                .padding(.horizontal, Tokens.spaceM)
                .padding(.bottom, 24)
            }
        }
    }

    private func chartPanel(_ s: Stats) -> some View {
        LunPanel(tint: Tokens.wood) {
            VStack(alignment: .leading, spacing: Tokens.spaceS) {
                LunSectionHeader(title: "Voyages at a glance")
                LunBarChart(bars: [
                    .init(label: "Guided", value: Double(s.shipsGuided), color: Tokens.brassBright),
                    .init(label: "Sorted", value: Double(s.shipsSorted), color: Tokens.safe),
                    .init(label: "Storms", value: Double(s.stormsWeathered), color: Color(hex: 0x9FC6FF)),
                    .init(label: "Dodged", value: Double(s.minesDodged), color: Color(hex: 0xC7A8FF)),
                    .init(label: "Wrecks", value: Double(s.wrecks), color: Tokens.hazard)
                ])
                .frame(height: 130)
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

struct LunBarChart: View {
    struct Bar: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }
    let bars: [Bar]

    var body: some View {
        let maxValue = max(1, bars.map { $0.value }.max() ?? 1)
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(bars) { bar in
                    VStack(spacing: 5) {
                        Text(bar.value.compactString).font(.lunBody(10).weight(.semibold)).foregroundStyle(Tokens.textSecondary)
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(LinearGradient(colors: [bar.color, bar.color.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                            .frame(height: max(3, (geo.size.height - 40) * bar.value / maxValue))
                        Text(bar.label).font(.lunBody(10)).foregroundStyle(Tokens.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
