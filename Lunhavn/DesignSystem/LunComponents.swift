import SwiftUI

struct LunPanel<Content: View>: View {
    var padding: CGFloat = Tokens.spaceM
    var tint: Color = Tokens.panelRaised
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Tokens.corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.96), tint.opacity(0.78)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.corner, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Tokens.brass.opacity(0.7), Tokens.brassDark.opacity(0.5)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
    }
}

enum LunButtonStyleKind {
    case primary
    case secondary
    case ghost
    case danger
}

struct LunButton: View {
    let title: String
    var icon: String? = nil
    var kind: LunButtonStyleKind = .primary
    var fullWidth: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    @State private var pressed = false

    private var fill: LinearGradient {
        switch kind {
        case .primary:
            return LinearGradient(colors: [Tokens.brassBright, Tokens.brass], startPoint: .top, endPoint: .bottom)
        case .secondary:
            return LinearGradient(colors: [Tokens.woodLight, Tokens.wood], startPoint: .top, endPoint: .bottom)
        case .ghost:
            return LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)], startPoint: .top, endPoint: .bottom)
        case .danger:
            return LinearGradient(colors: [Color(hex: 0xE07B6B), Color(hex: 0xA8413A)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var textColor: Color {
        switch kind {
        case .primary: return Tokens.ink
        default: return Tokens.textPrimary
        }
    }

    var body: some View {
        Button {
            guard enabled else { return }
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: Tokens.spaceXS) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.lunTitle(16))
            .foregroundStyle(textColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 13)
            .padding(.horizontal, Tokens.spaceL)
            .background(
                RoundedRectangle(cornerRadius: Tokens.cornerSmall, style: .continuous).fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.cornerSmall, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: kind == .primary ? Tokens.glow.opacity(0.4) : .black.opacity(0.3), radius: pressed ? 4 : 10, y: pressed ? 1 : 5)
            .scaleEffect(pressed ? 0.96 : 1)
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.08)) { pressed = true } }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = false } }
        )
    }
}

struct LunChip: View {
    let text: String
    var systemImage: String? = nil
    var color: Color = Tokens.brass

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 11, weight: .bold)) }
            Text(text).font(.lunBody(13).weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.14)))
        .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
    }
}

struct LunProgressBar: View {
    var value: Double
    var tint: Color = Tokens.brass
    var height: CGFloat = 9

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.35))
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, value)) * geo.size.width)
                    .shadow(color: tint.opacity(0.6), radius: 4)
            }
        }
        .frame(height: height)
    }
}

struct LunStatRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var tint: Color = Tokens.textPrimary

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon).foregroundStyle(Tokens.brass).frame(width: 22)
            }
            Text(label).font(.lunBody(15)).foregroundStyle(Tokens.textSecondary)
            Spacer()
            Text(value).font(.lunNumber(15)).foregroundStyle(tint)
        }
    }
}

struct LunSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.lunTitle(13))
                .tracking(2)
                .foregroundStyle(Tokens.brass)
            if let subtitle {
                Text(subtitle).font(.lunBody(13)).foregroundStyle(Tokens.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LunCloseButton: View {
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Tokens.textSecondary)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Tokens.panel))
                .overlay(Circle().strokeBorder(Tokens.brass.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
