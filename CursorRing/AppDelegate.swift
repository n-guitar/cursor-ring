import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay = OverlayController()
    let settingsWindow = SettingsWindowController()
    private let shortcuts = ShortcutMonitor(combo: AppSettings.shared.shortcut)

    private var shortcutCancellable: AnyCancellable?

    // タップ＝トグル / 長押し＝一時表示・伸縮 を見分ける状態。
    //
    // キー押下中はスクロール捕捉 ON（2本指スクロールで伸縮、下のアプリに漏れない）。
    // - 非表示からタップ        → 出したまま（クリック透過に戻す）
    // - 非表示から長押し        → 押している間だけ表示、離すと消える
    // - 出したまま中にタップ    → 消す
    // - 出したまま中に長押し    → 押している間は伸縮モード、離しても出したまま
    private enum ShowState {
        case hidden
        case pressingFromHidden   // 非表示から押下中（タップ/長押し未確定）
        case toggledOn            // タップで出したまま
        case pressingFromShown    // 出したまま中に押下中（タップ=消す / 長押し=伸縮）
    }
    private var showState: ShowState = .hidden
    private var pressDownAt = Date()
    private let tapThreshold: TimeInterval = 0.35   // これ未満の押下はタップ

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

    private func handlePress() {
        pressDownAt = Date()
        switch showState {
        case .hidden:
            overlay.show()
            overlay.setScrollCapture(true)
            showState = .pressingFromHidden
        case .toggledOn:
            overlay.setScrollCapture(true)
            showState = .pressingFromShown
        case .pressingFromHidden, .pressingFromShown:
            break
        }
    }

    private func handleRelease() {
        let isTap = Date().timeIntervalSince(pressDownAt) < tapThreshold
        switch showState {
        case .pressingFromHidden:
            if isTap {
                overlay.setScrollCapture(false)   // タップ → 出したまま（クリック透過に戻す）
                showState = .toggledOn
            } else {
                overlay.hide()                    // 長押し → 離したらしまう
                showState = .hidden
            }
        case .pressingFromShown:
            if isTap {
                overlay.hide()                    // タップ → 消す
                showState = .hidden
            } else {
                overlay.setScrollCapture(false)   // 長押し（伸縮）→ 出したままに戻る
                showState = .toggledOn
            }
        case .hidden, .toggledOn:
            break
        }
    }
}
