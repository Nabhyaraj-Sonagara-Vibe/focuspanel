# FocusPanel

A colourful, native **macOS Pomodoro timer with an integrated to-do list**, packed
into a compact, always-on-top floating window you tuck into a screen corner and
work alongside. Built in **Swift + SwiftUI/AppKit**, no Xcode project required —
it builds, tests, and runs straight from Swift Package Manager.

<!-- Screenshots optional; add under docs/ if desired. -->

## The problem

Most Pomodoro apps are either a full-window affair that hogs your screen, or a
tiny menu-bar countdown with nowhere to see what you're actually supposed to be
doing. FocusPanel keeps a **small, floating companion widget** pinned above your
other apps: the countdown and your task list live together in a slim panel, so
the thing you're timing and the thing you're doing are always in view — without
taking over the screen.

## What it does

- **Compact, always-on-top floating window.** A slim 300 pt-wide panel set to
  `NSWindow.level = .floating`, so it stays visible above other apps while you
  work. Fixed, widget-like footprint (not resizable, not fullscreen), parked in
  the top-right corner by default and draggable anywhere by its background.
- **Full Pomodoro cycle.** Configurable work / short-break / long-break durations
  (defaults 25 / 5 / 15 min), auto-cycling (work → short break, with a long break
  on every 4th focus session), a big readable countdown with a circular progress
  ring, and **pause / resume / reset / skip** controls.
- **Completed-pomodoro tally & cycle dots** show your progress toward the next
  long break and how many focus sessions you've finished.
- **Integrated to-do list.** Add tasks, tick them off, delete them, clear
  completed — a slim scrollable checklist that shares the same small footprint via
  a **Timer / Tasks** segmented toggle.
- **Colourful, session-aware UI.** Vibrant gradients that shift with the session
  type — energetic coral/magenta for focus, calm mint for short breaks, cool
  indigo for long breaks — with SF Symbols, rounded cards, and a soft dark
  backdrop.
- **End-of-session alert.** A native macOS user notification (when run as a
  bundled `.app`) and/or an `NSSound` chime.
- **Persists across launches.** Settings, the completed tally, and your todos are
  stored in `UserDefaults`.
- **100% local.** No network calls, no accounts, no paid or external dependencies —
  Foundation / SwiftUI / AppKit / UserNotifications only.

## Architecture

The project is a Swift package with a clean split so the logic is testable from
the command line:

- **`FocusPanelCore`** — a pure, UI-free library: the Pomodoro state machine
  (`PomodoroEngine`), cycle rules (`SessionPlanner`), settings + clamping
  (`PomodoroSettings`), time formatting (`TimeFormat`), and the todo model
  (`TodoList` / `TodoItem`). No SwiftUI/AppKit imports — fully unit-tested.
- **`FocusPanel`** — the executable target: the SwiftUI views, the observable
  `AppState`, `UserDefaults` persistence, notifications, and an AppKit
  bootstrap (`main.swift` + `AppDelegate`) that creates the floating `NSWindow`.
  A macOS SwiftUI app is launched from a SwiftPM executable target this way so it
  builds and runs from the CLI without an `.xcodeproj`.

## Requirements

- macOS 13 (Ventura) or later
- A Swift 5.9+ toolchain. **Running the tests requires a full Xcode install**
  (the XCTest framework ships with Xcode, not the standalone Command Line Tools).
  `swift build` and `swift run` work with either.

## Build & run

```bash
# Build
swift build

# Run the app (opens the floating panel)
swift run FocusPanel

# Run the logic tests
swift test
```

> If you have Xcode installed but the Command Line Tools are the active
> developer directory, point the toolchain at Xcode so `swift test` can find
> XCTest:
>
> ```bash
> DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
> ```

## Build a distributable `.app`

`swift run` launches the binary directly. To get a proper double-clickable app
bundle (with a bundle identifier, which also enables user notifications), use the
helper script:

```bash
./scripts/make_app.sh
open dist/FocusPanel.app
```

This builds a release binary and wraps it in `dist/FocusPanel.app` with a minimal
`Info.plist`.

## Tests

`swift test` runs the `FocusPanelCore` XCTest suite (26 tests) covering:

- Session-transition cycle logic, including the long break landing on the 4th
  focus session and custom long-break intervals.
- Duration / `mm:ss` time-format math (including the hour rollover and negative
  clamping).
- Settings clamping (below min, above max, in-range) and live-update behaviour.
- Engine ticking, completion, pause, skip (no false tally credit), reset, and
  progress.
- Todo model operations: add (with trimming + empty rejection), toggle, delete,
  reorder, clear-completed, counts, and Codable round-trip.

## License

MIT — see [LICENSE](LICENSE).
