import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay = OverlayController()
    let settingsWindow = SettingsWindowController()
    private let shortcuts = ShortcutMonitor(combo: AppSettings.shared.shortcut)

    private var shortcutCancellable: AnyCancellable?
    private var accessibilityTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // ステップ4: ショートカットを押している間だけサークルを表示する。
        shortcuts.onPress = { [weak self] in self?.overlay.show() }
        shortcuts.onRelease = { [weak self] in self?.overlay.hide() }

        // 設定でショートカットが変わったら監視に反映する。
        shortcutCancellable = AppSettings.shared.$shortcut.sink { [weak self] combo in
            self?.shortcuts.updateCombo(combo)
        }

        // グローバルキー監視にはアクセシビリティ権限が必要。
        if Accessibility.isTrusted {
            shortcuts.start()
        } else {
            Accessibility.requestIfNeeded()
            waitForAccessibility()
        }
    }

    /// 権限付与を検知して監視を開始する（付与後の再起動を不要にするための簡易ポーリング）。
    private func waitForAccessibility() {
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if Accessibility.isTrusted {
                self.shortcuts.start()
                timer.invalidate()
                self.accessibilityTimer = nil
            }
        }
    }
}
