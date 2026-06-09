import AppKit
import Combine

/// オーバーレイウィンドウの生成・表示・破棄を管理する。
/// ステップ2では「画面中央に固定の円を出す」までを担当（追従はステップ3で追加）。
final class OverlayController: ObservableObject {
    @Published private(set) var isVisible = false

    private var window: OverlayWindow?

    func show() {
        guard window == nil else { return }
        guard let screen = NSScreen.main else { return }

        let window = OverlayWindow(screen: screen)
        let view = CursorShapeView(frame: NSRect(origin: .zero, size: screen.frame.size))

        // ステップ2: 追従なし。画面中央に固定で描いてオーバーレイの土台を確認する。
        view.center = NSPoint(x: screen.frame.width / 2, y: screen.frame.height / 2)

        window.contentView = view
        window.orderFrontRegardless()

        self.window = window
        isVisible = true
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        isVisible = false
    }

    func toggle() {
        isVisible ? hide() : show()
    }
}
