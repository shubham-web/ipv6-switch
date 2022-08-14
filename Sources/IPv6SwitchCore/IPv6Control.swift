import Foundation

/// Turns IPv6 on or off for a network service with `networksetup`.
public enum IPv6Control {
    public enum Outcome: Equatable, Sendable {
        case success
        /// The user dismissed the administrator password prompt.
        case cancelled
        case failed(String)
    }

    /// The `networksetup` flag for each state. "On" means Automatic, the macOS default.
    public static func flag(enabled: Bool) -> String {
        enabled ? "-setv6automatic" : "-setv6off"
    }

    /// Sets IPv6 for `service`. Tries without privileges first, then falls back to the
    /// standard macOS administrator prompt. Blocks until done, so call it off the main thread.
    public static func set(enabled: Bool, service: String) -> Outcome {
        let direct = Shell.run("/usr/sbin/networksetup", [flag(enabled: enabled), service])
        if direct.succeeded && !direct.output.localizedCaseInsensitiveContains("error") {
            return .success
        }
        // The service name goes in as an argument and reaches the shell through
        // `quoted form of`, never by string interpolation.
        let elevated = Shell.run("/usr/bin/osascript", adminArguments(enabled: enabled, service: service))
        return outcome(of: elevated)
    }

    /// Arguments for `osascript` that run `networksetup <flag> <service>` as root.
    public static func adminArguments(enabled: Bool, service: String) -> [String] {
        [
            "-e", "on run argv",
            "-e", "do shell script \"/usr/sbin/networksetup \(flag(enabled: enabled)) \" & quoted form of (item 1 of argv) with administrator privileges",
            "-e", "end run",
            "--", service,
        ]
    }

    static func outcome(of result: CommandResult) -> Outcome {
        if result.succeeded { return .success }
        // AppleScript error -128 is "User canceled."
        if result.output.contains("(-128)") { return .cancelled }
        return .failed(result.output.isEmpty ? "networksetup failed (exit \(result.status))" : result.output)
    }
}
