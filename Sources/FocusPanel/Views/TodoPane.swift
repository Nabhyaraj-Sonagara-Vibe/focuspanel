import SwiftUI
import FocusPanelCore

/// Compact, scrollable checklist that lives below the timer in the same slim
/// footprint. Add a task, tick it off, delete it.
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
                                    onToggle: { state.toggleTodo(item.id) },
                                    onDelete: { state.deleteTodo(item.id) })
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 180)
            }
        }
    }

    private var header: some View {
        HStack {
            Label("Tasks", systemImage: "checklist")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            if state.todos.completedCount > 0 {
                Button("Clear done") { state.clearCompletedTodos() }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Text("\(state.todos.remainingCount) left")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Add a task…", text: $newTitle)
                .textFieldStyle(.plain)
                .font(.callout)
                .foregroundStyle(.white)
                .focused($inputFocused)
                .onSubmit(commit)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.08)))

            Button(action: commit) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Theme.gradient(for: .work)))
            }
            .buttonStyle(.plain)
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Theme.gradient(for: .shortBreak))
            Text("No tasks yet")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
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
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(item.isDone
                                     ? AnyShapeStyle(Theme.gradient(for: .shortBreak))
                                     : AnyShapeStyle(Color.white.opacity(0.4)))
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.callout)
                .foregroundStyle(item.isDone ? .white.opacity(0.4) : .white.opacity(0.9))
                .strikethrough(item.isDone, color: .white.opacity(0.4))
                .lineLimit(2)

            Spacer(minLength: 4)

            if hovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .help("Delete task")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(hovering ? 0.10 : 0.05)))
        .onHover { hovering = $0 }
    }
}
