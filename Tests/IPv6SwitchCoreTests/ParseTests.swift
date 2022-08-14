import Testing
@testable import IPv6SwitchCore

@Suite struct DefaultInterfaceTests {
    @Test func parsesRouteOutput() {
        let output = """
               route to: default
            destination: default
                   mask: default
                gateway: 192.168.1.1
              interface: en0
                  flags: <UP,GATEWAY,DONE,STATIC,PRCLONING,GLOBAL>
             recvpipe  sendpipe  ssthresh  rtt,msec    rttvar  hopcount      mtu     expire
                   0         0         0         0         0         0      1500         0
            """
        #expect(Parse.defaultInterface(routeOutput: output) == "en0")
    }

    @Test func parsesVPNInterface() {
        #expect(Parse.defaultInterface(routeOutput: "  interface: utun4\n") == "utun4")
    }

    @Test func returnsNilWithoutDefaultRoute() {
        #expect(Parse.defaultInterface(routeOutput: "route: writing to routing socket: not in table") == nil)
        #expect(Parse.defaultInterface(routeOutput: "") == nil)
    }
}

@Suite struct NetworkServicesTests {
    @Test func parsesServiceOrder() {
        let output = """
            An asterisk (*) denotes that a network service is disabled.
            (1) USB 10/100/1000 LAN
            (Hardware Port: USB 10/100/1000 LAN, Device: en7)

            (2) Thunderbolt Bridge
            (Hardware Port: Thunderbolt Bridge, Device: bridge0)

            (3) Wi-Fi
            (Hardware Port: Wi-Fi, Device: en0)

            """
        #expect(Parse.networkServices(serviceOrder: output) == [
            NetworkService(name: "USB 10/100/1000 LAN", device: "en7"),
            NetworkService(name: "Thunderbolt Bridge", device: "bridge0"),
            NetworkService(name: "Wi-Fi", device: "en0"),
        ])
    }

    @Test func handlesDisabledVPNAndRenamedServices() {
        let output = """
            An asterisk (*) denotes that a network service is disabled.
            (1) Office Wi-Fi (renamed)
            (Hardware Port: Wi-Fi, Device: en0)

            (*) Bluetooth PAN
            (Hardware Port: Bluetooth PAN, Device: en5)

            (2) Corp VPN
            (Hardware Port: com.example.vpn, Device: )

            (3) Alex's iPhone
            (Hardware Port: iPhone USB, Device: en8)
            """
        #expect(Parse.networkServices(serviceOrder: output) == [
            NetworkService(name: "Office Wi-Fi (renamed)", device: "en0"),
            NetworkService(name: "Bluetooth PAN", device: "en5", isEnabled: false),
            NetworkService(name: "Corp VPN", device: nil),
            NetworkService(name: "Alex's iPhone", device: "en8"),
        ])
    }

    @Test func ignoresHeaderLine() {
        #expect(Parse.networkServices(serviceOrder: "An asterisk (*) denotes that a network service is disabled.").isEmpty)
    }
}

@Suite struct IPv6EnabledTests {
    @Test(arguments: [
        ("IPv6: Automatic", true),
        ("IPv6: Manual", true),
        ("IPv6: Link-local only", true),
        ("IPv6: Off", false),
    ])
    func readsIPv6Mode(line: String, expected: Bool) {
        let info = """
            DHCP Configuration
            IP address: 192.168.1.20
            Subnet mask: 255.255.255.0
            Router: 192.168.1.1
            Client ID:
            \(line)
            IPv6 IP address: none
            IPv6 Router: none
            """
        #expect(Parse.ipv6Enabled(getInfo: info) == expected)
    }

    @Test func doesNotConfuseAddressLineWithModeLine() {
        #expect(Parse.ipv6Enabled(getInfo: "IPv6 IP address: Off\nIPv6: Automatic") == true)
    }

    @Test func defaultsToEnabledWhenUnknown() {
        #expect(Parse.ipv6Enabled(getInfo: "") == true)
    }
}

@Suite struct PrimaryServiceTests {
    let lan = NetworkService(name: "USB LAN", device: "en7")
    let bridge = NetworkService(name: "Thunderbolt Bridge", device: "bridge0")
    let wifi = NetworkService(name: "Wi-Fi", device: "en0")
    let vpn = NetworkService(name: "Corp VPN", device: nil)
    var services: [NetworkService] { [lan, bridge, vpn, wifi] }

    @Test func prefersDefaultRouteInterface() {
        let s = Parse.primaryService(defaultInterface: "en0", services: services, devicesWithAddresses: ["en0", "en7"])
        #expect(s == wifi)
    }

    @Test func fallsBackToFirstServiceWithAddressOnVPN() {
        let s = Parse.primaryService(defaultInterface: "utun3", services: services, devicesWithAddresses: ["en0", "utun3"])
        #expect(s == wifi)
    }

    @Test func skipsDisabledServices() {
        let disabledWifi = NetworkService(name: "Wi-Fi", device: "en0", isEnabled: false)
        let s = Parse.primaryService(defaultInterface: "en0", services: [disabledWifi], devicesWithAddresses: ["en0"])
        #expect(s == nil)
    }

    @Test func keepsPreviousServiceWhenNothingHasAnAddress() {
        // IPv6 was just turned off on a network with no IPv4: the user must still be able to turn it back on.
        let s = Parse.primaryService(defaultInterface: nil, services: services, devicesWithAddresses: [], previous: wifi)
        #expect(s == wifi)
    }

    @Test func dropsPreviousServiceThatNoLongerExists() {
        let s = Parse.primaryService(defaultInterface: nil, services: [lan], devicesWithAddresses: [], previous: wifi)
        #expect(s == nil)
    }
}
