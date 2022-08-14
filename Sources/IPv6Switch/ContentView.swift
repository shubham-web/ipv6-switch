import IPv6SwitchCore
import SwiftUI

struct Row: View {
    let label: String, value: String?
    var body: some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary).frame(width: 78, alignment: .leading)
            Text(value ?? "none").textSelection(.enabled)
                .foregroundStyle(value == nil ? .tertiary : .primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }.font(.system(size: 12, design: .monospaced))
    }
}

struct ContentView: View {
    @ObservedObject var m: Model

    private var subtitle: String {
        guard let s = m.snapshot else { return " " }
        guard let service = s.service else { return "No network service (\(s.defaultInterface ?? "no default route"))" }
        var text = "\(service.name) (\(service.device ?? "?"))"
        if let iface = s.defaultInterface, iface != service.device {
            text += " · default route via \(iface)"
        }
        return text
    }

    var body: some View {
        let s = m.snapshot
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(s?.connectivity.title ?? "Checking…").font(.headline)
                Spacer()
                if m.busy { ProgressView().controlSize(.small) }
            }
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            Divider()
            Row(label: "Local v4", value: s?.localIPv4)
            Row(label: "Local v6", value: s?.localIPv6)
            Row(label: "Public v4", value: s?.publicIPv4)
            Row(label: "Public v6", value: s?.publicIPv6)
            Divider()
            Toggle("IPv6 enabled", isOn: Binding(get: { s?.ipv6Enabled ?? true }, set: { m.setIPv6($0) }))
                .toggleStyle(.switch).disabled(m.busy || s?.service == nil)
            if let e = m.error { Text(e).font(.caption).foregroundStyle(.red).textSelection(.enabled) }
            HStack {
                Button("Refresh") { m.refresh() }.disabled(m.busy)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(14).frame(width: 330)
        .onAppear { m.refresh() }
    }
}
