import Foundation
import Observation
import SwiftUI

struct IdleReport: Identifiable {
    let id = UUID()
    let seconds: Double
    let gold: Double
    let oil: Double
    let capped: Bool
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
    let color: Color
}

@Observable
final class GameEngine {
    @ObservationIgnored var state: GameState
    @ObservationIgnored var stats: LighthouseStats

    @ObservationIgnored var ships: [Ship] = []
    @ObservationIgnored var mines: [Mine] = []
    @ObservationIgnored var rocks: [Rock] = []
    @ObservationIgnored var fogBanks: [FogBank] = []
    @ObservationIgnored var berths: [Berth] = []
    @ObservationIgnored var floatingRewards: [FloatingReward] = []
    @ObservationIgnored var weather = WeatherState()

    @ObservationIgnored var beamAngle = 0.0
    @ObservationIgnored var beamTargetAngle = 0.0
    @ObservationIgnored var secondBeamAngle = 0.4
    @ObservationIgnored var clock = 0.0
    @ObservationIgnored var lampFlicker = 1.0
    @ObservationIgnored var sceneActive = false

    @ObservationIgnored var rng: DeterministicRandom
    @ObservationIgnored private var accumulator = 0.0
    @ObservationIgnored private var spawnTimer = 0.0
    @ObservationIgnored private var mineTimer = 0.0
    @ObservationIgnored private var fogTimer = 0.0
    @ObservationIgnored private var uiAccumulator = 0.0
    @ObservationIgnored private var saveAccumulator = 0.0
    @ObservationIgnored private var goldBuffer = 0.0
    @ObservationIgnored private var oilBuffer = 0.0
    @ObservationIgnored private var nextEntityId = 1
    @ObservationIgnored private var driver: DisplayLinkDriver?
    @ObservationIgnored private var weatherStormCredited = false

    var version = 0
    var idleReport: IdleReport?
    var activeToast: ToastMessage?

    init() {
        let loaded = SaveService.shared.load()
        let initial = loaded ?? GameEngine.freshState()
        state = initial
        rng = DeterministicRandom(seed: initial.rngSeed)
        stats = LighthouseStats.build(from: initial)
        configureBay()
        if loaded != nil {
            applyOfflineProgress()
        } else {
            state.gold = stats.startingGold
        }
        ensureMissions()
        refreshDaily()
        syncAudioSettings()
    }

    static func freshState() -> GameState {
        var s = GameState()
        s.rngSeed = 0x1234_5678_9ABC_DEF0
        return s
    }

    func rebuildStats() {
        stats = LighthouseStats.build(from: state)
        state.secondSpotlightOn = state.secondSpotlightOn && stats.hasSecondSpotlight
    }

    func bumpVersion() {
        version &+= 1
    }

    func start() {
        Haptics.enabled = state.settings.hapticsEnabled
        AudioService.shared.start()
        syncAudioSettings()
        if driver == nil {
            driver = DisplayLinkDriver { [weak self] dt in
                self?.advance(dt)
            }
        }
        driver?.start()
    }

    func pauseLoop() {
        driver?.stop()
    }

    func resumeLoop() {
        driver?.start()
    }

    func handleBackground() {
        flushBuffers()
        state.lastActive = Date()
        state.rngSeed = rng.nextUInt()
        SaveService.shared.save(state)
        driver?.stop()
    }

    func handleForeground() {
        applyOfflineProgress()
        driver?.start()
    }

    func syncAudioSettings() {
        AudioService.shared.musicEnabled = state.settings.musicEnabled
        AudioService.shared.ambienceEnabled = state.settings.ambienceEnabled
        AudioService.shared.soundEffectsEnabled = state.settings.soundEnabled
        AudioService.shared.updateAmbience()
        Haptics.enabled = state.settings.hapticsEnabled
    }

    private func newId() -> Int {
        defer { nextEntityId += 1 }
        return nextEntityId
    }

