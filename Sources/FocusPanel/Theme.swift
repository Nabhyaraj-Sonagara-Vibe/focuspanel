import SwiftUI
import FocusPanelCore

/// Colourful, session-aware palette. Work is energetic; breaks are calm.
enum Theme {
    /// Gradient used for the timer card / progress ring per session type.
    static func gradient(for session: SessionType) -> LinearGradient {
        LinearGradient(colors: colors(for: session),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }

    static func colors(for session: SessionType) -> [Color] {
        switch session {
        case .work:
            // Energetic sunset: coral -> pink -> magenta
            return [Color(hex: 0xFF6B6B), Color(hex: 0xFF3D7F), Color(hex: 0xC724B1)]
        case .shortBreak:
            // Calm mint: teal -> green
            return [Color(hex: 0x2AF598), Color(hex: 0x08AEEA)]
        case .longBreak:
            // Cool focus recovery: indigo -> violet
            return [Color(hex: 0x667EEA), Color(hex: 0x764BA2), Color(hex: 0x6B2FB3)]
        }
    }

    /// The single accent colour for a session (used for tints and icons).
    static func accent(for session: SessionType) -> Color {
        colors(for: session).first ?? .accentColor
    }

    static func symbol(for session: SessionType) -> String {
        switch session {
        case .work: return "bolt.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }

    /// Soft app background.
    static let windowBackground = LinearGradient(
        colors: [Color(hex: 0x1A1A2E), Color(hex: 0x16213E)],
        startPoint: .top, endPoint: .bottom)
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
