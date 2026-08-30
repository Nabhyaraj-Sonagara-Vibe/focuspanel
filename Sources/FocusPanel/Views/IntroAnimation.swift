import SwiftUI

/// A short pixel-art "boot" animation shown once when the panel launches:
/// the screen powers on (a CRT-style horizontal scan line sweeps down), then
/// the app name types/flickers in cartridge-style, then the whole overlay
/// fades to reveal the app. Purely additive — it draws on top of the panel
/// and removes itself via `onFinished`, changing nothing about the app's
/// behaviour underneath.
///
/// Respects the system "Reduce Motion" accessibility setting: when enabled,
/// it skips the sweep/flicker and just shows a brief static title before
/// dismissing, so no large motion is forced on users who opted out.
struct IntroAnimation: View {
    let theme: PixelTheme
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scanY: CGFloat = -20      // scan line position (fraction driven)
    @State private var powered = false           // screen "on" (content visible)
    @State private var titleOn = false           // title block shown
    @State private var flickerOn = true          // title flicker toggle
    @State private var fadingOut = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Opaque screen-coloured backdrop that hides the app until the
                // boot completes.
                theme.screen
                    .overlay(theme.screenDark.opacity(powered ? 0 : 1))

                // Powering-on title.
                VStack(spacing: 10) {
                    // A little pixel "cartridge" mark: a block with the play
                    // triangle, echoing the Doodle's cartridge/play motif.
                    ZStack {
                        Rectangle()
                            .fill(theme.workAccent)
                            .frame(width: 44, height: 44)
                            .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 3))
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(powered ? 1 : 0.6)
                    .opacity(powered ? 1 : 0)

                    Text("FOCUS PANEL")
                        .font(PixelFont.font(size: 12))
                        .foregroundStyle(.white)
                        .opacity(titleOn ? (flickerOn ? 1 : 0.35) : 0)

                    Text("INSERT CARTRIDGE")
                        .font(PixelFont.font(size: 6))
                        .foregroundStyle(theme.paper.opacity(0.8))
                        .opacity(titleOn ? 1 : 0)
                }

                // CRT scan-line sweep (skipped under Reduce Motion).
                if !reduceMotion {
                    Rectangle()
                        .fill(.white.opacity(0.18))
                        .frame(height: 3)
                        .position(x: geo.size.width / 2, y: scanY * geo.size.height)
                        .opacity(powered ? 0 : 1)
                }
            }
            .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 3))
            .opacity(fadingOut ? 0 : 1)
            .onAppear { run() }
        }
    }

    private func run() {
        if reduceMotion {
            // Minimal, motion-free variant: show the title briefly, then fade.
            powered = true
            titleOn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeInOut(duration: 0.35)) { fadingOut = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onFinished() }
            }
            return
        }

        // 1) Scan line sweeps down as the screen powers on.
        withAnimation(.easeIn(duration: 0.45)) {
            scanY = 1.1
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
            powered = true
        }

        // 2) Title appears and flickers a few times (cartridge-boot feel).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            titleOn = true
            flicker(times: 4)
        }

        // 3) Hold briefly, then fade the whole overlay out.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.easeInOut(duration: 0.4)) { fadingOut = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onFinished() }
        }
    }

    private func flicker(times: Int) {
        guard times > 0 else { flickerOn = true; return }
        withAnimation(.linear(duration: 0.08)) { flickerOn.toggle() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            flicker(times: times - 1)
        }
    }
}
