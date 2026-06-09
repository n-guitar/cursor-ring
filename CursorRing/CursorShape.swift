import CoreGraphics

/// サークルの「形」。パスを差し替えて拡張する設計（描画ロジックから形を分離）。
/// 将来の追加（アニメーション・残像など）もここを起点に行う。
enum CursorShape: String, CaseIterable, Identifiable {
    case circle   // 塗りつぶし円
    case ring     // 輪郭のみの円
    case square   // 四角
    case cross    // 十字

    var id: String { rawValue }

    var label: String {
        switch self {
        case .circle: return "円（塗り）"
        case .ring:   return "リング"
        case .square: return "四角"
        case .cross:  return "十字"
        }
    }

    /// 塗りつぶしか（false の場合は輪郭線で描く）。
    var isFilled: Bool {
        switch self {
        case .circle: return true
        case .ring, .square, .cross: return false
        }
    }

    /// 指定矩形に収まるパスを返す。`lineWidth` は将来のインセット計算用に受け取る。
    func path(in rect: CGRect, lineWidth: CGFloat) -> CGPath {
        switch self {
        case .circle, .ring:
            return CGPath(ellipseIn: rect, transform: nil)
        case .square:
            return CGPath(rect: rect, transform: nil)
        case .cross:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            return path
        }
    }
}
