import Foundation
import FocusPanelCore

/// Lightweight UserDefaults-backed persistence for settings, tally and todos.
struct Persistence {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let settings = "focuspanel.settings"
        static let todos = "focuspanel.todos"
        static let completed = "focuspanel.completedPomodoros"
        static let cyclePosition = "focuspanel.cyclePosition"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: Settings

    func loadSettings() -> PomodoroSettings {
        guard let data = defaults.data(forKey: Key.settings),
              let decoded = try? decoder.decode(PomodoroSettings.self, from: data)
        else { return .default }
        return decoded.clamped()
    }

    func save(settings: PomodoroSettings) {
        if let data = try? encoder.encode(settings) {
            defaults.set(data, forKey: Key.settings)
        }
    }

    // MARK: Todos

    func loadTodos() -> TodoList {
        guard let data = defaults.data(forKey: Key.todos),
              let decoded = try? decoder.decode(TodoList.self, from: data)
        else { return TodoList() }
        return decoded
    }

    func save(todos: TodoList) {
        if let data = try? encoder.encode(todos) {
            defaults.set(data, forKey: Key.todos)
        }
    }

    // MARK: Counters

    func loadCompleted() -> Int { defaults.integer(forKey: Key.completed) }
    func loadCyclePosition() -> Int { defaults.integer(forKey: Key.cyclePosition) }

    func save(completed: Int, cyclePosition: Int) {
        defaults.set(completed, forKey: Key.completed)
        defaults.set(cyclePosition, forKey: Key.cyclePosition)
    }
}
