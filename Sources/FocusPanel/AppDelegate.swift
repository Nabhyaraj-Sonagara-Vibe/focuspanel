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

        // Chromeless title bar so our pixel-console chrome reaches the top.
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        // BUG FIX: whole-window background dragging was stealing clicks from
        // SwiftUI buttons. AppKit's `isMovableByWindowBackground` drags the
        // window on *any* mouseDown that a hit-tested view doesn't explicitly
        // claim, and with `isOpaque = false` that included the todo rows'
        // translucent backgrounds and icon-only toggle/delete buttons — a
        // quick tap could register as a sub-pixel drag instead of a click,
        // making the whole Tasks pane feel unresponsive. We now drag only via
        // an explicit handle (the title bar), so every button in the content
        // area reliably receives its click.
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = NSColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0)
        panel.isOpaque = true

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
