import AppKit
import IPv6SwitchCore

@MainActor
final class Model: ObservableObject {
    /// `nil` until the first refresh finishes.
    @Published private(set) var snapshot: NetworkSnapshot?
    @Published private(set) var busy = false
    @Published var error: String?

    func refresh() {
        #if DEBUG
        if Demo.isEnabled {
            snapshot = Demo.snapshot
            NSApp.dockTile.badgeLabel = Demo.snapshot.connectivity.badge
            return
        }
        #endif
        busy = true
        let previous = snapshot?.service
        Task {
            let snapshot = await Task.detached { await NetworkSnapshot.capture(previousService: previous) }.value
            self.snapshot = snapshot
            NSApp.dockTile.badgeLabel = snapshot.connectivity.badge
            busy = false
        }
    }

    func setIPv6(_ enabled: Bool) {
        #if DEBUG
        if Demo.isEnabled {
            snapshot?.ipv6Enabled = enabled
            return
        }
        #endif
        guard let service = snapshot?.service?.name else {
            error = "No network service found"
            return
        }
        error = nil
        busy = true
        Task {
            let outcome = await Task.detached { IPv6Control.set(enabled: enabled, service: service) }.value
            switch outcome {
            case .success:
                // Give the interface time to pick up (or drop) its IPv6 addresses before re-reading.
                try? await Task.sleep(nanoseconds: 2_500_000_000)
            case .cancelled:
                break
            case .failed(let message):
                error = message
            }
            refresh()
        }
    }
}
