import AppKit
import Combine

/// オーバーレイウィンドウの生成・表示・破棄と、マウス追従・設定反映を管理する。
final class OverlayController: ObservableObject {
    @Published private(set) var isVisible = false

    private var window: OverlayWindow?
    private var shapeView: CursorShapeView?
    private let tracker = MouseTracker()
    private let resizeKeys = ResizeKeyMonitor()
    private var settingsCancellable: AnyCancellable?

    /// 伸縮の下限・上限（設定スライダーと揃える）。
    private static let sizeRange: ClosedRange<Double> = 20...600

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

        // 矢印キーで縦横を伸縮（↑↓→縦、←→→横）。変更は設定に反映され即描画される。
        resizeKeys.onResize = { dWidth, dHeight in
            let s = AppSettings.shared
            let range = Self.sizeRange
            s.width = min(range.upperBound, max(range.lowerBound, s.width + Double(dWidth)))
            s.height = min(range.upperBound, max(range.lowerBound, s.height + Double(dHeight)))
        }
        resizeKeys.start()

        isVisible = true
    }

    func hide() {
        tracker.stop()
        resizeKeys.stop()
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
        view.shapeWidth = CGFloat(s.width)
        view.shapeHeight = CGFloat(s.height)
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
