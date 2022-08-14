import Darwin
import Foundation

/// Looks up the public address the internet sees, separately over IPv4 and IPv6.
///
/// The endpoints are ipify's single-stack hosts: `api4` only has an A record and `api6`
/// only has an AAAA record, so each request can only succeed over its own IP version.
public enum PublicIP {
    public static let ipv4Endpoint = URL(string: "https://api4.ipify.org")!
    public static let ipv6Endpoint = URL(string: "https://api6.ipify.org")!

    public static func ipv4(timeout: TimeInterval = 4) async -> String? {
        await fetch(ipv4Endpoint, family: AF_INET, timeout: timeout)
    }

    public static func ipv6(timeout: TimeInterval = 4) async -> String? {
        await fetch(ipv6Endpoint, family: AF_INET6, timeout: timeout)
    }

    static func fetch(_ url: URL, family: Int32, timeout: TimeInterval) async -> String? {
        let config = URLSessionConfiguration.ephemeral
        // Go direct, not through the system proxy, so the result reflects this Mac's own
        // connectivity rather than the proxy's.
        config.connectionProxyDictionary = [:]
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        // A new session per lookup, so a connection opened before IPv6 was toggled is never reused.
        let session = URLSession(configuration: config)
        defer { session.finishTasksAndInvalidate() }

        guard let (data, response) = try? await session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let body = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return IPAddress.isValid(body, family: family) ? body : nil
    }
}
