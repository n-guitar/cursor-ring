import AppKit
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

/// Carbon の RegisterEventHotKey でグローバルショートカットを「押している間」検知する。
///
/// Carbon ホットキーは **アクセシビリティ権限を必要としない**（NSEvent のグローバルキー監視と違う点）。
/// 押下で onPress、離すと onRelease を呼ぶ。
final class ShortcutMonitor {
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?

    private var combo: KeyCombo
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var started = false

    private static let signature: OSType = 0x4352_6E67  // 'CRng'

    init(combo: KeyCombo) {
        self.combo = combo
    }

    func updateCombo(_ combo: KeyCombo) {
        self.combo = combo
        if started {
            unregisterHotKey()
            registerHotKey()
        }
    }

    var isRunning: Bool { started }

    func start() {
        guard !started else { return }
        installHandler()
        registerHotKey()
        started = true
    }

    func stop() {
        unregisterHotKey()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
        started = false
    }

    private func installHandler() {
        guard handlerRef == nil else { return }
        var specs = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), Self.handler, 2, &specs, userData, &handlerRef)
    }

    private func registerHotKey() {
        guard hotKeyRef == nil else { return }
        let id = EventHotKeyID(signature: Self.signature, id: 1)
        RegisterEventHotKey(
            UInt32(combo.keyCode),
            Self.carbonModifiers(combo.modifiers),
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private static func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var c: UInt32 = 0
        if flags.contains(.command) { c |= UInt32(cmdKey) }
        if flags.contains(.option)  { c |= UInt32(optionKey) }
        if flags.contains(.control) { c |= UInt32(controlKey) }
        if flags.contains(.shift)   { c |= UInt32(shiftKey) }
        return c
    }

    // 非キャプチャクロージャなので C 関数ポインタ（EventHandlerUPP）として渡せる。
    private static let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
        guard let event, let userData else { return noErr }
        let monitor = Unmanaged<ShortcutMonitor>.fromOpaque(userData).takeUnretainedValue()
        let kind = GetEventKind(event)
        if kind == UInt32(kEventHotKeyPressed) {
            monitor.onPress?()
        } else if kind == UInt32(kEventHotKeyReleased) {
            monitor.onRelease?()
        }
        return noErr
    }
}
