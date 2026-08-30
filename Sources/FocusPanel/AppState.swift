import Foundation
import SwiftUI
import Combine
import FocusPanelCore

/// Observable view model bridging the pure `PomodoroEngine` / `TodoList` core to
/// SwiftUI, plus the 1-second timer, persistence, and end-of-session alerts.
@MainActor
final class AppState: ObservableObject {
    // Mirrored engine state (the engine itself is a plain, testable class).
    @Published private(set) var session: SessionType
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning: Bool
    @Published private(set) var completedPomodoros: Int
    @Published private(set) var progress: Double

    // Editable, persisted state.
    @Published var todos: TodoList { didSet { persistence.save(todos: todos) } }
    @Published private(set) var settings: PomodoroSettings

    private let engine: PomodoroEngine
    private let persistence: Persistence
    private var timer: Timer?

    init(persistence: Persistence = Persistence()) {
        self.persistence = persistence
        let loadedSettings = persistence.loadSettings()
        let e = PomodoroEngine(settings: loadedSettings)
        e.restore(completedPomodoros: persistence.loadCompleted(),
                  cyclePosition: persistence.loadCyclePosition())
        self.engine = e
        self.settings = loadedSettings
        self.todos = persistence.loadTodos()
        self.session = e.currentSession
        self.remainingSeconds = e.remainingSeconds
        self.isRunning = e.isRunning
        self.completedPomodoros = e.completedPomodoros
        self.progress = e.progress
        SessionAlert.requestAuthorizationIfPossible()
    }

    // MARK: - Derived display

    var clock: String { TimeFormat.clock(remainingSeconds) }
    var sessionTitle: String { session.title }

    /// The active visual theme, resolved from the persisted `settings.themeID`.
    var theme: PixelTheme { ThemeCatalog.theme(id: settings.themeID) }

    /// Accent colour for the current session under the active theme.
    var accent: Color { theme.accent(for: session) }

    /// Change the theme and persist it, leaving all timer settings intact.
    func setTheme(id: String) {
        guard id != settings.themeID else { return }
        var s = settings
        s.themeID = id
        updateSettings(s)
    }

    /// Progress toward the next long break, as filled/empty dots.
    var cycleDots: [Bool] {
        let interval = settings.longBreakInterval
        let filled = completedPomodoros % interval
        // A fresh long-break boundary shows all dots filled momentarily.
        let effective = (filled == 0 && completedPomodoros > 0) ? interval : filled
        return (0..<interval).map { $0 < effective }
    }

    // MARK: - Controls

    func toggleRunning() {
        engine.toggle()
        if engine.isRunning { startTimer() } else { stopTimer() }
        sync()
    }

    func reset() {
        engine.reset()
        stopTimer()
        sync()
    }

    func skip() {
        engine.skip()
        stopTimer()
        sync()
    }

    func updateSettings(_ newSettings: PomodoroSettings) {
        engine.updateSettings(newSettings)
        settings = engine.settings
        persistence.save(settings: settings)
        sync()
    }

    // MARK: - Todo passthrough (keeps @Published didSet firing)

    func addTodo(_ title: String) { todos.add(title) }
    func toggleTodo(_ id: UUID) { todos.toggle(id) }
    func deleteTodo(_ id: UUID) { todos.delete(id) }
    func moveTodo(from source: IndexSet, to destination: Int) { todos.move(from: source, to: destination) }
    func clearCompletedTodos() { todos.clearCompleted() }

    // MARK: - Timer

    private func startTimer() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.onTick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func onTick() {
        let finished = engine.tick()
        if let finished {
            // A session ended this tick.
            SessionAlert.fire(finished: finished,
                              next: engine.currentSession,
                              playSound: settings.playSound)
            persistence.save(completed: engine.completedPomodoros,
                             cyclePosition: engine.cyclePosition)
            if !engine.isRunning { stopTimer() } // auto-start off
        }
        sync()
    }

    /// Copy engine state into the published mirror.
    private func sync() {
        session = engine.currentSession
        remainingSeconds = engine.remainingSeconds
        isRunning = engine.isRunning
        completedPomodoros = engine.completedPomodoros
        progress = engine.progress
    }
}
