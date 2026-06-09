import AppKit

/// マウス位置を追従する。移動イベント発生ごとにグローバル座標を通知する。
/// マウス移動の監視はアクセシビリティ権限を必要としない（キー監視のみ必要）。
final class MouseTracker {
    var onMove: ((NSPoint) -> Void)?

    private var monitors: [Any] = []

    func start() {
        guard monitors.isEmpty else { return }
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
        ]

        if let g = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] _ in
            self?.emit()
        }) { monitors.append(g) }

        if let l = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] e in
            self?.emit(); return e
        }) { monitors.append(l) }

        emit()  // 表示直後に現在位置へ即合わせる
    }

    func stop() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
    }

    private func emit() {
        onMove?(NSEvent.mouseLocation)
    }
}
