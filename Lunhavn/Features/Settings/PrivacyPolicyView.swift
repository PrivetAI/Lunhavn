import SafariServices
import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    static let policyURL = URL(string: "https://www.termsfeed.com/live/c8bdd42a-185f-4bdd-8a32-12b754fdab08")!

    var body: some View {
        SafariSheet(url: Self.policyURL) { dismiss() }
            .ignoresSafeArea()
    }
}

/// Wraps `SFSafariViewController`. Its own "Done" button only notifies the delegate —
/// the SwiftUI sheet has to be dismissed by us, otherwise an empty sheet is left behind.
private struct SafariSheet: UIViewControllerRepresentable {
    let url: URL
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.delegate = context.coordinator
        controller.dismissButtonStyle = .done
        controller.preferredControlTintColor = UIColor(Tokens.brassBright)
        controller.preferredBarTintColor = UIColor(Tokens.ink)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {
        context.coordinator.onFinish = onFinish
    }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onFinish()
        }
    }
}
