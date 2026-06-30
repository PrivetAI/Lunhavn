import CoreGraphics
import Foundation

enum Mathx {
    static func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
        min(max(value, lower), upper)
    }

    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * clamp(t, 0, 1)
    }

    static func lerpUnclamped(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    static func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = clamp((x - edge0) / (edge1 - edge0), 0, 1)
        return t * t * (3 - 2 * t)
    }

    static func wrapAngle(_ angle: Double) -> Double {
        var a = angle
        while a > .pi { a -= 2 * .pi }
        while a < -.pi { a += 2 * .pi }
        return a
    }

    static func angleDelta(_ a: Double, _ b: Double) -> Double {
        wrapAngle(a - b)
    }

    static func moveToward(_ current: Double, _ target: Double, _ maxDelta: Double) -> Double {
        if abs(target - current) <= maxDelta { return target }
        return current + (target > current ? maxDelta : -maxDelta)
    }
}

struct Vec: Codable, Equatable {
    var x: Double
    var y: Double

    static let zero = Vec(x: 0, y: 0)

    var point: CGPoint { CGPoint(x: x, y: y) }
    var length: Double { (x * x + y * y).squareRoot() }

    func distance(to other: Vec) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }

    func normalized() -> Vec {
        let len = length
        if len < 0.000001 { return Vec(x: 0, y: 0) }
        return Vec(x: x / len, y: y / len)
    }

    static func + (lhs: Vec, rhs: Vec) -> Vec { Vec(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: Vec, rhs: Vec) -> Vec { Vec(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
    static func * (lhs: Vec, rhs: Double) -> Vec { Vec(x: lhs.x * rhs, y: lhs.y * rhs) }
}

struct DeterministicRandom: Codable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func nextUInt() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextUnit() -> Double {
        Double(nextUInt() >> 11) * (1.0 / 9007199254740992.0)
    }

    mutating func range(_ lower: Double, _ upper: Double) -> Double {
        lower + (upper - lower) * nextUnit()
    }

    mutating func intRange(_ lower: Int, _ upper: Int) -> Int {
        if upper <= lower { return lower }
        return lower + Int(nextUInt() % UInt64(upper - lower))
    }

    mutating func chance(_ probability: Double) -> Bool {
        nextUnit() < probability
    }
}

func fnvHash(_ string: String) -> UInt64 {
    var hash: UInt64 = 0xcbf29ce484222325
    for byte in string.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 0x100000001b3
    }
    return hash
}
