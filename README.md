# cursor-ring

[![Build](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml/badge.svg)](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml)

グローバルショートカットを押している間、マウスカーソルに追従してサークルを表示する macOS メニューバー常駐アプリ。

- 設計・調査ログ: [n-guitar/second-brain #287](https://github.com/n-guitar/second-brain/issues/287)
- 言語/UI: Swift + SwiftUI（`MenuBarExtra` / 設定画面）+ AppKit（オーバーレイ描画・イベント監視）
- 対象: macOS 13 (Ventura) 以降

## 進め方（#287 のステップ）

1. Xcode で macOS App（SwiftUI / `MenuBarExtra`）を新規作成。`LSUIElement=YES` ✅
2. 透明・クリック透過の `NSWindow` に固定の円を描く ✅
3. `NSEvent.mouseLocation` でマウス追従 ✅
4. グローバルショートカット（押している間だけ表示）+ アクセシビリティ権限誘導 ✅
5. 色・形・サイズ・ショートカットの設定 UI（`@AppStorage` / `UserDefaults`）✅
6. （配布するなら）署名・Notarization・権限誘導 — **未着手**（不可逆な配布の境界のため保留）

配布（署名/Notarization）は後回し。まずは個人利用版。

## 実装状況

- メニューバー常駐（`MenuBarExtra`、`LSUIElement=YES` で Dock に出さない）
- 透明・クリック透過・最前面のオーバーレイ（`OverlayWindow`）
  - `.borderless` / `backgroundColor = .clear` / `isOpaque = false`
  - `ignoresMouseEvents = true`（クリック透過）/ `level = .screenSaver`
  - 全ディスプレイを覆う矩形に対応（マルチディスプレイで追従）
- `CAShapeLayer` でサークル描画（`CursorShapeView`）。形は `enum CursorShape { circle, ring, square, cross }`
- `NSEvent` でマウス追従（`MouseTracker`）/ グローバルキー監視（`ShortcutMonitor`）
- 設定画面（`SettingsView`）: 色・形・サイズ・線幅・ショートカット変更・権限状態
- 設定は `UserDefaults` に永続化（`AppSettings`）

### ショートカットライブラリについて

#287 では設定 UI に `KeyboardShortcuts`（Sindre Sorhus）の採用を想定していたが、
本コミットでは**外部 SPM 依存を入れていない**。理由:

- この実行環境（Linux）では SPM のバージョン解決もビルドも検証できない
- 手書きの `.xcodeproj` に未検証の依存を足して解決に失敗すると、プロジェクト全体が開けなくなる

そのため**ショートカット記録 UI を `NSEvent` で自前実装**し、設定可否の要件は満たした上で
依存ゼロにしている。`KeyboardShortcuts` の Recorder に差し替えたい場合は、Xcode の
`File > Add Package Dependencies…` で `https://github.com/sindresorhus/KeyboardShortcuts`
を追加し、`SettingsView` の記録部分と `ShortcutMonitor` を `KeyboardShortcuts.onKeyDown/onKeyUp`
に置き換える（差し替え点は1ファイルずつに分離済み）。

## 検証状況

- **コンパイル・リンク: 検証済み**。GitHub Actions（macOS / Xcode 15.4、`arm64`＋`x86_64`、
  deployment target macOS 13.0）で `xcodebuild` が `** BUILD SUCCEEDED **`。
  以後の push でも `.github/workflows/build.yml` が自動でビルド検証する。
- **実機での動作（リングの見た目・マウス追従・権限フロー）: 未確認**。
  CI はコンパイルのみを保証する。実際の挙動はお手元で ⌘R して確認してほしい。
  おかしい点があれば指摘してくれれば直す。

## ビルド・実行

```sh
open CursorRing.xcodeproj
```

Xcode で Run（⌘R）。Dock には出ず、メニューバーに破線円アイコンが出る。

1. 初回起動時、グローバルキー監視のため**アクセシビリティ権限**を求められる
   （システム設定 > プライバシーとセキュリティ > アクセシビリティ で CursorRing を許可）
2. 既定ショートカット **⌃⌥R** を押している間、マウスに追従して赤いリングが出る
3. メニューの「設定…」で色・形・サイズ・ショートカットを変更できる
4. メニューの「サークルを表示（テスト）」で固定表示の確認もできる

> ローカル実行のみなら署名は「Sign to Run Locally」で動く。配布時に Apple Developer 署名 + Notarization が必要（ステップ6）。

## 構成

```
CursorRing/
  CursorRingApp.swift            @main / MenuBarExtra（メニュー）
  AppDelegate.swift              ショートカット監視と表示の配線・権限確認
  OverlayController.swift        オーバーレイ生成・表示・マウス追従・設定反映
  OverlayWindow.swift            透明・クリック透過・最前面の NSWindow
  CursorShapeView.swift          CAShapeLayer でサークルを描く NSView
  CursorShape.swift              形の enum（パス差し替え）
  MouseTracker.swift             NSEvent によるマウス追従
  ShortcutMonitor.swift          NSEvent によるグローバルキー監視 + 権限ヘルパ
  AppSettings.swift              設定の保持・永続化（UserDefaults）
  SettingsView.swift             設定画面（SwiftUI）
  SettingsWindowController.swift 設定ウィンドウ管理（AppKit）
  NSColor+Hex.swift              色の保存用 hex 変換
```
