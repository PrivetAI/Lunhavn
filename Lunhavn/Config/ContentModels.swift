import Foundation

enum UpgradeBranch: String, Codable, CaseIterable {
    case lamp
    case beam
    case mechanism
    case optics
    case harbor

    var title: String {
        switch self {
        case .lamp: return "Lamp"
        case .beam: return "Beam"
        case .mechanism: return "Mechanism"
        case .optics: return "Optics"
        case .harbor: return "Harbor"
        }
    }

    var icon: String {
        switch self {
        case .lamp: return "lightbulb.fill"
        case .beam: return "rays"
        case .mechanism: return "gearshape.2.fill"
        case .optics: return "eye.fill"
        case .harbor: return "sailboat.fill"
        }
    }
}

enum UpgradeEffect: String, Codable {
    case brightness
    case beamWidth
    case beamRange
    case edgeSharpness
    case rotationSpeed
    case secondSpotlight
    case fogPiercing
    case goldMultiplier
    case oilMultiplier
    case shipSpeed
    case harborCapacity
    case confidenceRetention
}

enum Currency: String, Codable, CaseIterable {
    case gold
    case oil
    case salvage
    case lumen

    var label: String {
        switch self {
        case .gold: return "Gold"
        case .oil: return "Oil"
        case .salvage: return "Salvage"
        case .lumen: return "Lumens"
        }
    }

    var icon: String {
        switch self {
        case .gold: return "circle.hexagongrid.fill"
        case .oil: return "drop.fill"
        case .salvage: return "shippingbox.fill"
        case .lumen: return "sparkles"
        }
    }
}

struct UpgradeDef: Identifiable {
    let id: String
    let name: String
    let detail: String
    let branch: UpgradeBranch
    let effect: UpgradeEffect
    let baseValue: Double
    let maxLevel: Int
    let baseCost: Double
    let costGrowth: Double
    let currency: Currency
    let requires: String?
    let requiresLevel: Int
}

struct KeeperDef: Identifiable {
    let id: String
    let name: String
    let detail: String
    let icon: String
    let baseCost: Double
    let costGrowth: Double
    let idleGoldPerLevel: Double
    let idleOilPerLevel: Double
    let activeAssistPerLevel: Double
    let maxLevel: Int
}

struct ShipTypeDef: Identifiable {
    let id: String
    let name: String
    let colorIndex: Int
    let reward: Double
    let oilReward: Double
    let speed: Double
    let weight: Double
    let minStage: Int
    let symbol: String
}

enum MissionMetric: String, Codable {
    case guide
    case sort
    case avoidWreck
    case dodgeMine
    case weatherStorm
    case earnGold
    case prestige
}

struct MissionDef: Identifiable {
    let id: String
    let name: String
    let detail: String
    let icon: String
    let metric: MissionMetric
    let target: Double
    let rewardGold: Double
    let rewardSalvage: Double
}

struct AchievementDef: Identifiable {
    let id: String
    let name: String
    let detail: String
    let icon: String
    let metric: String
    let target: Double
    let rewardSalvage: Double
}

enum CosmeticKind: String, Codable {
    case sky
    case sea
    case beam
    case lighthouse
}

struct LighthouseSkinDef: Identifiable {
    let id: String
    let name: String
    let body: UInt32
    let stripe: UInt32
    let lamp: UInt32
}

struct CosmeticDef: Identifiable {
    let id: String
    let name: String
    let detail: String
    let kind: CosmeticKind
    let paletteId: String
    let cost: Double
    let currency: Currency
}

enum PrestigeEffect: String, Codable {
    case globalGold
    case globalConfidence
    case offlineHours
    case keeperBoost
    case startingGold
    case oilGain
}

struct PrestigeUpgradeDef: Identifiable {
    let id: String
    let name: String
    let detail: String
    let icon: String
    let effect: PrestigeEffect
    let baseValue: Double
    let maxLevel: Int
    let baseCost: Double
    let costGrowth: Double
}
