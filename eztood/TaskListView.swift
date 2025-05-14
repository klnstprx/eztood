import SwiftUI
import UniformTypeIdentifiers

/// A scrollable, draggable list of tasks with support for selection, deletion, and toggling.
struct TaskListView: View {
    @Binding var tasks: [TaskStore.Task]
    @Binding var selection: TaskStore.Task.ID?
    var deleteTask: (TaskStore.Task.ID?) -> Void
    var toggleTask: (TaskStore.Task.ID?) -> Void

    @State private var draggedTask: TaskStore.Task?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Metrics.rowVerticalPadding) {
                ForEach(tasks) { task in
                    let isSelected = (selection == task.id)
                    let baseRow = TaskRow(
                        task: task,
                        isSelected: isSelected,
                        deleteAction: { deleteTask(task.id) },
                        toggleAction: { toggleTask(task.id) }
                    )

                    let decorated = baseRow
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? Theme.accent.opacity(0.25) : Color.clear)
                        .contentShape(Rectangle())
                        .opacity(draggedTask?.id == task.id ? 0 : 1)

                    let interactive = decorated
                        .onDrag {
                            draggedTask = task
                            return NSItemProvider(object: task.title as NSString)
                        }
                        .onDrop(
                            of: [UTType.plainText],
                            delegate: TaskDropDelegate(
                                targetTask: task,
                                tasks: $tasks,
                                draggedTask: $draggedTask,
                                selection: $selection
                            )
                        )

                    DraggableRowHost(content: interactive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .scrollClipDisabled(true)
    }
}
