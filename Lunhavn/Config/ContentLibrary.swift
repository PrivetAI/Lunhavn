import Foundation

enum ContentLibrary {
    static let upgrades: [UpgradeDef] = {
        var list: [UpgradeDef] = []
        list.append(UpgradeDef(id: "lamp_bright", name: "Brighter Wick", detail: "Strengthen the flame so light reaches ships faster.", branch: .lamp, effect: .brightness, baseValue: 0.12, maxLevel: 30, baseCost: 15, costGrowth: 1.17, currency: .gold, requires: nil, requiresLevel: 0))
        list.append(UpgradeDef(id: "lamp_warmth", name: "Warm Mantle", detail: "A steadier glow that keeps confidence climbing.", branch: .lamp, effect: .brightness, baseValue: 0.09, maxLevel: 22, baseCost: 120, costGrowth: 1.2, currency: .gold, requires: "lamp_bright", requiresLevel: 6))
        list.append(UpgradeDef(id: "lamp_steady", name: "Steady Hand", detail: "Ships hold their courage longer in the dark.", branch: .lamp, effect: .confidenceRetention, baseValue: 0.035, maxLevel: 20, baseCost: 90, costGrowth: 1.19, currency: .gold, requires: "lamp_bright", requiresLevel: 3))
        list.append(UpgradeDef(id: "lamp_oilflow", name: "Oil Flow", detail: "Refine the burn to yield more lamp oil.", branch: .lamp, effect: .oilMultiplier, baseValue: 0.06, maxLevel: 25, baseCost: 60, costGrowth: 1.22, currency: .oil, requires: nil, requiresLevel: 0))

        list.append(UpgradeDef(id: "beam_width", name: "Wider Lens", detail: "Broaden the cone to light more sea at once.", branch: .beam, effect: .beamWidth, baseValue: 0.03, maxLevel: 24, baseCost: 25, costGrowth: 1.16, currency: .gold, requires: nil, requiresLevel: 0))
        list.append(UpgradeDef(id: "beam_range", name: "Longer Reach", detail: "Cast the beam deeper toward the open water.", branch: .beam, effect: .beamRange, baseValue: 0.028, maxLevel: 24, baseCost: 22, costGrowth: 1.16, currency: .gold, requires: nil, requiresLevel: 0))
        list.append(UpgradeDef(id: "beam_focus", name: "Sharp Edge", detail: "Cut the falloff so the beam's rim stays bright.", branch: .beam, effect: .edgeSharpness, baseValue: 0.05, maxLevel: 20, baseCost: 80, costGrowth: 1.2, currency: .gold, requires: "beam_width", requiresLevel: 4))
        list.append(UpgradeDef(id: "beam_split", name: "Second Spotlight", detail: "Split the light into a second steerable beam.", branch: .beam, effect: .secondSpotlight, baseValue: 1, maxLevel: 1, baseCost: 1500, costGrowth: 1, currency: .oil, requires: "beam_focus", requiresLevel: 3))

        list.append(UpgradeDef(id: "mech_rotation", name: "Oiled Bearings", detail: "Turn the lens faster to chase ships across the bay.", branch: .mechanism, effect: .rotationSpeed, baseValue: 0.16, maxLevel: 20, baseCost: 35, costGrowth: 1.17, currency: .gold, requires: nil, requiresLevel: 0))
        list.append(UpgradeDef(id: "mech_gears", name: "Brass Gearworks", detail: "Precision gears for an even swifter sweep.", branch: .mechanism, effect: .rotationSpeed, baseValue: 0.11, maxLevel: 16, baseCost: 240, costGrowth: 1.21, currency: .oil, requires: "mech_rotation", requiresLevel: 6))
        list.append(UpgradeDef(id: "mech_tugs", name: "Harbor Tugs", detail: "Tugboats meet lit ships and hurry them home.", branch: .mechanism, effect: .shipSpeed, baseValue: 0.05, maxLevel: 20, baseCost: 70, costGrowth: 1.18, currency: .gold, requires: "mech_rotation", requiresLevel: 3))

        list.append(UpgradeDef(id: "optics_fog", name: "Fog Lens", detail: "A cut-glass lens that pierces fog banks.", branch: .optics, effect: .fogPiercing, baseValue: 0.07, maxLevel: 20, baseCost: 180, costGrowth: 1.22, currency: .oil, requires: nil, requiresLevel: 0))
        list.append(UpgradeDef(id: "optics_clarity", name: "Crystal Clarity", detail: "Polished optics sharpen the beam in any weather.", branch: .optics, effect: .edgeSharpness, baseValue: 0.04, maxLevel: 16, baseCost: 320, costGrowth: 1.23, currency: .oil, requires: "optics_fog", requiresLevel: 4))
        list.append(UpgradeDef(id: "optics_throw", name: "Long Throw", detail: "Refract the light to reach the far horizon.", branch: .optics, effect: .beamRange, baseValue: 0.04, maxLevel: 16, baseCost: 280, costGrowth: 1.22, currency: .oil, requires: "beam_range", requiresLevel: 8))

        list.append(UpgradeDef(id: "harbor_reward", name: "Berth Fees", detail: "Earn more gold from every ship guided home.", branch: .harbor, effect: .goldMultiplier, baseValue: 0.1, maxLevel: 30, baseCost: 50, costGrowth: 1.18, currency: .gold, requires: nil, requiresLevel: 0))
        list.append(UpgradeDef(id: "harbor_capacity", name: "Open Berths", detail: "Welcome more ships into the bay at once.", branch: .harbor, effect: .harborCapacity, baseValue: 1, maxLevel: 12, baseCost: 220, costGrowth: 1.28, currency: .gold, requires: nil, requiresLevel: 0))
        list.append(UpgradeDef(id: "harbor_depot", name: "Oil Depot", detail: "Harbored ships top up your oil reserves.", branch: .harbor, effect: .oilMultiplier, baseValue: 0.08, maxLevel: 20, baseCost: 160, costGrowth: 1.22, currency: .gold, requires: "harbor_reward", requiresLevel: 5))
        list.append(UpgradeDef(id: "harbor_grand", name: "Grand Quay", detail: "A prestigious quay that doubles down on gold.", branch: .harbor, effect: .goldMultiplier, baseValue: 0.22, maxLevel: 16, baseCost: 900, costGrowth: 1.24, currency: .oil, requires: "harbor_reward", requiresLevel: 12))
        return list
    }()

