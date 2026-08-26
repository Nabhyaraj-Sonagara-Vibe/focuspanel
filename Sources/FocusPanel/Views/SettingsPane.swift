import SwiftUI
import FocusPanelCore

/// Compact settings popover: durations, long-break interval, and toggles.
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
                Label("Settings", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            stepper("Focus", value: $work, range: 1...180, accent: Theme.accent(for: .work), unit: "min")
            stepper("Short break", value: $short, range: 1...180, accent: Theme.accent(for: .shortBreak), unit: "min")
            stepper("Long break", value: $long, range: 1...180, accent: Theme.accent(for: .longBreak), unit: "min")
            stepper("Long break every", value: $interval, range: 2...12, accent: Color(hex: 0xF7B733), unit: "focus")

            Toggle("Auto-start next session", isOn: $autoStart)
                .tint(Theme.accent(for: .work))
                .foregroundStyle(.white.opacity(0.85))
                .font(.callout)
            Toggle("Chime when a session ends", isOn: $playSound)
                .tint(Theme.accent(for: .work))
                .foregroundStyle(.white.opacity(0.85))
                .font(.callout)

            Button(action: apply) {
                Text("Save")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.gradient(for: .work)))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(width: 300)
        .background(Theme.windowBackground)
        .onAppear(perform: load)
    }

    private func stepper(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, accent: Color, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text("\(Int(value.wrappedValue)) \(unit)")
                .font(.callout.weight(.semibold).monospacedDigit())
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
