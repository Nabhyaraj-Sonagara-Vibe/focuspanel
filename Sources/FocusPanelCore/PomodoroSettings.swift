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

    public static let minMinutes = 1
    public static let maxMinutes = 180
    public static let minInterval = 2
    public static let maxInterval = 12

    public init(workMinutes: Int = 25,
                shortBreakMinutes: Int = 5,
                longBreakMinutes: Int = 15,
                longBreakInterval: Int = 4,
                autoStartNext: Bool = true,
                playSound: Bool = true) {
        self.workMinutes = workMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.longBreakInterval = longBreakInterval
        self.autoStartNext = autoStartNext
        self.playSound = playSound
    }

    public static let `default` = PomodoroSettings()

    /// Clamp a value into an inclusive range.
    public static func clamp(_ value: Int, min lo: Int, max hi: Int) -> Int {
        Swift.min(Swift.max(value, lo), hi)
    }

    /// Return a copy with every numeric field clamped to its valid range.
    public func clamped() -> PomodoroSettings {
        PomodoroSettings(
            workMinutes: Self.clamp(workMinutes, min: Self.minMinutes, max: Self.maxMinutes),
            shortBreakMinutes: Self.clamp(shortBreakMinutes, min: Self.minMinutes, max: Self.maxMinutes),
            longBreakMinutes: Self.clamp(longBreakMinutes, min: Self.minMinutes, max: Self.maxMinutes),
            longBreakInterval: Self.clamp(longBreakInterval, min: Self.minInterval, max: Self.maxInterval),
            autoStartNext: autoStartNext,
            playSound: playSound)
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
