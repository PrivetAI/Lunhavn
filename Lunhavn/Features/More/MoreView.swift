import SwiftUI

struct CoverScreen<Content: View>: View {
    var engine: GameEngine
    let title: String
    let subtitle: String
    let onClose: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            NightBackground(engine: engine)
            VStack(spacing: Tokens.spaceM) {
                HStack(alignment: .top) {
                    ScreenTitle(title: title, subtitle: subtitle)
                    Spacer()
                    LunCloseButton(action: onClose)
                }
                .padding(.horizontal, Tokens.spaceM)
                .padding(.top, 12)
                content
            }
        }
        .statusBarHidden()
    }
}

struct MoreView: View {
    @Bindable var engine: GameEngine
    let onOpen: (MoreRoute) -> Void

    private let items: [(MoreRoute, String, String, String)] = [
        (.prestige, "Rebirth", "Relight a grander lighthouse", "arrow.triangle.2.circlepath"),
        (.cosmetics, "Collection", "Skins, beams and palettes", "paintpalette.fill"),
        (.achievements, "Achievements", "Milestones of your watch", "rosette"),
        (.statistics, "Statistics", "A lifetime by the lamp", "chart.bar.fill"),
        (.settings, "Settings", "Sound, haptics and more", "gearshape.fill")
    ]

    var body: some View {
        let _ = engine.version
        return ZStack {
            NightBackground(engine: engine)
            VStack(spacing: Tokens.spaceM) {
                HStack {
                    ScreenTitle(title: "More", subtitle: "Everything else at the cape")
                    Spacer()
                }
                .padding(.horizontal, Tokens.spaceM)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: Tokens.spaceM) {
                        if engine.canPrestige {
                            prestigeBanner
                        }
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: Tokens.spaceM), GridItem(.flexible(), spacing: Tokens.spaceM)], spacing: Tokens.spaceM) {
                            ForEach(items, id: \.0) { item in
                                menuTile(route: item.0, title: item.1, subtitle: item.2, icon: item.3)
                            }
                        }
                    }
                    .padding(.horizontal, Tokens.spaceM)
                    .padding(.bottom, 96)
                }
            }
        }
    }

    private var prestigeBanner: some View {
        Button {
            Haptics.tap()
            onOpen(.prestige)
        } label: {
            HStack(spacing: Tokens.spaceM) {
                Image(systemName: "sparkles").font(.system(size: 24)).foregroundStyle(Color(hex: 0xE7D6FF))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ready to relight").font(.lunTitle(17)).foregroundStyle(Tokens.textPrimary)
                    Text("Earn \(engine.pendingLumens.compactString) Lumens by passing on the light").font(.lunBody(13)).foregroundStyle(Tokens.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Tokens.textMuted)
            }
            .padding(Tokens.spaceM)
            .background(RoundedRectangle(cornerRadius: Tokens.corner, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x2A1F40), Color(hex: 0x1A1530)], startPoint: .top, endPoint: .bottom)))
            .overlay(RoundedRectangle(cornerRadius: Tokens.corner, style: .continuous).strokeBorder(Color(hex: 0xA784FF).opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func menuTile(route: MoreRoute, title: String, subtitle: String, icon: String) -> some View {
        Button {
            Haptics.tap()
            onOpen(route)
        } label: {
            VStack(alignment: .leading, spacing: Tokens.spaceS) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Tokens.brassBright)
                Spacer()
                Text(title).font(.lunTitle(17)).foregroundStyle(Tokens.textPrimary)
                Text(subtitle).font(.lunBody(12)).foregroundStyle(Tokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .padding(Tokens.spaceM)
            .background(RoundedRectangle(cornerRadius: Tokens.corner, style: .continuous).fill(Tokens.panelRaised.opacity(0.9)))
            .overlay(RoundedRectangle(cornerRadius: Tokens.corner, style: .continuous).strokeBorder(Tokens.brass.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
