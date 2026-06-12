import SwiftUI
import AppKit
import Combine

/// サークルの見た目・ショートカットの設定。UserDefaults に永続化する。
/// SwiftUI からは @ObservedObject、AppKit 側からは objectWillChange / $shortcut で監視する。
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    /// デフォルトサイズ（「デフォルトに戻す」で使用）。
    static let defaultWidth: Double = 96
    static let defaultHeight: Double = 96
    static let defaultLineWidth: Double = 6

    private enum Keys {
        static let shape = "shape"
        static let width = "width"
        static let height = "height"
        static let lineWidth = "lineWidth"
        static let colorHex = "colorHex"
        static let shortcutKeyCode = "shortcutKeyCode"
        static let shortcutModifiers = "shortcutModifiers"
        static let shortcutKeyLabel = "shortcutKeyLabel"
        static let language = "language"
    }

    @Published var shape: CursorShape {
        didSet { defaults.set(shape.rawValue, forKey: Keys.shape) }
    }
    @Published var width: Double {
        didSet { defaults.set(width, forKey: Keys.width) }
    }
    @Published var height: Double {
        didSet { defaults.set(height, forKey: Keys.height) }
    }
    @Published var lineWidth: Double {
        didSet { defaults.set(lineWidth, forKey: Keys.lineWidth) }
    }
    @Published var color: Color {
        didSet { defaults.set(NSColor(color).hexString, forKey: Keys.colorHex) }
    }
    @Published var shortcut: KeyCombo {
        didSet {
            defaults.set(Int(shortcut.keyCode), forKey: Keys.shortcutKeyCode)
            defaults.set(Int(shortcut.modifiers.rawValue), forKey: Keys.shortcutModifiers)
            defaults.set(shortcut.keyLabel, forKey: Keys.shortcutKeyLabel)
        }
    }

    /// UI 言語（デフォルト英語）。
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    /// 描画に使う NSColor。
    var nsColor: NSColor { NSColor(color) }

    /// 現在の言語の文言。
    var l10n: L10n { L10n(language) }

    /// サイズ（横幅・縦幅・線の太さ）をデフォルトに戻す。
    func resetSize() {
        width = Self.defaultWidth
        height = Self.defaultHeight
        lineWidth = Self.defaultLineWidth
    }

    /// 形をリング⇄四角でトグルする。
    func toggleShape() {
        shape = (shape == .ring) ? .square : .ring
    }

    private init() {
        let d = UserDefaults.standard

        let shapeRaw = d.string(forKey: Keys.shape) ?? CursorShape.ring.rawValue
        shape = CursorShape(rawValue: shapeRaw) ?? .ring

        width = (d.object(forKey: Keys.width) as? Double) ?? Self.defaultWidth
        height = (d.object(forKey: Keys.height) as? Double) ?? Self.defaultHeight
        lineWidth = (d.object(forKey: Keys.lineWidth) as? Double) ?? Self.defaultLineWidth

        // 言語は未設定ならデフォルト英語。
        language = (d.string(forKey: Keys.language)).flatMap(AppLanguage.init(rawValue:)) ?? .english

        let hex = d.string(forKey: Keys.colorHex) ?? "#FF3B30FF"
        color = Color(nsColor: NSColor(hex: hex) ?? .systemRed)

        if d.object(forKey: Keys.shortcutKeyCode) != nil {
            let keyCode = UInt16(d.integer(forKey: Keys.shortcutKeyCode))
            let modifiers = NSEvent.ModifierFlags(rawValue: UInt(d.integer(forKey: Keys.shortcutModifiers)))
            let label = d.string(forKey: Keys.shortcutKeyLabel) ?? ""
            shortcut = KeyCombo(keyCode: keyCode, modifiers: modifiers, keyLabel: label)
        } else {
            shortcut = KeyCombo.default
        }
    }
}
