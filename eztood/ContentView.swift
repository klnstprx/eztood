import SwiftUI

/// The main window content displaying the tab bar, new task entry, and task list.
struct ContentView: View {

    // MARK: - State

    @EnvironmentObject private var tabStore: TabStore
    @State private var newTask = ""
    @State private var selection: TaskStore.Task.ID?
    @FocusState private var inputFocused: Bool
    @State private var confirmClose = false


    // State for keyboard navigation and drag operations are handled in separate components.

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // Tab bar
            tabBar

            // New task entry
            NewTaskEntryView(
                newTask: $newTask,
                inputFocused: $inputFocused,
                onSubmit: addTask
            )

            TaskListView(
                tasks: Binding(
                    get: { tabStore.tasks },
                    set: { tabStore.tasks = $0 }
                ),
                selection: $selection,
                deleteTask: deleteTask,
                toggleTask: { tabStore.toggle(taskID: $0) }
            )

            if confirmClose {
                Text("Press ⌘W again to close tab")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        // MARK: Global view modifiers
        .keyboardNavigator(
            onTabPrev: { moveSelection(-1) },
            onTabNext: { moveSelection(1) },
            onReorderUp: { moveTask(-1) },
            onReorderDown: { moveTask(1) }
        )
        .ignoresSafeArea()
        .accentColor(Theme.accent)
        // Hidden keyboard shortcuts
        .hiddenShortcut(.delete,  modifiers: .command) { deleteTask(selection) }
        .hiddenShortcut(.return,  modifiers: .command) { tabStore.toggle(taskID: selection) }
        .hiddenShortcut("n",      modifiers: .command, action: beginNewTask)
        .hiddenShortcut("j",      modifiers: .command) { moveSelection(1) }
        .hiddenShortcut("k",      modifiers: .command) { moveSelection(-1) }
        .hiddenShortcut(.downArrow) { moveSelection(1) }
        .hiddenShortcut(.upArrow)   { moveSelection(-1) }
        // Reorder shortcuts – Cmd + ↑ / ↓
        .hiddenShortcut(.upArrow,   modifiers: .command) { moveTask(-1) }
        .hiddenShortcut(.downArrow, modifiers: .command) { moveTask(1) }
        // Tab management shortcuts
        .hiddenShortcut("t", modifiers: .command) { tabStore.addTab() }
        .hiddenShortcut("w", modifiers: .command) { attemptCloseTab() }
        // Switch tabs: ⌘H = left, ⌘L = right
        .hiddenShortcut("h", modifiers: .command) { selectTab(delta: -1) }
        .hiddenShortcut("l", modifiers: .command) { selectTab(delta: 1) }
    }

    // MARK: - Sub-views

    /// Tab bar view extracted for clarity.
    private var tabBar: some View {
        TabBarView(
            tabs: tabStore.tabs,
            selectedTabID: tabStore.selectedTabID,
            onSelectTab: { tabStore.selectedTabID = $0 }
        )
    }


    // MARK: - Intents

    private func addTask() {
        let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // If empty, just focus the field so user can type.
            inputFocused = true
            return
        }

        tabStore.addTask(trimmed)

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

    // MARK: - Tab close confirmation

    private func attemptCloseTab() {
        if tabStore.tasks.isEmpty { // nothing in tab → close directly
            tabStore.close(tabID: tabStore.selectedTabID)
            confirmClose = false
            return
        }

        if confirmClose {
            tabStore.close(tabID: tabStore.selectedTabID)
            confirmClose = false
        } else {
            confirmClose = true
            // Auto-reset confirmation after a short window (3 s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                confirmClose = false
            }
        }
    }

    private func deleteTask(_ id: TaskStore.Task.ID?) {
        guard let id,
              let idx = tabStore.tasks.firstIndex(where: { $0.id == id }) else { return }

        // Perform deletion
        tabStore.deleteTask(taskID: id)

        // Decide next selection
        let tasks = tabStore.tasks
        guard !tasks.isEmpty else {
            selection = nil
            return
        }

        let newIndex = min(idx, tasks.count - 1)
        selection = tasks[newIndex].id
    }

    // Keyboard monitoring and drag state are handled by child views and modifiers.

    // MARK: - Selection navigation

    private func moveSelection(_ delta: Int) {
        guard !tabStore.tasks.isEmpty else { return }

        let orderedIDs = tabStore.tasks.map { $0.id }

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
        tabStore.move(taskID: selection, by: delta)

        // Update selection to follow moved task
            guard let id = selection,
              let idx = tabStore.tasks.firstIndex(where: { $0.id == id }) else { return }

        let orderedIDs = tabStore.tasks.map { $0.id }
        selection = orderedIDs[min(max(idx, 0), orderedIDs.count - 1)]
    }

    /// Switches the active tab by a delta (-1 = previous, +1 = next).
    private func selectTab(delta: Int) {
        let tabs = tabStore.tabs
        guard let currentIndex = tabs.firstIndex(where: { $0.id == tabStore.selectedTabID }) else { return }
        let newIndex = min(max(currentIndex + delta, 0), tabs.count - 1)
        tabStore.selectedTabID = tabs[newIndex].id
    }
}
