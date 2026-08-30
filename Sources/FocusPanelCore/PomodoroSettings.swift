import Foundation

/// User-configurable durations and cycle behaviour. Persisted as JSON.
public struct PomodoroSettings: Codable, Equatable, Sendable {
    public var workMinutes: Int
    public var shortBreakMinutes: Int
    public var longBreakMinutes: Int
    /// Number of focus sessions completed before a long break is scheduled.
    public var longBreakInterval: Int
    /// Automatically start the next session when one ends.
    public var autoStartNext: Bool
    /// Play a chime when a session ends.
    public var playSound: Bool
    /// Identifier of the selected visual theme (see `PixelTheme` in the app
    /// layer). Stored as a plain string in the core so the pure logic module
    /// has no UI/SwiftUI dependency; the app maps it to a concrete palette.
    public var themeID: String

    public static let minMinutes = 1
    public static let maxMinutes = 180
    public static let minInterval = 2
    public static let maxInterval = 12

    /// Default theme identifier. Kept in the core so both layers agree on the
    /// fallback without the core needing to know the theme's colours.
    public static let defaultThemeID = "channelF"

    public init(workMinutes: Int = 25,
                shortBreakMinutes: Int = 5,
                longBreakMinutes: Int = 15,
                longBreakInterval: Int = 4,
                autoStartNext: Bool = true,
                playSound: Bool = true,
                themeID: String = PomodoroSettings.defaultThemeID) {
        self.workMinutes = workMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.longBreakInterval = longBreakInterval
        self.autoStartNext = autoStartNext
        self.playSound = playSound
        self.themeID = themeID
    }

    // MARK: - Codable (backward compatible)

    private enum CodingKeys: String, CodingKey {
        case workMinutes, shortBreakMinutes, longBreakMinutes
        case longBreakInterval, autoStartNext, playSound, themeID
    }

    /// Custom decoder so settings JSON written by an OLDER build (which had no
    /// `themeID` field) still decodes cleanly, falling back to the default
    /// theme instead of failing the whole decode and wiping the user's saved
    /// durations. New optional fields must always degrade gracefully like this.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.workMinutes = try c.decode(Int.self, forKey: .workMinutes)
        self.shortBreakMinutes = try c.decode(Int.self, forKey: .shortBreakMinutes)
        self.longBreakMinutes = try c.decode(Int.self, forKey: .longBreakMinutes)
        self.longBreakInterval = try c.decode(Int.self, forKey: .longBreakInterval)
        self.autoStartNext = try c.decode(Bool.self, forKey: .autoStartNext)
        self.playSound = try c.decode(Bool.self, forKey: .playSound)
        self.themeID = try c.decodeIfPresent(String.self, forKey: .themeID)
            ?? PomodoroSettings.defaultThemeID
    }

    public static let `default` = PomodoroSettings()

    /// Clamp a value into an inclusive range.
    public static func clamp(_ value: Int, min lo: Int, max hi: Int) -> Int {
        Swift.min(Swift.max(value, lo), hi)
    }

    /// Return a copy with every numeric field clamped to its valid range.
    /// `themeID` is passed through untouched (validated in the app layer,
    /// which falls back to the default if the id is unknown).
    public func clamped() -> PomodoroSettings {
        PomodoroSettings(
            workMinutes: Self.clamp(workMinutes, min: Self.minMinutes, max: Self.maxMinutes),
            shortBreakMinutes: Self.clamp(shortBreakMinutes, min: Self.minMinutes, max: Self.maxMinutes),
            longBreakMinutes: Self.clamp(longBreakMinutes, min: Self.minMinutes, max: Self.maxMinutes),
            longBreakInterval: Self.clamp(longBreakInterval, min: Self.minInterval, max: Self.maxInterval),
            autoStartNext: autoStartNext,
            playSound: playSound,
            themeID: themeID)
    }

    /// Configured minutes for a given session type.
    public func minutes(for session: SessionType) -> Int {
        switch session {
        case .work: return workMinutes
        case .shortBreak: return shortBreakMinutes
        case .longBreak: return longBreakMinutes
        }
    }

    /// Configured duration in seconds for a given session type.
    public func duration(for session: SessionType) -> Int {
        minutes(for: session) * 60
    }
}
