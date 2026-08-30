import SwiftUI
import FocusPanelCore

/// Compact settings popover: theme picker, durations, long-break interval,
/// and toggles — pixel-console styled to match the rest of the panel.
struct SettingsPane: View {
    @EnvironmentObject var state: AppState
    @Environment(\.pixelTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var work: Double = 25
    @State private var short: Double = 5
    @State private var long: Double = 15
    @State private var interval: Double = 4
    @State private var autoStart = true
    @State private var playSound = true
    @State private var themeID: String = PomodoroSettings.defaultThemeID

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("SETTINGS")
                        .font(PixelFont.font(size: 9))
                        .foregroundStyle(.white)
                    Spacer()
                    PixelIconButton(systemImage: "xmark") { dismiss() }
                }

                themePicker

                Rectangle().fill(Theme.pixelBlack.opacity(0.4)).frame(height: 2)

                stepper("FOCUS", value: $work, range: 1...180, accent: theme.workAccent, unit: "min")
                stepper("SHORT BREAK", value: $short, range: 1...180, accent: theme.shortBreakAccent, unit: "min")
                stepper("LONG BREAK", value: $long, range: 1...180, accent: theme.longBreakAccent, unit: "min")
                stepper("LONG BREAK EVERY", value: $interval, range: 2...12, accent: theme.caseLight, unit: "focus")

                Toggle("Auto-start next session", isOn: $autoStart)
                    .tint(theme.workAccent)
                    .foregroundStyle(.white.opacity(0.85))
                    .font(.system(size: 12))
                Toggle("Chime when a session ends", isOn: $playSound)
                    .tint(theme.workAccent)
                    .foregroundStyle(.white.opacity(0.85))
                    .font(.system(size: 12))

                PixelButton(label: "SAVE", tint: theme.workAccent) {
                    apply()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(18)
        }
        .frame(width: 300)
        .frame(maxHeight: 520)
        .background(theme.screen)
        .onAppear(perform: load)
    }

    // MARK: - Theme picker

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THEME")
                .font(PixelFont.font(size: 7))
                .foregroundStyle(.white.opacity(0.85))

            // A 2-column grid of theme swatches; the selected one is outlined.
            let cols = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(ThemeCatalog.all) { t in
                    themeSwatch(t)
                }
            }
        }
    }

    private func themeSwatch(_ t: PixelTheme) -> some View {
        let selected = themeID == t.id
        return Button {
            themeID = t.id
            // Apply immediately so the change is live/previewable; Save also
            // persists it (updateSettings writes through to disk).
            state.setTheme(id: t.id)
        } label: {
            VStack(spacing: 6) {
                // Mini console preview: case frame + screen + 3 accent chips.
                ZStack {
                    Rectangle().fill(t.caseColor)
                    VStack(spacing: 3) {
                        Rectangle().fill(t.screen).frame(height: 14)
                        HStack(spacing: 3) {
                            Rectangle().fill(t.workAccent)
                            Rectangle().fill(t.shortBreakAccent)
                            Rectangle().fill(t.longBreakAccent)
                        }
                        .frame(height: 8)
                    }
                    .padding(4)
                }
                .frame(height: 40)
                .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 2))

                Text(t.name.uppercased())
                    .font(PixelFont.font(size: 6))
                    .foregroundStyle(.white.opacity(selected ? 1 : 0.6))
            }
            .padding(4)
            .background(selected ? Color.white.opacity(0.12) : .clear)
            .overlay(
                Rectangle().stroke(selected ? .white : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Steppers

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
        themeID = s.themeID
    }

    private func apply() {
        state.updateSettings(PomodoroSettings(
            workMinutes: Int(work),
            shortBreakMinutes: Int(short),
            longBreakMinutes: Int(long),
            longBreakInterval: Int(interval),
            autoStartNext: autoStart,
            playSound: playSound,
            themeID: themeID))
        dismiss()
    }
}
