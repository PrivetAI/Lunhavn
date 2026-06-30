import SwiftUI

struct ScenePalette {
    let sky: SkyPalette
    let sea: SeaPalette
    let beam: BeamTint
    let skin: LighthouseSkinDef
    let nightFactor: Double
    let stormFactor: Double

    static func resolve(_ engine: GameEngine) -> ScenePalette {
        let weather = engine.weather
        var night = weather.isNight ? 1.0 : 0.45
        switch engine.state.settings.theme {
        case .night: night = max(night, 0.85)
        case .day: night = min(night, 0.5)
        case .system: break
        }
        let storm = weather.kind == .storm ? 1.0 : (weather.kind == .fog ? 0.4 : 0.0)
        return ScenePalette(
            sky: Palettes.sky(engine.state.equippedSky),
            sea: Palettes.sea(engine.state.equippedSea),
            beam: Palettes.beam(engine.state.equippedBeam),
            skin: ContentLibrary.lighthouseSkins.first { $0.id == engine.state.equippedLighthouse } ?? ContentLibrary.lighthouseSkins[0],
            nightFactor: night,
            stormFactor: storm
        )
    }

    func skyTop() -> Color { mix(Color(hex: sky.top), Color(hex: 0x05070E), stormFactor * 0.5) }
    func skyBottom() -> Color { mix(Color(hex: sky.bottom), Color(hex: 0x0A0E18), stormFactor * 0.5) }
    func seaNear() -> Color { Color(hex: sea.near) }
    func seaFar() -> Color { Color(hex: sea.far) }
    func foam() -> Color { Color(hex: sea.foam) }
    func beamCore() -> Color { Color(hex: beam.core) }
    func beamEdge() -> Color { Color(hex: beam.edge) }
    func starColor() -> Color { Color(hex: sky.star) }

    private func mix(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let tt = Mathx.clamp(t, 0, 1)
        let ra = a.resolveComponents()
        let rb = b.resolveComponents()
        return Color(.sRGB,
                     red: ra.0 + (rb.0 - ra.0) * tt,
                     green: ra.1 + (rb.1 - ra.1) * tt,
                     blue: ra.2 + (rb.2 - ra.2) * tt,
                     opacity: 1)
    }
}

extension Color {
    func resolveComponents() -> (Double, Double, Double) {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #else
        return (0, 0, 0)
        #endif
    }
}
