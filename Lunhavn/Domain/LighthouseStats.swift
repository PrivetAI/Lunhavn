import Foundation

struct LighthouseStats {
    var brightness = Balance.baseBrightness
    var beamHalfAngle = Balance.baseBeamHalfAngle
    var beamRange = Balance.baseBeamRange
    var edgeSharpness = Balance.baseEdgeSharpness
    var rotationSpeed = Balance.baseRotationSpeed
    var hasSecondSpotlight = false
    var fogPiercing = 0.0
    var goldMultiplier = 1.0
    var oilMultiplier = 1.0
    var shipSpeedMultiplier = 1.0
    var harborCapacity = Balance.baseConcurrentShips
    var confidenceRetention = 0.0

    var globalGoldMultiplier = 1.0
    var globalConfidenceMultiplier = 1.0
    var keeperMultiplier = 1.0
    var oilGainMultiplier = 1.0
    var offlineHours = Balance.baseOfflineHours
    var startingGold = 0.0

    var idleGoldPerSecond = 0.0
    var idleOilPerSecond = 0.0
    var keeperAssist = 0.0

    static func build(from state: GameState) -> LighthouseStats {
        var stats = LighthouseStats()

        for def in ContentLibrary.prestigeUpgrades {
            let level = state.prestigeLevel(def.id)
            guard level > 0 else { continue }
            let total = def.baseValue * Double(level)
            switch def.effect {
            case .globalGold: stats.globalGoldMultiplier += total
            case .globalConfidence: stats.globalConfidenceMultiplier += total
            case .offlineHours: stats.offlineHours += total
            case .keeperBoost: stats.keeperMultiplier += total
            case .startingGold: stats.startingGold += total
            case .oilGain: stats.oilGainMultiplier += total
            }
        }

        for def in ContentLibrary.upgrades {
            let level = state.upgradeLevel(def.id)
            guard level > 0 else { continue }
            let total = def.baseValue * Double(level)
            switch def.effect {
            case .brightness: stats.brightness += total
            case .beamWidth: stats.beamHalfAngle += total
            case .beamRange: stats.beamRange += total
            case .edgeSharpness: stats.edgeSharpness += total
            case .rotationSpeed: stats.rotationSpeed += total
            case .secondSpotlight: stats.hasSecondSpotlight = level > 0
            case .fogPiercing: stats.fogPiercing += total
            case .goldMultiplier: stats.goldMultiplier += total
            case .oilMultiplier: stats.oilMultiplier += total
            case .shipSpeed: stats.shipSpeedMultiplier += total
            case .harborCapacity: stats.harborCapacity += Int(total)
            case .confidenceRetention: stats.confidenceRetention += total
            }
        }

        stats.beamHalfAngle = min(stats.beamHalfAngle, Balance.beamArcLimit * 0.8)
        stats.beamRange = min(stats.beamRange, 1.05)
        stats.fogPiercing = min(stats.fogPiercing, 0.95)
        stats.edgeSharpness = min(stats.edgeSharpness, 0.96)

        var idleGold = 0.0
        var idleOil = 0.0
        var assist = 0.0
        for def in ContentLibrary.keepers {
            let level = state.keeperLevel(def.id)
            guard level > 0 else { continue }
            idleGold += def.idleGoldPerLevel * Double(level)
            idleOil += def.idleOilPerLevel * Double(level)
            assist += def.activeAssistPerLevel * Double(level)
        }
        stats.idleGoldPerSecond = idleGold * stats.keeperMultiplier * stats.globalGoldMultiplier
        stats.idleOilPerSecond = idleOil * stats.keeperMultiplier * stats.oilGainMultiplier
        stats.keeperAssist = assist * stats.keeperMultiplier

        return stats
    }

    var effectiveGoldMultiplier: Double { goldMultiplier * globalGoldMultiplier }
    var effectiveOilMultiplier: Double { oilMultiplier * oilGainMultiplier }
    var confidenceGainRate: Double { Balance.baseConfidenceGain * brightness * globalConfidenceMultiplier }
    var confidenceDecayRate: Double { max(0.05, Balance.baseConfidenceDecay - confidenceRetention) }
}
