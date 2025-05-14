//
//  TaskDragAndDrop.swift
//  eztood
//
//  Contains drag & drop helpers for reordering tasks.
//

import SwiftUI
import UniformTypeIdentifiers

/// Drop delegate that enables reordering inside the task list (macOS & iOS).
struct TaskDropDelegate: DropDelegate {
    /// The row we are currently hovering over.
    let targetTask: TaskStore.Task
    /// Reference to the shared data model.
    let store: TaskStore
    /// Binding to the task being dragged (set in `onDrag`).
    @Binding var draggedTask: TaskStore.Task?
    /// Binding to the currently selected task so the selection follows the drag.
    @Binding var selection: TaskStore.Task.ID?

    // Called whenever the drag enters a row’s bounds.
    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask, dragged != targetTask else { return }

        if let from = store.tasks.firstIndex(of: dragged),
           let to = store.tasks.firstIndex(of: targetTask) {
            // Animate to keep visual smoothness now that performance is acceptable.
            withAnimation(.easeInOut(duration: 0.15)) {
                store.move(fromOffsets: IndexSet(integer: from),
                           toOffset: to > from ? to + 1 : to)
            }
        }
    }

    // Finalise – clear state & keep selection on moved item.
    func performDrop(info: DropInfo) -> Bool {
        selection = draggedTask?.id
        draggedTask = nil
        return true
    }

    // Tell the system this is a move-operation inside the same list.
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        true // Accept all moves of plain text items.
    }
}