    static let keepers: [KeeperDef] = {
        var list: [KeeperDef] = []
        list.append(KeeperDef(id: "novice", name: "Novice Keeper", detail: "Learns the lamp and lights the odd ship for you.", icon: "person.fill", baseCost: 60, costGrowth: 1.16, idleGoldPerLevel: 0.6, idleOilPerLevel: 0, activeAssistPerLevel: 0.05, maxLevel: 100))
        list.append(KeeperDef(id: "signaler", name: "Signal Keeper", detail: "Waves lit ships onward, hastening them to berth.", icon: "flag.fill", baseCost: 400, costGrowth: 1.17, idleGoldPerLevel: 2.4, idleOilPerLevel: 0, activeAssistPerLevel: 0.09, maxLevel: 100))
        list.append(KeeperDef(id: "oiler", name: "Oil Keeper", detail: "Tends the reserves, drawing steady lamp oil.", icon: "drop.fill", baseCost: 1200, costGrowth: 1.18, idleGoldPerLevel: 1.0, idleOilPerLevel: 0.5, activeAssistPerLevel: 0.04, maxLevel: 100))
        list.append(KeeperDef(id: "harbormaster", name: "Harbormaster", detail: "Runs the quay and rakes in gold around the clock.", icon: "building.columns.fill", baseCost: 6000, costGrowth: 1.19, idleGoldPerLevel: 11, idleOilPerLevel: 0, activeAssistPerLevel: 0.08, maxLevel: 100))
        list.append(KeeperDef(id: "stormwarden", name: "Storm Warden", detail: "Holds the light through gales, guiding many at once.", icon: "cloud.bolt.fill", baseCost: 26000, costGrowth: 1.2, idleGoldPerLevel: 28, idleOilPerLevel: 0.8, activeAssistPerLevel: 0.16, maxLevel: 100))
        list.append(KeeperDef(id: "lampwright", name: "Lampwright", detail: "A master of the lens, prized for gold and oil alike.", icon: "wrench.and.screwdriver.fill", baseCost: 120000, costGrowth: 1.21, idleGoldPerLevel: 90, idleOilPerLevel: 2.6, activeAssistPerLevel: 0.13, maxLevel: 100))
        return list
    }()

