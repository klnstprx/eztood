import SwiftUI
import UniformTypeIdentifiers

struct TaskDropDelegate: DropDelegate {
    let targetTask: TaskStore.Task                    // Row being hovered over
    @Binding var tasks: [TaskStore.Task]              // All tasks in current tab
    @Binding var draggedTask: TaskStore.Task?         // Task currently dragged
    @Binding var selection: TaskStore.Task.ID?        // Keeps selection following drag

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask, dragged != targetTask else { return }

        if let from = tasks.firstIndex(of: dragged),
           let to   = tasks.firstIndex(of: targetTask) {
            withAnimation(.easeInOut(duration: 0.15)) {
                tasks.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        selection = draggedTask?.id
        draggedTask = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool { true }
}
