import Foundation

/// Clock formatting for the countdown display.
public enum TimeFormat {
    /// Format a number of seconds as `mm:ss` (or `h:mm:ss` past an hour).
    /// Negative input is clamped to zero.
    public static func clock(_ totalSeconds: Int) -> String {
        let s = max(0, totalSeconds)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let seconds = s % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
