import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay = OverlayController()
    let settingsWindow = SettingsWindowController()
    private let shortcuts = ShortcutMonitor(combo: AppSettings.shared.shortcut)

    private var shortcutCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // ショートカットを押している間だけサークルを表示する。
        shortcuts.onPress = { [weak self] in self?.overlay.show() }
        shortcuts.onRelease = { [weak self] in self?.overlay.hide() }

        // 設定でショートカットが変わったら監視に反映する。
        shortcutCancellable = AppSettings.shared.$shortcut.sink { [weak self] combo in
            self?.shortcuts.updateCombo(combo)
        }

        // Carbon ホットキーはアクセシビリティ権限不要。起動時にそのまま有効化する。
        shortcuts.start()
    }
}
