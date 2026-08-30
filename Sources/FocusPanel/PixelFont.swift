import SwiftUI
import AppKit

/// Loads the bundled "Press Start 2P" pixel font (OFL-licensed, bundled
/// locally — no network fetch) and exposes it as a SwiftUI `Font`.
enum PixelFont {
    private static var registered = false

    /// Registers the bundled .ttf with the system font manager. Safe to call
    /// more than once (e.g. from both `main.swift` and SwiftUI previews).
    /// Tries `Bundle.module` first (SwiftPM's generated resource bundle,
    /// used by `swift build`/`swift run`), then falls back to `Bundle.main`
    /// (the Xcode app target, where resources land directly in
    /// `Contents/Resources`) — this file builds and runs under both.
    static func registerIfNeeded() {
        guard !registered else { return }
        registered = true
        let url = resourceBundle.url(forResource: "PressStart2P-Regular", withExtension: "ttf")
            ?? Bundle.main.url(forResource: "PressStart2P-Regular", withExtension: "ttf")
        guard let url else {
            NSLog("FocusPanel: bundled pixel font not found — falling back to system font")
            return
        }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        // A "duplicate" registration error just means it's already loaded
        // (e.g. a previous launch this session) — not a real failure.
    }

    /// `Bundle.module` only exists when SwiftPM generates resource-bundling
    /// glue (i.e. building via `swift build`). Under the Xcode target that
    /// symbol isn't generated, so we guard the reference behind a
    /// compile-time check and fall back to `Bundle.main` above.
    private static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }

    static func font(size: CGFloat) -> Font {
        .custom("Press Start 2P", size: size)
    }
}
