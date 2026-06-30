import SwiftUI

struct IdleSummaryView: View {
    let report: IdleReport
    let onClose: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0A1430), Color(hex: 0x05070E)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: Tokens.spaceL) {
                Spacer()
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Tokens.brassBright)
                    .shadow(color: Tokens.glow.opacity(0.6), radius: 16)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 6) {
                    Text("While You Were Away").font(.lunDisplay(26)).foregroundStyle(Tokens.textPrimary)
                    Text("Your keepers kept the light for \(timeText).").font(.lunBody(15)).foregroundStyle(Tokens.textSecondary)
                        .multilineTextAlignment(.center)
                }

                LunPanel {
                    VStack(spacing: Tokens.spaceM) {
                        earnRow(icon: "circle.hexagongrid.fill", value: report.gold.compactString, label: "Gold earned", color: Tokens.brassBright)
                        if report.oil > 0 {
                            earnRow(icon: "drop.fill", value: report.oil.compactString, label: "Oil gathered", color: Color(hex: 0x8FC9E0))
                        }
                        if report.capped {
                            Text("Offline guidance was capped — train Long Vigil to extend it.")
                                .font(.lunBody(12)).foregroundStyle(Tokens.textMuted)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, Tokens.spaceL)
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)

                Spacer()
                LunButton(title: "Welcome Back", icon: "sun.haze.fill", fullWidth: true, action: onClose)
                    .padding(.horizontal, Tokens.spaceL)
                Spacer().frame(height: 12)
            }
        }
        .statusBarHidden()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
            Haptics.success()
        }
    }

    private var timeText: String {
        let total = Int(report.seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m) minutes" }
        return "a short while"
    }

    private func earnRow(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: Tokens.spaceM) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(color).frame(width: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text("+\(value)").font(.lunNumber(24)).foregroundStyle(Tokens.textPrimary)
                Text(label).font(.lunBody(12)).foregroundStyle(Tokens.textMuted)
            }
            Spacer()
        }
    }
}
