import AppKit
import Combine

/// オーバーレイウィンドウの生成・表示・破棄と、マウス追従・設定反映を管理する。
final class OverlayController: ObservableObject {
    @Published private(set) var isVisible = false

    private var window: OverlayWindow?
    private var shapeView: CursorShapeView?
    private let tracker = MouseTracker()
    private var settingsCancellable: AnyCancellable?

    init() {
        // 設定変更（色・形・サイズ）を表示中に即反映する。
        settingsCancellable = AppSettings.shared.objectWillChange.sink { [weak self] in
            // objectWillChange は変更前に発火するので、新しい値を読むため次ランループへ。
            DispatchQueue.main.async { self?.applySettings() }
        }
    }

    func show() {
        guard window == nil else { return }

        let frame = Self.unionFrame()
        let window = OverlayWindow(frame: frame)
        let view = CursorShapeView(frame: NSRect(origin: .zero, size: frame.size))
        window.contentView = view
        window.orderFrontRegardless()

        self.window = window
        self.shapeView = view
        applySettings()

        // ステップ3: マウス追従。グローバル座標をウィンドウ内座標へ変換する。
        tracker.onMove = { [weak self] global in
            guard let self, let window = self.window else { return }
            let point = NSPoint(
                x: global.x - window.frame.origin.x,
                y: global.y - window.frame.origin.y
            )
            self.shapeView?.center = point
        }
        tracker.start()

        isVisible = true
    }

    func hide() {
        tracker.stop()
        window?.orderOut(nil)
        window = nil
        shapeView = nil
        isVisible = false
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    private func applySettings() {
        guard let view = shapeView else { return }
        let s = AppSettings.shared
        view.shape = s.shape
        view.diameter = CGFloat(s.diameter)
        view.lineWidth = CGFloat(s.lineWidth)
        view.color = s.nsColor
    }

    /// 全ディスプレイを覆う矩形（マルチディスプレイでも追従できるように）。
    private static func unionFrame() -> NSRect {
        let screens = NSScreen.screens
        guard var rect = screens.first?.frame else {
            return NSScreen.main?.frame ?? .zero
        }
        for screen in screens.dropFirst() {
            rect = rect.union(screen.frame)
        }
        return rect
    }
}
