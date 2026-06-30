import CoreGraphics
import Foundation

enum Balance {
    static let fixedTimestep = 1.0 / 60.0
    static let maxStepsPerFrame = 6

    static let baseBeamHalfAngle = 0.16
    static let baseBeamRange = 0.52
    static let baseBrightness = 1.0
    static let baseEdgeSharpness = 0.5
    static let baseRotationSpeed = 2.6
    static let beamArcLimit = 1.32

    static let baseConfidenceGain = 0.85
    static let baseConfidenceDecay = 0.28
    static let baseShipSpeed = 0.052
    static let arrivalRadius = 0.05
    static let driftStrength = 0.06
    static let hazardPullStrength = 0.05

    static let lighthouse = Vec(x: 0.5, y: 0.085)
    static let shoreY = 0.2
    static let spawnY = 0.97
    static let seaTop = 0.16

    static let baseSpawnInterval = 3.4
    static let minSpawnInterval = 0.9
    static let baseConcurrentShips = 5

    static let rockCount = 5
    static let baseMineChance = 0.16
    static let mineDetonatePenaltyGold = 0.12
    static let wreckPenaltyGold = 0.1

    static let dayLength = 90.0
    static let weatherMinDuration = 22.0
    static let weatherMaxDuration = 40.0
    static let fogDimming = 0.55
    static let stormVisibility = 0.55
    static let stormDrift = 0.09

    static let baseOfflineHours = 4.0
    static let offlineEfficiency = 0.55
    static let minOfflineSeconds = 60.0

    static let prestigeRequirement = 50000.0
    static let prestigeExponent = 0.5
    static let prestigeScale = 1.0 / 220.0

    static func upgradeCost(_ def: UpgradeDef, level: Int) -> Double {
        def.baseCost * pow(def.costGrowth, Double(level))
    }

    static func keeperCost(_ def: KeeperDef, level: Int) -> Double {
        def.baseCost * pow(def.costGrowth, Double(level))
    }

    static func prestigeCost(_ def: PrestigeUpgradeDef, level: Int) -> Double {
        (def.baseCost * pow(def.costGrowth, Double(level))).rounded()
    }

    static func lumensFor(totalGold: Double) -> Double {
        guard totalGold >= prestigeRequirement else { return 0 }
        return floor(pow(totalGold * prestigeScale, prestigeExponent))
    }

    static func stageFor(prestiges: Int, shipsGuided: Int) -> Int {
        let byShips = shipsGuided / 60
        return min(6, byShips + prestiges)
    }
}
