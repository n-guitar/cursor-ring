# cursor-ring

[![Build](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml/badge.svg)](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml)

グローバルショートカットを押している間、マウスカーソルに追従してサークルを表示する macOS メニューバー常駐アプリ。

- 言語/UI: Swift + SwiftUI（`MenuBarExtra` / 設定画面）+ AppKit（オーバーレイ描画・イベント監視）
- 対象: macOS 13 (Ventura) 以降

## 進め方（実装ステップ）

1. Xcode で macOS App（SwiftUI / `MenuBarExtra`）を新規作成。`LSUIElement=YES` ✅
2. 透明・クリック透過の `NSWindow` に固定の円を描く ✅
3. `NSEvent.mouseLocation` でマウス追従 ✅
4. グローバルショートカット（押している間だけ表示）— Carbon ホットキーで**権限不要** ✅
5. 色・形・サイズ・ショートカットの設定 UI（`@AppStorage` / `UserDefaults`）✅
6. （配布するなら）署名・Notarization・権限誘導 — **未着手**（不可逆な配布の境界のため保留）

配布（署名/Notarization）は後回し。まずは個人利用版。

## 実装状況

- メニューバー常駐（`MenuBarExtra`、`LSUIElement=YES` で Dock に出さない）
- 透明・クリック透過・最前面のオーバーレイ（`OverlayWindow`）
  - `.borderless` / `backgroundColor = .clear` / `isOpaque = false`
  - `ignoresMouseEvents = true`（クリック透過）/ `level = .screenSaver`
  - 全ディスプレイを覆う矩形に対応（マルチディスプレイで追従）
- `CAShapeLayer` でサークル描画（`CursorShapeView`）。形は `enum CursorShape { ring, square }`（縦横別指定で楕円・長方形に）
- ショートカットは **Carbon `RegisterEventHotKey`**（`ShortcutMonitor`）で検知 — **アクセシビリティ権限不要**
- マウス追従（`MouseTracker`）・スクロール伸縮（`ScrollMonitor`）は `NSEvent` のグローバル監視（マウス系は権限不要）
- 設定画面（`SettingsView`）: 色・形・横幅・縦幅・線幅・ショートカット変更
- 設定は `UserDefaults` に永続化（`AppSettings`）

> **権限について**: ショートカット検知に Carbon ホットキーを使うため、アクセシビリティ権限は不要。
> 当初は `NSEvent` のグローバルキー監視（要・アクセシビリティ権限）を使っていたが、未署名アプリだと
> 権限の付与が TCC の署名不一致で効かない問題があり、権限不要な Carbon 方式へ切り替えた。

### ショートカットライブラリについて

当初は設定 UI に `KeyboardShortcuts`（Sindre Sorhus）の採用を想定していたが、
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

## ダウンロードして使う（Xcode 不要）

push のたびに CI が `.app` をビルドし、成果物として添付する。

1. GitHub の Actions タブ → 対象の Build 実行 → 下部 Artifacts の `CursorRing-app` を取得
2. zip を展開し、`CursorRing.app` を Applications などに置く
3. **未署名のため初回起動は Gatekeeper に止められる**。回避はどちらか:
   - `CursorRing.app` を右クリック →「開く」→ ダイアログで「開く」
   - もしくはターミナルで `xattr -dr com.apple.quarantine /path/to/CursorRing.app`
4. 起動したら既定ショートカットを押している間にリングが出る。**アクセシビリティ等の権限付与は不要**

> CI 産の `.app` は未署名・未 Notarize。自分の Mac で動かす個人利用向け。配布は別途署名 + Notarization が必要。

## ビルド・実行（Xcode）

```sh
open CursorRing.xcodeproj
```

Xcode で Run（⌘R）。Dock には出ず、メニューバーに破線円アイコンが出る。

1. 既定ショートカット **⌃⌥R** を押している間、マウスに追従して赤いリングが出る（権限付与は不要）
2. リング表示中にスクロールで伸縮（上下スクロール＝縦、左右スクロール＝横。トラックパッドは2本指で縦横自在）
3. メニューの「設定…」で形・色・横幅・縦幅・線の太さ・ショートカットを変更できる
4. メニューの「サークルを表示（テスト）」で固定表示の確認もできる

> ローカル実行のみなら署名は「Sign to Run Locally」で動く。配布時に Apple Developer 署名 + Notarization が必要（ステップ6）。

## 構成

```
CursorRing/
  CursorRingApp.swift            @main / MenuBarExtra（メニュー）
  AppDelegate.swift              ショートカット監視と表示の配線
  OverlayController.swift        オーバーレイ生成・表示・マウス追従・スクロール伸縮・設定反映
  OverlayWindow.swift            透明・クリック透過・最前面の NSWindow
  CursorShapeView.swift          CAShapeLayer でサークルを描く NSView
  CursorShape.swift              形の enum（パス差し替え）
  MouseTracker.swift             NSEvent によるマウス追従
  ScrollMonitor.swift            NSEvent によるスクロール伸縮
  ShortcutMonitor.swift          Carbon RegisterEventHotKey によるホットキー検知（権限不要）
  AppSettings.swift              設定の保持・永続化（UserDefaults）
  SettingsView.swift             設定画面（SwiftUI）
  SettingsWindowController.swift 設定ウィンドウ管理（AppKit）
  NSColor+Hex.swift              色の保存用 hex 変換
```
