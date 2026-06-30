import AVFoundation
import Foundation

final class AudioService {
    static let shared = AudioService()

    private let engine = AVAudioEngine()
    private let ambienceNode = AVAudioPlayerNode()
    private let effectNode = AVAudioPlayerNode()
    private let sampleRate = 44100.0
    private var started = false

    var musicEnabled = true
    var ambienceEnabled = true
    var soundEffectsEnabled = true

    private var ambienceBuffer: AVAudioPCMBuffer?

    private init() {}

    func start() {
        guard !started else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            engine.attach(ambienceNode)
            engine.attach(effectNode)
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            engine.connect(ambienceNode, to: engine.mainMixerNode, format: format)
            engine.connect(effectNode, to: engine.mainMixerNode, format: format)
            try engine.start()
            started = true
            ambienceBuffer = makeAmbienceBuffer(format: format)
            scheduleAmbienceLoop()
        } catch {
            started = false
        }
    }

    func updateAmbience() {
        guard started else { return }
        let active = musicEnabled || ambienceEnabled
        if active {
            ambienceNode.volume = ambienceEnabled ? 0.5 : 0.0
            if !ambienceNode.isPlaying { scheduleAmbienceLoop() }
        } else {
            ambienceNode.volume = 0.0
        }
    }

    private func scheduleAmbienceLoop() {
        guard let buffer = ambienceBuffer else { return }
        ambienceNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        ambienceNode.volume = ambienceEnabled ? 0.5 : 0.0
        ambienceNode.play()
    }

    private func makeAmbienceBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let seconds = 6.0
        let frames = AVAudioFrameCount(seconds * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        var rng = DeterministicRandom(seed: 7349)
        var brown = 0.0
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let white = rng.range(-1, 1)
            brown = (brown + 0.02 * white)
            brown = max(-1, min(1, brown * 0.996))
            let swell = 0.5 + 0.5 * sin(2 * .pi * 0.08 * t)
            let surf = brown * 0.35 * swell
            let lowHum = sin(2 * .pi * 56 * t) * 0.04
            let sample = Float(surf + lowHum)
            left[i] = sample
            right[i] = sample * 0.92
        }
        applyFadeLoop(buffer: buffer, frames: Int(frames))
        return buffer
    }

    private func applyFadeLoop(buffer: AVAudioPCMBuffer, frames: Int) {
        let fade = Int(sampleRate * 0.3)
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]
        for i in 0..<fade {
            let g = Float(i) / Float(fade)
            left[i] *= g
            right[i] *= g
            left[frames - 1 - i] *= g
            right[frames - 1 - i] *= g
        }
    }

    func playHorn() {
        guard soundEffectsEnabled else { return }
        playTone(frequencies: [196, 294], duration: 0.7, volume: 0.22, fade: 0.25)
    }

    func playChime() {
        guard soundEffectsEnabled else { return }
        playTone(frequencies: [660, 880, 1320], duration: 0.5, volume: 0.16, fade: 0.3)
    }

    func playCreak() {
        guard soundEffectsEnabled else { return }
        playNoise(duration: 0.18, volume: 0.07, centerFrequency: 320)
    }

    func playThud() {
        guard soundEffectsEnabled else { return }
        playNoise(duration: 0.3, volume: 0.15, centerFrequency: 120)
    }

    private func playTone(frequencies: [Double], duration: Double, volume: Double, fade: Double) {
        guard started, let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buffer.frameLength = frames
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            var value = 0.0
            for f in frequencies { value += sin(2 * .pi * f * t) }
            value /= Double(frequencies.count)
            let env = envelope(t: t, duration: duration, fade: fade)
            let sample = Float(value * volume * env)
            left[i] = sample
            right[i] = sample
        }
        effectNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !effectNode.isPlaying { effectNode.play() }
    }

    private func playNoise(duration: Double, volume: Double, centerFrequency: Double) {
        guard started, let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buffer.frameLength = frames
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]
        var rng = DeterministicRandom(seed: UInt64(centerFrequency))
        var last = 0.0
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let white = rng.range(-1, 1)
            last = last * 0.6 + white * 0.4
            let mod = sin(2 * .pi * centerFrequency * t)
            let env = envelope(t: t, duration: duration, fade: duration * 0.5)
            let sample = Float((last * 0.7 + mod * 0.3) * volume * env)
            left[i] = sample
            right[i] = sample
        }
        effectNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !effectNode.isPlaying { effectNode.play() }
    }

    private func envelope(t: Double, duration: Double, fade: Double) -> Double {
        let attack = min(0.02, fade)
        if t < attack { return t / attack }
        let releaseStart = duration - fade
        if t > releaseStart { return max(0, (duration - t) / fade) }
        return 1
    }
}
