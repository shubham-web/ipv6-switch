import Darwin
import Testing
@testable import IPv6SwitchCore

@Suite struct IPAddressTests {
    @Test func validatesByFamily() {
        #expect(IPAddress.isValid("203.0.113.7", family: AF_INET))
        #expect(IPAddress.isValid("2001:db8::1", family: AF_INET6))
        #expect(!IPAddress.isValid("2001:db8::1", family: AF_INET))
        #expect(!IPAddress.isValid("203.0.113.7", family: AF_INET6))
        #expect(!IPAddress.isValid("<html>captive portal</html>", family: AF_INET))
        #expect(!IPAddress.isValid("", family: AF_INET6))
    }

    @Test func detectsLinkLocal() {
        #expect(IPAddress.isLinkLocal("169.254.10.20"))
        #expect(IPAddress.isLinkLocal("fe80::1%en0"))
        #expect(IPAddress.isLinkLocal("FEBF::1"))
        #expect(!IPAddress.isLinkLocal("192.168.1.20"))
        #expect(!IPAddress.isLinkLocal("2001:db8::1"))
        #expect(!IPAddress.isLinkLocal("fd12:3456::1"))
    }
}

@Suite struct ConnectivityTests {
    @Test func derivesFromAddresses() {
        #expect(NetworkSnapshot(localIPv4: "10.0.0.2", publicIPv6: "2001:db8::1").connectivity == .dualStack)
        #expect(NetworkSnapshot(publicIPv4: "203.0.113.7").connectivity == .ipv4Only)
        #expect(NetworkSnapshot(localIPv6: "2001:db8::2").connectivity == .ipv6Only)
        #expect(NetworkSnapshot().connectivity == .offline)
    }

    @Test func badges() {
        #expect(Connectivity.dualStack.badge == "v4+v6")
        #expect(Connectivity.offline.badge == "off")
    }
}

@Suite struct IPv6ControlTests {
    @Test func usesAutomaticForOn() {
        #expect(IPv6Control.flag(enabled: true) == "-setv6automatic")
        #expect(IPv6Control.flag(enabled: false) == "-setv6off")
    }

    @Test func passesServiceNameAsArgumentNotInScript() {
        let hostile = "Bob's \"Wi-Fi\" $(rm -rf ~)"
        let args = IPv6Control.adminArguments(enabled: false, service: hostile)
        #expect(args.last == hostile)
        #expect(args[args.count - 2] == "--")
        let script = args.dropLast(2).joined(separator: "\n")
        #expect(!script.contains(hostile))
        #expect(script.contains("quoted form of (item 1 of argv)"))
        #expect(script.contains("/usr/sbin/networksetup -setv6off "))
    }

    @Test func mapsAdminPromptResults() {
        #expect(IPv6Control.outcome(of: CommandResult(output: "", status: 0)) == .success)
        #expect(IPv6Control.outcome(of: CommandResult(output: "0:150: execution error: User canceled. (-128)", status: 1)) == .cancelled)
        #expect(IPv6Control.outcome(of: CommandResult(output: "boom", status: 1)) == .failed("boom"))
    }
}
