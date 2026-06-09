import SwiftUI
import AppKit

@main
struct CursorRingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Dock に出さずメニューバー常駐（LSUIElement=YES と併用）。
        MenuBarExtra("Cursor Ring", systemImage: "circle.dashed") {
            Button("設定…") { appDelegate.settingsWindow.show() }
                .keyboardShortcut(",")

            Divider()

            Button(appDelegate.overlay.isVisible ? "サークルを隠す" : "サークルを表示（テスト）") {
                appDelegate.overlay.toggle()
            }
            Text("「\(AppSettings.shared.shortcut.displayString)」を押している間だけ表示")

            Divider()

            Button("CursorRing を終了") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
