import SwiftUI
import FocusPanelCore

/// The always-visible compact timer at the top of the panel: session badge,
/// circular progress ring with the big countdown, and primary transport.
struct TimerCard: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 14) {
            sessionBadge

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: CGFloat(state.progress))
                    .stroke(Theme.gradient(for: state.session),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: state.progress)

                VStack(spacing: 2) {
                    Text(state.clock)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(state.isRunning ? "in progress" : "paused")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(width: 176, height: 176)
            .padding(.vertical, 2)

            transport
            cycleIndicator
        }
    }

    private var sessionBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: Theme.symbol(for: state.session))
            Text(state.sessionTitle.uppercased())
                .fontWeight(.semibold)
                .tracking(1.5)
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Theme.gradient(for: state.session))
        )
        .shadow(color: state.accent.opacity(0.5), radius: 8, y: 2)
    }

    private var transport: some View {
        HStack(spacing: 22) {
            controlButton(system: "arrow.counterclockwise", size: 18) { state.reset() }
                .help("Reset current session")

            Button(action: { state.toggleRunning() }) {
                ZStack {
                    Circle().fill(Theme.gradient(for: state.session))
                        .frame(width: 60, height: 60)
                        .shadow(color: state.accent.opacity(0.6), radius: 10, y: 3)
                    Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: state.isRunning ? 0 : 2)
                }
            }
            .buttonStyle(.plain)
            .help(state.isRunning ? "Pause" : "Start")

            controlButton(system: "forward.fill", size: 18) { state.skip() }
                .help("Skip to next session")
        }
    }

    private var cycleIndicator: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                ForEach(Array(state.cycleDots.enumerated()), id: \.offset) { _, filled in
                    Circle()
                        .fill(filled ? AnyShapeStyle(Theme.gradient(for: .work))
                                     : AnyShapeStyle(Color.white.opacity(0.18)))
                        .frame(width: 8, height: 8)
                }
            }
            Text("\(state.completedPomodoros) completed today")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func controlButton(system: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}
