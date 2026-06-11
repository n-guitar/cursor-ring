import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay = OverlayController()
    let settingsWindow = SettingsWindowController()
    private let shortcuts = ShortcutMonitor(combo: AppSettings.shared.shortcut)

    private var shortcutCancellable: AnyCancellable?

    // タップ＝トグル / 長押し＝一時表示 を見分ける状態。
    private enum ShowState {
        case hidden      // 非表示
        case pressing    // 押下中（タップか長押しか未確定）
        case toggledOn   // タップで出したまま
    }
    private var showState: ShowState = .hidden
    private var pressDownAt: Date?
    private var keyIsDown = false
    private let tapThreshold: TimeInterval = 0.35   // これ未満の押下はタップ＝トグル

    func applicationDidFinishLaunching(_ notification: Notification) {
        shortcuts.onPress = { [weak self] in self?.handlePress() }
        shortcuts.onRelease = { [weak self] in self?.handleRelease() }

        // 設定でショートカットが変わったら監視に反映する。
        shortcutCancellable = AppSettings.shared.$shortcut.sink { [weak self] combo in
            self?.shortcuts.updateCombo(combo)
        }

        // Carbon ホットキーはアクセシビリティ権限不要。起動時にそのまま有効化する。
        shortcuts.start()
    }

    /// ショートカット押下。
    /// - 非表示 → 表示して押下中（タップ/長押し未確定）
    /// - 出したまま → もう一度押されたので消す
    private func handlePress() {
        if keyIsDown { return }   // キーの自動リピートを無視
        keyIsDown = true

        switch showState {
        case .toggledOn:
            overlay.hide()
            showState = .hidden
        case .hidden:
            overlay.show()
            showState = .pressing
            pressDownAt = Date()
        case .pressing:
            break
        }
    }

    /// ショートカットを離した。押下が短ければタップ＝出したまま、長ければ長押し＝消す。
    private func handleRelease() {
        keyIsDown = false
        guard showState == .pressing else { return }

        let held = Date().timeIntervalSince(pressDownAt ?? Date())
        if held < tapThreshold {
            showState = .toggledOn      // タップ → 出したまま
        } else {
            overlay.hide()              // 長押し → 離したらしまう
            showState = .hidden
        }
    }
}
