import SwiftUI
import AppKit

/// macOS Settings window (Preferences) for the app.
/// Allows the user to change the window opacity (transparency).
struct SettingsView: View {
    // Persisted slider value in user defaults. Range 0.2 – 1.0.
    @AppStorage("windowOpacity") private var windowOpacity: Double = 1.0

    var body: some View {
        Form {
            HStack {
                Text("Window Opacity")
                Spacer()
                Text(String(format: "%.0f%%", windowOpacity * 100))
                    .foregroundStyle(.secondary)
            }

            Slider(value: $windowOpacity, in: 0.2...1.0, step: 0.05)
                .onChange(of: windowOpacity, initial: false) { _, newValue in
                    applyOpacity(newValue)
                }
        }
        .padding()
        .frame(width: 320)
        // When the view first appears, ensure the current value is applied.
        .onAppear { applyOpacity(windowOpacity) }
    }

    /// Updates the alpha value of all app windows so the change is immediate.
    private func applyOpacity(_ value: Double) {
        // Only change the floating todo window – leave the Settings panel itself unaffected.
        for window in NSApplication.shared.windows where window.level == .floating {
            window.alphaValue = value
        }
    }
}
