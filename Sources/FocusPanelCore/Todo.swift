import Foundation

/// A single checklist task.
public struct TodoItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isDone: Bool
    public let createdAt: Date

    public init(id: UUID = UUID(),
                title: String,
                isDone: Bool = false,
                createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
    }
}

/// An ordered list of tasks with the small set of mutations the UI needs.
/// Value type + pure mutations = trivially testable.
public struct TodoList: Codable, Equatable, Sendable {
    public private(set) var items: [TodoItem]

    public init(items: [TodoItem] = []) {
        self.items = items
    }

    /// Append a task. Whitespace is trimmed and empty titles are rejected.
    /// Returns the created item, or `nil` if the title was blank.
    @discardableResult
    public mutating func add(_ title: String) -> TodoItem? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let item = TodoItem(title: trimmed)
        items.append(item)
        return item
    }

    /// Flip the done state of the task with the given id (no-op if absent).
    public mutating func toggle(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isDone.toggle()
    }

    /// Remove the task with the given id (no-op if absent).
    public mutating func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    /// Reorder tasks (used by drag-to-reorder in the UI). Implemented without
    /// SwiftUI's `Array.move(fromOffsets:toOffset:)` so the core stays
    /// Foundation-only and independently testable.
    public mutating func move(from source: IndexSet, to destination: Int) {
        let moving = source.sorted().map { items[$0] }
        // Number of removed elements before the destination shifts the insert point.
        let insertOffset = source.filter { $0 < destination }.count
        for index in source.sorted(by: >) {
            items.remove(at: index)
        }
        let insertionIndex = max(0, min(destination - insertOffset, items.count))
        items.insert(contentsOf: moving, at: insertionIndex)
    }

    /// Drop every completed task.
    public mutating func clearCompleted() {
        items.removeAll { $0.isDone }
    }

    public var remainingCount: Int { items.lazy.filter { !$0.isDone }.count }
    public var completedCount: Int { items.lazy.filter { $0.isDone }.count }
}
