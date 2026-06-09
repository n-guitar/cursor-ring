import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// グローバルショートカットの1組（キー + 修飾キー）。
struct KeyCombo: Equatable {
    var keyCode: UInt16
    var modifiers: NSEvent.ModifierFlags
    /// 表示用ラベル（記録時に `charactersIgnoringModifiers` から保持）。
    var keyLabel: String

    /// 既定: Control + Option + R。
    static let `default` = KeyCombo(
        keyCode: UInt16(kVK_ANSI_R),
        modifiers: [.control, .option],
        keyLabel: "R"
    )

    /// 比較・保存に使う修飾キーのみ（control/option/shift/command）。
    static let trackedModifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command]

    /// "⌃⌥R" のような表示文字列。
    var displayString: String {
        var s = ""
        if modifiers.contains(.control) { s += "⌃" }
        if modifiers.contains(.option)  { s += "⌥" }
        if modifiers.contains(.shift)   { s += "⇧" }
        if modifiers.contains(.command) { s += "⌘" }
        s += keyLabel.isEmpty ? "?" : keyLabel
        return s
    }
}

/// アクセシビリティ権限（グローバルキー監視に必要）のヘルパ。
enum Accessibility {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// 未許可ならシステムの権限付与プロンプトを表示する。
    @discardableResult
    static func requestIfNeeded() -> Bool {
        // kAXTrustedCheckOptionPrompt の実値。定数のブリッジ方法が SDK 版で揺れるため文字列で指定。
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// システム設定の「プライバシーとセキュリティ > アクセシビリティ」を開く。
    static func openSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

/// グローバルショートカットを「押している間」検知する。
/// keyDown で onPress、keyUp で onRelease を呼ぶ（キーリピートは無視）。
///
/// NSEvent のグローバルキー監視にはアクセシビリティ権限が必要（#287 参照）。
/// キーを横取りしない読み取り専用のため CGEventTap は使わない。
final class ShortcutMonitor {
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?

    private var combo: KeyCombo
    private var monitors: [Any] = []
    private var isDown = false

    init(combo: KeyCombo) {
        self.combo = combo
    }

    func updateCombo(_ combo: KeyCombo) {
        self.combo = combo
        isDown = false
    }

    var isRunning: Bool { !monitors.isEmpty }

    func start() {
        guard monitors.isEmpty else { return }

        if let g1 = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: { [weak self] e in
            self?.handleKeyDown(e)
        }) { monitors.append(g1) }

        if let g2 = NSEvent.addGlobalMonitorForEvents(matching: .keyUp, handler: { [weak self] e in
            self?.handleKeyUp(e)
        }) { monitors.append(g2) }

        // 自アプリがアクティブな時はグローバル監視が呼ばれないのでローカルも張る。
        if let l1 = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] e in
            self?.handleKeyDown(e); return e
        }) { monitors.append(l1) }

        if let l2 = NSEvent.addLocalMonitorForEvents(matching: .keyUp, handler: { [weak self] e in
            self?.handleKeyUp(e); return e
        }) { monitors.append(l2) }
    }

    func stop() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
        isDown = false
    }

    private func matches(_ e: NSEvent) -> Bool {
        let mods = e.modifierFlags.intersection(KeyCombo.trackedModifiers)
        let wanted = combo.modifiers.intersection(KeyCombo.trackedModifiers)
        return e.keyCode == combo.keyCode && mods == wanted
    }

    private func handleKeyDown(_ e: NSEvent) {
        guard matches(e) else { return }
        if !isDown {            // キーリピートを1回押下として扱う
            isDown = true
            onPress?()
        }
    }

    private func handleKeyUp(_ e: NSEvent) {
        guard isDown, e.keyCode == combo.keyCode else { return }
        isDown = false
        onRelease?()
    }
}
