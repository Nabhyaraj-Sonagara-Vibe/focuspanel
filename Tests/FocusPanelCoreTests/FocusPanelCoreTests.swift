import XCTest
@testable import FocusPanelCore

final class FocusPanelCoreTests: XCTestCase {

    // MARK: - TimeFormat

    func testClockFormatsUnderAnHour() {
        XCTAssertEqual(TimeFormat.clock(0), "00:00")
        XCTAssertEqual(TimeFormat.clock(5), "00:05")
        XCTAssertEqual(TimeFormat.clock(65), "01:05")
        XCTAssertEqual(TimeFormat.clock(25 * 60), "25:00")
        XCTAssertEqual(TimeFormat.clock(59 * 60 + 59), "59:59")
    }

    func testClockFormatsOverAnHour() {
        XCTAssertEqual(TimeFormat.clock(3600), "1:00:00")
        XCTAssertEqual(TimeFormat.clock(3661), "1:01:01")
    }

    func testClockClampsNegative() {
        XCTAssertEqual(TimeFormat.clock(-42), "00:00")
    }

    // MARK: - Settings clamping & math

    func testSettingsClampBelowMinimum() {
        let s = PomodoroSettings(workMinutes: 0,
                                 shortBreakMinutes: -3,
                                 longBreakMinutes: 0,
                                 longBreakInterval: 1).clamped()
        XCTAssertEqual(s.workMinutes, PomodoroSettings.minMinutes)
        XCTAssertEqual(s.shortBreakMinutes, PomodoroSettings.minMinutes)
        XCTAssertEqual(s.longBreakMinutes, PomodoroSettings.minMinutes)
        XCTAssertEqual(s.longBreakInterval, PomodoroSettings.minInterval)
    }

    func testSettingsClampAboveMaximum() {
        let s = PomodoroSettings(workMinutes: 9999,
                                 shortBreakMinutes: 500,
                                 longBreakMinutes: 1000,
                                 longBreakInterval: 99).clamped()
        XCTAssertEqual(s.workMinutes, PomodoroSettings.maxMinutes)
        XCTAssertEqual(s.shortBreakMinutes, PomodoroSettings.maxMinutes)
        XCTAssertEqual(s.longBreakMinutes, PomodoroSettings.maxMinutes)
        XCTAssertEqual(s.longBreakInterval, PomodoroSettings.maxInterval)
    }

    func testSettingsInRangeUnchanged() {
        let s = PomodoroSettings(workMinutes: 30,
                                 shortBreakMinutes: 6,
                                 longBreakMinutes: 20,
                                 longBreakInterval: 4).clamped()
        XCTAssertEqual(s.workMinutes, 30)
        XCTAssertEqual(s.shortBreakMinutes, 6)
        XCTAssertEqual(s.longBreakMinutes, 20)
        XCTAssertEqual(s.longBreakInterval, 4)
    }

    func testDurationMath() {
        let s = PomodoroSettings.default
        XCTAssertEqual(s.duration(for: .work), 25 * 60)
        XCTAssertEqual(s.duration(for: .shortBreak), 5 * 60)
        XCTAssertEqual(s.duration(for: .longBreak), 15 * 60)
        XCTAssertEqual(s.minutes(for: .work), 25)
    }

    // MARK: - SessionPlanner cycle rules

    func testPlannerWorkYieldsShortBreakBeforeInterval() {
        XCTAssertEqual(SessionPlanner.next(after: .work, completedWorkSessions: 1, longBreakInterval: 4), .shortBreak)
        XCTAssertEqual(SessionPlanner.next(after: .work, completedWorkSessions: 2, longBreakInterval: 4), .shortBreak)
        XCTAssertEqual(SessionPlanner.next(after: .work, completedWorkSessions: 3, longBreakInterval: 4), .shortBreak)
    }

    func testPlannerLongBreakOnInterval() {
        XCTAssertEqual(SessionPlanner.next(after: .work, completedWorkSessions: 4, longBreakInterval: 4), .longBreak)
        XCTAssertEqual(SessionPlanner.next(after: .work, completedWorkSessions: 8, longBreakInterval: 4), .longBreak)
    }

    func testPlannerBreaksYieldWork() {
        XCTAssertEqual(SessionPlanner.next(after: .shortBreak, completedWorkSessions: 2, longBreakInterval: 4), .work)
        XCTAssertEqual(SessionPlanner.next(after: .longBreak, completedWorkSessions: 4, longBreakInterval: 4), .work)
    }

