import SwiftUI

#if os(macOS)
import AppKit

/// Wraps SwiftUI row content in a view that prevents window-dragging and fully
/// participates in the macOS drag-and-drop system.
struct DraggableRowHost<Content: View>: NSViewRepresentable {
    var content: Content

    func makeNSView(context: Context) -> NonMovableHostingView {
        NonMovableHostingView(rootView: content)
    }

    func updateNSView(_ nsView: NonMovableHostingView, context: Context) {
        nsView.rootView = content
    }

    final class NonMovableHostingView: NSHostingView<Content> {
        override var mouseDownCanMoveWindow: Bool { false }
    }
}

#else

// On non-macOS platforms this is just an identity wrapper.
struct DraggableRowHost<Content: View>: View {
    var content: Content
    var body: some View { content }
}

#endif