    static let shipTypes: [ShipTypeDef] = {
        var list: [ShipTypeDef] = []
        list.append(ShipTypeDef(id: "skiff", name: "Skiff", colorIndex: 0, reward: 4, oilReward: 0, speed: 1.2, weight: 1.0, minStage: 0, symbol: "sailboat"))
        list.append(ShipTypeDef(id: "cutter", name: "Cutter", colorIndex: 1, reward: 7, oilReward: 0, speed: 1.05, weight: 0.9, minStage: 0, symbol: "ferry"))
        list.append(ShipTypeDef(id: "trawler", name: "Trawler", colorIndex: 3, reward: 12, oilReward: 0.2, speed: 0.85, weight: 0.7, minStage: 1, symbol: "ferry.fill"))
        list.append(ShipTypeDef(id: "packet", name: "Packet", colorIndex: 2, reward: 18, oilReward: 0.3, speed: 0.95, weight: 0.55, minStage: 1, symbol: "ferry"))
        list.append(ShipTypeDef(id: "freighter", name: "Freighter", colorIndex: 4, reward: 30, oilReward: 0.8, speed: 0.7, weight: 0.4, minStage: 2, symbol: "ferry.fill"))
        list.append(ShipTypeDef(id: "clipper", name: "Clipper", colorIndex: 1, reward: 44, oilReward: 0.6, speed: 1.35, weight: 0.28, minStage: 3, symbol: "sailboat.fill"))
        list.append(ShipTypeDef(id: "galleon", name: "Galleon", colorIndex: 0, reward: 78, oilReward: 1.8, speed: 0.6, weight: 0.16, minStage: 4, symbol: "ferry.fill"))
        return list
    }()

    static let missionTemplates: [MissionDef] = {
        var list: [MissionDef] = []
        list.append(MissionDef(id: "m_guide_s", name: "Safe Passage", detail: "Guide ships home to harbor.", icon: "sailboat.fill", metric: .guide, target: 12, rewardGold: 120, rewardSalvage: 1))
        list.append(MissionDef(id: "m_guide_m", name: "Busy Night", detail: "Guide many ships home to harbor.", icon: "sailboat.fill", metric: .guide, target: 40, rewardGold: 500, rewardSalvage: 2))
        list.append(MissionDef(id: "m_sort_s", name: "Right Berth", detail: "Sort ships into their correct berths.", icon: "arrow.triangle.branch", metric: .sort, target: 16, rewardGold: 220, rewardSalvage: 2))
        list.append(MissionDef(id: "m_wreck", name: "Clean Watch", detail: "Harbor ships without a single wreck.", icon: "shield.lefthalf.filled", metric: .avoidWreck, target: 18, rewardGold: 300, rewardSalvage: 3))
        list.append(MissionDef(id: "m_mine", name: "Mind the Mines", detail: "Bring ships home while dodging mines.", icon: "burst.fill", metric: .dodgeMine, target: 10, rewardGold: 260, rewardSalvage: 3))
        list.append(MissionDef(id: "m_storm", name: "Weather the Storm", detail: "Guide ships safely during stormy weather.", icon: "cloud.bolt.rain.fill", metric: .weatherStorm, target: 8, rewardGold: 360, rewardSalvage: 4))
        list.append(MissionDef(id: "m_gold", name: "Full Coffers", detail: "Earn gold from harbored ships.", icon: "circle.hexagongrid.fill", metric: .earnGold, target: 1500, rewardGold: 400, rewardSalvage: 2))
        list.append(MissionDef(id: "m_guide_l", name: "Convoy", detail: "Shepherd a great convoy home.", icon: "sailboat.fill", metric: .guide, target: 80, rewardGold: 1400, rewardSalvage: 5))
        return list
    }()

