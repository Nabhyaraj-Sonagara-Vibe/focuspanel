import SwiftUI
import FocusPanelCore

/// The root view of the compact floating panel. Styled as a retro
/// cartridge-console: a wood/amber outer "case" (the window chrome) framing
/// a circuit-board-green "screen" that hosts the timer/tasks content —
/// directly inspired by Google's Jerry Lawson Doodle (Fairchild Channel F,
/// the first cartridge-based home console Lawson helped create). Hard
/// edges, thick black outlines, flat colors — no soft gradients or blur.
struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var tab: Tab = .timer
    @State private var showSettings = false

    enum Tab: String, CaseIterable { case timer = "TIMER", tasks = "TASKS" }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            screen
        }
        .background(Theme.caseAmber)
        .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 3))
        .frame(width: 300)
        .frame(minHeight: 480)
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
            SettingsPane().environmentObject(state)
        }
        .onAppear { PixelFont.registerIfNeeded() }
    }

    /// The wood-console "handle" strip. This is the ONLY draggable region
    /// (see AppDelegate: `isMovableByWindowBackground` is off, so the
    /// window drags from here explicitly rather than stealing clicks from
    /// buttons elsewhere in the panel).
    private var titleBar: some View {
        HStack(spacing: 8) {
            // Cartridge-slot ridges, purely decorative — echoes the ribbed
            // console-front detailing in the Doodle reference.
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(Theme.caseAmberDark).frame(width: 3, height: 14)
                }
            }
            Text("FOCUS PANEL")
                .font(PixelFont.font(size: 9))
                .foregroundStyle(Theme.pixelBlack)
            Spacer()
            PixelIconButton(systemImage: "slider.horizontal.3", tint: Theme.caseAmberDark) {
                showSettings.toggle()
            }
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(WindowDragHandle())
        .overlay(Rectangle().frame(height: 3).foregroundStyle(Theme.pixelBlack), alignment: .bottom)
    }

    /// The circuit-board-green "screen" — everything interactive lives here.
    private var screen: some View {
        VStack(spacing: 12) {
            picker

            Group {
                switch tab {
                case .timer: TimerCard()
                case .tasks: TodoPane()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(screenBackground)
    }

    private var picker: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button {
                    tab = t
                } label: {
                    Text(t.rawValue)
                        .font(PixelFont.font(size: 8))
                        .foregroundStyle(tab == t ? .white : Theme.pixelBlack.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(tab == t ? state.accent : Theme.cream)
                        .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Pixelated circuit-board texture: a solid green base with a sparse
    /// grid of lighter "trace" squares, echoing the Doodle's screen.
    private var screenBackground: some View {
        ZStack {
            Theme.screenGreen
            GeometryReader { geo in
                let step: CGFloat = 18
                Path { p in
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += step
                    }
                }
                .stroke(Theme.screenGreenLight.opacity(0.25), lineWidth: 1)
            }
        }
        .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 3))
    }
}

/// An `NSViewRepresentable` that makes exactly its own frame draggable,
/// instead of the whole window background. Keeps drag-to-move working from
/// the title bar without swallowing clicks anywhere else in the panel (the
/// original bug: `NSWindow.isMovableByWindowBackground` intercepts mouseDown
/// on any non-hit-testing view first, including translucent SwiftUI rows).
private struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragHandleView { DragHandleView() }
    func updateNSView(_ nsView: DragHandleView, context: Context) {}

    final class DragHandleView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
