# FocusPanel

A colourful, native **macOS Pomodoro timer with an integrated to-do list**, packed
into a compact, always-on-top floating window you tuck into a screen corner and
work alongside. Built in **Swift + SwiftUI/AppKit**.

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
- **Colourful, session-aware UI.** A retro cartridge-console look directly
  inspired by Google's [Jerry Lawson Doodle](https://doodles.google/doodle/gerald-jerry-lawsons-82nd-birthday/)
  (celebrating the Fairchild Channel F, the first cartridge-based home
  console): a wood/amber console "case" framing a circuit-board-green
  "screen", thick black pixel outlines, hard edges, flat primary-color
  accents that shift per session (cartridge red for focus, circuit green for
  short breaks, console blue for long breaks), and the bundled **Press
  Start 2P** pixel font throughout.
- **End-of-session alert.** A native macOS user notification and/or an `NSSound`
  chime.
- **Persists across launches.** Settings, the completed tally, and your todos are
  stored in `UserDefaults`.
- **100% local.** No network calls, no accounts, no paid or external dependencies —
  Foundation / SwiftUI / AppKit / UserNotifications only.

## Architecture

The project is a proper **Xcode project** (`FocusPanel.xcodeproj`), generated
and kept in sync from a checked-in [XcodeGen](https://github.com/yonaskolb/XcodeGen)
spec (`project.yml`) rather than hand-edited — so the project file itself never
needs manual merge-conflict surgery, and anyone can regenerate it identically.
Under the hood it's still a clean two-target split so the logic is independently
testable:

- **`FocusPanelCore`** — a pure, UI-free static library: the Pomodoro state
  machine (`PomodoroEngine`), cycle rules (`SessionPlanner`), settings +
  clamping (`PomodoroSettings`), time formatting (`TimeFormat`), and the todo
  model (`TodoList` / `TodoItem`). No SwiftUI/AppKit imports — fully unit-tested.
- **`FocusPanel`** — the app target: the SwiftUI views, the observable
  `AppState`, `UserDefaults` persistence, notifications, and an AppKit
  bootstrap (`main.swift` + `AppDelegate`) that creates the floating `NSWindow`.
  Ships with a real bundle identifier (`com.nabhyaraj.focuspanel`) and
  `Info.plist`, so it behaves like a proper macOS app — Dock icon, Launch
  Services registration, working notification permissions — not just a bare
  command-line binary.
- **`FocusPanelCoreTests`** — an XCTest bundle target exercising `FocusPanelCore`.

## Requirements

- macOS 13 (Ventura) or later.
- **Xcode 15+** (full Xcode, not just Command Line Tools — XCTest and app
  bundle code-signing both require it).

## Build & run (Xcode — primary path)

1. Open `FocusPanel.xcodeproj` in Xcode.
2. Select the **FocusPanel** scheme.
3. Press **⌘R** to build and run. The floating panel opens in the top-right
   corner of your screen.
4. Press **⌘U** to run the test suite (26 tests, `FocusPanelCoreTests`).

Or from the command line:

```bash
# Build
xcodebuild -project FocusPanel.xcodeproj -scheme FocusPanel -destination 'platform=macOS' build

# Run the tests
xcodebuild -project FocusPanel.xcodeproj -scheme FocusPanel -destination 'platform=macOS' test

# Launch the built app
open ~/Library/Developer/Xcode/DerivedData/FocusPanel-*/Build/Products/Debug/FocusPanel.app
```

### Regenerating the Xcode project

The `.xcodeproj` is generated from `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) and
is checked into the repo so you can open it immediately without a generation
step. If you change `project.yml` (or add/remove source files), regenerate it:

```bash
xcodegen generate
```

### Building a Release archive

```bash
xcodebuild -project FocusPanel.xcodeproj -scheme FocusPanel -configuration Release -destination 'platform=macOS' build
```

## Tests

The `FocusPanelCoreTests` XCTest suite (26 tests, run via ⌘U in Xcode or
`xcodebuild test` above) covers:

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
