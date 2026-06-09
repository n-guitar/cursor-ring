import SwiftUI
import AppKit

@main
struct CursorRingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Dock に出さずメニューバー常駐（LSUIElement=YES と併用）。
        MenuBarExtra("Cursor Ring", systemImage: "circle.dashed") {
            AppMenu(overlay: appDelegate.overlay)
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct AppMenu: View {
    @ObservedObject var overlay: OverlayController

    var body: some View {
        Button(overlay.isVisible ? "サークルを隠す" : "サークルを表示") {
            overlay.toggle()
        }
        Divider()
        Button("CursorRing を終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
