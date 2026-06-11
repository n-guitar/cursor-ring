import AppKit

/// サークル表示中のスクロールで縦横を伸縮する。
/// 上下スクロール→縦(height)、左右スクロール→横(width) の増分を通知する。
/// オーバーレイ表示中（ショートカット押下中）だけ動かす。
final class ScrollMonitor {
    /// (dWidth, dHeight) をピクセル単位で通知する。
    var onResize: ((CGFloat, CGFloat) -> Void)?

    private var monitors: [Any] = []

    func start() {
        guard monitors.isEmpty else { return }

        if let g = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel, handler: { [weak self] e in
            self?.handle(e)
        }) { monitors.append(g) }

        if let l = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel, handler: { [weak self] e in
            self?.handle(e); return e
        }) { monitors.append(l) }
    }

    func stop() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
    }

    private func handle(_ e: NSEvent) {
        // マウスホイール（行単位）は粗いので拡大、トラックパッド（精密）はそのまま。
        let scale: CGFloat = e.hasPreciseScrollingDeltas ? 1.0 : 10.0
        let dHeight = e.scrollingDeltaY * scale
        let dWidth = e.scrollingDeltaX * scale
        guard dWidth != 0 || dHeight != 0 else { return }
        onResize?(dWidth, dHeight)
    }
}
