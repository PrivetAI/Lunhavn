import SwiftUI

struct KeepersView: View {
    @Bindable var engine: GameEngine

    var body: some View {
        let _ = engine.version
        return ZStack {
            NightBackground(engine: engine)
            VStack(spacing: Tokens.spaceM) {
                header
                ScrollView {
                    VStack(spacing: Tokens.spaceM) {
                        idlePanel
                        ForEach(ContentLibrary.keepers) { def in
                            KeeperCard(engine: engine, def: def)
                        }
                    }
                    .padding(.horizontal, Tokens.spaceM)
                    .padding(.bottom, 96)
                }
            }
            .padding(.top, 8)
        }
    }

    private var header: some View {
        VStack(spacing: Tokens.spaceS) {
            HStack {
                ScreenTitle(title: "Keepers", subtitle: "Hire a crew to tend the light")
                Spacer()
            }
            TopCurrencyBar(engine: engine, currencies: [.gold, .oil])
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Tokens.spaceM)
    }

    private var idlePanel: some View {
        LunPanel(tint: Tokens.wood) {
            VStack(spacing: Tokens.spaceS) {
                LunSectionHeader(title: "Idle Yield", subtitle: "Your crew works even while you're away")
                HStack(spacing: Tokens.spaceM) {
                    yieldStat(icon: "circle.hexagongrid.fill", value: NumberFormat.rate(engine.stats.idleGoldPerSecond), label: "Gold", color: Tokens.brassBright)
                    yieldStat(icon: "drop.fill", value: NumberFormat.rate(engine.stats.idleOilPerSecond), label: "Oil", color: Color(hex: 0x8FC9E0))
                    yieldStat(icon: "rays", value: String(format: "%.0f%%", engine.stats.keeperAssist * 100), label: "Assist", color: Tokens.safe)
                }
                Text("Offline guidance is capped at \(Int(engine.stats.offlineHours)) hours.")
                    .font(.lunBody(12)).foregroundStyle(Tokens.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func yieldStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.lunNumber(15)).foregroundStyle(Tokens.textPrimary)
            Text(label).font(.lunBody(11)).foregroundStyle(Tokens.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Tokens.cornerSmall).fill(Tokens.ink.opacity(0.4)))
    }
}

struct KeeperCard: View {
    @Bindable var engine: GameEngine
    let def: KeeperDef

    var body: some View {
        let level = engine.state.keeperLevel(def.id)
        let cost = engine.keeperCost(def)
        let canBuy = engine.canBuyKeeper(def)
        let locked = level == 0 && !canBuy && engine.state.gold < cost * 0.5

        LunPanel {
            VStack(alignment: .leading, spacing: Tokens.spaceS) {
                HStack(alignment: .top) {
                    Image(systemName: def.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(level > 0 ? Tokens.brassBright : Tokens.textMuted)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Tokens.ink.opacity(0.5)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(def.name).font(.lunTitle(17)).foregroundStyle(Tokens.textPrimary)
                        Text(def.detail).font(.lunBody(13)).foregroundStyle(Tokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Text("Lv \(level)").font(.lunNumber(16)).foregroundStyle(Tokens.brass)
                }

                HStack(spacing: Tokens.spaceM) {
                    if def.idleGoldPerLevel > 0 {
                        contributionTag(icon: "circle.hexagongrid.fill", text: NumberFormat.rate(def.idleGoldPerLevel * Double(max(1, level))))
                    }
                    if def.idleOilPerLevel > 0 {
                        contributionTag(icon: "drop.fill", text: NumberFormat.rate(def.idleOilPerLevel * Double(max(1, level))))
                    }
                    contributionTag(icon: "rays", text: "+\(Int(def.activeAssistPerLevel * Double(max(1, level)) * 100))% assist")
                }

                Button {
                    engine.buyKeeper(def)
                } label: {
                    HStack {
                        Image(systemName: "circle.hexagongrid.fill")
                        Text(cost.compactString).font(.lunNumber(15))
                        Spacer()
                        Text(level == 0 ? "Hire" : "Train").font(.lunTitle(15))
                    }
                    .foregroundStyle(canBuy ? Tokens.ink : Tokens.textMuted)
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: Tokens.cornerSmall, style: .continuous)
                        .fill(canBuy ? AnyShapeStyle(LinearGradient(colors: [Tokens.brassBright, Tokens.brass], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Tokens.panel.opacity(0.7))))
                }
                .buttonStyle(.plain)
                .disabled(!canBuy)
                .opacity(locked ? 0.7 : 1)
            }
        }
    }

    private func contributionTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(text).font(.lunBody(12).weight(.semibold))
        }
        .foregroundStyle(Tokens.textSecondary)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(Tokens.ink.opacity(0.4)))
    }
}