    static let achievements: [AchievementDef] = {
        var list: [AchievementDef] = []
        list.append(AchievementDef(id: "a_first", name: "First Light", detail: "Guide your first ship home.", icon: "sparkles", metric: "shipsGuided", target: 1, rewardSalvage: 1))
        list.append(AchievementDef(id: "a_guide50", name: "Faithful Keeper", detail: "Guide 50 ships home.", icon: "sailboat.fill", metric: "shipsGuided", target: 50, rewardSalvage: 2))
        list.append(AchievementDef(id: "a_guide500", name: "Beacon of the Cape", detail: "Guide 500 ships home.", icon: "sailboat.fill", metric: "shipsGuided", target: 500, rewardSalvage: 5))
        list.append(AchievementDef(id: "a_guide5000", name: "Legend of Lunhavn", detail: "Guide 5,000 ships home.", icon: "crown.fill", metric: "shipsGuided", target: 5000, rewardSalvage: 12))
        list.append(AchievementDef(id: "a_sort100", name: "Orderly Bay", detail: "Sort 100 ships to the right berth.", icon: "arrow.triangle.branch", metric: "shipsSorted", target: 100, rewardSalvage: 3))
        list.append(AchievementDef(id: "a_storm", name: "Storm Caller", detail: "Weather 20 storms.", icon: "cloud.bolt.fill", metric: "stormsWeathered", target: 20, rewardSalvage: 4))
        list.append(AchievementDef(id: "a_mine", name: "Steady Nerves", detail: "Dodge 50 mines.", icon: "burst.fill", metric: "minesDodged", target: 50, rewardSalvage: 4))
        list.append(AchievementDef(id: "a_gold1m", name: "Golden Cape", detail: "Earn 1,000,000 gold in total.", icon: "circle.hexagongrid.fill", metric: "totalGold", target: 1_000_000, rewardSalvage: 6))
        list.append(AchievementDef(id: "a_keeper", name: "Crew of Keepers", detail: "Hire keepers to 25 total levels.", icon: "person.3.fill", metric: "keeperLevels", target: 25, rewardSalvage: 4))
        list.append(AchievementDef(id: "a_upgrade", name: "Master Mechanism", detail: "Purchase 60 upgrade levels.", icon: "gearshape.2.fill", metric: "upgradeLevels", target: 60, rewardSalvage: 5))
        list.append(AchievementDef(id: "a_prestige1", name: "New Keeper", detail: "Relight the lighthouse once.", icon: "arrow.triangle.2.circlepath", metric: "prestiges", target: 1, rewardSalvage: 8))
        list.append(AchievementDef(id: "a_prestige5", name: "Eternal Flame", detail: "Relight the lighthouse 5 times.", icon: "flame.fill", metric: "prestiges", target: 5, rewardSalvage: 20))
        list.append(AchievementDef(id: "a_idle", name: "While You Slept", detail: "Collect offline earnings 10 times.", icon: "moon.zzz.fill", metric: "idleCollections", target: 10, rewardSalvage: 3))
        list.append(AchievementDef(id: "a_daily", name: "Daily Devotion", detail: "Complete 7 daily harbor challenges.", icon: "calendar", metric: "dailyCompletions", target: 7, rewardSalvage: 6))
        return list
    }()

