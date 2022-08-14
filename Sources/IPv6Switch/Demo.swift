#if DEBUG
import AppKit
import IPv6SwitchCore

/// Screenshot mode, only in debug builds. `IPV6SWITCH_DEMO=dark swift run` (or `light`) shows
/// fixed example addresses from the documentation ranges and never touches network settings.
/// `make screenshot` uses it to regenerate the README images.
@MainActor
enum Demo {
    private static let value = ProcessInfo.processInfo.environment["IPV6SWITCH_DEMO"] ?? ""

    static var isEnabled: Bool { !value.isEmpty }

    static let snapshot = NetworkSnapshot(
        defaultInterface: "en0",
        service: NetworkService(name: "Wi-Fi", device: "en0"),
        localIPv4: "192.168.1.42",
        localIPv6: "2001:db8:4f2a:1c00:8d3e:5b7a:91c4:2e6f",
        publicIPv4: "203.0.113.24",
        publicIPv6: "2001:db8:4f2a:1c00:a1b2:c3d4:e5f6:7a8b",
        ipv6Enabled: true)

    /// Forces the requested appearance and brings the window to the front, so it's
    /// captured with the active-window look.
    static func prepareApp() {
        guard isEnabled else { return }
        switch value {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: break
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
