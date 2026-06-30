import SwiftUI

struct CosmeticsView: View {
    @Bindable var engine: GameEngine
    let onClose: () -> Void
    @State private var kind: CosmeticKind = .sky

    var body: some View {
        let _ = engine.version
        return CoverScreen(engine: engine, title: "Collection", subtitle: "Earn and equip with salvage", onClose: onClose) {
            VStack(spacing: Tokens.spaceM) {
                HStack {
                    CurrencyPill(currency: .salvage, value: engine.state.salvage)
                    Spacer()
                }
                .padding(.horizontal, Tokens.spaceM)

                kindPicker
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Tokens.spaceM), GridItem(.flexible(), spacing: Tokens.spaceM)], spacing: Tokens.spaceM) {
                        ForEach(items) { def in
                            CosmeticCard(engine: engine, def: def)
                        }
                    }
                    .padding(.horizontal, Tokens.spaceM)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var items: [CosmeticDef] {
        ContentLibrary.cosmetics.filter { $0.kind == kind }
    }

    private var kindPicker: some View {
        HStack(spacing: 8) {
            ForEach([CosmeticKind.sky, .sea, .beam, .lighthouse], id: \.self) { k in
                Button {
                    Haptics.tap()
                    withAnimation(.easeOut(duration: 0.2)) { kind = k }
                } label: {
                    Text(label(k))
                        .font(.lunBody(13).weight(.semibold))
                        .foregroundStyle(kind == k ? Tokens.ink : Tokens.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(kind == k ? Tokens.brass : Tokens.panel.opacity(0.8)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Tokens.spaceM)
    }

    private func label(_ k: CosmeticKind) -> String {
        switch k {
        case .sky: return "Sky"
        case .sea: return "Sea"
        case .beam: return "Beam"
        case .lighthouse: return "Tower"
        }
    }
}

struct CosmeticCard: View {
    @Bindable var engine: GameEngine
    let def: CosmeticDef

    var body: some View {
        let owned = engine.ownsCosmetic(def.id)
        let equipped = engine.isEquipped(def)
        let canBuy = engine.canAfford(def.cost, currency: def.currency)

        VStack(alignment: .leading, spacing: Tokens.spaceS) {
            CosmeticSwatch(def: def)
                .frame(height: 76)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.cornerSmall, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Tokens.cornerSmall).strokeBorder(equipped ? Tokens.brassBright : Tokens.brass.opacity(0.3), lineWidth: equipped ? 2 : 1))

            Text(def.name).font(.lunTitle(15)).foregroundStyle(Tokens.textPrimary)
            Text(def.detail).font(.lunBody(11)).foregroundStyle(Tokens.textMuted)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                if owned { engine.equipCosmetic(def) } else { engine.buyCosmetic(def) }
            } label: {
                Text(buttonLabel(owned: owned, equipped: equipped))
                    .font(.lunBody(13).weight(.bold))
                    .foregroundStyle(equipped ? Tokens.brassBright : (owned || canBuy ? Tokens.ink : Tokens.textMuted))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(background(owned: owned, equipped: equipped, canBuy: canBuy))
            }
            .buttonStyle(.plain)
            .disabled(equipped || (!owned && !canBuy))
        }
        .padding(Tokens.spaceS)
        .background(RoundedRectangle(cornerRadius: Tokens.corner, style: .continuous).fill(Tokens.panelRaised.opacity(0.9)))
    }

    private func buttonLabel(owned: Bool, equipped: Bool) -> String {
        if equipped { return "Equipped" }
        if owned { return "Equip" }
        return "\(Int(def.cost)) Salvage"
    }

    @ViewBuilder
    private func background(owned: Bool, equipped: Bool, canBuy: Bool) -> some View {
        if equipped {
            Capsule().fill(Tokens.ink.opacity(0.5))
        } else if owned || canBuy {
            Capsule().fill(Tokens.brass)
        } else {
            Capsule().fill(Tokens.panel.opacity(0.7))
        }
    }
}

struct CosmeticSwatch: View {
    let def: CosmeticDef

    var body: some View {
        switch def.kind {
        case .sky:
            let sky = Palettes.sky(def.paletteId)
            LinearGradient(colors: [Color(hex: sky.top), Color(hex: sky.bottom)], startPoint: .top, endPoint: .bottom)
                .overlay(starsOverlay(Color(hex: sky.star)))
        case .sea:
            let sea = Palettes.sea(def.paletteId)
            LinearGradient(colors: [Color(hex: sea.near), Color(hex: sea.far)], startPoint: .top, endPoint: .bottom)
        case .beam:
            let beam = Palettes.beam(def.paletteId)
            ZStack {
                Color(hex: 0x0A0F1C)
                LinearGradient(colors: [Color(hex: beam.core), Color(hex: beam.edge).opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)
            }
        case .lighthouse:
            let skin = ContentLibrary.lighthouseSkins.first { $0.id == def.paletteId } ?? ContentLibrary.lighthouseSkins[0]
            ZStack {
                Color(hex: 0x0A0F1C)
                HStack(spacing: 0) {
                    Color(hex: skin.body)
                    Color(hex: skin.stripe)
                    Color(hex: skin.body)
                }
                Circle().fill(Color(hex: skin.lamp)).frame(width: 22, height: 22).shadow(color: Color(hex: skin.lamp), radius: 8)
            }
        }
    }

    private func starsOverlay(_ color: Color) -> some View {
        Canvas { ctx, size in
            var rng = DeterministicRandom(seed: 771)
            for _ in 0..<14 {
                let x = rng.nextUnit() * Double(size.width)
                let y = rng.nextUnit() * Double(size.height) * 0.7
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)), with: .color(color.opacity(0.7)))
            }
        }
    }
}
