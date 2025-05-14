import SwiftUI

/// A styled text field for creating new tasks, handling focus and submission.
struct NewTaskEntryView: View {
    @Binding var newTask: String
    @FocusState.Binding var inputFocused: Bool
    var onSubmit: () -> Void

    var body: some View {
        TextField("New task", text: $newTask)
            .textFieldStyle(.plain)
            .onSubmit(onSubmit)
            .submitLabel(.done)
            .background(Theme.base.opacity(0.3))
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .focused($inputFocused)
            .padding(.horizontal, Theme.Metrics.textFieldPaddingH)
            .padding(.vertical, Theme.Metrics.textFieldPaddingV)
    }
}