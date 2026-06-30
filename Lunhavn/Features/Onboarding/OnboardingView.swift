import SwiftUI

struct OnboardingStep {
    let icon: String
    let title: String
    let body: String
}

struct OnboardingView: View {
    @Bindable var engine: GameEngine
    @State private var index = 0

    private let steps: [OnboardingStep] = [
        OnboardingStep(icon: "light.beacon.max.fill", title: "Welcome, Keeper", body: "You tend the lighthouse of Lunhavn. Guide ships through the night, the fog and the storms, safely home to harbour."),
        OnboardingStep(icon: "hand.draw.fill", title: "Sweep the Light", body: "Drag anywhere on the sea to rotate the great lamp. The beam follows your finger — try sweeping it now."),
        OnboardingStep(icon: "sailboat.fill", title: "Guide Them Home", body: "Ships sail toward your light. Hold the beam on a vessel to build its confidence, and it surges upward toward shore."),
        OnboardingStep(icon: "arrow.triangle.branch", title: "Sort the Fleet", body: "Each ship carries a coloured sail. Lead it to the berth light of the same colour before it reaches the shore."),
        OnboardingStep(icon: "exclamationmark.triangle.fill", title: "Mind the Hazards", body: "Ships left in the dark lose courage and drift onto the rocks. Keep them lit to keep them safe."),
        OnboardingStep(icon: "burst.fill", title: "Never Light a Mine", body: "Floating mines drift among the ships. If your beam touches one, it detonates. Sweep around them."),
        OnboardingStep(icon: "gearshape.2.fill", title: "Grow Your Light", body: "Spend gold on a brighter lamp and a wider beam, and hire keepers who guide ships — and earn — even while you are away.")
    ]

    var body: some View {
        ZStack {
            CoastlineSceneView(engine: engine, interactive: index >= 1)
                .ignoresSafeArea()
            LinearGradient(colors: [.clear, Tokens.ink.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        finish()
                    }
                    .font(.lunBody(14).weight(.semibold))
                    .foregroundStyle(Tokens.textSecondary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Tokens.panel.opacity(0.7)))
                    .padding(.trailing, Tokens.spaceM)
                    .padding(.top, 8)
                }
                Spacer()
                card
                    .padding(.horizontal, Tokens.spaceM)
                    .padding(.bottom, Tokens.spaceL)
            }
        }
        .onAppear { engine.setSceneActive(true) }
    }

    private var card: some View {
        let step = steps[index]
        return LunPanel {
            VStack(spacing: Tokens.spaceM) {
                Image(systemName: step.icon)
                    .font(.system(size: 38))
                    .foregroundStyle(Tokens.brassBright)
                    .shadow(color: Tokens.glow.opacity(0.5), radius: 10)
                Text(step.title).font(.lunDisplay(24)).foregroundStyle(Tokens.textPrimary)
                Text(step.body).font(.lunBody(15)).foregroundStyle(Tokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == index ? Tokens.brassBright : Tokens.textMuted.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }

                LunButton(title: index == steps.count - 1 ? "Begin Your Watch" : "Next",
                          icon: index == steps.count - 1 ? "light.beacon.max.fill" : "arrow.right",
                          fullWidth: true) {
                    advance()
                }
            }
        }
        .id(index)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    private func advance() {
        if index >= steps.count - 1 {
            finish()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { index += 1 }
        }
    }

    private func finish() {
        engine.completeTutorial()
    }
}
