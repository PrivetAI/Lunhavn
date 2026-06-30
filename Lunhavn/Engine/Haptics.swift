import UIKit

enum Haptics {
    static var enabled = true

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notify = UINotificationFeedbackGenerator()

    static func tap() {
        guard enabled else { return }
        light.impactOccurred(intensity: 0.6)
    }

    static func soften() {
        guard enabled else { return }
        soft.impactOccurred(intensity: 0.5)
    }

    static func arrive() {
        guard enabled else { return }
        rigid.impactOccurred(intensity: 0.8)
    }

    static func success() {
        guard enabled else { return }
        notify.notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        notify.notificationOccurred(.warning)
    }
}
