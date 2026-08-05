import Foundation

extension GameEngine {
    func recordMetric(_ metric: MissionMetric, amount: Double) {
        guard amount != 0 else { return }
        for index in state.missions.indices {
            guard let def = ContentLibrary.missionTemplates.first(where: { $0.id == state.missions[index].defId }) else { continue }
            if def.metric == metric && !state.missions[index].claimed {
                state.missions[index].progress = min(state.missions[index].target, state.missions[index].progress + amount)
            }
        }
        if let def = ContentLibrary.missionTemplates.first(where: { $0.id == state.daily.defId }), def.metric == metric, !state.daily.claimed {
            state.daily.progress = min(state.daily.target, state.daily.progress + amount)
        }
    }

    func registerSafeArrival() {
        recordMetric(.avoidWreck, amount: 1)
        recordMetric(.dodgeMine, amount: mines.isEmpty ? 0 : 0)
    }

    func resetWreckStreak() {
        for index in state.missions.indices {
            guard let def = ContentLibrary.missionTemplates.first(where: { $0.id == state.missions[index].defId }) else { continue }
            if def.metric == .avoidWreck && !state.missions[index].completed && !state.missions[index].claimed {
                state.missions[index].progress = 0
            }
        }
        if let def = ContentLibrary.missionTemplates.first(where: { $0.id == state.daily.defId }), def.metric == .avoidWreck, !state.daily.completed, !state.daily.claimed {
            state.daily.progress = 0
        }
    }

    func ensureMissions() {
        let activeIds = Set(state.missions.map { $0.defId })
        let pool = ContentLibrary.missionTemplates.filter { $0.metric != .prestige }
        while state.missions.count < 3 {
            let candidates = pool.filter { template in
                !activeIds.contains(template.id) && !state.missions.contains { $0.defId == template.id }
            }
            let choice = candidates.isEmpty ? pool[rng.intRange(0, pool.count)] : candidates[rng.intRange(0, candidates.count)]
            state.missions.append(MissionState(id: UUID().uuidString, defId: choice.id, progress: 0, target: choice.target, claimed: false))
        }
    }

    func claimMission(_ mission: MissionState) {
        guard let index = state.missions.firstIndex(where: { $0.id == mission.id }) else { return }
        guard state.missions[index].completed, !state.missions[index].claimed else { return }
        guard let def = ContentLibrary.missionTemplates.first(where: { $0.id == state.missions[index].defId }) else { return }
        state.gold += def.rewardGold
        state.stats.totalGold += def.rewardGold
        state.salvage += def.rewardSalvage
        state.missions.remove(at: index)
        ensureMissions()
        Haptics.success()
        AudioService.shared.playChime()
        showToast("Contract complete: \(def.name)", icon: "checkmark.seal.fill", color: Tokens.safe)
        checkAchievements()
        bumpVersion()
    }

    func dateKey(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    func refreshDaily() {
        let key = dateKey(Date())
        if state.daily.dateKey == key && !state.daily.defId.isEmpty { return }
        let pool = ContentLibrary.missionTemplates.filter { $0.metric != .prestige }
        let seed = fnvHash(key)
        let choice = pool[Int(seed % UInt64(pool.count))]
        let scaledTarget = (choice.target * 1.5).rounded()
        state.daily = DailyState(dateKey: key, defId: choice.id, progress: 0, target: scaledTarget, claimed: false)
        bumpVersion()
    }

    func claimDaily() {
        guard state.daily.completed, !state.daily.claimed else { return }
        guard let def = ContentLibrary.missionTemplates.first(where: { $0.id == state.daily.defId }) else { return }
        state.gold += def.rewardGold * 2
        state.stats.totalGold += def.rewardGold * 2
        state.salvage += def.rewardSalvage * 2
        state.daily.claimed = true
        state.stats.dailyCompletions += 1
        Haptics.success()
        AudioService.shared.playChime()
        showToast("Daily Harbor complete!", icon: "calendar.badge.checkmark", color: Tokens.safe)
        checkAchievements()
        bumpVersion()
    }

    func achievementProgress(_ def: AchievementDef) -> Double {
        state.stats.value(for: def.metric, keeperLevels: state.keeperLevelTotal, upgradeLevels: state.upgradeLevelTotal)
    }

    func isAchievementUnlocked(_ def: AchievementDef) -> Bool {
        achievementProgress(def) >= def.target
    }

    func isAchievementClaimed(_ def: AchievementDef) -> Bool {
        state.achievementsClaimed.contains(def.id)
    }

    func checkAchievements() {
        for def in ContentLibrary.achievements where !state.achievementsClaimed.contains(def.id) {
            if isAchievementUnlocked(def) {
                state.achievementsClaimed.insert(def.id)
                state.salvage += def.rewardSalvage
                showToast("Achievement: \(def.name)", icon: def.icon, color: Tokens.brassBright)
                Haptics.success()
            }
        }
    }

    func applyOfflineProgress() {
        let now = Date()
        let elapsed = now.timeIntervalSince(state.lastActive)
        state.lastActive = now
        guard elapsed >= Balance.minOfflineSeconds else { return }
        guard stats.idleGoldPerSecond > 0 || stats.idleOilPerSecond > 0 else { return }
        let cap = stats.offlineHours * 3600
        let capped = elapsed > cap
        let effective = min(elapsed, cap) * Balance.offlineEfficiency
        let gold = stats.idleGoldPerSecond * effective
        let oil = stats.idleOilPerSecond * effective
        guard gold > 0 || oil > 0 else { return }
        state.gold += gold
        state.oil += oil
        state.stats.totalGold += gold
        state.stats.idleSeconds += elapsed
        state.stats.idleCollections += 1
        idleReport = IdleReport(seconds: min(elapsed, cap), gold: gold, oil: oil, capped: capped)
        checkAchievements()
        bumpVersion()
    }

    func dismissIdleReport() {
        idleReport = nil
    }

    func resetProgress() {
        SaveService.shared.wipe()
        state = GameEngine.freshState()
        syncTutorialFlag()
        rng = DeterministicRandom(seed: state.rngSeed)
        rebuildStats()
        ships.removeAll()
        mines.removeAll()
        fogBanks.removeAll()
        floatingRewards.removeAll()
        configureBay()
        ensureMissions()
        refreshDaily()
        syncAudioSettings()
        bumpVersion()
    }

    func resetTutorial() {
        state.tutorialDone = false
        syncTutorialFlag()
        bumpVersion()
    }

    func completeTutorial() {
        state.tutorialDone = true
        syncTutorialFlag()
        persist()
        bumpVersion()
    }
}
