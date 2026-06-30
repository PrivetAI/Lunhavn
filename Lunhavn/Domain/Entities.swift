import Foundation

final class Ship: Identifiable {
    let id: Int
    let type: ShipTypeDef
    let berthIndex: Int
    var pos: Vec
    var confidence: Double = 0
    var illumination: Double = 0
    var heading = Vec(x: 0, y: -1)
    var bobPhase: Double
    var sway: Double = 0
    var alive = true
    var arrived = false
    var wrecking = false
    var wreckTimer = 0.0
    var arriveTimer = 0.0
    var wakeStrength = 0.0
    var nearMineFlash = 0.0

    init(id: Int, type: ShipTypeDef, berthIndex: Int, pos: Vec, bobPhase: Double) {
        self.id = id
        self.type = type
        self.berthIndex = berthIndex
        self.pos = pos
        self.bobPhase = bobPhase
    }
}

final class Mine: Identifiable {
    let id: Int
    var pos: Vec
    var drift: Vec
    var pulse: Double
    var lit: Double = 0
    var detonating = false
    var detonateTimer = 0.0

    init(id: Int, pos: Vec, drift: Vec, pulse: Double) {
        self.id = id
        self.pos = pos
        self.drift = drift
        self.pulse = pulse
    }
}

struct Rock: Identifiable {
    let id: Int
    var pos: Vec
    var radius: Double
}

final class FogBank: Identifiable {
    let id: Int
    var center: Vec
    var radius: Double
    var density: Double
    var drift: Vec

    init(id: Int, center: Vec, radius: Double, density: Double, drift: Vec) {
        self.id = id
        self.center = center
        self.radius = radius
        self.density = density
        self.drift = drift
    }
}

struct Berth: Identifiable {
    let id: Int
    let colorIndex: Int
    var pos: Vec
}

enum WeatherKind: String {
    case clear
    case fog
    case storm
    case calm

    var label: String {
        switch self {
        case .clear: return "Clear"
        case .fog: return "Fog"
        case .storm: return "Storm"
        case .calm: return "Calm"
        }
    }

    var icon: String {
        switch self {
        case .clear: return "moon.stars.fill"
        case .fog: return "cloud.fog.fill"
        case .storm: return "cloud.bolt.rain.fill"
        case .calm: return "sparkles"
        }
    }
}

struct WeatherState {
    var kind: WeatherKind = .clear
    var intensity: Double = 0
    var timeRemaining: Double = 0
    var visibility: Double = 1
    var tidePhase: Double = 0
    var dayProgress: Double = 0

    var isNight: Bool { dayProgress < 0.28 || dayProgress > 0.72 }
}

struct FloatingReward: Identifiable {
    let id: Int
    var pos: Vec
    var text: String
    var color: UInt32
    var age: Double = 0
    var life: Double = 1.4
}
