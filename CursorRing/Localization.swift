import Foundation

/// アプリ内 UI 言語（システムロケールに依存せず設定で切り替える）。デフォルトは英語。
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case japanese = "ja"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .english:  return "English"
        case .japanese: return "日本語"
        }
    }
}

/// UI 文言。`AppSettings.language` に応じて英日を返す。
struct L10n {
    let lang: AppLanguage
    init(_ lang: AppLanguage) { self.lang = lang }

    private func t(_ en: String, _ ja: String) -> String {
        lang == .japanese ? ja : en
    }

    // メニュー
    var menuSettings: String { t("Settings…", "設定…") }
    var menuShowTest: String { t("Show ring (test)", "サークルを表示（テスト）") }
    var menuHide: String { t("Hide ring", "サークルを隠す") }
    var menuToggleShape: String { t("Toggle shape (ring / square)", "形を切り替え（リング／四角）") }
    var menuQuit: String { t("Quit CursorRing", "CursorRing を終了") }
    func menuHint(_ shortcut: String) -> String {
        t("Tap “\(shortcut)” to show / hold for temporary / scroll while held to resize",
          "「\(shortcut)」タップで表示／長押しで一時表示／押しながらスクロールで伸縮")
    }

    // 設定ウィンドウ
    var settingsTitle: String { t("CursorRing Settings", "CursorRing 設定") }

    var sectionAppearance: String { t("Appearance", "見た目") }
    var shape: String { t("Shape", "形") }
    var color: String { t("Color", "色") }
    var width: String { t("Width", "横幅") }
    var height: String { t("Height", "縦幅") }
    var lineWidth: String { t("Line width", "線の太さ") }
    var resetSize: String { t("Reset to default size", "デフォルトサイズに戻す") }

    func shapeName(_ shape: CursorShape) -> String {
        switch shape {
        case .ring:   return t("Ring", "リング")
        case .square: return t("Square", "四角")
        }
    }

    var sectionShortcut: String { t("Shortcut (shown while held)", "ショートカット（押している間だけ表示）") }
    var current: String { t("Current:", "現在:") }
    var change: String { t("Change", "変更") }
    var pressKeys: String { t("Press modifier + key…", "修飾キー + キーを押す…") }
    var shortcutHintCombo: String {
        t("Combine with ⌃ ⌥ ⇧ ⌘, or use a single F1–F20. No special permission needed.",
          "⌃ ⌥ ⇧ ⌘ との組み合わせ、または F1〜F20 単独で記録できます。特別な権限は不要です。")
    }
    var shortcutHintBehavior: String {
        t("Tap = stays on (tap again to hide). Hold = shown while held. Scroll while holding to resize (won't affect the app underneath).",
          "タップ＝出したまま（もう一度タップで消す）／長押し＝離すまで表示。キーを押しながら2本指スクロールで伸縮（その間ブラウザ等には影響しません）。")
    }
    var shortcutHintFnKey: String {
        t("To use an F-key alone, enable “Use F1, F2, etc. as standard function keys” in System Settings > Keyboard, or hold Fn.",
          "Fキー単独を使う場合、システム設定 > キーボードで「F1, F2 等を標準のファンクションキーとして使用」を ON にするか Fn 併用が必要です。")
    }

    var sectionLanguage: String { t("Language", "言語") }
}
