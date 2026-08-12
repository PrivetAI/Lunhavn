import SwiftUI

struct SettingsView: View {
    @Bindable var engine: GameEngine
    let onClose: () -> Void
    @State private var showResetConfirm = false
    @State private var showPrivacy = false

    var body: some View {
        let _ = engine.version
        return CoverScreen(engine: engine, title: "Settings", subtitle: "Tune your watch", onClose: onClose) {
            ScrollView {
                VStack(spacing: Tokens.spaceM) {
                    soundPanel
                    feelPanel
                    themePanel
                    dataPanel
                    aboutPanel
                }
                .padding(.horizontal, Tokens.spaceM)
                .padding(.bottom, 24)
            }
        }
        .alert("Reset all progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                engine.resetProgress()
                onClose()
            }
        } message: {
            Text("This permanently erases all gold, upgrades, keepers, cosmetics and statistics. This cannot be undone.")
        }
        .sheet(isPresented: $showPrivacy) {
            // Same entry point as the launch panel, opened directly — no redirect check here.
            LunhavnBeaconPanel(urlString: "https://mountainapiary.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
        }
    }

    private var soundPanel: some View {
        LunPanel {
            VStack(spacing: Tokens.spaceS) {
                LunSectionHeader(title: "Sound")
                toggle("Ambience (sea & hum)", icon: "water.waves", binding: audioBinding(\.ambienceEnabled))
                toggle("Music & melody", icon: "music.note", binding: audioBinding(\.musicEnabled))
                toggle("Sound effects (horns, chimes)", icon: "speaker.wave.2.fill", binding: audioBinding(\.soundEnabled))
            }
        }
    }

    private var feelPanel: some View {
        LunPanel {
            VStack(spacing: Tokens.spaceS) {
                LunSectionHeader(title: "Feel")
                toggle("Haptics", icon: "hand.tap.fill", binding: audioBinding(\.hapticsEnabled))
                toggle("Reduced motion", icon: "wind", binding: settingBinding(\.reducedMotion))
            }
        }
    }

    private var themePanel: some View {
        LunPanel {
            VStack(alignment: .leading, spacing: Tokens.spaceS) {
                LunSectionHeader(title: "Atmosphere")
                HStack(spacing: 8) {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            Haptics.tap()
                            engine.state.settings.theme = theme
                            engine.persist()
                            engine.bumpVersion()
                        } label: {
                            Text(theme.label)
                                .font(.lunBody(13).weight(.semibold))
                                .foregroundStyle(engine.state.settings.theme == theme ? Tokens.ink : Tokens.textSecondary)
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(Capsule().fill(engine.state.settings.theme == theme ? Tokens.brass : Tokens.panel.opacity(0.8)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dataPanel: some View {
        LunPanel {
            VStack(spacing: Tokens.spaceS) {
                LunSectionHeader(title: "Watch")
                LunButton(title: "Replay Tutorial", icon: "graduationcap.fill", kind: .secondary, fullWidth: true) {
                    engine.resetTutorial()
                    onClose()
                }
                LunButton(title: "Privacy Policy", icon: "hand.raised.fill", kind: .secondary, fullWidth: true) {
                    showPrivacy = true
                }
                LunButton(title: "Reset All Progress", icon: "trash.fill", kind: .danger, fullWidth: true) {
                    showResetConfirm = true
                }
            }
        }
    }

    private var aboutPanel: some View {
        LunPanel(tint: Tokens.wood) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Lunhavn").font(.lunDisplay(22)).foregroundStyle(Tokens.textPrimary)
                Text("A cozy lighthouse-keeper's idle game. Sweep the beam, guide ships safely home through fog and storm, and grow your light across endless nights.")
                    .font(.lunBody(13)).foregroundStyle(Tokens.textSecondary)
                Text("Plays fully offline. No ads, no purchases.")
                    .font(.lunBody(12)).foregroundStyle(Tokens.textMuted)
                    .padding(.top, 4)
            }
        }
    }

    private func toggle(_ title: String, icon: String, binding: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(Tokens.brass).frame(width: 26)
            Text(title).font(.lunBody(15)).foregroundStyle(Tokens.textPrimary)
            Spacer()
            Toggle("", isOn: binding).labelsHidden().tint(Tokens.brass)
        }
    }

    private func audioBinding(_ keyPath: WritableKeyPath<GameSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { engine.state.settings[keyPath: keyPath] },
            set: { newValue in
                engine.state.settings[keyPath: keyPath] = newValue
                engine.syncAudioSettings()
                engine.persist()
                engine.bumpVersion()
            }
        )
    }

    private func settingBinding(_ keyPath: WritableKeyPath<GameSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { engine.state.settings[keyPath: keyPath] },
            set: { newValue in
                engine.state.settings[keyPath: keyPath] = newValue
                engine.persist()
                engine.bumpVersion()
            }
        )
    }
}
