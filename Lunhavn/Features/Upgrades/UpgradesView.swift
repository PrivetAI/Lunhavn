import SwiftUI

struct UpgradesView: View {
    @Bindable var engine: GameEngine
    @State private var branch: UpgradeBranch = .lamp

    var body: some View {
        let _ = engine.version
        return ZStack {
            NightBackground(engine: engine)
            VStack(spacing: Tokens.spaceM) {
                header
                branchPicker
                ScrollView {
                    VStack(spacing: Tokens.spaceM) {
                        ForEach(upgrades) { def in
                            UpgradeCard(engine: engine, def: def)
                        }
                    }
                    .padding(.horizontal, Tokens.spaceM)
                    .padding(.bottom, 96)
                }
            }
            .padding(.top, 8)
        }
    }

    private var upgrades: [UpgradeDef] {
        ContentLibrary.upgrades.filter { $0.branch == branch }
    }

    private var header: some View {
        VStack(spacing: Tokens.spaceS) {
            HStack {
                ScreenTitle(title: "Upgrades", subtitle: "Tend and grow the lighthouse")
                Spacer()
            }
            TopCurrencyBar(engine: engine, currencies: [.gold, .oil])
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Tokens.spaceM)
    }

    private var branchPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(UpgradeBranch.allCases, id: \.self) { b in
                    Button {
                        Haptics.tap()
                        withAnimation(.easeOut(duration: 0.2)) { branch = b }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: b.icon).font(.system(size: 12, weight: .bold))
                            Text(b.title).font(.lunBody(14).weight(.semibold))
                        }
                        .foregroundStyle(branch == b ? Tokens.ink : Tokens.textSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(branch == b ? Tokens.brass : Tokens.panel.opacity(0.8)))
                        .overlay(Capsule().strokeBorder(Tokens.brass.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Tokens.spaceM)
        }
    }
}

struct UpgradeCard: View {
    @Bindable var engine: GameEngine
    let def: UpgradeDef

    var body: some View {
        let level = engine.state.upgradeLevel(def.id)
        let unlocked = engine.isUpgradeUnlocked(def)
        let maxed = level >= def.maxLevel
        let cost = engine.upgradeCost(def)
        let canBuy = engine.canBuyUpgrade(def)

        LunPanel {
            VStack(alignment: .leading, spacing: Tokens.spaceS) {
                HStack(alignment: .top) {
                    Image(systemName: def.branch.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Tokens.brassBright)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Tokens.ink.opacity(0.5)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(def.name).font(.lunTitle(17)).foregroundStyle(Tokens.textPrimary)
                        Text(def.detail).font(.lunBody(13)).foregroundStyle(Tokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                if unlocked {
                    HStack {
                        Text("Level \(level) / \(def.maxLevel)")
                            .font(.lunBody(12).weight(.semibold)).foregroundStyle(Tokens.textMuted)
                        Spacer()
                        Text(effectLabel).font(.lunBody(12).weight(.semibold)).foregroundStyle(Tokens.safe)
                    }
                    LunProgressBar(value: Double(level) / Double(def.maxLevel), tint: Tokens.brass)

                    if maxed {
                        Text("Fully upgraded")
                            .font(.lunBody(13).weight(.bold))
                            .foregroundStyle(Tokens.brassBright)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    } else {
                        Button {
                            engine.buyUpgrade(def)
                        } label: {
                            HStack {
                                Image(systemName: def.currency.icon)
                                Text(cost.compactString).font(.lunNumber(15))
                                Spacer()
                                Text("Upgrade").font(.lunTitle(15))
                            }
                            .foregroundStyle(canBuy ? Tokens.ink : Tokens.textMuted)
                            .padding(.horizontal, 14).padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: Tokens.cornerSmall, style: .continuous)
                                .fill(canBuy ? AnyShapeStyle(LinearGradient(colors: [Tokens.brassBright, Tokens.brass], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Tokens.panel.opacity(0.7))))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canBuy)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill").foregroundStyle(Tokens.textMuted)
                        Text(lockLabel).font(.lunBody(13)).foregroundStyle(Tokens.textMuted)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var effectLabel: String {
        switch def.effect {
        case .secondSpotlight: return "Unlocks a second beam"
        case .harborCapacity: return "+\(Int(def.baseValue)) berth"
        case .goldMultiplier, .oilMultiplier, .shipSpeed, .brightness, .confidenceRetention:
            return "+\(Int(def.baseValue * 100))% / level"
        default:
            return "+\(String(format: "%.2f", def.baseValue)) / level"
        }
    }

    private var lockLabel: String {
        guard let req = def.requires, let reqDef = ContentLibrary.upgrade(req) else { return "Locked" }
        return "Requires \(reqDef.name) Lv \(def.requiresLevel)"
    }
}
