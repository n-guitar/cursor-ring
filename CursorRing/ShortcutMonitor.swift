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
/// - Carbon ホットキーは **アクセシビリティ権限を必要としない**
/// - 「離した」検知は Carbon の released イベントに頼らない。修飾キーを先に離すと
///   released が届かないことがあるため、**キーの物理状態を CGEventSource.keyState で
///   ポーリング**して確実に検知する（これも権限不要）。
final class ShortcutMonitor {
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?

    private var combo: KeyCombo
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var started = false
    private var isDown = false
    private var releaseTimer: Timer?

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
        releaseTimer?.invalidate()
        releaseTimer = nil
        isDown = false
        started = false
    }

    private func installHandler() {
        guard handlerRef == nil else { return }
        var specs = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
        ]
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), Self.handler, 1, &specs, userData, &handlerRef)
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

    fileprivate func handlePressed() {
        guard !isDown else { return }   // 自動リピートを無視
        isDown = true
        onPress?()
        startReleasePolling()
    }

    /// キーの物理状態を 30ms ごとに確認し、離れたら onRelease を1回だけ呼ぶ。
    private func startReleasePolling() {
        releaseTimer?.invalidate()
        let keyCode = CGKeyCode(combo.keyCode)
        releaseTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if !CGEventSource.keyState(.combinedSessionState, key: keyCode) {
                timer.invalidate()
                self.releaseTimer = nil
                self.isDown = false
                self.onRelease?()
            }
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
        guard let userData else { return noErr }
        let monitor = Unmanaged<ShortcutMonitor>.fromOpaque(userData).takeUnretainedValue()
        monitor.handlePressed()
        return noErr
    }
}

/// キーコードの表示名ヘルパ。
enum KeyNames {
    /// ファンクションキーのキーコード → ラベル。
    static let functionKeys: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17",
        kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20",
    ]

    static func isFunctionKey(_ code: UInt16) -> Bool {
        functionKeys[Int(code)] != nil
    }

    static func label(for code: UInt16) -> String? {
        functionKeys[Int(code)]
    }
}
