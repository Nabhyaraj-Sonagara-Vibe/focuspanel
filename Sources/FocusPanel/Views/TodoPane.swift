import SwiftUI
import FocusPanelCore

/// Compact, scrollable checklist that lives below the timer in the same
/// slim footprint. Rebuilt in the pixel-console style with much larger,
/// reliable hit targets — the earlier build's icon-only SF Symbol toggle
/// (17pt glyph, no padding) and hover-only delete button made rows hard to
/// click precisely, compounded by the window-wide drag gesture (see
/// AppDelegate/ContentView) that could swallow a quick tap as a drag.
struct TodoPane: View {
    @EnvironmentObject var state: AppState
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
                    .foregroundStyle(Theme.cream.opacity(0.7))
            }
            Text("\(state.todos.remainingCount) LEFT")
                .font(PixelFont.font(size: 6))
                .foregroundStyle(Theme.cream.opacity(0.6))
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
                .background(Theme.cream)
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
                .foregroundStyle(Theme.cream.opacity(0.6))
            Text("NO TASKS YET")
                .font(PixelFont.font(size: 7))
                .foregroundStyle(Theme.cream.opacity(0.6))
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
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // BUG FIX: was a bare 17pt SF Symbol button with no padding —
            // a precise, easy-to-miss tap target. PixelCheckbox gives a
            // full 32x32 hit area (see PixelControls.swift).
            PixelCheckbox(isChecked: item.isDone, accent: accent, action: onToggle)

            Text(item.title)
                .font(.system(size: 12))
                .foregroundStyle(item.isDone ? Theme.cream.opacity(0.45) : .white)
                .strikethrough(item.isDone, color: .white.opacity(0.5))
                .lineLimit(2)

            Spacer(minLength: 4)

            // BUG FIX: was hover-only (`if hovering { ... }`), which is
            // unreliable for trackpad/quick taps and shifts row layout the
            // instant the cursor arrives, causing the tap to land on empty
            // space. Now always visible, so its position never moves.
            PixelIconButton(systemImage: "trash", action: onDelete)
                .help("Delete task")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(item.isDone ? Theme.screenGreenDark.opacity(0.6) : Theme.screenGreenLight.opacity(0.35))
        .overlay(Rectangle().stroke(Theme.pixelBlack.opacity(0.4), lineWidth: 1.5))
        // Explicit hit-testable background for the whole row — with the
        // window's own drag gesture now scoped to just the title bar (see
        // ContentView.WindowDragHandle), this row reliably receives its own
        // clicks instead of the window intercepting them.
        .contentShape(Rectangle())
    }
}
