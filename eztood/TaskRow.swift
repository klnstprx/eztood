//
//  TaskRow.swift
//  eztood
//
//  Extracted from ContentView for clarity – shows a single task with action buttons.
//

import SwiftUI

private typealias Metrics = Theme.Metrics

/// A single row representing `TaskStore.Task`.
struct TaskRow: View {
    let task: TaskStore.Task
    let isSelected: Bool
    var deleteAction: () -> Void
    var toggleAction: () -> Void

    @State private var isHovering = false

    private var textColor: Color {
        task.isDone ? Theme.accent : Theme.contrast
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(task.title)
                .font(.body)
                .strikethrough(task.isDone)
                .foregroundColor(textColor)

            Spacer(minLength: 4)

            if isHovering || isSelected {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Metrics.rowVerticalPadding)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}
