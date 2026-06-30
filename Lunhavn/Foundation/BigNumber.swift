import Foundation

enum NumberFormat {
    private static let shortSuffixes = ["", "K", "M", "B", "T"]

    static func compact(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return "0" }
        let sign = value < 0 ? "-" : ""
        let magnitude = abs(value)
        if magnitude < 1000 {
            if magnitude < 10 && magnitude != magnitude.rounded() {
                return sign + trimmed(magnitude, decimals: 1)
            }
            return sign + String(Int(magnitude.rounded()))
        }
        var tier = 0
        var scaled = magnitude
        while scaled >= 1000 && tier < 1_000_000 {
            scaled /= 1000
            tier += 1
        }
        let suffix = suffixFor(tier: tier)
        return sign + trimmed(scaled, decimals: scaled < 10 ? 2 : (scaled < 100 ? 1 : 0)) + suffix
    }

    static func whole(_ value: Double) -> String {
        compact(value.rounded(.down))
    }

    static func rate(_ value: Double) -> String {
        compact(value) + "/s"
    }

    private static func suffixFor(tier: Int) -> String {
        if tier < shortSuffixes.count { return shortSuffixes[tier] }
        var index = tier - shortSuffixes.count
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        let first = index / letters.count
        let second = index % letters.count
        index = first
        if first == 0 {
            return String(letters[second]) + String(letters[second])
        }
        return String(letters[min(first - 1, 25)]) + String(letters[second])
    }

    private static func trimmed(_ value: Double, decimals: Int) -> String {
        let formatted = String(format: "%.\(decimals)f", value)
        if formatted.contains(".") {
            var trimmed = formatted
            while trimmed.hasSuffix("0") { trimmed.removeLast() }
            if trimmed.hasSuffix(".") { trimmed.removeLast() }
            return trimmed
        }
        return formatted
    }
}

extension Double {
    var compactString: String { NumberFormat.compact(self) }
    var wholeString: String { NumberFormat.whole(self) }
}
