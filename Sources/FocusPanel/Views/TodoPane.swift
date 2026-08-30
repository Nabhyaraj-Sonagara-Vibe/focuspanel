import SwiftUI
import FocusPanelCore

/// Compact, scrollable checklist that lives below the timer in the same slim
/// footprint. Pixel-console styled with large, reliable hit targets, coloured
/// by the active theme.
struct TodoPane: View {
    @EnvironmentObject var state: AppState
    @Environment(\.pixelTheme) private var theme
    @State private var newTitle: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            header
            inputRow

            if state.todos.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(state.todos.items) { item in
                            TodoRow(item: item,
                                    accent: state.accent,
                                    theme: theme,
                                    onToggle: { state.toggleTodo(item.id) },
                                    onDelete: { state.deleteTodo(item.id) })
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 220)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("TASKS")
                .font(PixelFont.font(size: 8))
                .foregroundStyle(.white)
            Spacer()
            if state.todos.completedCount > 0 {
                Button("CLEAR") { state.clearCompletedTodos() }
                    .buttonStyle(.plain)
                    .font(PixelFont.font(size: 6))
                    .foregroundStyle(theme.paper.opacity(0.7))
            }
            Text("\(state.todos.remainingCount) LEFT")
                .font(PixelFont.font(size: 6))
                .foregroundStyle(theme.paper.opacity(0.6))
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Add a task…", text: $newTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Theme.pixelBlack)
                .focused($inputFocused)
                .onSubmit(commit)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(theme.paper)
                .overlay(Rectangle().stroke(Theme.pixelBlack, lineWidth: 2))

            PixelButton(systemImage: "plus", tint: state.accent) {
                commit()
            }
            .opacity(newTitle.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(theme.paper.opacity(0.6))
            Text("NO TASKS YET")
                .font(PixelFont.font(size: 7))
                .foregroundStyle(theme.paper.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }

    private func commit() {
        state.addTodo(newTitle)
        newTitle = ""
        inputFocused = true
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let accent: Color
    let theme: PixelTheme
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Full 32x32 hit area (see PixelControls.swift) — reliably tappable.
            PixelCheckbox(isChecked: item.isDone, accent: accent, action: onToggle)

            Text(item.title)
                .font(.system(size: 12))
                .foregroundStyle(item.isDone ? theme.paper.opacity(0.45) : .white)
                .strikethrough(item.isDone, color: .white.opacity(0.5))
                .lineLimit(2)

            Spacer(minLength: 4)

            // Always visible (not hover-only), so its position never shifts
            // out from under a tap.
            PixelIconButton(systemImage: "trash", action: onDelete)
                .help("Delete task")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(item.isDone ? theme.screenDark.opacity(0.6) : theme.screenLight.opacity(0.35))
        .overlay(Rectangle().stroke(Theme.pixelBlack.opacity(0.4), lineWidth: 1.5))
        // Explicit hit-testable background for the whole row; with the window's
        // drag gesture scoped to just the title bar, this row reliably receives
        // its own clicks.
        .contentShape(Rectangle())
    }
}
