
//
//  ContentView.swift
//  eztood
//
//  Created by Ignacy Borzestowski on 13/05/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

private typealias Metrics = Theme.Metrics


    struct ContentView: View {
        @StateObject private var store = TaskStore()
        @State private var newTask = ""
        @State private var selection: TaskStore.Task.ID?
        @FocusState private var inputFocused: Bool
    @State private var keyMonitor: Any?

        var body: some View {
        VStack(spacing: 8) {
            TextField("New task", text: $newTask, onCommit: addTask)
                .textFieldStyle(.plain)
                .padding(.vertical, Metrics.textFieldPaddingV)
                .padding(.horizontal, Metrics.textFieldPaddingH)
                .background(Theme.base.opacity(0.3))
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .focused($inputFocused)
                .padding(.all)

                List(selection: $selection) {
                    ForEach(store.tasks) { task in
                        let isSel = (selection == task.id)
                        TaskRow(
                            task: task,
                            isSelected: isSel,
                            deleteAction: { deleteTask(task.id) },
                            toggleAction: { store.toggleDone(taskID: task.id) }
                        )
                        .tag(task.id)
                    }
                }
                // Minimal list appearance & background matches Base colour
                
                .listRowBackground(Color.clear)
                .background(Color.clear)
                .scrollClipDisabled(true)
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .listRowSeparator(.hidden)
            }
            // (Tab navigation handled via NSEvent monitor)
            .onAppear(perform: setupKeyMonitor)
            .onDisappear(perform: removeKeyMonitor)
        .ignoresSafeArea()
        .accentColor(Theme.accent)
        // Hidden keyboard shortcuts
        .hiddenShortcut(.delete, modifiers: .command) { deleteTask(selection) }
        .hiddenShortcut(.return, modifiers: .command) { store.toggleDone(taskID: selection) }
        .hiddenShortcut("n", modifiers: .command, action: beginNewTask)
        .hiddenShortcut("j", modifiers: .command) { moveSelection(1) }
        .hiddenShortcut("k", modifiers: .command) { moveSelection(-1) }
        .hiddenShortcut(.downArrow) { moveSelection(1) }
        .hiddenShortcut(.upArrow) { moveSelection(-1) }

        }

        private func addTask() {
            let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                // If empty, just focus the field so user can type
                inputFocused = true
                return
            }
            store.add(title: trimmed)

            // Clearing & refocusing must occur on the next run-loop tick so that
            // it wins against NSTextField trying to restore the committed value.
            DispatchQueue.main.async {
                newTask = ""
                inputFocused = true
                //
            }
        }

        private func beginNewTask() {
            // Clear any existing draft and put focus into the text field
            newTask = ""
            inputFocused = true
            //
        }

        private func deleteTask(_ id: TaskStore.Task.ID?) {
            guard let id = id, let idx = store.tasks.firstIndex(where: { $0.id == id }) else { return }

            // Perform deletion
            store.delete(taskID: id)

            // Decide next selection
            let tasks = store.tasks
            guard !tasks.isEmpty else {
                selection = nil
                return
            }

            let newIndex = min(idx, tasks.count - 1)
            selection = tasks[newIndex].id

            // keep current focus
        }

#if os(macOS)
        private func setupKeyMonitor() {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard event.keyCode == 48 else { return event } // 48 = Tab key

                if event.modifierFlags.contains(.shift) {
                    moveSelection(-1)
                } else {
                    moveSelection(1)
                }
                return nil // swallow so system focus traversal doesn't run
            }
        }

        private func removeKeyMonitor() {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
#else
        private func setupKeyMonitor() {}
        private func removeKeyMonitor() {}
#endif

        private func moveSelection(_ delta: Int) {
            guard !store.tasks.isEmpty else { return }

            let orderedIDs = store.tasks.map { $0.id }
            // If nothing selected → pick first or last depending on direction
            if selection == nil {
                selection = delta > 0 ? orderedIDs.first : orderedIDs.last
                return
            }

            guard let current = selection, let idx = orderedIDs.firstIndex(of: current) else {
                selection = orderedIDs.first
                return
            }

            let newIndexRaw = idx + delta
            let newIndex = min(max(newIndexRaw, 0), orderedIDs.count - 1)
            selection = orderedIDs[newIndex]

            // keep focus unchanged
        }



    }

// MARK: - Row that reveals action icons on hover

private struct TaskRow: View {
    let task: TaskStore.Task
    let isSelected: Bool
    var deleteAction: () -> Void
    var toggleAction: () -> Void

    @State private var hovering = false

    private var colorForText: Color {
        if task.isDone {
            return Theme.accent
        } else {
            return Theme.contrast
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(task.title)
                .font(.body)
                .strikethrough(task.isDone)
                .foregroundColor(colorForText)

            Spacer(minLength: 4)

            if hovering || isSelected {
                HStack(spacing: 6) {
                    Button(action: toggleAction) {
                        Image(systemName: task.isDone ? "arrow.uturn.left.circle" : "checkmark.circle")
                            .foregroundColor(Theme.accent)
                    }
                    .buttonStyle(.borderless)

                    Button(action: deleteAction) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(Theme.accent)
                    }
                    .buttonStyle(.borderless)
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, Metrics.rowVerticalPadding)
        .onHover { isOver in
            withAnimation(.easeInOut(duration: 0.1)) {
                hovering = isOver
            }
        }
    }
}
