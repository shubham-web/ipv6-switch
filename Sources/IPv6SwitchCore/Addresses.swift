import Darwin

/// Addresses assigned to one interface, in the order the system lists them.
public struct InterfaceAddresses: Equatable, Sendable {
    public var ipv4: [String] = []
    public var ipv6: [String] = []

    public init(ipv4: [String] = [], ipv6: [String] = []) {
        self.ipv4 = ipv4
        self.ipv6 = ipv6
    }

    public var isEmpty: Bool { ipv4.isEmpty && ipv6.isEmpty }
}

public enum IPAddress {
    /// Whether `string` is a valid numeric address of the given family (`AF_INET` or `AF_INET6`).
    public static func isValid(_ string: String, family: Int32) -> Bool {
        var buffer = [UInt8](repeating: 0, count: 16)
        return string.withCString { inet_pton(family, $0, &buffer) } == 1
    }

    /// Link-local addresses (`169.254.0.0/16`, `fe80::/10`) only work on the local link,
    /// so they don't count as connectivity.
    public static func isLinkLocal(_ address: String) -> Bool {
        let a = address.lowercased()
        return a.hasPrefix("169.254.") || a.hasPrefix("fe8") || a.hasPrefix("fe9")
            || a.hasPrefix("fea") || a.hasPrefix("feb")
    }

    /// Non-link-local addresses on every interface, keyed by interface name.
    public static func byInterface() -> [String: InterfaceAddresses] {
        var result: [String: InterfaceAddresses] = [:]
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else { return result }
        defer { freeifaddrs(ifap) }
        for p in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let a = p.pointee
            guard let sa = a.ifa_addr else { continue }
            let family = Int32(sa.pointee.sa_family)
            guard family == AF_INET || family == AF_INET6 else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count),
                              nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let address = host.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
            guard !isLinkLocal(address) else { continue }
            let name = String(cString: a.ifa_name)
            if family == AF_INET { result[name, default: .init()].ipv4.append(address) }
            else { result[name, default: .init()].ipv6.append(address) }
        }
        return result
    }
}
