import SwiftUI

struct NightBackground: View {
    var engine: GameEngine

    var body: some View {
        let sky = Palettes.sky(engine.state.equippedSky)
        ZStack {
            LinearGradient(
                colors: [Color(hex: sky.top), Color(hex: sky.bottom), Tokens.ink],
                startPoint: .top, endPoint: .bottom
            )
            Canvas { context, size in
                var rng = DeterministicRandom(seed: 4242)
                for _ in 0..<60 {
                    let x = rng.nextUnit() * Double(size.width)
                    let y = rng.nextUnit() * Double(size.height) * 0.7
                    let r = rng.range(0.5, 1.6)
                    let o = rng.range(0.1, 0.5)
                    context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                                 with: .color(Color(hex: sky.star).opacity(o)))
                }
            }
            .blur(radius: 0.3)
        }
        .ignoresSafeArea()
    }
}

struct CurrencyPill: View {
    let currency: Currency
    let value: Double

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: currency.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(value.compactString)
                .font(.lunNumber(15))
                .foregroundStyle(Tokens.textPrimary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(Capsule().fill(Tokens.panel.opacity(0.85)))
        .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
    }

    private var color: Color {
        switch currency {
        case .gold: return Tokens.brassBright
        case .oil: return Color(hex: 0x8FC9E0)
        case .salvage: return Tokens.safe
        case .lumen: return Color(hex: 0xE7D6FF)
        }
    }
}

struct TopCurrencyBar: View {
    let engine: GameEngine
    var currencies: [Currency] = [.gold, .oil, .salvage]

    var body: some View {
        let _ = engine.version
        return HStack(spacing: 8) {
            ForEach(currencies, id: \.self) { c in
                CurrencyPill(currency: c, value: engine.state.balance(of: c))
            }
        }
    }
}

struct ScreenTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.lunDisplay(30))
                .foregroundStyle(Tokens.textPrimary)
            Text(subtitle)
                .font(.lunBody(14))
                .foregroundStyle(Tokens.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Tokens.spaceM) {
            Image(systemName: icon)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Tokens.brass.opacity(0.7))
            Text(title)
                .font(.lunTitle(19))
                .foregroundStyle(Tokens.textPrimary)
            Text(message)
                .font(.lunBody(14))
                .foregroundStyle(Tokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Tokens.spaceXL)
    }
}
