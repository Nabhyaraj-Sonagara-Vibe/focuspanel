import SwiftUI

/// Reusable pixel-art UI primitives shared by every pane, styled after the
/// Google "Jerry Lawson" Doodle's console/cartridge look: thick black
/// outlines, hard corners (no rounded-rect blur), and a light/dark bevel
/// pair standing in for pixel-shaded highlights and shadows instead of
/// smooth gradients or blurs.

/// A blocky panel with a thick black border and a two-tone bevel edge —
/// the "screen" or "cartridge" surface everything else sits on.
struct PixelPanel<Content: View>: View {
    var fill: Color
    var border: Color = Theme.pixelBlack
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(fill)
            .overlay(PixelBevel(light: fill.opacity(0.35), dark: .black.opacity(0.35)))
            .overlay(Rectangle().stroke(border, lineWidth: 3))
    }
}

/// A thin inset highlight (top/left) + shadow (bottom/right) that reads as a
/// chunky pixel-art bevel at small sizes, instead of a soft drop shadow.
private struct PixelBevel: View {
    let light: Color
    let dark: Color

    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: geo.size.height))
                p.addLine(to: .zero)
                p.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(light, lineWidth: 2)

            Path { p in
                p.move(to: CGPoint(x: geo.size.width, y: 0))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                p.addLine(to: CGPoint(x: 0, y: geo.size.height))
            }
            .stroke(dark, lineWidth: 2)
        }
    }
}

/// A chunky, hard-edged pixel-art button: flat fill, thick outline, and a
/// pressed state that shifts down-right by a couple of points (the classic
/// "cartridge button" press) instead of an opacity fade.
struct PixelButton: View {
    var label: String? = nil
    var systemImage: String? = nil
    var tint: Color
    var textColor: Color = .white
    var isProminent: Bool = false
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(PixelFont.font(size: 11))
                }
                if let label {
                    Text(label)
                        .font(PixelFont.font(size: 9))
                }
            }
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minWidth: 0)
            .background(tint)
            .overlay(
                Rectangle().stroke(Theme.pixelBlack, lineWidth: 2)
            )
            .overlay(alignment: .topLeading) {
                // Pixel highlight sliver, top-left, like a sprite's rim light.
                Rectangle()
                    .fill(.white.opacity(0.35))
                    .frame(height: 2)
            }
            .offset(x: pressed ? 2 : 0, y: pressed ? 2 : 0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

/// A square pixel-art checkbox: an empty black-bordered box, or a filled
/// block with a chunky pixel checkmark — deliberately blocky, not a smooth
/// SF Symbol circle, so it reads as "part of the console" rather than a
/// generic macOS control.
struct PixelCheckbox: View {
    var isChecked: Bool
    var accent: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(isChecked ? accent : Theme.pixelBlack.opacity(0.25))
                    .frame(width: 20, height: 20)
                    .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 2))

                if isChecked {
                    // Blocky checkmark built from two rectangles, pixel-style.
                    PixelCheckmark()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter))
                        .frame(width: 12, height: 10)
                }
            }
        }
        .buttonStyle(.plain)
        // Enlarges the hit target well beyond the visible 20x20 box so a
        // slightly-off tap still registers — the earlier build's rows had
        // tight/overlapping hit areas that made checking a task feel unreliable.
        .contentShape(Rectangle().size(width: 32, height: 32))
        .frame(width: 32, height: 32)
    }
}

private struct PixelCheckmark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        p.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        return p
    }
}

/// A small square pixel-art icon button (delete, settings, etc.) — same
/// hard-edged + bevel language as `PixelButton` but icon-only and square.
struct PixelIconButton: View {
    var systemImage: String
    var tint: Color = Theme.pixelBlack.opacity(0.35)
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(tint)
                .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
