import CoreGraphics

/// サークルの「形」。パスを差し替えて拡張する設計（描画ロジックから形を分離）。
/// 横幅・縦幅を別々に指定できるので、リングは楕円、四角は長方形にも伸縮できる。
enum CursorShape: String, CaseIterable, Identifiable {
    case ring     // 輪郭の円（縦横を変えると楕円）
    case square   // 四角（縦横を変えると長方形）

    var id: String { rawValue }

    // 表示名は言語に依存するため L10n.shapeName(_:) で扱う。

    /// 指定矩形に収まるパスを返す。`lineWidth` は将来のインセット計算用に受け取る。
    func path(in rect: CGRect, lineWidth: CGFloat) -> CGPath {
        switch self {
        case .ring:
            return CGPath(ellipseIn: rect, transform: nil)
        case .square:
            return CGPath(rect: rect, transform: nil)
        }
    }
}
