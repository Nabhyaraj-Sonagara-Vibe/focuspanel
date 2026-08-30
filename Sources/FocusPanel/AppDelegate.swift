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
            //
            // BUG FIX: `.closable` is intentionally OMITTED. With
            // titlebarAppearsTransparent + titleVisibility = .hidden, the
            // title *text* disappears but AppKit still places a real,
            // clickable native close (red traffic-light) button in the
            // top-left corner — it just becomes visually blended into our
            // custom title bar chrome (the drag handle + decorative
            // "cartridge ridges" live in exactly that corner). A click
            // anywhere near there could land on the *real* close button
            // instead of our SwiftUI content, closing the panel — and since
            // it's the app's only window, applicationShouldTerminateAfter-
            // LastWindowClosed then quit the entire app. That was the
            // "closes a lot unexpectedly" bug. This widget is only meant to
            // end via a deliberate Quit (⌘Q / menu), never via an incidental
            // click, so there is no close button at all now.
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
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

        // Keep it small: no fullscreen/zoom, tight footprint. No close button
        // exists (styleMask omits .closable, see above) — belt-and-braces,
        // also explicitly hide/disable any standard buttons AppKit might
        // still surface so there is no accidental way to dismiss the panel
        // other than quitting the app.
        panel.styleMask.remove(.resizable)   // fixed, widget-like footprint
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
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

    /// BUG FIX (the actual "closes a lot unexpectedly" / "quits when adding
    /// tasks or saving settings" root cause): this delegate method fires
    /// whenever AppKit's count of open windows drops to zero — and that
    /// count includes transient windows, not just our main panel. The
    /// Settings popover (SwiftUI's `.popover`) is implemented as its own
    /// short-lived window; opening or dismissing it (e.g. by tapping Save,
    /// which calls `dismiss()`) could transiently bring the *counted* window
    /// total to zero, since our main window is a special non-activating
    /// `NSPanel` that AppKit doesn't always count the same way a regular
    /// window is counted. Returning `true` here treated that transient dip
    /// as "the user closed everything" and quit the whole app — which is
    /// exactly what was happening on every task add / settings save, not
    /// just on an explicit close.
    ///
    /// This widget's main panel has no close button at all (see above) and
    /// is the only *intended* persistent window, so we simply never quit
    /// from a window-count heuristic. The single, deliberate way to quit is
    /// the Quit menu item / ⌘Q, which calls `NSApplication.terminate(_:)`
    /// directly and does not go through this method at all.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
