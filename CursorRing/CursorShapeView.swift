import AppKit
import QuartzCore

/// CAShapeLayer でサークルを描く透明ビュー。
/// 色・形・横幅・縦幅・線幅・描画中心をプロパティで可変にしてある。
final class CursorShapeView: NSView {
    private let shapeLayer = CAShapeLayer()

    var shape: CursorShape = .ring { didSet { redraw() } }
    var shapeWidth: CGFloat = 96 { didSet { redraw() } }
    var shapeHeight: CGFloat = 96 { didSet { redraw() } }
    var lineWidth: CGFloat = 6 { didSet { redraw() } }
    var color: NSColor = .systemRed { didSet { redraw() } }

    /// 描画中心（ビュー座標 = 左下原点）。
    var center: NSPoint = .zero { didSet { redraw() } }

    /// スクロール捕捉中（クリック透過を一時解除している間）に呼ばれる。(dWidth, dHeight)
    var onScroll: ((CGFloat, CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        // マウスホイール（行単位）は粗いので拡大、トラックパッド（精密）はそのまま。
        let scale: CGFloat = event.hasPreciseScrollingDeltas ? 1.0 : 10.0
        let dHeight = event.scrollingDeltaY * scale
        let dWidth = event.scrollingDeltaX * scale
        if dWidth != 0 || dHeight != 0 {
            onScroll?(dWidth, dHeight)
        }
        // 下のアプリには渡さない（このビューで消費する）。
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(shapeLayer)
        redraw()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // AppKit デフォルトの左下原点を使う（グローバル座標と揃える）。
    override var isFlipped: Bool { false }

    private func redraw() {
        let rect = CGRect(
            x: center.x - shapeWidth / 2,
            y: center.y - shapeHeight / 2,
            width: shapeWidth,
            height: shapeHeight
        )

        // 位置・パスの暗黙アニメーションを切る（追従時のカクつき防止）。
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        shapeLayer.path = shape.path(in: rect, lineWidth: lineWidth)
        shapeLayer.fillColor = NSColor.clear.cgColor   // 輪郭線のみ
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineJoin = .round
        shapeLayer.lineCap = .round

        CATransaction.commit()
    }
}