    func configureBay() {
        berths.removeAll()
        let colors = Array(Set(ContentLibrary.shipTypes.map { $0.colorIndex })).sorted()
        let leftCount = (colors.count + 1) / 2
        for (index, color) in colors.enumerated() {
            let x: Double
            if index < leftCount {
                let t = leftCount == 1 ? 0.5 : Double(index) / Double(leftCount - 1)
                x = Mathx.lerp(0.09, 0.36, t)
            } else {
                let rightIndex = index - leftCount
                let rightCount = colors.count - leftCount
                let t = rightCount == 1 ? 0.5 : Double(rightIndex) / Double(rightCount - 1)
                x = Mathx.lerp(0.64, 0.91, t)
            }
            berths.append(Berth(id: color, colorIndex: color, pos: Vec(x: x, y: Balance.shoreY)))
        }
        rocks.removeAll()
        for i in 0..<Balance.rockCount {
            let t = Double(i) / Double(Balance.rockCount - 1)
            let x = Mathx.lerp(0.16, 0.84, t) + rng.range(-0.05, 0.05)
            let y = rng.range(0.42, 0.72)
            rocks.append(Rock(id: newId(), pos: Vec(x: x, y: y), radius: rng.range(0.028, 0.045)))
        }
        weather = WeatherState()
        weather.kind = .clear
        weather.visibility = 1
        weather.timeRemaining = Balance.weatherMinDuration
    }

    var currentStage: Int {
        Balance.stageFor(prestiges: state.stats.prestiges, shipsGuided: state.stats.shipsGuided)
    }

    func advance(_ realDelta: Double) {
        accumulator += realDelta
        var steps = 0
        while accumulator >= Balance.fixedTimestep && steps < Balance.maxStepsPerFrame {
            step(Balance.fixedTimestep)
            accumulator -= Balance.fixedTimestep
            steps += 1
        }
        if steps == Balance.maxStepsPerFrame {
            accumulator = 0
        }

        uiAccumulator += realDelta
        if uiAccumulator >= 0.2 {
            uiAccumulator = 0
            flushBuffers()
            bumpVersion()
        }
        saveAccumulator += realDelta
        if saveAccumulator >= 12 {
            saveAccumulator = 0
            persist()
        }
    }

    private func step(_ dt: Double) {
        clock += dt
        lampFlicker = 0.92 + 0.08 * sin(clock * 7.3) + 0.02 * sin(clock * 19.1)
        accrueIdle(dt)
        updateWeather(dt)
        moveBeams(dt)
        guard sceneActive else { return }
        updateSpawning(dt)
        updateShips(dt)
        updateMines(dt)
        updateFog(dt)
        updateRewards(dt)
    }

    private func accrueIdle(_ dt: Double) {
        goldBuffer += stats.idleGoldPerSecond * dt
        oilBuffer += stats.idleOilPerSecond * dt
    }

    private func flushBuffers() {
        if goldBuffer > 0 {
            state.gold += goldBuffer
            state.stats.totalGold += goldBuffer
            goldBuffer = 0
        }
        if oilBuffer > 0 {
            state.oil += oilBuffer
            oilBuffer = 0
        }
    }

    func persist() {
        flushBuffers()
        state.lastActive = Date()
        SaveService.shared.save(state)
    }

    private func moveBeams(_ dt: Double) {
        let maxDelta = stats.rotationSpeed * dt
        beamAngle = beamAngle + Mathx.clamp(Mathx.angleDelta(beamTargetAngle, beamAngle), -maxDelta, maxDelta)

        if stats.hasSecondSpotlight && state.secondSpotlightOn {
            let target = autoBeamTarget()
            secondBeamAngle = secondBeamAngle + Mathx.clamp(Mathx.angleDelta(target, secondBeamAngle), -maxDelta, maxDelta)
        }
    }

    private func autoBeamTarget() -> Double {
        var best: Ship?
        var bestScore = -1.0
        for ship in ships where ship.alive && !ship.arrived {
            let progress = (Balance.spawnY - ship.pos.y)
            let score = (1 - ship.confidence) * (0.5 + progress)
            if score > bestScore {
                bestScore = score
                best = ship
            }
        }
        guard let ship = best else { return secondBeamAngle }
        return angleTo(ship.pos)
    }