    static let lighthouseSkins: [LighthouseSkinDef] = {
        var list: [LighthouseSkinDef] = []
        list.append(LighthouseSkinDef(id: "classic", name: "Cape Classic", body: 0xEDE7D6, stripe: 0xC0392B, lamp: 0xFFE7A8))
        list.append(LighthouseSkinDef(id: "brass", name: "Brass Tower", body: 0xC9B27A, stripe: 0x6E5421, lamp: 0xFFD98A))
        list.append(LighthouseSkinDef(id: "slate", name: "Slate Sentinel", body: 0xAAB4C0, stripe: 0x37414D, lamp: 0xEAF3FF))
        list.append(LighthouseSkinDef(id: "jade", name: "Jade Watch", body: 0xCFE8DE, stripe: 0x2E6B57, lamp: 0xD8FFD0))
        list.append(LighthouseSkinDef(id: "ember", name: "Ember Spire", body: 0xE8C9A0, stripe: 0x9B4A2F, lamp: 0xFFCDA0))
        return list
    }()

    static let cosmetics: [CosmeticDef] = {
        var list: [CosmeticDef] = []
        list.append(CosmeticDef(id: "sky_harbor_night", name: "Harbor Night", detail: "The classic deep-navy keeper's sky.", kind: .sky, paletteId: "harbor_night", cost: 0, currency: .salvage))
        list.append(CosmeticDef(id: "sky_aurora", name: "Aurora Watch", detail: "Green light dances over the cape.", kind: .sky, paletteId: "aurora", cost: 8, currency: .salvage))
        list.append(CosmeticDef(id: "sky_ember", name: "Ember Dusk", detail: "A smouldering twilight horizon.", kind: .sky, paletteId: "ember_dusk", cost: 10, currency: .salvage))
        list.append(CosmeticDef(id: "sky_storm", name: "Deep Storm", detail: "Bruised clouds and distant thunder.", kind: .sky, paletteId: "deep_storm", cost: 12, currency: .salvage))
        list.append(CosmeticDef(id: "sky_dawn", name: "Pale Dawn", detail: "The first soft grey of morning.", kind: .sky, paletteId: "pale_dawn", cost: 14, currency: .salvage))

        list.append(CosmeticDef(id: "sea_ink", name: "Ink Tide", detail: "Dark, glassy water at rest.", kind: .sea, paletteId: "ink", cost: 0, currency: .salvage))
        list.append(CosmeticDef(id: "sea_jade", name: "Jade Swell", detail: "Cool green rollers.", kind: .sea, paletteId: "jade", cost: 8, currency: .salvage))
        list.append(CosmeticDef(id: "sea_wine", name: "Wine Current", detail: "A deep crimson sea.", kind: .sea, paletteId: "wine", cost: 10, currency: .salvage))
        list.append(CosmeticDef(id: "sea_slate", name: "Slate Reach", detail: "Steel-grey northern water.", kind: .sea, paletteId: "slate", cost: 12, currency: .salvage))
        list.append(CosmeticDef(id: "sea_amber", name: "Amberglass", detail: "Warm lantern-lit shallows.", kind: .sea, paletteId: "amberglass", cost: 14, currency: .salvage))

        list.append(CosmeticDef(id: "beam_honey", name: "Honey Lamp", detail: "The warm amber light of home.", kind: .beam, paletteId: "honey", cost: 0, currency: .salvage))
        list.append(CosmeticDef(id: "beam_moon", name: "Moonsilver", detail: "A cold, clear silver beam.", kind: .beam, paletteId: "moonsilver", cost: 9, currency: .salvage))
        list.append(CosmeticDef(id: "beam_rose", name: "Rose Glass", detail: "A gentle pink-tinted light.", kind: .beam, paletteId: "rose", cost: 11, currency: .salvage))
        list.append(CosmeticDef(id: "beam_verdant", name: "Verdant Ray", detail: "An uncanny green glow.", kind: .beam, paletteId: "verdant", cost: 13, currency: .salvage))
        list.append(CosmeticDef(id: "beam_violet", name: "Violet Hour", detail: "Dusk captured in the lens.", kind: .beam, paletteId: "viole", cost: 15, currency: .salvage))

        list.append(CosmeticDef(id: "lh_classic", name: "Cape Classic", detail: "Red-and-white striped tower.", kind: .lighthouse, paletteId: "classic", cost: 0, currency: .salvage))
        list.append(CosmeticDef(id: "lh_brass", name: "Brass Tower", detail: "Gleaming brass and dark bands.", kind: .lighthouse, paletteId: "brass", cost: 10, currency: .salvage))
        list.append(CosmeticDef(id: "lh_slate", name: "Slate Sentinel", detail: "Cool grey stone tower.", kind: .lighthouse, paletteId: "slate", cost: 12, currency: .salvage))
        list.append(CosmeticDef(id: "lh_jade", name: "Jade Watch", detail: "Sea-green tiled lighthouse.", kind: .lighthouse, paletteId: "jade", cost: 14, currency: .salvage))
        list.append(CosmeticDef(id: "lh_ember", name: "Ember Spire", detail: "Sun-baked terracotta tower.", kind: .lighthouse, paletteId: "ember", cost: 16, currency: .salvage))
        return list
    }()

