import SwiftUI

struct AchievementsView: View {
    @Bindable var engine: GameEngine
    let onClose: () -> Void

    var body: some View {
        let _ = engine.version
        return CoverScreen(engine: engine, title: "Achievements", subtitle: "Milestones of your watch", onClose: onClose) {
            ScrollView {
                VStack(spacing: Tokens.spaceM) {
                    summary
                    ForEach(ContentLibrary.achievements) { def in
                        AchievementRow(engine: engine, def: def)
                    }
                }
                .padding(.horizontal, Tokens.spaceM)
                .padding(.bottom, 24)
            }
        }
    }

    private var summary: some View {
        let unlocked = ContentLibrary.achievements.filter { engine.isAchievementUnlocked($0) }.count
        let total = ContentLibrary.achievements.count
        return LunPanel(tint: Tokens.wood) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(unlocked) of \(total) unlocked").font(.lunTitle(18)).foregroundStyle(Tokens.textPrimary)
                    Text("Salvage rewards arrive automatically").font(.lunBody(12)).foregroundStyle(Tokens.textMuted)
                }
                Spacer()
                Image(systemName: "rosette").font(.system(size: 30)).foregroundStyle(Tokens.brassBright)
            }
        }
    }
}

struct AchievementRow: View {
    @Bindable var engine: GameEngine
    let def: AchievementDef

    var body: some View {
        let progress = engine.achievementProgress(def)
        let unlocked = engine.isAchievementUnlocked(def)

        LunPanel {
            HStack(spacing: Tokens.spaceM) {
                Image(systemName: def.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(unlocked ? Tokens.brassBright : Tokens.textMuted)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Tokens.ink.opacity(0.5)))
                    .overlay(Circle().strokeBorder(unlocked ? Tokens.brass : Tokens.textMuted.opacity(0.3), lineWidth: 1))
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(def.name).font(.lunTitle(16)).foregroundStyle(Tokens.textPrimary)
                        if unlocked { Image(systemName: "checkmark.seal.fill").foregroundStyle(Tokens.safe).font(.system(size: 13)) }
                    }
                    Text(def.detail).font(.lunBody(12)).foregroundStyle(Tokens.textSecondary)
                    if !unlocked {
                        LunProgressBar(value: min(1, progress / def.target), tint: Tokens.brass, height: 6)
                        Text("\(progress.compactString) / \(def.target.compactString)").font(.lunBody(11)).foregroundStyle(Tokens.textMuted)
                    }
                }
                Spacer()
                LunChip(text: def.rewardSalvage.compactString, systemImage: "shippingbox.fill", color: Tokens.safe)
            }
        }
    }
}
