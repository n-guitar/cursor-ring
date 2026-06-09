import AppKit

/// 透明・クリック透過・最前面のオーバーレイウィンドウ。
/// 下のアプリ操作を邪魔せずにサークルを重ねるための「板」。
final class OverlayWindow: NSWindow {
    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: .borderless,        // 枠なし
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear           // 透明
        hasShadow = false
        ignoresMouseEvents = true          // クリック透過（下のアプリを操作できる）
        level = .screenSaver               // 他アプリより前面
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    // クリック透過オーバーレイなのでキー／メインにはしない。
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
