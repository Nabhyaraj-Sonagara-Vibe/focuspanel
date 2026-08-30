import SwiftUI
import FocusPanelCore

/// The root view of the compact floating panel. Styled as a retro
/// cartridge-console: a console "case" (the window chrome) framing a
/// "screen" that hosts the timer/tasks content — inspired by Google's Jerry
/// Lawson Doodle (Fairchild Channel F). The exact palette comes from the
/// active `PixelTheme`, injected into the environment here so a theme swap
/// restyles every child view.
struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var tab: Tab = .timer
    @State private var showSettings = false
    @State private var showIntro = true

    enum Tab: String, CaseIterable { case timer = "TIMER", tasks = "TASKS" }

    var body: some View {
        let theme = state.theme
        ZStack {
            VStack(spacing: 0) {
                titleBar(theme)
                screen(theme)
            }
            .background(theme.caseColor)
            .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 3))

            // Little boot/intro animation, shown once on launch. Purely
            // additive — it overlays the panel, then removes itself.
            if showIntro {
                IntroAnimation(theme: theme) {
                    showIntro = false
                }
                .transition(.opacity)
            }
        }
        .frame(width: 300)
        .frame(minHeight: 480)
        .environment(\.pixelTheme, theme)
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
            SettingsPane()
                .environmentObject(state)
                .environment(\.pixelTheme, theme)
        }
        .onAppear { PixelFont.registerIfNeeded() }
    }

    /// The console "handle" strip. This is the ONLY draggable region (see
    /// AppDelegate: `isMovableByWindowBackground` is off, so the window drags
    /// from here explicitly rather than stealing clicks from buttons
    /// elsewhere in the panel).
    private func titleBar(_ theme: PixelTheme) -> some View {
        HStack(spacing: 8) {
            // Cartridge-slot ridges, purely decorative.
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(theme.caseDark).frame(width: 3, height: 14)
                }
            }
            Text("FOCUS PANEL")
                .font(PixelFont.font(size: 9))
                .foregroundStyle(Theme.pixelBlack)
            Spacer()
            PixelIconButton(systemImage: "slider.horizontal.3", tint: theme.caseDark) {
                showSettings.toggle()
            }
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(WindowDragHandle())
        .overlay(Rectangle().frame(height: 3).foregroundStyle(Theme.pixelBlack), alignment: .bottom)
    }

    /// The "screen" — everything interactive lives here.
    private func screen(_ theme: PixelTheme) -> some View {
        VStack(spacing: 12) {
            picker(theme)

            Group {
                switch tab {
                case .timer: TimerCard()
                case .tasks: TodoPane()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(screenBackground(theme))
    }

    private func picker(_ theme: PixelTheme) -> some View {
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
                        .background(tab == t ? state.accent : theme.paper)
                        .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Pixelated circuit-board texture: a solid base with a sparse grid of
    /// lighter "trace" lines, tinted by the active theme's screen colours.
    private func screenBackground(_ theme: PixelTheme) -> some View {
        ZStack {
            theme.screen
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
                .stroke(theme.screenLight.opacity(0.25), lineWidth: 1)
            }
        }
        .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 3))
    }
}

/// An `NSViewRepresentable` that makes exactly its own frame draggable,
/// instead of the whole window background. Keeps drag-to-move working from
/// the title bar without swallowing clicks anywhere else in the panel.
private struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragHandleView { DragHandleView() }
    func updateNSView(_ nsView: DragHandleView, context: Context) {}

    final class DragHandleView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
