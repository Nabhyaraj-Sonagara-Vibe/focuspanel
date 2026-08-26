import Foundation

/// Pure decision logic for what session follows another. Kept separate from the
/// engine so the cycle rules can be unit-tested in isolation.
public enum SessionPlanner {
    /// Given the session that just finished and the number of completed focus
    /// sessions *including* the one that just finished, decide what comes next.
    ///
    /// Work is followed by a short break, except on every `longBreakInterval`-th
    /// completed focus session, which earns a long break. Any break is followed
    /// by work.
    public static func next(after finished: SessionType,
                            completedWorkSessions: Int,
                            longBreakInterval: Int) -> SessionType {
        let interval = max(PomodoroSettings.minInterval, longBreakInterval)
        switch finished {
        case .work:
            if completedWorkSessions > 0 && completedWorkSessions % interval == 0 {
                return .longBreak
            }
            return .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }
}
