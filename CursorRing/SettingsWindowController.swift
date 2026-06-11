import AppKit
import SwiftUI

/// 設定ウィンドウを管理する（macOS 13 でも確実に開けるよう AppKit で自前管理）。
final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = "CursorRing 設定"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 440, height: 480))
            window.center()
            self.window = window
        }
        // アクセサリアプリ（LSUIElement）なので前面化してから表示する。
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
