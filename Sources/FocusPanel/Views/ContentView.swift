import SwiftUI
import FocusPanelCore

/// The root view of the compact floating panel. A slim column: title bar with a
/// settings button, a segmented Timer/Tasks toggle, and the active pane. Sized
/// to feel like a tuck-in-the-corner companion widget.
struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var tab: Tab = .timer
    @State private var showSettings = false

    enum Tab: String, CaseIterable { case timer = "Timer", tasks = "Tasks" }

    var body: some View {
        VStack(spacing: 14) {
            titleBar
            picker

            Group {
                switch tab {
                case .timer: TimerCard()
                case .tasks: TodoPane()
                }
            }
            .transition(.opacity)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 300)
        .frame(minHeight: 460)
        .background(sessionAwareBackground)
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
            SettingsPane().environmentObject(state)
        }
    }

    private var titleBar: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "timer")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.gradient(for: state.session))
                Text("FocusPanel")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button { showSettings.toggle() } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }

    private var picker: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { tab = t }
                } label: {
                    Text(t.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tab == t ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            ZStack {
                                if tab == t {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.gradient(for: state.session))
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
    }

    /// Background blends the deep app gradient with a subtle wash of the current
    /// session's accent, so the whole panel shifts colour as sessions change.
    private var sessionAwareBackground: some View {
        ZStack {
            Theme.windowBackground
            Theme.accent(for: state.session).opacity(0.12)
            RadialGradient(colors: [state.accent.opacity(0.25), .clear],
                           center: .top, startRadius: 0, endRadius: 260)
        }
        .ignoresSafeArea()
    }
}
