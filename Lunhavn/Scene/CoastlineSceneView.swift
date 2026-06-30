import SwiftUI

struct CoastlineSceneView: View {
    @Bindable var engine: GameEngine
    var interactive: Bool = true

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { _ in
                Canvas { context, size in
                    let renderer = SceneRenderer(
                        context: context,
                        size: size,
                        engine: engine,
                        palette: ScenePalette.resolve(engine),
                        time: engine.clock,
                        reducedMotion: engine.state.settings.reducedMotion
                    )
                    renderer.draw()
                }
                .drawingGroup(opaque: true)
            }
            .background(Color(hex: 0x05070E))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard interactive, geo.size.width > 0 else { return }
                        let v = Vec(x: Double(value.location.x / geo.size.width),
                                    y: Double(value.location.y / geo.size.height))
                        engine.aimPrimary(at: v)
                    }
            )
        }
        .ignoresSafeArea()
    }
}

struct SceneRenderer {
    let context: GraphicsContext
    let size: CGSize
    let engine: GameEngine
    let palette: ScenePalette
    let time: Double
    let reducedMotion: Bool

    private func p(_ v: Vec) -> CGPoint {
        CGPoint(x: v.x * size.width, y: v.y * size.height)
    }

    private var lighthouse: CGPoint { p(Balance.lighthouse) }

    func draw() {
        drawSky()
        drawStars()
        drawMoon()
        drawSea()
        drawBeams()
        drawRocks()
        drawBerths()
        drawFog()
        drawMines()
        drawShips()
        drawLighthouse()
        drawMotes()
        drawRewards()
    }

