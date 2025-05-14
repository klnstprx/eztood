import SwiftUI
import AppKit
import Carbon.HIToolbox     // kVK codes & Hot Key API (no extra perms needed)

@main
struct FloatingTodoApp: App {

    // Hook into AppKit to fine-tune the NSWindow once SwiftUI created it.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var tabStore = TabStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tabStore)
                .frame(minWidth: 260, minHeight: 320)
        }
        // Remove title-bar visuals (macOS 13+). Keeps underlying titled style so
        // keyboard focus & shortcuts still work.
        .windowStyle(.hiddenTitleBar)
        // No additional commands; Tab handling is via local NSEvent monitor

        Settings {
            SettingsView()
        }
    }
}

// MARK: - AppKit tweaks

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Carbon hot-key reference (Cmd + .)
    private var hotKeyRef: EventHotKeyRef?

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
        // Register global shortcut (⌘ + .)
        registerGlobalShortcut()
    }

    // MARK: - Global Shortcut using Carbon Hot-Key (Cmd + .)
    private func registerGlobalShortcut() {
        // Hot-key id signature – arbitrary 4-byte code
        let hotKeyID = EventHotKeyID(signature: OSType(0x66747074), id: 1) // 'ftpt'

        let keyCode: UInt32   = UInt32(kVK_ANSI_Period)   // . key
        let modifiers: UInt32 = UInt32(cmdKey)            // ⌘

        // Register with macOS – this works sandboxed without extra entitlements
        if RegisterEventHotKey(keyCode,
                              modifiers,
                              hotKeyID,
                              GetApplicationEventTarget(),
                              0,
                              &hotKeyRef) != noErr {
            NSLog("Unable to register global hot-key ⌘+.")
        }

        // Install handler once
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (_ /*next*/, evt, userData) in
            var hkCom = EventHotKeyID()
            GetEventParameter(evt,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout.size(ofValue: hkCom),
                              nil,
                              &hkCom)

            if hkCom.signature == OSType(0x66747074) && hkCom.id == 1 {
                // Convert userData back to AppDelegate
                if let userData = userData {
                    let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                    DispatchQueue.main.async {
                        delegate.toggleWindow()
                    }
                }
            }
            return noErr
        },
        1,
        &eventType,
        UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
        nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }

    @objc private func toggleWindow() {
        let app = NSApplication.shared
        if app.isActive, app.windows.first?.isVisible == true {
            app.hide(nil)
        } else {
            app.activate(ignoringOtherApps: true)
            app.windows.forEach { $0.makeKeyAndOrderFront(nil) }
            NotificationCenter.default.post(name: .toggleShowTodo, object: nil)
        }
    }

    // No longer need CGEventTap callback – Carbon handler above calls toggleWindow()
}
