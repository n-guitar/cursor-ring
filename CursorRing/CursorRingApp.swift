import SwiftUI
import AppKit

@main
struct CursorRingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Dock に出さずメニューバー常駐（LSUIElement=YES と併用）。
        MenuBarExtra("Cursor Ring", systemImage: "circle.dashed") {
            MenuContent(overlay: appDelegate.overlay, settingsWindow: appDelegate.settingsWindow)
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct MenuContent: View {
    @ObservedObject var overlay: OverlayController
    @ObservedObject private var settings = AppSettings.shared
    let settingsWindow: SettingsWindowController

    var body: some View {
        let l = settings.l10n

        Button(l.menuSettings) { settingsWindow.show() }
            .keyboardShortcut(",")

        Divider()

        Button(overlay.isVisible ? l.menuHide : l.menuShowTest) {
            overlay.toggle()
        }
        Button(l.menuToggleShape) {
            settings.toggleShape()
        }
        Text(l.menuHint(settings.shortcut.displayString))

        Divider()

        Button(l.menuQuit) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
