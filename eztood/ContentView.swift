//
//  ContentView.swift
//  eztood
//
//  Cleaned-up version created by Codex on 13/05/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif
import UniformTypeIdentifiers

private typealias Metrics = Theme.Metrics

/// The main window content displaying the text-field for new items and the task list.
struct ContentView: View {

    // MARK: - State

    @StateObject private var store = TaskStore()
    @State private var newTask = ""
    @State private var selection: TaskStore.Task.ID?
    @FocusState private var inputFocused: Bool

    // Drag & keyboard helpers (macOS only)
    @State private var keyMonitors: [Any] = []
    @State private var draggedTask: TaskStore.Task?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            TextField("New task", text: $newTask, onCommit: addTask)
                .textFieldStyle(.plain)
                .background(Theme.base.opacity(0.3))
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .focused($inputFocused)
                .padding()

            taskListView
        }
        // MARK: Global view modifiers
        .onAppear(perform: setupKeyMonitor)
        .onDisappear(perform: removeKeyMonitor)
        .ignoresSafeArea()
        .accentColor(Theme.accent)
        // Hidden keyboard shortcuts
        .hiddenShortcut(.delete,  modifiers: .command) { deleteTask(selection) }
        .hiddenShortcut(.return,  modifiers: .command) { store.toggleDone(taskID: selection) }
        .hiddenShortcut("n",      modifiers: .command, action: beginNewTask)
        .hiddenShortcut("j",      modifiers: .command) { moveSelection(1) }
        .hiddenShortcut("k",      modifiers: .command) { moveSelection(-1) }
        .hiddenShortcut(.downArrow) { moveSelection(1) }
        .hiddenShortcut(.upArrow)   { moveSelection(-1) }
        // Reorder shortcuts – Cmd + ↑ / ↓
        .hiddenShortcut(.upArrow,   modifiers: .command) { moveTask(-1) }
        .hiddenShortcut(.downArrow, modifiers: .command) { moveTask(1) }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(store.tasks) { task in
                    taskRowView(for: task)
                }
            }
        }
        .scrollClipDisabled(true)
    }

    @ViewBuilder
    private func taskRowView(for task: TaskStore.Task) -> some View {
        let isSelected = (selection == task.id)

        // Base row UI (no gestures yet)
        let baseRow = TaskRow(
            task: task,
            isSelected: isSelected,
            deleteAction: { deleteTask(task.id) },
            toggleAction: { store.toggleDone(taskID: task.id) }
        )

        let decorated = baseRow
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Theme.accent.opacity(0.25) : Color.clear)
            .contentShape(Rectangle())
            .opacity(draggedTask?.id == task.id ? 0.0 : 1.0) // Hide while dragging
            // No mouse-click selection; keeps drag start instantaneous.

        // Modern draggable with immediate response. We piggy-back selection logic
        // into `onDragEnded` when no movement occurred.
        let interactive = decorated
            .onDrag { // Provide data & remember dragged item
                draggedTask = task
                return NSItemProvider(object: task.title as NSString)
            }
            .onDrop(
                of: [UTType.plainText],
                delegate: TaskDropDelegate(
                    targetTask: task,
                    store: store,
                    draggedTask: $draggedTask,
                    selection: $selection)
            )

        DraggableRowHost(content: interactive)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Intents

    private func addTask() {
        let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // If empty, just focus the field so user can type.
            inputFocused = true
            return
        }

        store.add(title: trimmed)

        // Clearing & refocusing must occur on the next run-loop tick so that
        // it wins against NSTextField trying to restore the committed value.
        DispatchQueue.main.async {
            newTask = ""
            inputFocused = true
        }
    }

    private func beginNewTask() {
        newTask = ""
        inputFocused = true
    }

    private func deleteTask(_ id: TaskStore.Task.ID?) {
        guard let id,
              let idx = store.tasks.firstIndex(where: { $0.id == id }) else { return }

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
    }

    // MARK: - Keyboard helpers

#if os(macOS)
    private func setupKeyMonitor() {
        let tabMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == 48 else { return event } // 48 = Tab key

            // Handle Tab navigation (without Cmd).
            if !event.modifierFlags.contains(.command) {
                if event.modifierFlags.contains(.shift) {
                    moveSelection(-1)
                } else {
                    moveSelection(1)
                }
                return nil // swallow – prevent system focus traversal
            }
            return event
        }

        // Additional monitor for Cmd + ↑ / ↓ to reorder quickly.
        let cmdArrowMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let isCmd = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)
            guard isCmd else { return event }

            switch event.keyCode {
            case 126: // Up arrow
                moveTask(-1)
                return nil
            case 125: // Down arrow
                moveTask(1)
                return nil
            default:
                return event
            }
        }

        keyMonitors = [tabMonitor, cmdArrowMonitor].compactMap { $0 }
    }

    private func removeKeyMonitor() {
        keyMonitors.forEach(NSEvent.removeMonitor(_:))
        keyMonitors.removeAll()
    }
#else
    private func setupKeyMonitor() {}
    private func removeKeyMonitor() {}
#endif

    // MARK: - Selection navigation

    private func moveSelection(_ delta: Int) {
        guard !store.tasks.isEmpty else { return }

        let orderedIDs = store.tasks.map { $0.id }

        // If nothing selected → pick first or last depending on direction
        if selection == nil {
            selection = delta > 0 ? orderedIDs.first : orderedIDs.last
            return
        }

        guard let current = selection,
              let idx = orderedIDs.firstIndex(of: current) else {
            selection = orderedIDs.first
            return
        }

        let newIndexRaw = idx + delta
        let newIndex = min(max(newIndexRaw, 0), orderedIDs.count - 1)
        selection = orderedIDs[newIndex]
    }

    private func moveTask(_ delta: Int) {
        store.move(taskID: selection, by: delta)

        // Update selection to follow moved task
        guard let id = selection,
              let idx = store.tasks.firstIndex(where: { $0.id == id }) else { return }

        let orderedIDs = store.tasks.map { $0.id }
        selection = orderedIDs[min(max(idx, 0), orderedIDs.count - 1)]
    }
}
