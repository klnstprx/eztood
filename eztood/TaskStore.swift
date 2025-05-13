//
//  TaskStore.swift
//  eztood
//
//  Created by Ignacy Borzestowski on 13/05/2025.
//

import SwiftUI

    /// Simple in-memory list of tasks
    final class TaskStore: ObservableObject {
    struct Task: Identifiable, Hashable, Equatable {
        let id = UUID()
        var title: String
        var isDone: Bool = false
    }

        @Published var tasks: [Task] = []

        func add(title: String) {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            tasks.append(Task(title: trimmed))
        }

        func delete(at offsets: IndexSet) {
            tasks.remove(atOffsets: offsets)
        }

        func delete(taskID: Task.ID?) {
            guard let id = taskID, let index = tasks.firstIndex(where: { $0.id == id }) else { return }
            tasks.remove(at: index)
        }

        func toggleDone(taskID: Task.ID?) {
            guard let id = taskID, let index = tasks.firstIndex(where: { $0.id == id }) else { return }
            tasks[index].isDone.toggle()
        }

    }