    private func drawSky() {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [palette.skyTop(), palette.skyBottom()]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height * Balance.seaTop)
            )
        )
    }

    private func drawStars() {
        var rng = DeterministicRandom(seed: 99221)
        let count = 70
        let seaTopY = size.height * Balance.seaTop
        for i in 0..<count {
            let x = rng.nextUnit() * Double(size.width)
            let y = rng.nextUnit() * Double(seaTopY) * 0.95
            let base = rng.range(0.3, 1.0)
            let twinkle = reducedMotion ? base : base * (0.6 + 0.4 * sin(time * 1.5 + Double(i)))
            let r = rng.range(0.6, 1.7)
            let star = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            context.fill(star, with: .color(palette.starColor().opacity(twinkle * 0.9 * palette.nightFactor)))
        }
    }

    private func drawMoon() {
        let mx = size.width * 0.78
        let my = size.height * 0.06
        let radius = size.width * 0.07
        let glow = Path(ellipseIn: CGRect(x: mx - radius * 2.4, y: my - radius * 2.4, width: radius * 4.8, height: radius * 4.8))
        context.fill(glow, with: .radialGradient(
            Gradient(colors: [Color(hex: 0xFFF6DD).opacity(0.5 * palette.nightFactor), .clear]),
            center: CGPoint(x: mx, y: my), startRadius: 0, endRadius: radius * 2.4))
        let moon = Path(ellipseIn: CGRect(x: mx - radius, y: my - radius, width: radius * 2, height: radius * 2))
        context.fill(moon, with: .color(Color(hex: 0xFBF3DA).opacity(0.92)))
        let shadow = Path(ellipseIn: CGRect(x: mx - radius * 0.7, y: my - radius * 1.1, width: radius * 2, height: radius * 2))
        context.fill(shadow, with: .color(palette.skyTop().opacity(0.5)))
    }

    private func drawSea() {
        let seaTopY = size.height * Balance.seaTop
        let rect = CGRect(x: 0, y: seaTopY, width: size.width, height: size.height - seaTopY)
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [palette.seaNear().opacity(0.92), palette.seaFar()]),
                startPoint: CGPoint(x: 0, y: seaTopY),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        let reflection = Path { path in
            let mx = size.width * 0.78
            path.move(to: CGPoint(x: mx - 6, y: seaTopY))
            path.addLine(to: CGPoint(x: mx + 6, y: seaTopY))
            path.addLine(to: CGPoint(x: mx + 26, y: size.height))
            path.addLine(to: CGPoint(x: mx - 26, y: size.height))
            path.closeSubpath()
        }
        context.fill(reflection, with: .linearGradient(
            Gradient(colors: [palette.foam().opacity(0.18 * palette.nightFactor), .clear]),
            startPoint: CGPoint(x: 0, y: seaTopY), endPoint: CGPoint(x: 0, y: size.height)))

        let rows = 13
        for i in 0..<rows {
            let t = Double(i) / Double(rows)
            let y = seaTopY + (size.height - seaTopY) * t
            let amplitude = reducedMotion ? 0 : (1.2 + t * 3.5)
            var wave = Path()
            wave.move(to: CGPoint(x: 0, y: y))
            var x = 0.0
            while x <= Double(size.width) {
                let offset = sin(x * 0.03 + time * (0.6 + t) + Double(i)) * amplitude
                wave.addLine(to: CGPoint(x: x, y: y + offset))
                x += 14
            }
            context.stroke(wave, with: .color(palette.foam().opacity(0.05 + 0.05 * t)), lineWidth: 1)
        }
    }

    private func beamPath(angle: Double, half: Double, range: Double) -> Path {
        let apex = lighthouse
        let leftDir = angle - half
        let rightDir = angle + half
        let len = range * Double(size.height) * 1.3
        let left = CGPoint(x: apex.x + sin(leftDir) * len, y: apex.y + cos(leftDir) * len)
        let right = CGPoint(x: apex.x + sin(rightDir) * len, y: apex.y + cos(rightDir) * len)
        var path = Path()
        path.move(to: apex)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()
        return path
    }

    private func drawBeam(angle: Double, intensity: Double) {
        let apex = lighthouse
        let half = engine.stats.beamHalfAngle
        let range = engine.stats.beamRange
        let cone = beamPath(angle: angle, half: half, range: range)
        let endLen = range * Double(size.height) * 1.3
        let endPoint = CGPoint(x: apex.x + sin(angle) * endLen, y: apex.y + cos(angle) * endLen)

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 6))
            layer.fill(cone, with: .linearGradient(
                Gradient(colors: [
                    palette.beamCore().opacity(0.55 * intensity),
                    palette.beamEdge().opacity(0.22 * intensity),
                    .clear
                ]),
                startPoint: apex,
                endPoint: endPoint
            ))
        }
        let innerCone = beamPath(angle: angle, half: half * 0.5, range: range * 0.95)
        context.fill(innerCone, with: .linearGradient(
            Gradient(colors: [palette.beamCore().opacity(0.5 * intensity), .clear]),
            startPoint: apex, endPoint: endPoint))
    }

    private func drawBeams() {
        context.drawLayer { layer in
            var blended = layer
            blended.blendMode = .plusLighter
            let renderer = SceneRenderer(context: blended, size: size, engine: engine, palette: palette, time: time, reducedMotion: reducedMotion)
            renderer.drawBeam(angle: engine.beamAngle, intensity: 1.0)
            if engine.stats.hasSecondSpotlight && engine.state.secondSpotlightOn {
                renderer.drawBeam(angle: engine.secondBeamAngle, intensity: 0.7)
            }
        }
    }

    private func drawRocks() {
        for rock in engine.rocks {
            let center = p(rock.pos)
            let r = rock.radius * Double(size.width)
            var path = Path()
            var rng = DeterministicRandom(seed: UInt64(rock.id * 7 + 13))
            let points = 8
            for i in 0...points {
                let a = Double(i) / Double(points) * 2 * .pi
                let rr = r * rng.range(0.7, 1.1)
                let pt = CGPoint(x: center.x + cos(a) * rr, y: center.y + sin(a) * rr * 0.7)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            let foam = Path(ellipseIn: CGRect(x: center.x - r * 1.3, y: center.y - r * 0.9, width: r * 2.6, height: r * 1.8))
            context.stroke(foam, with: .color(palette.foam().opacity(0.22)), lineWidth: 2)
            context.fill(path, with: .color(Color(hex: 0x0C1018)))
            context.stroke(path, with: .color(Color(hex: 0x2A3140).opacity(0.8)), lineWidth: 1.2)
        }
    }

    private func drawBerths() {
        for berth in engine.berths {
            let center = p(berth.pos)
            let color = Tokens.berthColors[berth.colorIndex % Tokens.berthColors.count]
            let dock = Path(roundedRect: CGRect(x: center.x - 16, y: center.y - 5, width: 32, height: 10), cornerRadius: 3)
            context.fill(dock, with: .color(Color(hex: 0x2A1C12)))
            context.stroke(dock, with: .color(Tokens.brass.opacity(0.5)), lineWidth: 1)
            let pulse = reducedMotion ? 1 : (0.7 + 0.3 * sin(time * 2 + Double(berth.id)))
            let light = Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 14, width: 10, height: 10))
            context.fill(light, with: .color(color.opacity(0.95)))
            let glow = Path(ellipseIn: CGRect(x: center.x - 14, y: center.y - 23, width: 28, height: 28))
            context.fill(glow, with: .radialGradient(
                Gradient(colors: [color.opacity(0.5 * pulse), .clear]),
                center: CGPoint(x: center.x, y: center.y - 9), startRadius: 0, endRadius: 16))
        }
    }

    private func drawFog() {
        context.drawLayer { layer in
            var add = layer
            add.blendMode = .plusLighter
            for fog in engine.fogBanks {
                let center = p(fog.center)
                let r = fog.radius * Double(size.width)
                let blob = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 0.7, width: r * 2, height: r * 1.4))
                add.fill(blob, with: .radialGradient(
                    Gradient(colors: [Color(hex: 0xB8C2D6).opacity(0.28 * fog.density), .clear]),
                    center: center, startRadius: 0, endRadius: r))
            }
        }
    }

    private func drawMines() {
        for mine in engine.mines {
            let center = p(mine.pos)
            let r = size.width * 0.018
            if mine.detonating {
                let burst = Path(ellipseIn: CGRect(x: center.x - r * 3, y: center.y - r * 3, width: r * 6, height: r * 6))
                context.fill(burst, with: .radialGradient(
                    Gradient(colors: [Tokens.mine.opacity(0.8), .clear]),
                    center: center, startRadius: 0, endRadius: r * 3))
                continue
            }
            let warn = mine.lit
            if warn > 0.1 {
                let glow = Path(ellipseIn: CGRect(x: center.x - r * 2.6, y: center.y - r * 2.6, width: r * 5.2, height: r * 5.2))
                context.fill(glow, with: .radialGradient(
                    Gradient(colors: [Tokens.mine.opacity(0.6 * warn), .clear]),
                    center: center, startRadius: 0, endRadius: r * 2.6))
            }
            let spikes = 8
            var spikePath = Path()
            for i in 0..<spikes {
                let a = Double(i) / Double(spikes) * 2 * .pi
                spikePath.move(to: CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r))
                spikePath.addLine(to: CGPoint(x: center.x + cos(a) * r * 1.5, y: center.y + sin(a) * r * 1.5))
            }
            context.stroke(spikePath, with: .color(Color(hex: 0x40121A)), lineWidth: 2)
            let body = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
            context.fill(body, with: .radialGradient(
                Gradient(colors: [Color(hex: 0x6B2030), Color(hex: 0x2A0A12)]),
                center: CGPoint(x: center.x - r * 0.3, y: center.y - r * 0.3), startRadius: 0, endRadius: r * 1.4))
            let pulse = 0.5 + 0.5 * sin(mine.pulse * 4)
            let eye = Path(ellipseIn: CGRect(x: center.x - r * 0.3, y: center.y - r * 0.3, width: r * 0.6, height: r * 0.6))
            context.fill(eye, with: .color(Tokens.mine.opacity(0.6 + 0.4 * pulse)))
        }
    }

    private func drawShips() {
        for ship in engine.ships {
            let center = p(ship.pos)
            let bob = reducedMotion ? 0 : sin(time * 2 + ship.bobPhase) * 2
            let color = Tokens.berthColors[ship.type.colorIndex % Tokens.berthColors.count]
            let scale = size.width * 0.026 * (ship.type.id == "galleon" || ship.type.id == "freighter" ? 1.35 : 1.0)

            if ship.wrecking {
                let burst = Path(ellipseIn: CGRect(x: center.x - scale * 2, y: center.y - scale * 2, width: scale * 4, height: scale * 4))
                context.fill(burst, with: .radialGradient(
                    Gradient(colors: [Tokens.hazard.opacity(0.7 * ship.wreckTimer), .clear]),
                    center: center, startRadius: 0, endRadius: scale * 2))
            }

            if ship.wakeStrength > 0.1 && !reducedMotion {
                var wake = Path()
                wake.move(to: CGPoint(x: center.x - scale * 0.6, y: center.y + bob))
                wake.addLine(to: CGPoint(x: center.x - scale * 1.4, y: center.y + scale * 3 + bob))
                wake.addLine(to: CGPoint(x: center.x + scale * 1.4, y: center.y + scale * 3 + bob))
                wake.addLine(to: CGPoint(x: center.x + scale * 0.6, y: center.y + bob))
                wake.closeSubpath()
                context.fill(wake, with: .linearGradient(
                    Gradient(colors: [palette.foam().opacity(0.25 * ship.wakeStrength), .clear]),
                    startPoint: CGPoint(x: 0, y: center.y), endPoint: CGPoint(x: 0, y: center.y + scale * 3)))
            }

            if ship.illumination > 0.05 {
                let glow = Path(ellipseIn: CGRect(x: center.x - scale * 2.2, y: center.y - scale * 2.2 + bob, width: scale * 4.4, height: scale * 4.4))
                context.fill(glow, with: .radialGradient(
                    Gradient(colors: [palette.beamCore().opacity(0.4 * ship.illumination), .clear]),
                    center: CGPoint(x: center.x, y: center.y + bob), startRadius: 0, endRadius: scale * 2.2))
            }

            var hull = Path()
            let y = center.y + bob
            hull.move(to: CGPoint(x: center.x - scale, y: y))
            hull.addQuadCurve(to: CGPoint(x: center.x + scale, y: y), control: CGPoint(x: center.x, y: y + scale * 1.3))
            hull.closeSubpath()
            context.fill(hull, with: .color(Color(hex: 0x2A2018)))
            context.stroke(hull, with: .color(color.opacity(0.9)), lineWidth: 1.4)

            var sail = Path()
            sail.move(to: CGPoint(x: center.x, y: y - scale * 1.6))
            sail.addLine(to: CGPoint(x: center.x + scale * 0.8, y: y - scale * 0.1))
            sail.addLine(to: CGPoint(x: center.x, y: y - scale * 0.1))
            sail.closeSubpath()
            context.fill(sail, with: .color(color))
            context.stroke(Path { p in
                p.move(to: CGPoint(x: center.x, y: y - scale * 1.7))
                p.addLine(to: CGPoint(x: center.x, y: y))
            }, with: .color(Color(hex: 0x6E5421)), lineWidth: 1)

            let confW = scale * 1.6
            let barY = y - scale * 2.2
            let back = Path(roundedRect: CGRect(x: center.x - confW / 2, y: barY, width: confW, height: 3), cornerRadius: 1.5)
            context.fill(back, with: .color(.black.opacity(0.4)))
            let front = Path(roundedRect: CGRect(x: center.x - confW / 2, y: barY, width: confW * min(1, ship.confidence), height: 3), cornerRadius: 1.5)
            context.fill(front, with: .color(ship.confidence > 0.5 ? Tokens.safe : Tokens.glow))
        }
    }

    private func drawLighthouse() {
        let base = lighthouse
        let towerWidth = size.width * 0.085
        let towerHeight = size.height * 0.11
        let topY = base.y
        let bottomY = base.y + towerHeight

        let cliff = Path { path in
            path.move(to: CGPoint(x: base.x - towerWidth * 1.8, y: bottomY + towerHeight * 0.5))
            path.addLine(to: CGPoint(x: base.x - towerWidth * 0.9, y: bottomY - 4))
            path.addLine(to: CGPoint(x: base.x + towerWidth * 0.9, y: bottomY - 4))
            path.addLine(to: CGPoint(x: base.x + towerWidth * 1.8, y: bottomY + towerHeight * 0.5))
            path.closeSubpath()
        }
        context.fill(cliff, with: .color(Color(hex: 0x14110C)))

        var tower = Path()
        tower.move(to: CGPoint(x: base.x - towerWidth * 0.42, y: topY + towerHeight * 0.32))
        tower.addLine(to: CGPoint(x: base.x - towerWidth * 0.5, y: bottomY))
        tower.addLine(to: CGPoint(x: base.x + towerWidth * 0.5, y: bottomY))
        tower.addLine(to: CGPoint(x: base.x + towerWidth * 0.42, y: topY + towerHeight * 0.32))
        tower.closeSubpath()
        context.fill(tower, with: .color(Color(hex: palette.skin.body)))

        let stripes = 3
        for i in 0..<stripes {
            let t0 = Double(i) / Double(stripes)
            let t1 = (Double(i) + 0.5) / Double(stripes)
            let yA = (topY + towerHeight * 0.32) + (bottomY - (topY + towerHeight * 0.32)) * t0
            let yB = (topY + towerHeight * 0.32) + (bottomY - (topY + towerHeight * 0.32)) * t1
            let wA = Mathx.lerp(towerWidth * 0.42, towerWidth * 0.5, t0)
            let wB = Mathx.lerp(towerWidth * 0.42, towerWidth * 0.5, t1)
            var stripe = Path()
            stripe.move(to: CGPoint(x: base.x - wA, y: yA))
            stripe.addLine(to: CGPoint(x: base.x - wB, y: yB))
            stripe.addLine(to: CGPoint(x: base.x + wB, y: yB))
            stripe.addLine(to: CGPoint(x: base.x + wA, y: yA))
            stripe.closeSubpath()
            context.fill(stripe, with: .color(Color(hex: palette.skin.stripe)))
        }

        let galleryY = topY + towerHeight * 0.32
        let gallery = Path(roundedRect: CGRect(x: base.x - towerWidth * 0.5, y: galleryY - 5, width: towerWidth, height: 7), cornerRadius: 2)
        context.fill(gallery, with: .color(Color(hex: 0x3A2A1C)))

        let flicker = engine.lampFlicker
        let lampRect = CGRect(x: base.x - towerWidth * 0.36, y: topY + towerHeight * 0.06, width: towerWidth * 0.72, height: towerHeight * 0.28)
        let lampGlow = Path(ellipseIn: lampRect.insetBy(dx: -towerWidth * 0.5, dy: -towerWidth * 0.5))
        context.fill(lampGlow, with: .radialGradient(
            Gradient(colors: [Color(hex: palette.skin.lamp).opacity(0.7 * flicker), .clear]),
            center: CGPoint(x: lampRect.midX, y: lampRect.midY), startRadius: 0, endRadius: towerWidth))
        let lamp = Path(roundedRect: lampRect, cornerRadius: 4)
        context.fill(lamp, with: .color(Color(hex: palette.skin.lamp).opacity(0.95 * flicker)))
        let roof = Path { path in
            path.move(to: CGPoint(x: base.x - towerWidth * 0.4, y: topY + towerHeight * 0.06))
            path.addLine(to: CGPoint(x: base.x, y: topY - towerHeight * 0.08))
            path.addLine(to: CGPoint(x: base.x + towerWidth * 0.4, y: topY + towerHeight * 0.06))
            path.closeSubpath()
        }
        context.fill(roof, with: .color(Color(hex: 0x2A1C12)))
    }

    private func drawMotes() {
        guard !reducedMotion else { return }
        context.drawLayer { layer in
            var add = layer
            add.blendMode = .plusLighter
            var rng = DeterministicRandom(seed: 5151)
            let apex = lighthouse
            for i in 0..<22 {
                let along = (rng.nextUnit() + time * 0.05 * rng.range(0.5, 1.5)).truncatingRemainder(dividingBy: 1)
                let len = engine.stats.beamRange * Double(size.height) * 1.2
                let spread = rng.range(-1, 1) * engine.stats.beamHalfAngle
                let a = engine.beamAngle + spread
                let dist = along * len
                let x = apex.x + sin(a) * dist
                let y = apex.y + cos(a) * dist
                let r = rng.range(0.8, 2.2)
                let fade = (1 - along) * 0.5
                let dot = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                add.fill(dot, with: .color(palette.beamCore().opacity(fade)))
                _ = i
            }
        }
    }

    private func drawRewards() {
        for reward in engine.floatingRewards {
            let center = p(reward.pos)
            let progress = reward.age / reward.life
            let opacity = 1 - progress
            let text = Text(reward.text)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: reward.color, alpha: opacity))
            context.draw(text, at: CGPoint(x: center.x, y: center.y - 18 - progress * 14))
        }
    }
}