    func angleTo(_ p: Vec) -> Double {
        let dx = p.x - Balance.lighthouse.x
        let dy = p.y - Balance.lighthouse.y
        return Mathx.clamp(atan2(dx, dy), -Balance.beamArcLimit, Balance.beamArcLimit)
    }

    func aimPrimary(at p: Vec) {
        beamTargetAngle = angleTo(p)
    }

    func illumination(of p: Vec, beam: Double) -> Double {
        let dx = p.x - Balance.lighthouse.x
        let dy = p.y - Balance.lighthouse.y
        let dist = (dx * dx + dy * dy).squareRoot()
        if dist > stats.beamRange { return 0 }
        let shipAngle = atan2(dx, dy)
        let angDiff = abs(Mathx.angleDelta(shipAngle, beam))
        let half = stats.beamHalfAngle
        if angDiff > half { return 0 }
        let edgeStart = half * Mathx.lerp(0.2, 0.95, stats.edgeSharpness)
        let angular = 1 - Mathx.smoothstep(edgeStart, half, angDiff)
        let rangeFalloff = 1 - Mathx.smoothstep(stats.beamRange * 0.72, stats.beamRange, dist)
        var value = angular * rangeFalloff * stats.brightness
        value *= fogFactor(at: p)
        value *= weather.visibility
        return max(0, value)
    }

    private func fogFactor(at p: Vec) -> Double {
        var factor = 1.0
        for fog in fogBanks {
            let d = p.distance(to: fog.center)
            if d < fog.radius {
                let coverage = (1 - d / fog.radius) * fog.density
                let dimming = coverage * (1 - stats.fogPiercing)
                factor *= max(0.1, 1 - dimming)
            }
        }
        return factor
    }

    func combinedIllumination(of p: Vec) -> Double {
        var value = illumination(of: p, beam: beamAngle)
        if stats.hasSecondSpotlight && state.secondSpotlightOn {
            value = max(value, illumination(of: p, beam: secondBeamAngle))
        }
        return value
    }

    private func updateSpawning(_ dt: Double) {
        spawnTimer -= dt
        let activeShips = ships.filter { $0.alive && !$0.arrived }.count
        if spawnTimer <= 0 && activeShips < stats.harborCapacity {
            spawnShip()
            let stage = Double(currentStage)
            let interval = max(Balance.minSpawnInterval, Balance.baseSpawnInterval - stage * 0.35)
            spawnTimer = interval * rng.range(0.7, 1.25)
        }
    }

    private func spawnShip() {
        let stage = currentStage
        let available = ContentLibrary.shipTypes.filter { $0.minStage <= stage }
        let totalWeight = available.reduce(0) { $0 + $1.weight }
        var roll = rng.range(0, totalWeight)
        var chosen = available.first!
        for type in available {
            roll -= type.weight
            if roll <= 0 { chosen = type; break }
        }
        let x = rng.range(0.12, 0.88)
        let ship = Ship(id: newId(), type: chosen, berthIndex: chosen.colorIndex, pos: Vec(x: x, y: Balance.spawnY), bobPhase: rng.range(0, 6.28))
        ships.append(ship)
    }

    private func updateShips(_ dt: Double) {
        let gain = stats.confidenceGainRate
        let decay = stats.confidenceDecayRate
        let assistPerShip = unlitAssistShare()

        for ship in ships where ship.alive {
            if ship.arrived {
                ship.arriveTimer += dt
                continue
            }
            if ship.wrecking {
                ship.wreckTimer -= dt
                if ship.wreckTimer <= 0 { ship.alive = false }
                continue
            }

            let illum = combinedIllumination(of: ship.pos)
            ship.illumination = illum
            if illum > 0.04 {
                ship.confidence = min(1.2, ship.confidence + gain * illum * dt)
            } else {
                ship.confidence = max(0, ship.confidence - decay * dt)
                if assistPerShip > 0 {
                    ship.confidence = min(1.0, ship.confidence + assistPerShip * dt)
                }
            }

            let conf = min(1, ship.confidence)
            let upSpeed = Balance.baseShipSpeed * ship.type.speed * stats.shipSpeedMultiplier * (0.12 + 0.88 * conf)
            ship.pos.y -= upSpeed * dt
            ship.wakeStrength = conf

            if illum > 0.08 {
                let axisX = Balance.lighthouse.x + tan(beamSteer(for: ship)) * (ship.pos.y - Balance.lighthouse.y)
                let steerRate = 0.55 * illum
                ship.pos.x += (axisX - ship.pos.x) * min(1, steerRate * dt * 4)
            } else {
                applyDrift(ship, dt: dt, conf: conf)
            }

            ship.pos.x = Mathx.clamp(ship.pos.x, 0.05, 0.95)
            resolveRocks(ship)
            if ship.alive && ship.pos.y <= Balance.shoreY {
                harbor(ship)
            }
        }

        ships.removeAll { !$0.alive || ($0.arrived && $0.arriveTimer > 1.0) }
    }

