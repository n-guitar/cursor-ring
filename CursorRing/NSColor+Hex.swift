import AppKit

extension NSColor {
    /// "#RRGGBB" または "#RRGGBBAA" を sRGB の NSColor に変換する。失敗時は nil。
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard let value = UInt64(s, radix: 16) else { return nil }

        let r, g, b, a: CGFloat
        switch s.count {
        case 6:
            r = CGFloat((value & 0xFF0000) >> 16) / 255
            g = CGFloat((value & 0x00FF00) >> 8) / 255
            b = CGFloat(value & 0x0000FF) / 255
            a = 1
        case 8:
            r = CGFloat((value & 0xFF00_0000) >> 24) / 255
            g = CGFloat((value & 0x00FF_0000) >> 16) / 255
            b = CGFloat((value & 0x0000_FF00) >> 8) / 255
            a = CGFloat(value & 0x0000_00FF) / 255
        default:
            return nil
        }
        self.init(srgbRed: r, green: g, blue: b, alpha: a)
    }

    /// "#RRGGBBAA" 形式の文字列。
    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "#FF3B30FF" }
        let r = Int(round(c.redComponent * 255))
        let g = Int(round(c.greenComponent * 255))
        let b = Int(round(c.blueComponent * 255))
        let a = Int(round(c.alphaComponent * 255))
        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
    }
}
