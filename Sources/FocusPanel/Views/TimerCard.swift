import SwiftUI
import FocusPanelCore

/// The always-visible compact timer: session badge, a chunky pixel-ring
/// progress indicator built from discrete blocks (not a smooth stroke), and
/// primary transport — all in the console's hard-edged, flat-color style.
struct TimerCard: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            sessionBadge
            pixelRing
            transport
            cycleIndicator
        }
    }

    private var sessionBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: Theme.symbol(for: state.session))
                .font(.system(size: 11, weight: .bold))
            Text(state.sessionTitle.uppercased())
                .font(PixelFont.font(size: 9))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(state.accent)
        .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 2))
    }

    /// A ring of small square "pixels" that fill in clockwise as the session
    /// progresses — echoes the blocky, non-anti-aliased shapes in the Doodle
    /// rather than a smooth circular stroke.
    private var pixelRing: some View {
        let segments = 32
        let filled = Int(Double(segments) * state.progress)

        return ZStack {
            PixelPanel(fill: Theme.screenGreenDark) {
                Color.clear.frame(width: 170, height: 170)
            }

            ForEach(0..<segments, id: \.self) { i in
                let angle = Angle(degrees: Double(i) / Double(segments) * 360 - 90)
                Rectangle()
                    .fill(i < filled ? state.accent : Theme.pixelBlack.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .offset(y: -76)
                    .rotationEffect(angle)
                    .animation(.easeInOut(duration: 0.2), value: filled)
            }

            VStack(spacing: 4) {
                Text(state.clock)
                    .font(PixelFont.font(size: 26))
                    .foregroundStyle(.white)
                Text(state.isRunning ? "RUNNING" : "PAUSED")
                    .font(PixelFont.font(size: 7))
                    .foregroundStyle(Theme.cream.opacity(0.7))
            }
        }
        .frame(width: 176, height: 176)
    }

    private var transport: some View {
        HStack(spacing: 14) {
            PixelButton(systemImage: "arrow.counterclockwise", tint: Theme.caseAmberDark) {
                state.reset()
            }
            .help("Reset current session")

            PixelButton(
                systemImage: state.isRunning ? "pause.fill" : "play.fill",
                tint: state.accent
            ) {
                state.toggleRunning()
            }
            .help(state.isRunning ? "Pause" : "Start")

            PixelButton(systemImage: "forward.fill", tint: Theme.caseAmberDark) {
                state.skip()
            }
            .help("Skip to next session")
        }
    }

    private var cycleIndicator: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                ForEach(Array(state.cycleDots.enumerated()), id: \.offset) { _, filled in
                    Rectangle()
                        .fill(filled ? Theme.accent(for: .work) : Theme.pixelBlack.opacity(0.3))
                        .frame(width: 9, height: 9)
                        .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 1.5))
                }
            }
            Text("\(state.completedPomodoros) COMPLETED TODAY")
                .font(PixelFont.font(size: 6))
                .foregroundStyle(Theme.cream.opacity(0.75))
        }
    }
}