    private func beamSteer(for ship: Ship) -> Double {
        let primary = illumination(of: ship.pos, beam: beamAngle)
        if stats.hasSecondSpotlight && state.secondSpotlightOn {
            let second = illumination(of: ship.pos, beam: secondBeamAngle)
            if second > primary { return secondBeamAngle }
        }
        return beamAngle
    }

    private func unlitAssistShare() -> Double {
        let unlit = ships.filter { $0.alive && !$0.arrived && !$0.wrecking && $0.illumination <= 0.04 }
        guard !unlit.isEmpty, stats.keeperAssist > 0 else { return 0 }
        return stats.keeperAssist / Double(unlit.count)
    }

    private func applyDrift(_ ship: Ship, dt: Double, conf: Double) {
        let driftFactor = 1 - conf
        ship.sway += dt
        let sway = sin(ship.sway * 1.3 + ship.bobPhase) * Balance.driftStrength * driftFactor
        ship.pos.x += sway * dt

        if let nearest = nearestRock(to: ship.pos) {
            let dir = (nearest.pos - ship.pos)
            let d = dir.length
            if d < 0.22 && d > 0.001 {
                let pull = dir.normalized() * (Balance.hazardPullStrength * driftFactor * dt)
                ship.pos = ship.pos + pull
            }
        }

        if weather.kind == .storm {
            ship.pos.x += sin(clock * 1.7 + ship.bobPhase) * Balance.stormDrift * driftFactor * dt
            ship.pos.y += Balance.stormDrift * 0.4 * driftFactor * dt
        }
    }

    private func nearestRock(to p: Vec) -> Rock? {
        var best: Rock?
        var bestDist = Double.greatestFiniteMagnitude
        for rock in rocks {
            let d = rock.pos.distance(to: p)
            if d < bestDist { bestDist = d; best = rock }
        }
        return best
    }

    private func resolveRocks(_ ship: Ship) {
        for rock in rocks {
            if ship.pos.distance(to: rock.pos) < rock.radius + 0.02 {
                wreck(ship)
                return
            }
        }
    }

    private func updateMines(_ dt: Double) {
        for mine in mines {
            if mine.detonating {
                mine.detonateTimer -= dt
                if mine.detonateTimer <= 0 { mine.lit = 0 }
                continue
            }
            mine.pos = mine.pos + mine.drift * dt
            mine.pos.x = Mathx.clamp(mine.pos.x, 0.06, 0.94)
            mine.pulse += dt
            let illum = combinedIllumination(of: mine.pos)
            mine.lit = illum
            if illum > 0.45 {
                detonateMine(mine)
            }
        }
        let before = mines.count
        mines.removeAll { mine in
            (mine.detonating && mine.detonateTimer <= -0.6) || mine.pos.y < Balance.seaTop + 0.04
        }
        let dodged = mines.filter { $0.pos.y < Balance.seaTop + 0.04 && !$0.detonating }.count
        _ = before
        if dodged > 0 {
            state.stats.minesDodged += dodged
            recordMetric(.dodgeMine, amount: Double(dodged))
        }

        mineTimer -= dt
        if mineTimer <= 0 {
            let stage = currentStage
            let chance = Balance.baseMineChance + Double(stage) * 0.03
            if stage >= 2 && rng.chance(min(0.6, chance)) && mines.count < 4 + stage {
                spawnMine()
            }
            mineTimer = rng.range(4, 8)
        }
    }

