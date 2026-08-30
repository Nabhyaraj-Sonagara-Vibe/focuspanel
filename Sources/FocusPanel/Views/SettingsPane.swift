import SwiftUI
import FocusPanelCore

/// Compact settings popover: durations, long-break interval, and toggles —
/// pixel-console styled to match the rest of the panel.
struct SettingsPane: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var work: Double = 25
    @State private var short: Double = 5
    @State private var long: Double = 15
    @State private var interval: Double = 4
    @State private var autoStart = true
    @State private var playSound = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SETTINGS")
                    .font(PixelFont.font(size: 9))
                    .foregroundStyle(.white)
                Spacer()
                PixelIconButton(systemImage: "xmark") { dismiss() }
            }

            stepper("FOCUS", value: $work, range: 1...180, accent: Theme.accent(for: .work), unit: "min")
            stepper("SHORT BREAK", value: $short, range: 1...180, accent: Theme.accent(for: .shortBreak), unit: "min")
            stepper("LONG BREAK", value: $long, range: 1...180, accent: Theme.accent(for: .longBreak), unit: "min")
            stepper("LONG BREAK EVERY", value: $interval, range: 2...12, accent: Theme.caseAmberLight, unit: "focus")

            Toggle("Auto-start next session", isOn: $autoStart)
                .tint(Theme.accent(for: .work))
                .foregroundStyle(.white.opacity(0.85))
                .font(.system(size: 12))
            Toggle("Chime when a session ends", isOn: $playSound)
                .tint(Theme.accent(for: .work))
                .foregroundStyle(.white.opacity(0.85))
                .font(.system(size: 12))

            PixelButton(label: "SAVE", tint: Theme.accent(for: .work)) {
                apply()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(width: 300)
        .background(Theme.screenGreen)
        .onAppear(perform: load)
    }

    private func stepper(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, accent: Color, unit: String) -> some View {
        HStack {
            Text(label)
                .font(PixelFont.font(size: 7))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text("\(Int(value.wrappedValue)) \(unit)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent)
                .frame(minWidth: 62, alignment: .trailing)
            Stepper("", value: value, in: range, step: 1)
                .labelsHidden()
        }
    }

    private func load() {
        let s = state.settings
        work = Double(s.workMinutes)
        short = Double(s.shortBreakMinutes)
        long = Double(s.longBreakMinutes)
        interval = Double(s.longBreakInterval)
        autoStart = s.autoStartNext
        playSound = s.playSound
    }

    private func apply() {
        state.updateSettings(PomodoroSettings(
            workMinutes: Int(work),
            shortBreakMinutes: Int(short),
            longBreakMinutes: Int(long),
            longBreakInterval: Int(interval),
            autoStartNext: autoStart,
            playSound: playSound))
        dismiss()
    }
}
