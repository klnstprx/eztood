import SwiftUI

enum Theme {
    // Color palette
    static let accent   = Color("Accent", bundle: nil)
    static let contrast = Color("Contrast", bundle: nil)
    static let base     = Color("Base", bundle: nil)

    // Metrics
    enum Metrics {
        static let cornerRadius: CGFloat      = 8
        static let rowCornerRadius: CGFloat   = 6
        static let rowVerticalPadding: CGFloat = 2
        static let textFieldPaddingV: CGFloat  = 6
        static let textFieldPaddingH: CGFloat  = 10
    }
}

// MARK: - Helpers for invisible shortcut buttons

extension View {
    /// Adds an invisible button that triggers `action` when the given shortcut is pressed.
    func hiddenShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = [], action: @escaping () -> Void) -> some View {
        self.background(
            Button(action: action) { EmptyView() }
                .keyboardShortcut(key, modifiers: modifiers)
                .frame(width: 0, height: 0)
                .opacity(0)
        )
    }

    /// Character overload convenience.
    func hiddenShortcut(_ char: Character, modifiers: EventModifiers = [], action: @escaping () -> Void) -> some View {
        hiddenShortcut(KeyEquivalent(char), modifiers: modifiers, action: action)
    }

    func hiddenShortcut(_ string: String, modifiers: EventModifiers = [], action: @escaping () -> Void) -> some View {
        guard let ch = string.first else { return AnyView(self) }
        return AnyView(hiddenShortcut(KeyEquivalent(ch), modifiers: modifiers, action: action))
    }
}