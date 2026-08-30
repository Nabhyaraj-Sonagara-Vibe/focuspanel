import AppKit
import SwiftUI
import FocusPanelCore

/// Application delegate that builds the compact, always-on-top floating panel.
///
/// We bootstrap AppKit directly (rather than the SwiftUI `App`/`WindowGroup`
/// lifecycle) because the key UX requirement — a small, non-fullscreen window
/// pinned above other apps — needs direct control over the window object.
///
/// The window is an `NSPanel` (not a plain `NSWindow`): a non-activating,
/// floating utility panel is the correct AppKit primitive for a widget that
/// must stay visible *while the user works in another app*. A regular
/// `NSWindow` at `.floating` level gets tucked away by macOS window
/// management (Stage Manager, Space switching, app hide-on-deactivate) once
/// another app becomes active — which is exactly the "it doesn't stay open
/// while I use another app" symptom. A non-activating panel with
/// `hidesOnDeactivate = false` and `.canJoinAllSpaces` collection behaviour
/// stays put across all of those.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSPanel!
    private let state = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let rootView = ContentView().environmentObject(state)
        let hosting = NSHostingView(rootView: rootView)

        // Compact footprint: a slim panel, taller than it is wide, that tucks
        // into a screen corner.
        let initialSize = NSSize(width: 300, height: 480)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: initialSize),
            // `.nonactivatingPanel` is the crucial bit: clicking the panel (or
            // having it visible) doesn't yank activation away from the app the
            // user is actually working in, and the panel stays on screen while
            // that other app is frontmost.
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false)

        panel.contentView = hosting
        panel.title = "FocusPanel"

        // Behave like a floating HUD/utility panel that never hides when the
        // app is not frontmost.
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true   // only take key focus for text entry (the task field)

        // Chromeless title bar so our pixel-console chrome reaches the top.
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        // Dragging is scoped to an explicit title-bar handle (see
        // ContentView.WindowDragHandle) rather than the whole background, so
        // buttons everywhere else reliably receive their clicks.
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = NSColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0)
        panel.isOpaque = true

        // THE key requirement: float above other apps, on every Space, and
        // over full-screen apps — while the user works elsewhere.
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false

        // Keep it small: no fullscreen/zoom, tight footprint.
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

        // Order it front once at launch. A non-activating panel does not need
        // (and shouldn't force) full app activation to remain visible.
        panel.orderFrontRegardless()
        self.window = panel
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
