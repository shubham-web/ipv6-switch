import Foundation

public enum Connectivity: Equatable, Sendable {
    case dualStack, ipv4Only, ipv6Only, offline

    public init(hasIPv4: Bool, hasIPv6: Bool) {
        switch (hasIPv4, hasIPv6) {
        case (true, true): self = .dualStack
        case (true, false): self = .ipv4Only
        case (false, true): self = .ipv6Only
        case (false, false): self = .offline
        }
    }

    public var title: String {
        switch self {
        case .dualStack: "Dual-stack (IPv4 + IPv6)"
        case .ipv4Only: "IPv4 only"
        case .ipv6Only: "IPv6 only"
        case .offline: "No connectivity"
        }
    }

    /// Short label for the Dock icon badge.
    public var badge: String {
        switch self {
        case .dualStack: "v4+v6"
        case .ipv4Only: "v4"
        case .ipv6Only: "v6"
        case .offline: "off"
        }
    }
}

/// Everything the app shows, captured at one point in time.
public struct NetworkSnapshot: Equatable, Sendable {
    /// Interface of the default route, e.g. `en0`, or `utun3` on a full-tunnel VPN.
    public var defaultInterface: String?
    /// The service the IPv6 switch controls.
    public var service: NetworkService?
    public var localIPv4: String?
    public var localIPv6: String?
    public var publicIPv4: String?
    public var publicIPv6: String?
    public var ipv6Enabled: Bool

    public init(defaultInterface: String? = nil, service: NetworkService? = nil,
                localIPv4: String? = nil, localIPv6: String? = nil,
                publicIPv4: String? = nil, publicIPv6: String? = nil,
                ipv6Enabled: Bool = true) {
        self.defaultInterface = defaultInterface
        self.service = service
        self.localIPv4 = localIPv4
        self.localIPv6 = localIPv6
        self.publicIPv4 = publicIPv4
        self.publicIPv6 = publicIPv6
        self.ipv6Enabled = ipv6Enabled
    }

    public var connectivity: Connectivity {
        Connectivity(hasIPv4: publicIPv4 != nil || localIPv4 != nil,
                     hasIPv6: publicIPv6 != nil || localIPv6 != nil)
    }

    /// Reads the current state from the system. Runs `route` and `networksetup` and makes
    /// two HTTPS requests, so call it off the main actor.
    public static func capture(previousService: NetworkService? = nil) async -> NetworkSnapshot {
        async let publicV4 = PublicIP.ipv4()
        async let publicV6 = PublicIP.ipv6()

        let iface = Parse.defaultInterface(routeOutput: Shell.run("/sbin/route", ["-n", "get", "default"]).output)
        let services = Parse.networkServices(
            serviceOrder: Shell.run("/usr/sbin/networksetup", ["-listnetworkserviceorder"]).output)
        let addresses = IPAddress.byInterface()
        let service = Parse.primaryService(
            defaultInterface: iface,
            services: services,
            devicesWithAddresses: Set(addresses.filter { !$0.value.isEmpty }.keys),
            previous: previousService)

        var ipv6Enabled = true
        if let service {
            ipv6Enabled = Parse.ipv6Enabled(
                getInfo: Shell.run("/usr/sbin/networksetup", ["-getinfo", service.name]).output)
        }
        let local = (service?.device ?? iface).flatMap { addresses[$0] }

        return NetworkSnapshot(
            defaultInterface: iface,
            service: service,
            localIPv4: local?.ipv4.first,
            localIPv6: local?.ipv6.first,
            publicIPv4: await publicV4,
            publicIPv6: await publicV6,
            ipv6Enabled: ipv6Enabled)
    }
}
