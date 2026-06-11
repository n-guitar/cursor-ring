import AppKit
import Combine

/// オーバーレイの生成・表示・破棄と、マウス追従・伸縮・設定反映を管理する。
///
/// マルチディスプレイ対応のため、**ディスプレイごとに1枚ずつ**オーバーレイを作る。
/// （1枚の巨大ウィンドウで全画面を覆う方式は、解像度・スケール差や配置で
///  片方の画面に描画されないことがあるため。）
/// カーソルがいる画面のリングだけ表示し、他の画面では隠す。
final class OverlayController: ObservableObject {
    @Published private(set) var isVisible = false

    private struct ScreenOverlay {
        let screen: NSScreen
        let window: OverlayWindow
        let view: CursorShapeView
    }

    private var overlays: [ScreenOverlay] = []
    private let tracker = MouseTracker()
    private var settingsCancellable: AnyCancellable?
    private var screenChangeObserver: NSObjectProtocol?
    private var scrollCaptureOn = false

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
        guard overlays.isEmpty else { return }

        buildOverlays()
        applySettings()
        positionRing(at: NSEvent.mouseLocation)

        // マウス追従。
        tracker.onMove = { [weak self] global in
            self?.positionRing(at: global)
        }
        tracker.start()

        // ディスプレイの抜き差し・配置変更に追従して作り直す。
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, !self.overlays.isEmpty else { return }
            self.rebuild()
        }

        isVisible = true
    }

    /// スクロール捕捉の切り替え。
    /// ON: 全画面のクリック透過を解除し、スクロールをオーバーレイで消費（下のアプリに漏れない）。
    /// OFF: 通常のクリック透過に戻す。
    func setScrollCapture(_ capture: Bool) {
        scrollCaptureOn = capture
        for o in overlays {
            o.window.ignoresMouseEvents = !capture
        }
    }

    func hide() {
        tracker.stop()
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            screenChangeObserver = nil
        }
        for o in overlays {
            o.window.orderOut(nil)
        }
        overlays.removeAll()
        isVisible = false
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    // MARK: - 内部

    private func buildOverlays() {
        overlays = NSScreen.screens.map { screen in
            let window = OverlayWindow(frame: screen.frame)
            let view = CursorShapeView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.onScroll = { [weak self] dWidth, dHeight in
                self?.resize(dWidth, dHeight)
            }
            window.contentView = view
            window.ignoresMouseEvents = !scrollCaptureOn
            window.orderFrontRegardless()
            return ScreenOverlay(screen: screen, window: window, view: view)
        }
    }

    private func rebuild() {
        for o in overlays { o.window.orderOut(nil) }
        overlays.removeAll()
        buildOverlays()
        applySettings()
        positionRing(at: NSEvent.mouseLocation)
    }

    /// カーソルがいる画面にだけリングを置き、他の画面では隠す。
    private func positionRing(at global: NSPoint) {
        for o in overlays {
            if NSMouseInRect(global, o.screen.frame, false) {
                o.view.center = NSPoint(
                    x: global.x - o.screen.frame.origin.x,
                    y: global.y - o.screen.frame.origin.y
                )
                o.view.setRingHidden(false)
            } else {
                o.view.setRingHidden(true)
            }
        }
    }

    private func resize(_ dWidth: CGFloat, _ dHeight: CGFloat) {
        let s = AppSettings.shared
        let range = Self.sizeRange
        s.width = min(range.upperBound, max(range.lowerBound, s.width + Double(dWidth)))
        s.height = min(range.upperBound, max(range.lowerBound, s.height + Double(dHeight)))
    }

    private func applySettings() {
        let s = AppSettings.shared
        for o in overlays {
            o.view.shape = s.shape
            o.view.shapeWidth = CGFloat(s.width)
            o.view.shapeHeight = CGFloat(s.height)
            o.view.lineWidth = CGFloat(s.lineWidth)
            o.view.color = s.nsColor
        }
    }
}
