import SwiftUI
import FocusPanelCore

/// Static, theme-independent constants and the hex `Color` helper.
///
/// The actual palette (console casing, screen, per-session accents) now lives
/// in `PixelTheme` / `ThemeCatalog` and is injected through the environment so
/// it can be swapped at runtime. Only genuinely theme-agnostic pieces remain
/// here.
enum Theme {
    /// Session icon — the same glyph regardless of theme.
    static func symbol(for session: SessionType) -> String {
        switch session {
        case .work: return "bolt.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }

    /// A near-black used for pixel outlines across every theme (each theme also
    /// carries its own `ink`, but outline strokes use this shared value for a
    /// consistent hard-edged look).
    static let pixelBlack = Color(hex: 0x151109)
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha)
    }
}
