import AppKit
import SwiftUI

private let chipHeatLabDelegate = ChipHeatLabDelegate()

@main
struct ChipHeatLabMain {
    static func main() {
        let app = NSApplication.shared
        app.delegate = chipHeatLabDelegate
        app.setActivationPolicy(.regular)
        app.finishLaunching()
        app.run()
    }
}

final class ChipHeatLabDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let rootView = ContentView()
            .frame(minWidth: 1280, minHeight: 760)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1360, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Chip Heat Lab"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: rootView)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
