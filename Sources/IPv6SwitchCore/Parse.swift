import Foundation

/// A macOS network service, such as "Wi-Fi" or "USB 10/100/1000 LAN".
///
/// `networksetup` changes settings per *service*. A service's name can differ from its
/// hardware port name, for example when the user renames it in System Settings.
public struct NetworkService: Equatable, Hashable, Sendable {
    public var name: String
    /// BSD device name such as `en0`. `nil` for services without one, like many VPNs.
    public var device: String?
    public var isEnabled: Bool

    public init(name: String, device: String?, isEnabled: Bool = true) {
        self.name = name
        self.device = device
        self.isEnabled = isEnabled
    }
}

/// Parsers for the text output of macOS networking tools. They are pure functions so
/// they can be tested against captured output.
public enum Parse {
    /// Interface of the default route, from `route -n get default`.
    public static func defaultInterface(routeOutput: String) -> String? {
        for line in routeOutput.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces) == "interface" else { continue }
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }
        return nil
    }

    /// Services in priority order, from `networksetup -listnetworkserviceorder`:
    ///
    ///     An asterisk (*) denotes that a network service is disabled.
    ///     (1) Wi-Fi
    ///     (Hardware Port: Wi-Fi, Device: en0)
    ///
    ///     (*) Bluetooth PAN
    ///     (Hardware Port: Bluetooth PAN, Device: en5)
    public static func networkServices(serviceOrder: String) -> [NetworkService] {
        var services: [NetworkService] = []
        var pending: NetworkService?
        for raw in serviceOrder.split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("(Hardware Port:") {
                guard var service = pending else { continue }
                if let r = line.range(of: "Device:", options: .backwards) {
                    let device = line[r.upperBound...]
                        .trimmingCharacters(in: CharacterSet(charactersIn: ")").union(.whitespaces))
                    service.device = device.isEmpty ? nil : device
                }
                services.append(service)
                pending = nil
            } else if let header = serviceHeader(line) {
                if let pending { services.append(pending) }
                pending = header
            }
        }
        if let pending { services.append(pending) }
        return services
    }

    /// Parses "(1) Wi-Fi" or "(*) Bluetooth PAN".
    private static func serviceHeader(_ line: String) -> NetworkService? {
        guard line.hasPrefix("("), let close = line.firstIndex(of: ")") else { return nil }
        let tag = line[line.index(after: line.startIndex)..<close]
        let disabled = tag == "*"
        guard disabled || (!tag.isEmpty && tag.allSatisfy(\.isNumber)) else { return nil }
        var name = line[line.index(after: close)...].trimmingCharacters(in: .whitespaces)
        if name.hasPrefix("*") { name.removeFirst() }
        guard !name.isEmpty else { return nil }
        return NetworkService(name: name, device: nil, isEnabled: !disabled)
    }

    /// Whether IPv6 is configured on a service, from `networksetup -getinfo <service>`.
    /// "Automatic", "Manual" and "Link-local only" all count as enabled. Only "Off" is off.
    public static func ipv6Enabled(getInfo: String) -> Bool {
        for line in getInfo.split(separator: "\n") where line.hasPrefix("IPv6:") {
            return line.dropFirst("IPv6:".count).trimmingCharacters(in: .whitespaces).lowercased() != "off"
        }
        return true
    }

    /// Picks the service whose IPv6 setting the app should control.
    ///
    /// 1. The service that owns the default route's interface.
    /// 2. Otherwise the highest-priority enabled service whose device has an address. This
    ///    covers full-tunnel VPNs, where the default route goes through a `utun` interface.
    /// 3. Otherwise `previous`, if it still exists. Turning IPv6 off on a network with no
    ///    IPv4 leaves no addresses at all, and the user still needs a way to turn it back on.
    public static func primaryService(
        defaultInterface: String?,
        services: [NetworkService],
        devicesWithAddresses: Set<String>,
        previous: NetworkService? = nil
    ) -> NetworkService? {
        let enabled = services.filter(\.isEnabled)
        if let iface = defaultInterface, let match = enabled.first(where: { $0.device == iface }) {
            return match
        }
        if let active = enabled.first(where: { $0.device.map(devicesWithAddresses.contains) ?? false }) {
            return active
        }
        if let previous, enabled.contains(previous) {
            return previous
        }
        return nil
    }
}
