import Foundation

struct GameSettings: Codable {
    var musicEnabled = true
    var ambienceEnabled = true
    var soundEnabled = true
    var hapticsEnabled = true
    var reducedMotion = false
    var theme = AppTheme.night
}

struct Stats: Codable {
    var shipsGuided = 0
    var shipsSorted = 0
    var wrecks = 0
    var minesDetonated = 0
    var minesDodged = 0
    var stormsWeathered = 0
    var totalGold = 0.0
    var idleCollections = 0
    var dailyCompletions = 0
    var prestiges = 0
    var idleSeconds = 0.0
    var bestNightStreak = 0

    func value(for metric: String, keeperLevels: Int, upgradeLevels: Int) -> Double {
        switch metric {
        case "shipsGuided": return Double(shipsGuided)
        case "shipsSorted": return Double(shipsSorted)
        case "stormsWeathered": return Double(stormsWeathered)
        case "minesDodged": return Double(minesDodged)
        case "totalGold": return totalGold
        case "prestiges": return Double(prestiges)
        case "idleCollections": return Double(idleCollections)
        case "dailyCompletions": return Double(dailyCompletions)
        case "keeperLevels": return Double(keeperLevels)
        case "upgradeLevels": return Double(upgradeLevels)
        default: return 0
        }
    }
}

struct MissionState: Codable, Identifiable {
    var id: String
    var defId: String
    var progress: Double
    var target: Double
    var claimed: Bool

    var completed: Bool { progress >= target }
}

struct DailyState: Codable {
    var dateKey: String = ""
    var defId: String = ""
    var progress: Double = 0
    var target: Double = 0
    var claimed: Bool = false

    var completed: Bool { progress >= target }
}

struct GameState: Codable {
    var version = 1
    var gold = 0.0
    var oil = 0.0
    var salvage = 0.0
    var lumen = 0.0
    var upgradeLevels: [String: Int] = [:]
    var keeperLevels: [String: Int] = [:]
    var prestigeLevels: [String: Int] = [:]
    var ownedCosmetics: Set<String> = ["sky_harbor_night", "sea_ink", "beam_honey", "lh_classic"]
    var equippedSky = "harbor_night"
    var equippedSea = "ink"
    var equippedBeam = "honey"
    var equippedLighthouse = "classic"
    var secondSpotlightOn = true
    var missions: [MissionState] = []
    var achievementsClaimed: Set<String> = []
    var daily = DailyState()
    var stats = Stats()
    var settings = GameSettings()
    var tutorialDone = false
    var lastActive = Date()
    var rngSeed: UInt64 = 0x1234_5678_9ABC_DEF0
    var lifetimeLumens = 0.0

    var upgradeLevelTotal: Int { upgradeLevels.values.reduce(0, +) }
    var keeperLevelTotal: Int { keeperLevels.values.reduce(0, +) }

    func upgradeLevel(_ id: String) -> Int { upgradeLevels[id] ?? 0 }
    func keeperLevel(_ id: String) -> Int { keeperLevels[id] ?? 0 }
    func prestigeLevel(_ id: String) -> Int { prestigeLevels[id] ?? 0 }

    func balance(of currency: Currency) -> Double {
        switch currency {
        case .gold: return gold
        case .oil: return oil
        case .salvage: return salvage
        case .lumen: return lumen
        }
    }
}
