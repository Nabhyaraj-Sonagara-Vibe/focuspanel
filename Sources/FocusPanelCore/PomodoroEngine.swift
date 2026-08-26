import Foundation

/// The Pomodoro state machine: a pure, UI-free clock and cycle tracker. All UI
/// (SwiftUI/AppKit) lives elsewhere and merely observes and drives this type,
/// which keeps the cycle logic fully unit-testable.
public final class PomodoroEngine {
    public private(set) var settings: PomodoroSettings
    public private(set) var currentSession: SessionType
    public private(set) var remainingSeconds: Int
    /// Focus sessions that have *ended* (completed or skipped). Drives long-break timing.
    public private(set) var cyclePosition: Int
    /// Focus sessions completed naturally (the tally the user sees). Skips do not count.
    public private(set) var completedPomodoros: Int
    public private(set) var isRunning: Bool

    public init(settings: PomodoroSettings = .default) {
        let s = settings.clamped()
        self.settings = s
        self.currentSession = .work
        self.remainingSeconds = s.duration(for: .work)
        self.cyclePosition = 0
        self.completedPomodoros = 0
        self.isRunning = false
    }

    // MARK: - Run control

    public func start() { isRunning = true }
    public func pause() { isRunning = false }
    public func toggle() { isRunning.toggle() }

    /// Advance the clock by one second. Returns the session that just finished if
    /// the countdown reached zero on this tick, otherwise `nil`.
    @discardableResult
    public func tick() -> SessionType? {
        guard isRunning else { return nil }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        if remainingSeconds == 0 {
            return complete()
        }
        return nil
    }

    /// Finish the current session naturally and transition to the next one.
    /// Returns the session that just finished.
    @discardableResult
    public func complete() -> SessionType {
        let finished = currentSession
        if finished == .work {
            cyclePosition += 1
            completedPomodoros += 1
        }
        let next = SessionPlanner.next(after: finished,
                                       completedWorkSessions: cyclePosition,
                                       longBreakInterval: settings.longBreakInterval)
        transition(to: next, autoStart: settings.autoStartNext)
        return finished
    }

    /// Jump to the next session in the cycle without crediting a completed
    /// pomodoro. The next session starts paused.
    public func skip() {
        let finished = currentSession
        if finished == .work {
            cyclePosition += 1 // advance the cycle, but do not credit a pomodoro
        }
        let next = SessionPlanner.next(after: finished,
                                       completedWorkSessions: cyclePosition,
                                       longBreakInterval: settings.longBreakInterval)
        transition(to: next, autoStart: false)
    }

    /// Restart the current session's countdown and pause it.
    public func reset() {
        remainingSeconds = settings.duration(for: currentSession)
        isRunning = false
    }

    /// Apply new settings. If the current countdown is untouched (at full
    /// duration and paused), refresh it to the new duration so edits take effect
    /// immediately; a running/partial timer is left alone.
    public func updateSettings(_ newSettings: PomodoroSettings) {
        let clamped = newSettings.clamped()
        let atFullDuration = remainingSeconds == settings.duration(for: currentSession)
        settings = clamped
        if atFullDuration && !isRunning {
            remainingSeconds = clamped.duration(for: currentSession)
        }
    }

    /// Restore persisted counters after relaunch.
    public func restore(completedPomodoros: Int, cyclePosition: Int) {
        self.completedPomodoros = max(0, completedPomodoros)
        self.cyclePosition = max(0, cyclePosition)
    }

    // MARK: - Derived

    /// Fraction of the current session elapsed, in `0...1`.
    public var progress: Double {
        let total = settings.duration(for: currentSession)
        guard total > 0 else { return 0 }
        let elapsed = total - remainingSeconds
        return min(1.0, max(0.0, Double(elapsed) / Double(total)))
    }

    // MARK: - Private

    private func transition(to session: SessionType, autoStart: Bool) {
        currentSession = session
        remainingSeconds = settings.duration(for: session)
        isRunning = autoStart
    }
}