    static let prestigeUpgrades: [PrestigeUpgradeDef] = {
        var list: [PrestigeUpgradeDef] = []
        list.append(PrestigeUpgradeDef(id: "pr_gold", name: "Golden Legacy", detail: "+15% gold from all ships per level.", icon: "circle.hexagongrid.fill", effect: .globalGold, baseValue: 0.15, maxLevel: 50, baseCost: 2, costGrowth: 1.35))
        list.append(PrestigeUpgradeDef(id: "pr_conf", name: "Guiding Spirit", detail: "+6% confidence gain per level.", icon: "sparkle", effect: .globalConfidence, baseValue: 0.06, maxLevel: 25, baseCost: 3, costGrowth: 1.45))
        list.append(PrestigeUpgradeDef(id: "pr_offline", name: "Long Vigil", detail: "+1 hour of offline guidance per level.", icon: "moon.zzz.fill", effect: .offlineHours, baseValue: 1, maxLevel: 16, baseCost: 5, costGrowth: 1.55))
        list.append(PrestigeUpgradeDef(id: "pr_keeper", name: "Devoted Crew", detail: "+20% keeper output per level.", icon: "person.3.fill", effect: .keeperBoost, baseValue: 0.2, maxLevel: 40, baseCost: 4, costGrowth: 1.4))
        list.append(PrestigeUpgradeDef(id: "pr_start", name: "Inheritance", detail: "Begin each relight with more gold.", icon: "gift.fill", effect: .startingGold, baseValue: 250, maxLevel: 30, baseCost: 3, costGrowth: 1.42))
        list.append(PrestigeUpgradeDef(id: "pr_oil", name: "Refiner's Touch", detail: "+25% oil gain per level.", icon: "drop.fill", effect: .oilGain, baseValue: 0.25, maxLevel: 20, baseCost: 4, costGrowth: 1.45))
        return list
    }()

    static func upgrade(_ id: String) -> UpgradeDef? { upgrades.first { $0.id == id } }
    static func keeper(_ id: String) -> KeeperDef? { keepers.first { $0.id == id } }
    static func shipType(_ id: String) -> ShipTypeDef? { shipTypes.first { $0.id == id } }
    static func prestige(_ id: String) -> PrestigeUpgradeDef? { prestigeUpgrades.first { $0.id == id } }
}
