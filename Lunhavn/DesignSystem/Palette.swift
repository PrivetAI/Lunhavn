import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

struct SkyPalette: Identifiable, Hashable {
    let id: String
    let name: String
    let top: UInt32
    let bottom: UInt32
    let star: UInt32
}

struct SeaPalette: Identifiable, Hashable {
    let id: String
    let name: String
    let near: UInt32
    let far: UInt32
    let foam: UInt32
}

struct BeamTint: Identifiable, Hashable {
    let id: String
    let name: String
    let core: UInt32
    let edge: UInt32
}

enum Palettes {
    static let skies: [SkyPalette] = [
        SkyPalette(id: "harbor_night", name: "Harbor Night", top: 0x0A1430, bottom: 0x1B2A4A, star: 0xE8EEFF),
        SkyPalette(id: "aurora", name: "Aurora Watch", top: 0x05122A, bottom: 0x123A3A, star: 0xCFFFE8),
        SkyPalette(id: "ember_dusk", name: "Ember Dusk", top: 0x2A1530, bottom: 0x542A38, star: 0xFFE6D0),
        SkyPalette(id: "deep_storm", name: "Deep Storm", top: 0x0B0F1A, bottom: 0x232A38, star: 0xBFC9DD),
        SkyPalette(id: "pale_dawn", name: "Pale Dawn", top: 0x213A5A, bottom: 0x6E5A6A, star: 0xFFF2E0)
    ]

    static let seas: [SeaPalette] = [
        SeaPalette(id: "ink", name: "Ink Tide", near: 0x16243F, far: 0x070D1C, foam: 0xBFD4F0),
        SeaPalette(id: "jade", name: "Jade Swell", near: 0x123733, far: 0x06150F, foam: 0xCFF3E2),
        SeaPalette(id: "wine", name: "Wine Current", near: 0x2C1730, far: 0x100614, foam: 0xF0D2E0),
        SeaPalette(id: "slate", name: "Slate Reach", near: 0x1A2230, far: 0x0A0E16, foam: 0xCDD6E6),
        SeaPalette(id: "amberglass", name: "Amberglass", near: 0x2A2118, far: 0x110B06, foam: 0xF4E2C4)
    ]

    static let beams: [BeamTint] = [
        BeamTint(id: "honey", name: "Honey Lamp", core: 0xFFE7A8, edge: 0xFFB85C),
        BeamTint(id: "moonsilver", name: "Moonsilver", core: 0xEAF3FF, edge: 0x9FC6FF),
        BeamTint(id: "rose", name: "Rose Glass", core: 0xFFD9E0, edge: 0xFF8FB0),
        BeamTint(id: "verdant", name: "Verdant Ray", core: 0xD8FFD0, edge: 0x76E08A),
        BeamTint(id: "viole", name: "Violet Hour", core: 0xE7D6FF, edge: 0xA784FF)
    ]

    static func sky(_ id: String) -> SkyPalette { skies.first { $0.id == id } ?? skies[0] }
    static func sea(_ id: String) -> SeaPalette { seas.first { $0.id == id } ?? seas[0] }
    static func beam(_ id: String) -> BeamTint { beams.first { $0.id == id } ?? beams[0] }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case night
    case day
    case system

    var id: String { rawValue }
    var label: String {
        switch self {
        case .night: return "Night"
        case .day: return "Dusk"
        case .system: return "System"
        }
    }
}

struct Tokens {
    static let brass = Color(hex: 0xC9A24B)
    static let brassBright = Color(hex: 0xF0D38A)
    static let brassDark = Color(hex: 0x6E5421)
    static let wood = Color(hex: 0x3A2A1C)
    static let woodLight = Color(hex: 0x5A4330)
    static let panel = Color(hex: 0x141C2E)
    static let panelRaised = Color(hex: 0x1E2940)
    static let ink = Color(hex: 0x0A0F1C)
    static let parchment = Color(hex: 0xF3E7C9)
    static let textPrimary = Color(hex: 0xF6EEDC)
    static let textSecondary = Color(hex: 0xB7AE97)
    static let textMuted = Color(hex: 0x7C7563)

    static let safe = Color(hex: 0x7BE0A6)
    static let hazard = Color(hex: 0xE07B6B)
    static let mine = Color(hex: 0xE0556B)
    static let glow = Color(hex: 0xFFD98A)

    static let cornerLarge: CGFloat = 22
    static let corner: CGFloat = 16
    static let cornerSmall: CGFloat = 11

    static let spaceXS: CGFloat = 6
    static let spaceS: CGFloat = 10
    static let spaceM: CGFloat = 16
    static let spaceL: CGFloat = 24
    static let spaceXL: CGFloat = 34

    static let berthColors: [Color] = [
        Color(hex: 0xF0C24B),
        Color(hex: 0x6BB8E0),
        Color(hex: 0xE07BA6),
        Color(hex: 0x8CE07B),
        Color(hex: 0xC79BF0)
    ]
}

extension Font {
    static func lunDisplay(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .serif) }
    static func lunTitle(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    static func lunBody(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func lunNumber(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded).monospacedDigit() }
}
