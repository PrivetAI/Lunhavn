import SwiftUI

struct VoyagesView: View {
    @Bindable var engine: GameEngine

    var body: some View {
        let _ = engine.version
        return ZStack {
            NightBackground(engine: engine)
            VStack(spacing: Tokens.spaceM) {
                header
                ScrollView {
                    VStack(spacing: Tokens.spaceM) {
                        dailySection
                        contractsSection
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
                ScreenTitle(title: "Voyages", subtitle: "Contracts and the daily harbor")
                Spacer()
            }
            TopCurrencyBar(engine: engine, currencies: [.gold, .salvage])
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Tokens.spaceM)
    }

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: Tokens.spaceS) {
            LunSectionHeader(title: "Daily Harbor", subtitle: "Resets each day")
            if let def = ContentLibrary.missionTemplates.first(where: { $0.id == engine.state.daily.defId }) {
                DailyCard(engine: engine, def: def)
            }
        }
    }

    private var contractsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.spaceS) {
            LunSectionHeader(title: "Contracts", subtitle: "Complete to earn gold and salvage")
            if engine.state.missions.isEmpty {
                EmptyStateView(icon: "scroll", title: "No contracts", message: "New contracts will arrive shortly.")
            } else {
                ForEach(engine.state.missions) { mission in
                    if let def = ContentLibrary.missionTemplates.first(where: { $0.id == mission.defId }) {
                        MissionCard(engine: engine, mission: mission, def: def)
                    }
                }
            }
        }
    }
}

struct DailyCard: View {
    @Bindable var engine: GameEngine
    let def: MissionDef

    var body: some View {
        let daily = engine.state.daily
        LunPanel(tint: Tokens.wood) {
            VStack(alignment: .leading, spacing: Tokens.spaceS) {
                HStack {
                    Image(systemName: def.icon).font(.system(size: 18, weight: .bold)).foregroundStyle(Tokens.brassBright)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(def.name).font(.lunTitle(17)).foregroundStyle(Tokens.textPrimary)
                        Text(def.detail).font(.lunBody(13)).foregroundStyle(Tokens.textSecondary)
                    }
                    Spacer()
                }
                progressLine(progress: daily.progress, target: daily.target)
                rewardRow(gold: def.rewardGold * 2, salvage: def.rewardSalvage * 2)
                if daily.claimed {
                    claimedLabel
                } else if daily.completed {
                    claimButton { engine.claimDaily() }
                }
            }
        }
    }

    private func progressLine(progress: Double, target: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(Int(progress)) / \(Int(target))").font(.lunBody(12).weight(.semibold)).foregroundStyle(Tokens.textMuted)
                Spacer()
            }
            LunProgressBar(value: target > 0 ? progress / target : 0, tint: Tokens.brassBright)
        }
    }

    private func rewardRow(gold: Double, salvage: Double) -> some View {
        HStack(spacing: 8) {
            LunChip(text: gold.compactString, systemImage: "circle.hexagongrid.fill", color: Tokens.brassBright)
            LunChip(text: salvage.compactString, systemImage: "shippingbox.fill", color: Tokens.safe)
        }
    }

    private var claimedLabel: some View {
        Text("Claimed — see you tomorrow")
            .font(.lunBody(13).weight(.bold)).foregroundStyle(Tokens.safe)
            .frame(maxWidth: .infinity).padding(.vertical, 8)
    }

    private func claimButton(_ action: @escaping () -> Void) -> some View {
        LunButton(title: "Claim Reward", icon: "gift.fill", fullWidth: true, action: action)
    }
}

struct MissionCard: View {
    @Bindable var engine: GameEngine
    let mission: MissionState
    let def: MissionDef

    var body: some View {
        LunPanel {
            VStack(alignment: .leading, spacing: Tokens.spaceS) {
                HStack {
                    Image(systemName: def.icon).font(.system(size: 17, weight: .bold)).foregroundStyle(Tokens.brass)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(def.name).font(.lunTitle(16)).foregroundStyle(Tokens.textPrimary)
                        Text(def.detail).font(.lunBody(13)).foregroundStyle(Tokens.textSecondary)
                    }
                    Spacer()
                }
                HStack {
                    Text("\(Int(mission.progress)) / \(Int(mission.target))").font(.lunBody(12).weight(.semibold)).foregroundStyle(Tokens.textMuted)
                    Spacer()
                    LunChip(text: def.rewardGold.compactString, systemImage: "circle.hexagongrid.fill", color: Tokens.brassBright)
                    LunChip(text: def.rewardSalvage.compactString, systemImage: "shippingbox.fill", color: Tokens.safe)
                }
                LunProgressBar(value: mission.target > 0 ? mission.progress / mission.target : 0, tint: mission.completed ? Tokens.safe : Tokens.brass)
                if mission.completed {
                    LunButton(title: "Claim Reward", icon: "checkmark.seal.fill", fullWidth: true) {
                        engine.claimMission(mission)
                    }
                }
            }
        }
    }
}
