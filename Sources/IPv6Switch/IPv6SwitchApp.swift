import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }

    #if DEBUG
    func applicationDidFinishLaunching(_ notification: Notification) { Demo.prepareApp() }
    #endif
}

@main
struct IPv6SwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = Model()
    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some Scene {
        Window("IPv6 Switch", id: "main") {
            ContentView(m: model)
                .onReceive(timer) { _ in if !model.busy { model.refresh() } }
        }
        .windowResizability(.contentSize)
    }
}
