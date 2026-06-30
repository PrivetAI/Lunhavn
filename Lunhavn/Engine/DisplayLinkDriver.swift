import QuartzCore

final class DisplayLinkDriver {
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private let onTick: (Double) -> Void

    init(onTick: @escaping (Double) -> Void) {
        self.onTick = onTick
    }

    func start() {
        guard link == nil else { return }
        let display = CADisplayLink(target: self, selector: #selector(step))
        display.add(to: .main, forMode: .common)
        link = display
        lastTimestamp = 0
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func step(_ sender: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = sender.timestamp
            return
        }
        let delta = sender.timestamp - lastTimestamp
        lastTimestamp = sender.timestamp
        onTick(min(delta, 0.25))
    }
}
