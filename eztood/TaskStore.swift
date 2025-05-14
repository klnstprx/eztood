import Combine
import UniformTypeIdentifiers
import CoreTransferable

/// Simple in-memory storage for tasks.
final class TaskStore: ObservableObject {

    /// A single todo task, identifiable and codable for persistence.
    struct Task: Identifiable, Hashable, Equatable, Codable {
        var id = UUID()
        var title: String
        var isDone: Bool = false
    }

    // Published array consumed by UI.
    @Published var tasks: [Task] = []

    // MARK: - CRUD

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(Task(title: trimmed))
    }

    func delete(taskID: Task.ID?) {
        guard let id = taskID,
              let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks.remove(at: index)
    }

    func toggleDone(taskID: Task.ID?) {
        guard let id = taskID,
              let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isDone.toggle()
    }

    // MARK: - Reordering

    /// Reorders tasks by moving them from `fromOffsets` to `toOffset` (for drag & drop).
    func move(fromOffsets: IndexSet, toOffset: Int) {
        tasks.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    /// Moves the task with `taskID` up or down by `delta` positions.
    /// Positive `delta` moves the task towards the end; negative towards the beginning.
    func move(taskID: Task.ID?, by delta: Int) {
        guard delta != 0,
              let id = taskID,
              let currentIndex = tasks.firstIndex(where: { $0.id == id }) else { return }

        let newIndexRaw = currentIndex + delta
        let newIndex = min(max(newIndexRaw, 0), tasks.count - 1)
        guard newIndex != currentIndex else { return }

        let task = tasks.remove(at: currentIndex)
        tasks.insert(task, at: newIndex)
    }
}

// MARK: - Transferable conformance (macOS 14+, iOS 17+)

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension TaskStore.Task: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \TaskStore.Task.title)
    }
}