    private func spawnMine() {
        let x = rng.range(0.12, 0.88)
        let y = rng.range(0.55, 0.85)
        let drift = Vec(x: rng.range(-0.01, 0.01), y: rng.range(-0.012, -0.004))
        mines.append(Mine(id: newId(), pos: Vec(x: x, y: y), drift: drift, pulse: rng.range(0, 6.28)))
    }

    private func updateFog(_ dt: Double) {
        for fog in fogBanks {
            fog.center = fog.center + fog.drift * dt
            if fog.center.x < -0.2 || fog.center.x > 1.2 {
                fog.drift.x *= -1
            }
        }
        fogBanks.removeAll { $0.density <= 0.02 }

        if weather.kind == .fog {
            fogTimer -= dt
            if fogTimer <= 0 && fogBanks.count < 4 {
                spawnFog()
                fogTimer = rng.range(2.5, 5)
            }
        } else {
            for fog in fogBanks {
                fog.density = max(0, fog.density - 0.12 * dt)
            }
        }
    }

    private func spawnFog() {
        let x = rng.range(0.15, 0.85)
        let y = rng.range(0.4, 0.78)
        let radius = rng.range(0.12, 0.22)
        let drift = Vec(x: rng.range(-0.02, 0.02), y: 0)
        fogBanks.append(FogBank(id: newId(), center: Vec(x: x, y: y), radius: radius, density: rng.range(0.6, 0.95), drift: drift))
    }

    private func updateRewards(_ dt: Double) {
        for index in floatingRewards.indices {
            floatingRewards[index].age += dt
            floatingRewards[index].pos.y -= 0.06 * dt
        }
        floatingRewards.removeAll { $0.age >= $0.life }
    }

    private func updateWeather(_ dt: Double) {
        weather.timeRemaining -= dt
        weather.dayProgress = (clock / Balance.dayLength).truncatingRemainder(dividingBy: 1)
        weather.tidePhase = sin(clock * 0.05)

        for rock in rocks.indices {
            let baseX = rocks[rock].pos.x
            rocks[rock].pos.x = Mathx.clamp(baseX + weather.tidePhase * 0.0008, 0.08, 0.92)
        }

        switch weather.kind {
        case .storm:
            weather.visibility = Balance.stormVisibility
        case .fog:
            weather.visibility = 0.85
        case .calm:
            weather.visibility = 1.0
        case .clear:
            weather.visibility = weather.isNight ? 0.92 : 1.0
        }

        if weather.timeRemaining <= 0 {
            advanceWeather()
        }
    }

    private func advanceWeather() {
        if weather.kind == .storm && !weatherStormCredited {
            state.stats.stormsWeathered += 1
            recordMetric(.weatherStorm, amount: 1)
        }
        weatherStormCredited = false

        let stage = currentStage
        let roll = rng.nextUnit()
        var next: WeatherKind = .clear
        if stage >= 1 && roll < 0.22 {
            next = .fog
        } else if stage >= 2 && roll < 0.4 {
            next = .storm
        } else if roll < 0.55 {
            next = .calm
        } else {
            next = .clear
        }
        weather.kind = next
        weather.timeRemaining = rng.range(Balance.weatherMinDuration, Balance.weatherMaxDuration)
        if next == .storm {
            showToast("A storm rolls in.", icon: "cloud.bolt.rain.fill", color: Tokens.hazard)
        } else if next == .fog {
            showToast("Fog settles over the bay.", icon: "cloud.fog.fill", color: Tokens.textSecondary)
        }
    }

    func setSceneActive(_ active: Bool) {
        sceneActive = active
        if active && weather.kind == .storm {
            weatherStormCredited = false
        }
    }

    func showToast(_ text: String, icon: String, color: Color) {
        activeToast = ToastMessage(text: text, icon: icon, color: color)
    }
}
