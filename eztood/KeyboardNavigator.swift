import SwiftUI
#if os(macOS)
import AppKit

/// A view modifier that listens for Tab and Command+Arrow keys to navigate selection and reordering.
struct KeyboardNavigator: ViewModifier {
    let onTabPrev: () -> Void
    let onTabNext: () -> Void
    let onReorderUp: () -> Void
    let onReorderDown: () -> Void

    @State private var monitors: [Any] = []

    func body(content: Content) -> some View {
        content
            .onAppear(perform: setup)
            .onDisappear(perform: remove)
    }

    private func setup() {
        let tabKey: UInt16 = 48
        let upArrow: UInt16 = 126
        let downArrow: UInt16 = 125

        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            switch event.keyCode {
            case tabKey:
                if !flags.contains(.command) {
                    if flags.contains(.shift) { onTabPrev() }
                    else { onTabNext() }
                    return nil
                }
                return event
            case upArrow where flags.contains(.command):
                onReorderUp()
                return nil
            case downArrow where flags.contains(.command):
                onReorderDown()
                return nil
            default:
                return event
            }
        }
        monitors = [monitor].compactMap { $0 }
    }

    private func remove() {
        monitors.forEach(NSEvent.removeMonitor(_:))
        monitors.removeAll()
    }
}
#else
// No-op modifier on non-macOS platforms
struct KeyboardNavigator: ViewModifier {
    func body(content: Content) -> some View { content }
}
#endif

extension View {
    /// Installs keyboard navigation for selection (Tab/Shift+Tab) and reordering (Cmd+↑/↓).
    func keyboardNavigator(
        onTabPrev: @escaping () -> Void = {},
        onTabNext: @escaping () -> Void = {},
        onReorderUp: @escaping () -> Void = {},
        onReorderDown: @escaping () -> Void = {}
    ) -> some View {
        modifier(KeyboardNavigator(
            onTabPrev: onTabPrev,
            onTabNext: onTabNext,
            onReorderUp: onReorderUp,
            onReorderDown: onReorderDown
        ))
    }
}