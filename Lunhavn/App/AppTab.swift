import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case play
    case upgrades
    case keepers
    case voyages
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .play: return "Light"
        case .upgrades: return "Upgrades"
        case .keepers: return "Keepers"
        case .voyages: return "Voyages"
        case .more: return "More"
        }
    }

    var icon: String {
        switch self {
        case .play: return "light.beacon.max.fill"
        case .upgrades: return "gearshape.2.fill"
        case .keepers: return "person.3.fill"
        case .voyages: return "scroll.fill"
        case .more: return "ellipsis.circle.fill"
        }
    }
}

enum MoreRoute: String, Identifiable {
    case cosmetics
    case prestige
    case achievements
    case statistics
    case settings

    var id: String { rawValue }
}

private struct TabBarButton: View {
    let tab: AppTab
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 19, weight: .semibold))
                Text(tab.title)
                    .font(.lunBody(10).weight(.semibold))
            }
            .foregroundStyle(selected ? Tokens.ink : Tokens.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(selectedBackground)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var selectedBackground: some View {
        if selected {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(LinearGradient(colors: [Tokens.brassBright, Tokens.brass], startPoint: .top, endPoint: .bottom))
                .shadow(color: Tokens.glow.opacity(0.5), radius: 8, y: 2)
        } else {
            Color.clear
        }
    }
}

struct LunTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                TabBarButton(tab: tab, selected: selection == tab) {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = tab
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(Tokens.panel.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .strokeBorder(Tokens.brass.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
        )
        .padding(.horizontal, Tokens.spaceM)
    }
}
