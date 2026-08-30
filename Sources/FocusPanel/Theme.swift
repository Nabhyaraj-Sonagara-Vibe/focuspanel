import SwiftUI
import FocusPanelCore

/// Retro pixel-console palette, directly inspired by Google's "Jerry Lawson"
/// Doodle (celebrating the Fairchild Channel F, the first cartridge-based
/// home console): a circuit-board green "screen", a wood/amber console
/// casing, thick black pixel outlines, and flat, primary-color accent
/// buttons rather than smooth gradients — pixel art avoids anti-aliased
/// blends in favor of hard edges and light/dark bevels.
enum Theme {

    // MARK: - Session accent (flat pixel-art primaries + their bevel tones)

    static func accent(for session: SessionType) -> Color {
        switch session {
        case .work: return Color(hex: 0xEA4335)        // cartridge red
        case .shortBreak: return Color(hex: 0x34A853)  // circuit green
        case .longBreak: return Color(hex: 0x4285F4)   // console blue
        }
    }

    static func accentLight(for session: SessionType) -> Color {
        switch session {
        case .work: return Color(hex: 0xFF7A6B)
        case .shortBreak: return Color(hex: 0x6FE39A)
        case .longBreak: return Color(hex: 0x83B4FF)
        }
    }

    static func accentDark(for session: SessionType) -> Color {
        switch session {
        case .work: return Color(hex: 0x9A241A)
        case .shortBreak: return Color(hex: 0x1E7A38)
        case .longBreak: return Color(hex: 0x1F4FA8)
        }
    }

    static func symbol(for session: SessionType) -> String {
        switch session {
        case .work: return "bolt.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }

    // MARK: - Console chrome

    /// Wood/amber cartridge-console casing.
    static let caseAmber = Color(hex: 0xC77B3D)
    static let caseAmberLight = Color(hex: 0xE6A868)
    static let caseAmberDark = Color(hex: 0x7A431E)

    /// Circuit-board green screen the timer/tasks sit on.
    static let screenGreen = Color(hex: 0x1B7A34)
    static let screenGreenLight = Color(hex: 0x2FA84C)
    static let screenGreenDark = Color(hex: 0x0E4A20)

    static let pixelBlack = Color(hex: 0x151109)
    static let cream = Color(hex: 0xF5E6C8)
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
