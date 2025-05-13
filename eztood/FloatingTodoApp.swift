//
//  FloatingTodoApp.swift
//  eztood
//

import SwiftUI
import AppKit

@main
struct FloatingTodoApp: App {

    // Hook into AppKit to fine-tune the NSWindow once SwiftUI created it.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 260, minHeight: 320)
        }
        // Remove title-bar visuals (macOS 13+). Keeps underlying titled style so
        // keyboard focus & shortcuts still work.
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .textEditing) {
                Button("Next Task") {
                    NotificationCenter.default.post(name: .nextTask, object: nil)
                }
                .keyboardShortcut(.tab)

                Button("Previous Task") {
                    NotificationCenter.default.post(name: .prevTask, object: nil)
                }
                .keyboardShortcut(.tab, modifiers: [.shift])
            }
        }

        Settings {
            SettingsView()
        }
    }
}

// MARK: - AppKit tweaks

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let win = NSApplication.shared.windows.first else { return }

        // Always-on-top & visible on every Space.
        win.level = .floating
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Ultra-compact look: hide title text and traffic-light buttons.
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.styleMask.insert(.fullSizeContentView) // allow content to extend into title bar area
        [.closeButton, .miniaturizeButton, .zoomButton].forEach {
            win.standardWindowButton($0)?.isHidden = true
        }

        // Allow dragging from anywhere.
        win.isMovableByWindowBackground = true

        // Rounded corners
        win.isOpaque = false
        if let content = win.contentView {
            content.wantsLayer = true
            content.layer?.cornerRadius = 12
            content.layer?.masksToBounds = true

            // Use custom palette background (falls back to window background)
            if let baseColor = NSColor(named: "Base") {
                content.layer?.backgroundColor = baseColor.cgColor
            }
        }

        // Apply persisted opacity.
        let saved = UserDefaults.standard.double(forKey: "windowOpacity")
        win.alphaValue = saved == 0 ? 1.0 : saved
    }
}
