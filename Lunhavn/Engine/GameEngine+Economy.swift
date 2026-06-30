import Foundation

extension GameEngine {
    func harbor(_ ship: Ship) {
        ship.arrived = true
        ship.illumination = 1
        let berth = berths.min { abs($0.pos.x - ship.pos.x) < abs($1.pos.x - ship.pos.x) }
        let correct = berth?.colorIndex == ship.type.colorIndex
        let baseGold = ship.type.reward * stats.effectiveGoldMultiplier
        let gold = correct ? baseGold : baseGold * 0.4
        state.gold += gold
        state.stats.totalGold += gold

        if correct {
            let oil = ship.type.oilReward * stats.effectiveOilMultiplier
            if oil > 0 { state.oil += oil }
            state.stats.shipsSorted += 1
            recordMetric(.sort, amount: 1)
            if rng.chance(0.06) { state.salvage += 1 }
            AudioService.shared.playChime()
            AudioService.shared.playHorn()
            spawnReward(at: ship.pos, text: "+\(gold.compactString)", color: 0xFFD98A)
        } else {
            spawnReward(at: ship.pos, text: "+\(gold.compactString)", color: 0xC9A24B)
        }

        state.stats.shipsGuided += 1
        recordMetric(.guide, amount: 1)
        recordMetric(.earnGold, amount: gold)
        registerSafeArrival()
        Haptics.arrive()
        checkAchievements()
    }

    func wreck(_ ship: Ship) {
        guard !ship.wrecking else { return }
        ship.wrecking = true
        ship.wreckTimer = 0.9
        ship.confidence = 0
        state.stats.wrecks += 1
        let penalty = min(state.gold * 0.04, 30)
        state.gold = max(0, state.gold - penalty)
        resetWreckStreak()
        spawnReward(at: ship.pos, text: "wreck", color: 0xE07B6B)
        AudioService.shared.playThud()
        Haptics.warning()
        showToast("A ship struck the rocks.", icon: "exclamationmark.triangle.fill", color: Tokens.hazard)
    }

    func detonateMine(_ mine: Mine) {
        guard !mine.detonating else { return }
        mine.detonating = true
        mine.detonateTimer = 0.5
        state.stats.minesDetonated += 1
        let penalty = min(state.gold * mineDetonateShare(), 40)
        state.gold = max(0, state.gold - penalty)
        for ship in ships where ship.alive && !ship.arrived {
            if ship.pos.distance(to: mine.pos) < 0.18 {
                ship.confidence = max(0, ship.confidence - 0.5)
                ship.nearMineFlash = 1
            }
        }
        spawnReward(at: mine.pos, text: "mine!", color: 0xE0556B)
        AudioService.shared.playThud()
        Haptics.warning()
        showToast("Don't light the mines!", icon: "burst.fill", color: Tokens.mine)
    }

    private func mineDetonateShare() -> Double { Balance.mineDetonatePenaltyGold }

    private func spawnReward(at pos: Vec, text: String, color: UInt32) {
        floatingRewards.append(FloatingReward(id: rewardId(), pos: pos, text: text, color: color))
        if floatingRewards.count > 24 { floatingRewards.removeFirst() }
    }

    private func rewardId() -> Int { Int.random(in: 1...Int.max) }

    func canAfford(_ amount: Double, currency: Currency) -> Bool {
        state.balance(of: currency) >= amount
    }

    func spend(_ amount: Double, currency: Currency) {
        switch currency {
        case .gold: state.gold = max(0, state.gold - amount)
        case .oil: state.oil = max(0, state.oil - amount)
        case .salvage: state.salvage = max(0, state.salvage - amount)
        case .lumen: state.lumen = max(0, state.lumen - amount)
        }
    }

    func upgradeCost(_ def: UpgradeDef) -> Double {
        Balance.upgradeCost(def, level: state.upgradeLevel(def.id))
    }

    func isUpgradeUnlocked(_ def: UpgradeDef) -> Bool {
        guard let req = def.requires else { return true }
        return state.upgradeLevel(req) >= def.requiresLevel
    }

    func canBuyUpgrade(_ def: UpgradeDef) -> Bool {
        guard isUpgradeUnlocked(def) else { return false }
        guard state.upgradeLevel(def.id) < def.maxLevel else { return false }
        return canAfford(upgradeCost(def), currency: def.currency)
    }

    @discardableResult
    func buyUpgrade(_ def: UpgradeDef) -> Bool {
        guard canBuyUpgrade(def) else { return false }
        spend(upgradeCost(def), currency: def.currency)
        state.upgradeLevels[def.id, default: 0] += 1
        if def.effect == .secondSpotlight { state.secondSpotlightOn = true }
        rebuildStats()
        AudioService.shared.playChime()
        Haptics.success()
        recordMetric(.guide, amount: 0)
        checkAchievements()
        bumpVersion()
        return true
    }

