import AppKit
import Carbon.HIToolbox

/// サークル表示中だけ矢印キーで縦横を伸縮する。
///
/// Carbon の RegisterEventHotKey で矢印キーを登録するため:
/// - アクセシビリティ権限が不要
/// - 押下が他アプリに漏れない（ホットキーとして消費される＝ブラウザ等を誤操作しない）
/// 表示中のみ登録し、非表示で解除する。
final class ResizeKeyMonitor {
    /// (dWidth, dHeight) をピクセル単位で通知する（押下中はフレームごとに連続）。
    var onResize: ((CGFloat, CGFloat) -> Void)?

    private struct Direction { let dWidth: CGFloat; let dHeight: CGFloat }

    private static let signature: OSType = 0x4352_6E67  // 'CRng'（id で用途を区別）

    // ホットキー id → 方向（↑ 縦+ / ↓ 縦- / ← 横- / → 横+）
    private let directions: [UInt32: Direction] = [
        2: Direction(dWidth: 0, dHeight: 1),
        3: Direction(dWidth: 0, dHeight: -1),
        4: Direction(dWidth: -1, dHeight: 0),
        5: Direction(dWidth: 1, dHeight: 0),
    ]
    private let keyCodes: [UInt32: Int] = [
        2: kVK_UpArrow, 3: kVK_DownArrow, 4: kVK_LeftArrow, 5: kVK_RightArrow,
    ]

    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var handlerRef: EventHandlerRef?
    private var active: Set<UInt32> = []
    private var timer: Timer?
    private let step: CGFloat = 4   // 1 フレームあたりの増分(px) → 約 240px/秒
    private var started = false

    func start() {
        guard !started else { return }
        installHandler()
        for (id, code) in keyCodes {
            var ref: EventHotKeyRef?
            let hkID = EventHotKeyID(signature: Self.signature, id: id)
            RegisterEventHotKey(UInt32(code), 0, hkID, GetApplicationEventTarget(), 0, &ref)
            hotKeyRefs.append(ref)
        }
        started = true
    }

    func stop() {
        hotKeyRefs.forEach { if let r = $0 { UnregisterEventHotKey(r) } }
        hotKeyRefs.removeAll()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
        active.removeAll()
        timer?.invalidate()
        timer = nil
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

    fileprivate func handle(id: UInt32, pressed: Bool) {
        guard directions[id] != nil else { return }   // 自分の id（矢印）だけ扱う
        if pressed {
            active.insert(id)
            startTimerIfNeeded()
        } else {
            active.remove(id)
            if active.isEmpty {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            var dWidth: CGFloat = 0
            var dHeight: CGFloat = 0
            for id in self.active {
                if let dir = self.directions[id] {
                    dWidth += dir.dWidth * self.step
                    dHeight += dir.dHeight * self.step
                }
            }
            if dWidth != 0 || dHeight != 0 {
                self.onResize?(dWidth, dHeight)
            }
        }
    }

    private static let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
        guard let event, let userData else { return noErr }
        let monitor = Unmanaged<ResizeKeyMonitor>.fromOpaque(userData).takeUnretainedValue()
        var hkID = EventHotKeyID()
        GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                          nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
        guard hkID.signature == ResizeKeyMonitor.signature else { return noErr }
        let pressed = GetEventKind(event) == UInt32(kEventHotKeyPressed)
        monitor.handle(id: hkID.id, pressed: pressed)
        return noErr
    }
}
