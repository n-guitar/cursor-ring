import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay = OverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // ステップ2: 起動時に画面中央へ固定円を表示し、
        // 透明・クリック透過オーバーレイの土台が機能することを確認する。
        overlay.show()
    }
}
