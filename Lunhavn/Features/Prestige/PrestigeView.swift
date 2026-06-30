import SwiftUI

struct PrestigeView: View {
    @Bindable var engine: GameEngine
    let onClose: () -> Void
    @State private var showConfirm = false

    var body: some View {
        let _ = engine.version
        return CoverScreen(engine: engine, title: "Rebirth", subtitle: "Pass the light to a new keeper", onClose: onClose) {
            ScrollView {
                VStack(spacing: Tokens.spaceM) {
                    relightPanel
                    LunSectionHeader(title: "Eternal Upgrades", subtitle: "Permanent bonuses bought with Lumens")
                        .padding(.horizontal, Tokens.spaceM)
                    ForEach(ContentLibrary.prestigeUpgrades) { def in
                        PrestigeCard(engine: engine, def: def)
                            .padding(.horizontal, Tokens.spaceM)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .alert("Relight the lighthouse?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Relight") { engine.performPrestige() }
        } message: {
            Text("You will reset gold, oil, upgrades and keepers, but gain \(engine.pendingLumens.compactString) Lumens and keep all eternal upgrades and cosmetics.")
        }
    }

    private var relightPanel: some View {
        LunPanel(tint: Color(hex: 0x1A1530)) {
            VStack(spacing: Tokens.spaceM) {
                HStack(spacing: Tokens.spaceL) {
                    lumenStat(value: engine.state.lumen.compactString, label: "Lumens held")
                    lumenStat(value: engine.pendingLumens.compactString, label: "Lumens on relight")
                }
                Text(engine.canPrestige
                     ? "Your total gold this watch is great enough to relight a grander lighthouse."
                     : "Earn at least \(Balance.prestigeRequirement.compactString) total gold this watch to relight.")
                    .font(.lunBody(13)).foregroundStyle(Tokens.textSecondary)
                    .multilineTextAlignment(.center)
                LunButton(title: "Relight the Lighthouse", icon: "sparkles", fullWidth: true, enabled: engine.canPrestige) {
                    showConfirm = true
                }
                Text("Prestiges: \(engine.state.stats.prestiges)")
                    .font(.lunBody(12)).foregroundStyle(Tokens.textMuted)
            }
        }
        .padding(.horizontal, Tokens.spaceM)
    }

    private func lumenStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles").foregroundStyle(Color(hex: 0xE7D6FF))
                Text(value).font(.lunNumber(22)).foregroundStyle(Tokens.textPrimary)
            }
            Text(label).font(.lunBody(12)).foregroundStyle(Tokens.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PrestigeCard: View {
    @Bindable var engine: GameEngine
    let def: PrestigeUpgradeDef

    var body: some View {
        let level = engine.state.prestigeLevel(def.id)
        let maxed = level >= def.maxLevel
        let cost = engine.prestigeCost(def)
        let canBuy = engine.canBuyPrestige(def)

        LunPanel {
            VStack(alignment: .leading, spacing: Tokens.spaceS) {
                HStack(alignment: .top) {
                    Image(systemName: def.icon).font(.system(size: 17, weight: .bold)).foregroundStyle(Color(hex: 0xC7A8FF))
                        .frame(width: 38, height: 38).background(Circle().fill(Tokens.ink.opacity(0.5)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(def.name).font(.lunTitle(16)).foregroundStyle(Tokens.textPrimary)
                        Text(def.detail).font(.lunBody(13)).foregroundStyle(Tokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Text("Lv \(level)").font(.lunNumber(15)).foregroundStyle(Color(hex: 0xC7A8FF))
                }
                LunProgressBar(value: Double(level) / Double(def.maxLevel), tint: Color(hex: 0xA784FF))
                if maxed {
                    Text("Fully upgraded").font(.lunBody(13).weight(.bold)).foregroundStyle(Color(hex: 0xC7A8FF))
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                } else {
                    Button {
                        engine.buyPrestigeUpgrade(def)
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("\(Int(cost)) Lumens").font(.lunNumber(15))
                            Spacer()
                            Text("Empower").font(.lunTitle(15))
                        }
                        .foregroundStyle(canBuy ? Tokens.ink : Tokens.textMuted)
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: Tokens.cornerSmall, style: .continuous)
                            .fill(canBuy ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xC7A8FF), Color(hex: 0x8E6BE0)], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Tokens.panel.opacity(0.7))))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canBuy)
                }
            }
        }
    }
}
