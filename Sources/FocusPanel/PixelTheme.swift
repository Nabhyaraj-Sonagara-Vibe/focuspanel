import SwiftUI
import FocusPanelCore

/// A complete pixel-art palette for the app. Every colour the UI needs is
/// expressed here so a theme swap restyles the whole panel — console casing,
/// circuit-board "screen", outlines, and the three session accents — without
/// any view hard-coding a colour.
struct PixelTheme: Identifiable, Equatable {
    let id: String
    let name: String

    // Console casing (window chrome / title bar).
    let caseColor: Color
    let caseLight: Color
    let caseDark: Color

    // The "screen" the content sits on.
    let screen: Color
    let screenLight: Color
    let screenDark: Color

    // Shared ink + a light "paper" fill for input fields / inactive tabs.
    let ink: Color
    let paper: Color

    // Per-session accents (flat pixel-art primaries).
    let workAccent: Color
    let shortBreakAccent: Color
    let longBreakAccent: Color

    func accent(for session: SessionType) -> Color {
        switch session {
        case .work: return workAccent
        case .shortBreak: return shortBreakAccent
        case .longBreak: return longBreakAccent
        }
    }
}

/// The built-in theme catalog. `themeID` in `PomodoroSettings` indexes into
/// this; unknown ids fall back to the default (Channel F).
enum ThemeCatalog {
    static let all: [PixelTheme] = [channelF, gameBoy, synthwave, arcade]

    /// Resolve a stored id to a concrete theme, defaulting safely.
    static func theme(id: String) -> PixelTheme {
        all.first { $0.id == id } ?? channelF
    }

    static var `default`: PixelTheme { channelF }

    // MARK: - Channel F (the original Jerry Lawson Doodle look)

    static let channelF = PixelTheme(
        id: "channelF",
        name: "Channel F",
        caseColor: Color(hex: 0xC77B3D),
        caseLight: Color(hex: 0xE6A868),
        caseDark: Color(hex: 0x7A431E),
        screen: Color(hex: 0x1B7A34),
        screenLight: Color(hex: 0x2FA84C),
        screenDark: Color(hex: 0x0E4A20),
        ink: Color(hex: 0x151109),
        paper: Color(hex: 0xF5E6C8),
        workAccent: Color(hex: 0xEA4335),      // cartridge red
        shortBreakAccent: Color(hex: 0x34A853), // circuit green
        longBreakAccent: Color(hex: 0x4285F4)   // console blue
    )

    // MARK: - Game Boy (4-tone DMG green)

    static let gameBoy = PixelTheme(
        id: "gameBoy",
        name: "Game Boy",
        caseColor: Color(hex: 0x8B8B7A),
        caseLight: Color(hex: 0xB8B8A0),
        caseDark: Color(hex: 0x5A5A4A),
        screen: Color(hex: 0x8BAC0F),
        screenLight: Color(hex: 0x9BBC0F),
        screenDark: Color(hex: 0x306230),
        ink: Color(hex: 0x0F380F),
        paper: Color(hex: 0xCADC9F),
        workAccent: Color(hex: 0x306230),      // deep DMG green
        shortBreakAccent: Color(hex: 0x8BAC0F), // mid green
        longBreakAccent: Color(hex: 0x0F380F)   // darkest green
    )

    // MARK: - Synthwave (neon on deep purple)

    static let synthwave = PixelTheme(
        id: "synthwave",
        name: "Synthwave",
        caseColor: Color(hex: 0x2B1055),
        caseLight: Color(hex: 0x4A1F8A),
        caseDark: Color(hex: 0x150829),
        screen: Color(hex: 0x1A0B2E),
        screenLight: Color(hex: 0x3A1E5C),
        screenDark: Color(hex: 0x0D0518),
        ink: Color(hex: 0x0A0414),
        paper: Color(hex: 0xF5D5F0),
        workAccent: Color(hex: 0xFF2A6D),      // hot pink
        shortBreakAccent: Color(hex: 0x05D9E8), // cyan
        longBreakAccent: Color(hex: 0xD100FF)   // magenta-violet
    )

    // MARK: - Arcade (bright cabinet primaries on black)

    static let arcade = PixelTheme(
        id: "arcade",
        name: "Arcade",
        caseColor: Color(hex: 0x1A1A1A),
        caseLight: Color(hex: 0x3A3A3A),
        caseDark: Color(hex: 0x000000),
        screen: Color(hex: 0x101018),
        screenLight: Color(hex: 0x24243A),
        screenDark: Color(hex: 0x000000),
        ink: Color(hex: 0x000000),
        paper: Color(hex: 0xFFF4C2),
        workAccent: Color(hex: 0xFFD400),      // coin yellow
        shortBreakAccent: Color(hex: 0x00E676), // pac green
        longBreakAccent: Color(hex: 0xFF4081)   // cabinet pink
    )
}

// MARK: - Environment plumbing

private struct PixelThemeKey: EnvironmentKey {
    static let defaultValue: PixelTheme = ThemeCatalog.default
}

extension EnvironmentValues {
    /// The active pixel theme, injected at the root and read by every view.
    var pixelTheme: PixelTheme {
        get { self[PixelThemeKey.self] }
        set { self[PixelThemeKey.self] = newValue }
    }
}