    func keeperCost(_ def: KeeperDef) -> Double {
        Balance.keeperCost(def, level: state.keeperLevel(def.id))
    }

    func canBuyKeeper(_ def: KeeperDef) -> Bool {
        state.keeperLevel(def.id) < def.maxLevel && canAfford(keeperCost(def), currency: .gold)
    }

    @discardableResult
    func buyKeeper(_ def: KeeperDef) -> Bool {
        guard canBuyKeeper(def) else { return false }
        spend(keeperCost(def), currency: .gold)
        state.keeperLevels[def.id, default: 0] += 1
        rebuildStats()
        AudioService.shared.playChime()
        Haptics.success()
        checkAchievements()
        bumpVersion()
        return true
    }

    func prestigeCost(_ def: PrestigeUpgradeDef) -> Double {
        Balance.prestigeCost(def, level: state.prestigeLevel(def.id))
    }

    func canBuyPrestige(_ def: PrestigeUpgradeDef) -> Bool {
        state.prestigeLevel(def.id) < def.maxLevel && canAfford(prestigeCost(def), currency: .lumen)
    }

    @discardableResult
    func buyPrestigeUpgrade(_ def: PrestigeUpgradeDef) -> Bool {
        guard canBuyPrestige(def) else { return false }
        spend(prestigeCost(def), currency: .lumen)
        state.prestigeLevels[def.id, default: 0] += 1
        rebuildStats()
        Haptics.success()
        AudioService.shared.playChime()
        bumpVersion()
        return true
    }

    var pendingLumens: Double {
        Balance.lumensFor(totalGold: state.stats.totalGold)
    }

    var canPrestige: Bool {
        pendingLumens >= 1
    }

    func performPrestige() {
        let gained = max(0, pendingLumens)
        guard gained >= 1 else { return }
        var preserved = state
        let newLumenTotal = preserved.lumen + gained
        preserved.lumen = newLumenTotal
        preserved.lifetimeLumens += gained

        var fresh = GameEngine.freshState()
        fresh.lumen = preserved.lumen
        fresh.lifetimeLumens = preserved.lifetimeLumens
        fresh.prestigeLevels = preserved.prestigeLevels
        fresh.ownedCosmetics = preserved.ownedCosmetics
        fresh.equippedSky = preserved.equippedSky
        fresh.equippedSea = preserved.equippedSea
        fresh.equippedBeam = preserved.equippedBeam
        fresh.equippedLighthouse = preserved.equippedLighthouse
        fresh.salvage = preserved.salvage
        fresh.achievementsClaimed = preserved.achievementsClaimed
        fresh.settings = preserved.settings
        fresh.tutorialDone = preserved.tutorialDone
        fresh.stats = preserved.stats
        fresh.stats.prestiges += 1
        fresh.stats.totalGold = 0
        fresh.daily = preserved.daily
        fresh.rngSeed = rng.nextUInt()

        state = fresh
        rng = DeterministicRandom(seed: fresh.rngSeed)
        rebuildStats()
        state.gold = stats.startingGold
        ships.removeAll()
        mines.removeAll()
        fogBanks.removeAll()
        floatingRewards.removeAll()
        configureBay()
        ensureMissions()
        recordMetric(.prestige, amount: 1)
        checkAchievements()
        persist()
        Haptics.success()
        AudioService.shared.playChime()
        bumpVersion()
    }

    func ownsCosmetic(_ id: String) -> Bool {
        state.ownedCosmetics.contains(id)
    }

    @discardableResult
    func buyCosmetic(_ def: CosmeticDef) -> Bool {
        guard !ownsCosmetic(def.id) else { equipCosmetic(def); return true }
        guard canAfford(def.cost, currency: def.currency) else { return false }
        spend(def.cost, currency: def.currency)
        state.ownedCosmetics.insert(def.id)
        equipCosmetic(def)
        Haptics.success()
        AudioService.shared.playChime()
        bumpVersion()
        return true
    }

    func equipCosmetic(_ def: CosmeticDef) {
        switch def.kind {
        case .sky: state.equippedSky = def.paletteId
        case .sea: state.equippedSea = def.paletteId
        case .beam: state.equippedBeam = def.paletteId
        case .lighthouse: state.equippedLighthouse = def.paletteId
        }
        Haptics.tap()
        bumpVersion()
    }

    func isEquipped(_ def: CosmeticDef) -> Bool {
        switch def.kind {
        case .sky: return state.equippedSky == def.paletteId
        case .sea: return state.equippedSea == def.paletteId
        case .beam: return state.equippedBeam == def.paletteId
        case .lighthouse: return state.equippedLighthouse == def.paletteId
        }
    }
}
