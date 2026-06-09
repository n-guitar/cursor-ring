import SwiftUI
import AppKit
import Combine

/// サークルの見た目・ショートカットの設定。UserDefaults に永続化する。
/// SwiftUI からは @ObservedObject、AppKit 側からは objectWillChange / $shortcut で監視する。
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let shape = "shape"
        static let diameter = "diameter"
        static let lineWidth = "lineWidth"
        static let colorHex = "colorHex"
        static let shortcutKeyCode = "shortcutKeyCode"
        static let shortcutModifiers = "shortcutModifiers"
        static let shortcutKeyLabel = "shortcutKeyLabel"
    }

    @Published var shape: CursorShape {
        didSet { defaults.set(shape.rawValue, forKey: Keys.shape) }
    }
    @Published var diameter: Double {
        didSet { defaults.set(diameter, forKey: Keys.diameter) }
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

    /// 描画に使う NSColor。
    var nsColor: NSColor { NSColor(color) }

    private init() {
        let d = UserDefaults.standard

        let shapeRaw = d.string(forKey: Keys.shape) ?? CursorShape.ring.rawValue
        shape = CursorShape(rawValue: shapeRaw) ?? .ring

        diameter = (d.object(forKey: Keys.diameter) as? Double) ?? 96
        lineWidth = (d.object(forKey: Keys.lineWidth) as? Double) ?? 6

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
