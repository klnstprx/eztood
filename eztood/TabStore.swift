import Foundation
import Combine
import Foundation

final class TabStore: ObservableObject {

    /// A single named tab containing a list of tasks.
    struct Tab: Identifiable, Codable {
        let id: UUID
        var name: String
        var tasks: [TaskStore.Task]

        init(id: UUID = UUID(), name: String, tasks: [TaskStore.Task] = []) {
            self.id = id
            self.name = name
            self.tasks = tasks
        }
    }

    // MARK: - Published state

    @Published private(set) var tabs: [Tab]
    @Published var selectedTabID: Tab.ID

    // File-based storage URL under Application Support/eztood/tabs.json
    private let storageURL: URL = {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("eztood", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("tabs.json")
    }()

    private struct Storage: Codable {
        var tabs: [Tab]
        var selectedTabID: Tab.ID
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load persisted state if available
        if let data = try? Data(contentsOf: storageURL),
           let stored = try? JSONDecoder().decode(Storage.self, from: data) {
            self.tabs = stored.tabs
            self.selectedTabID = stored.selectedTabID
        } else {
            let defaultTab = Tab(name: "Home")
            self.tabs = [defaultTab]
            self.selectedTabID = defaultTab.id
        }
        // Observe changes and persist
        Publishers.CombineLatest($tabs, $selectedTabID)
            .sink { [weak self] tabs, selected in
                guard let self = self else { return }
                let stored = Storage(tabs: tabs, selectedTabID: selected)
                if let data = try? JSONEncoder().encode(stored) {
                    try? data.write(to: self.storageURL)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Tab operations

    func addTab(named baseName: String = "Tab") {
        var index = 1
        var proposed = baseName
        let names = tabs.map { $0.name }
        while names.contains(proposed) {
            index += 1
            proposed = "\(baseName) \(index)"
        }
        let tab = Tab(name: proposed)
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func close(tabID: Tab.ID?) {
        guard let id = tabID, tabs.count > 1,
              let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: idx)
        // Adjust selection
        let newIndex = min(idx, tabs.count - 1)
        selectedTabID = tabs[newIndex].id
    }

    // MARK: - Access helpers

    private func indexOfCurrent() -> Int? {
        tabs.firstIndex { $0.id == selectedTabID }
    }

    var tasks: [TaskStore.Task] {
        get { tabs.first(where: { $0.id == selectedTabID })?.tasks ?? [] }
        set {
            guard let idx = indexOfCurrent() else { return }
            tabs[idx].tasks = newValue
        }
    }

    // MARK: - Task mutations (forwarded to current tab)

    func addTask(_ title: String) {
        guard let idx = indexOfCurrent() else { return }
        let store = TaskStore()
        store.tasks = tabs[idx].tasks
        store.add(title: title)
        tabs[idx].tasks = store.tasks
    }

    func deleteTask(taskID: TaskStore.Task.ID?) {
        guard let taskID, let idx = indexOfCurrent() else { return }
        let store = TaskStore()
        store.tasks = tabs[idx].tasks
        store.delete(taskID: taskID)
        tabs[idx].tasks = store.tasks
    }

    func toggle(taskID: TaskStore.Task.ID?) {
        guard let idx = indexOfCurrent() else { return }
        let store = TaskStore()
        store.tasks = tabs[idx].tasks
        store.toggleDone(taskID: taskID)
        tabs[idx].tasks = store.tasks
    }

    func moveTasks(fromOffsets: IndexSet, toOffset: Int) {
        guard let idx = indexOfCurrent() else { return }
        var list = tabs[idx].tasks
        list.move(fromOffsets: fromOffsets, toOffset: toOffset)
        tabs[idx].tasks = list
    }

    func move(taskID: TaskStore.Task.ID?, by delta: Int) {
        guard let idx = indexOfCurrent() else { return }
        let store = TaskStore()
        store.tasks = tabs[idx].tasks
        store.move(taskID: taskID, by: delta)
        tabs[idx].tasks = store.tasks
    }
}
