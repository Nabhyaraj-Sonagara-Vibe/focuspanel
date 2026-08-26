import AppKit

// Manual AppKit bootstrap so the app builds and runs as a SwiftPM executable
// (`swift build` / `swift run`) with no Xcode project. This is the equivalent
// of `@NSApplicationMain`, spelled out so it works from an `@main`-less
// top-level file in an executable target.
//
// Top-level code in `main.swift` is nonisolated under Swift 6, but it runs on
// the main thread at process start, so we assume main-actor isolation to touch
// the main-actor-isolated AppKit APIs and our AppDelegate.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate

    // `.regular` shows a Dock icon and standard menu; the floating window still
    // stays above other apps because of its window level.
    app.setActivationPolicy(.regular)

    // Minimal main menu so ⌘Q / ⌘W / ⌘H behave natively.
    let mainMenu = NSMenu()
    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)
    let appMenu = NSMenu()
    appMenu.addItem(withTitle: "Hide FocusPanel", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(withTitle: "Quit FocusPanel", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    appMenuItem.submenu = appMenu
    app.mainMenu = mainMenu

    app.run()
}