    func testPlannerRespectsCustomInterval() {
        XCTAssertEqual(SessionPlanner.next(after: .work, completedWorkSessions: 2, longBreakInterval: 2), .longBreak)
        XCTAssertEqual(SessionPlanner.next(after: .work, completedWorkSessions: 1, longBreakInterval: 2), .shortBreak)
    }

    // MARK: - Engine cycle: long break lands on the 4th focus session

    func testEngineFullCycleWithLongBreakOnFourth() {
        let engine = PomodoroEngine(settings: .default) // interval 4, autoStart on
        // Record the session we transition INTO after completing each session,
        // starting from the initial work session.
        var transitions: [SessionType] = []
        for _ in 0..<8 {
            engine.complete()
            transitions.append(engine.currentSession)
        }
        // work->short, short->work, work->short, short->work,
        // work->short, short->work, work->LONG, long->work
        XCTAssertEqual(transitions, [
            .shortBreak, .work,
            .shortBreak, .work,
            .shortBreak, .work,
            .longBreak, .work
        ])
        // Four focus sessions were completed naturally.
        XCTAssertEqual(engine.completedPomodoros, 4)
    }

    func testEngineTallyOnlyCountsFocusSessions() {
        let engine = PomodoroEngine(settings: .default)
        engine.complete() // finish work #1 -> short break
        XCTAssertEqual(engine.completedPomodoros, 1)
        engine.complete() // finish short break -> work
        XCTAssertEqual(engine.completedPomodoros, 1) // break does not add to tally
    }

    // MARK: - Engine ticking

    func testEngineTickCountsDownAndCompletes() {
        let engine = PomodoroEngine(settings: PomodoroSettings(workMinutes: 1, autoStartNext: false))
        engine.start()
        XCTAssertEqual(engine.remainingSeconds, 60)
        var finished: SessionType?
        for _ in 0..<59 {
            finished = engine.tick()
            XCTAssertNil(finished)
        }
        XCTAssertEqual(engine.remainingSeconds, 1)
        finished = engine.tick() // 60th tick -> zero -> complete
        XCTAssertEqual(finished, .work)
        XCTAssertEqual(engine.currentSession, .shortBreak)
        XCTAssertEqual(engine.completedPomodoros, 1)
    }

    func testTickDoesNothingWhenPaused() {
        let engine = PomodoroEngine(settings: .default)
        XCTAssertFalse(engine.isRunning)
        let before = engine.remainingSeconds
        XCTAssertNil(engine.tick())
        XCTAssertEqual(engine.remainingSeconds, before)
    }

    // MARK: - Skip & reset

    func testSkipAdvancesWithoutCreditingPomodoro() {
        let engine = PomodoroEngine(settings: .default)
        engine.start()
        engine.skip() // skip focus #1
        XCTAssertEqual(engine.currentSession, .shortBreak)
        XCTAssertEqual(engine.completedPomodoros, 0) // skip is not a completion
        XCTAssertFalse(engine.isRunning)             // skipped-into session is paused
        engine.skip() // skip the break
        XCTAssertEqual(engine.currentSession, .work)
    }

    func testResetRestoresDurationAndPauses() {
        let engine = PomodoroEngine(settings: PomodoroSettings(workMinutes: 1))
        engine.start()
        _ = engine.tick()
        _ = engine.tick()
        XCTAssertLessThan(engine.remainingSeconds, 60)
        engine.reset()
        XCTAssertEqual(engine.remainingSeconds, 60)
        XCTAssertFalse(engine.isRunning)
    }

    func testProgressIsFractionElapsed() {
        let engine = PomodoroEngine(settings: PomodoroSettings(workMinutes: 1, autoStartNext: false))
        XCTAssertEqual(engine.progress, 0.0, accuracy: 0.0001)
        engine.start()
        for _ in 0..<30 { _ = engine.tick() }
        XCTAssertEqual(engine.progress, 0.5, accuracy: 0.02)
    }

    func testUpdateSettingsRefreshesIdleDuration() {
        let engine = PomodoroEngine(settings: .default)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
        engine.updateSettings(PomodoroSettings(workMinutes: 40))
        XCTAssertEqual(engine.remainingSeconds, 40 * 60) // idle + at full -> refreshed
    }

    func testUpdateSettingsClampsInput() {
        let engine = PomodoroEngine(settings: .default)
        engine.updateSettings(PomodoroSettings(workMinutes: 100000))
        XCTAssertEqual(engine.settings.workMinutes, PomodoroSettings.maxMinutes)
    }

