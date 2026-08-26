import Foundation

/// The three kinds of session in a Pomodoro cycle.
public enum SessionType: String, Codable, CaseIterable, Sendable {
    case work
    case shortBreak
    case longBreak

    /// Human-readable label shown in the UI.
    public var title: String {
        switch self {
        case .work: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    /// Whether this session is a break (short or long).
    public var isBreak: Bool { self != .work }
}
