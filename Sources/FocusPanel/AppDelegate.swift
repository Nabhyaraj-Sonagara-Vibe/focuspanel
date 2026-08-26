import AppKit
import SwiftUI
import FocusPanelCore

/// Application delegate that builds the compact, always-on-top floating panel.
///
/// We bootstrap AppKit directly (rather than the SwiftUI `App`/`WindowGroup`
/// lifecycle) because the key UX requirement — a small, non-fullscreen window
/// pinned above other apps at `NSWindow.level = .floating` — needs direct
/// control over the `NSWindow`. The window hosts the SwiftUI `ContentView`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let state = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let rootView = ContentView().environmentObject(state)
        let hosting = NSHostingView(rootView: rootView)

        // Compact footprint: a slim panel, taller than it is wide, that tucks
        // into a screen corner. Non-zoomable, only lightly resizable.
        let initialSize = NSSize(width: 300, height: 480)
        let panel = NSWindow(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false)

        panel.contentView = hosting
        panel.title = "FocusPanel"

        // Chromeless, translucent title bar so our gradient reaches the top.
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0)
        panel.isOpaque = false

        // THE key requirement: float above other apps while the user works.
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        // Keep it small: no fullscreen/zoom, tight min/max size.
        panel.styleMask.remove(.resizable)   // fixed, widget-like footprint
        panel.standardWindowButton(.zoomButton)?.isEnabled = false
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true

        // Park it in the top-right corner of the main screen.
        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            let x = vf.maxX - initialSize.width - 24
            let y = vf.maxY - initialSize.height - 24
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            panel.center()
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = panel
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