    // MARK: - Todo model operations

    func testTodoAddTrimsAndRejectsEmpty() {
        var list = TodoList()
        XCTAssertNotNil(list.add("  Write report  "))
        XCTAssertEqual(list.items.count, 1)
        XCTAssertEqual(list.items.first?.title, "Write report")
        XCTAssertNil(list.add("   "))        // whitespace only
        XCTAssertNil(list.add(""))           // empty
        XCTAssertEqual(list.items.count, 1)
    }

    func testTodoToggle() {
        var list = TodoList()
        let item = list.add("Task")!
        XCTAssertFalse(list.items[0].isDone)
        list.toggle(item.id)
        XCTAssertTrue(list.items[0].isDone)
        list.toggle(item.id)
        XCTAssertFalse(list.items[0].isDone)
    }

    func testTodoDelete() {
        var list = TodoList()
        let a = list.add("A")!
        let b = list.add("B")!
        list.delete(a.id)
        XCTAssertEqual(list.items.map(\.title), ["B"])
        list.delete(b.id)
        XCTAssertTrue(list.items.isEmpty)
        list.delete(UUID()) // no-op on unknown id
    }

    func testTodoMoveReorders() {
        var list = TodoList()
        list.add("A"); list.add("B"); list.add("C")
        list.move(from: IndexSet(integer: 0), to: 3) // move A to the end
        XCTAssertEqual(list.items.map(\.title), ["B", "C", "A"])
    }

    func testTodoCountsAndClearCompleted() {
        var list = TodoList()
        let a = list.add("A")!
        list.add("B")
        list.add("C")
        list.toggle(a.id)
        XCTAssertEqual(list.completedCount, 1)
        XCTAssertEqual(list.remainingCount, 2)
        list.clearCompleted()
        XCTAssertEqual(list.items.map(\.title), ["B", "C"])
    }

    func testTodoListCodableRoundTrip() throws {
        var list = TodoList()
        list.add("Persist me")
        list.toggle(list.items[0].id)
        let data = try JSONEncoder().encode(list)
        let decoded = try JSONDecoder().decode(TodoList.self, from: data)
        XCTAssertEqual(decoded, list)
    }

    // MARK: - Settings theme + backward-compatible decoding

    func testSettingsDefaultThemeID() {
        XCTAssertEqual(PomodoroSettings.default.themeID, PomodoroSettings.defaultThemeID)
    }

    func testSettingsThemeIDRoundTrips() throws {
        let s = PomodoroSettings(workMinutes: 30, themeID: "synthwave")
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(PomodoroSettings.self, from: data)
        XCTAssertEqual(decoded.themeID, "synthwave")
        XCTAssertEqual(decoded, s)
    }

    /// Settings JSON written by an OLDER build had no `themeID` field. Decoding
    /// it must succeed and fall back to the default theme, NOT throw and wipe
    /// the user's saved durations.
    func testSettingsDecodesLegacyJSONWithoutThemeID() throws {
        let legacyJSON = """
        {
          "workMinutes": 45,
          "shortBreakMinutes": 7,
          "longBreakMinutes": 20,
          "longBreakInterval": 3,
          "autoStartNext": false,
          "playSound": true
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(PomodoroSettings.self, from: legacyJSON)
        XCTAssertEqual(decoded.workMinutes, 45)
        XCTAssertEqual(decoded.shortBreakMinutes, 7)
        XCTAssertEqual(decoded.longBreakMinutes, 20)
        XCTAssertEqual(decoded.longBreakInterval, 3)
        XCTAssertFalse(decoded.autoStartNext)
        XCTAssertTrue(decoded.playSound)
        // The crucial part: missing themeID -> default, not a decode failure.
        XCTAssertEqual(decoded.themeID, PomodoroSettings.defaultThemeID)
    }

    func testSettingsClampPreservesThemeID() {
        let s = PomodoroSettings(workMinutes: 9999, themeID: "gameBoy").clamped()
        XCTAssertEqual(s.workMinutes, PomodoroSettings.maxMinutes)
        XCTAssertEqual(s.themeID, "gameBoy") // clamp must not drop the theme
    }

    func testEngineUpdateSettingsPreservesThemeID() {
        let engine = PomodoroEngine(settings: .default)
        engine.updateSettings(PomodoroSettings(workMinutes: 40, themeID: "arcade"))
        XCTAssertEqual(engine.settings.themeID, "arcade")
    }
}
