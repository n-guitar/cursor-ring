# cursor-ring

[![Build](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml/badge.svg)](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml)

**マウスカーソルの位置に“リング”を出して、今どこを指しているか一目で分かるようにする macOS アプリ。**
キーを押すだけでカーソルの周りに目印が出るので、画面共有・プレゼン・録画・大きな画面での作業で「マウスどこ？」を解決します。メニューバーに常駐し、Dock には出ません。

## できること

- 🔵 **カーソルに追従するリング**を、キー一つで表示
- ⏱ **2通りの出し方**
  - **タップ**（ポンと押す）→ 出したまま固定。もう一度タップで消す
  - **長押し**（押しっぱなし）→ 押している間だけ表示、離すと消える
- 🖱 **大きさをその場で調整** — キーを押しながら2本指スクロール（上下＝縦、左右＝横）。リングを楕円にも長方形にもできる
- 🎨 **見た目を自由に** — 形（リング／四角）・色・横幅・縦幅・線の太さを設定画面で変更
- ⌨️ **ショートカットは変更可能** — 好きなキー（F1 などの単独キーもOK）に割り当て
- 🪟 マルチディスプレイ対応 / 下のアプリ操作を邪魔しない（クリックは透過）
- 🔒 **特別な権限は不要**（アクセシビリティ権限などの許可なしで動く）

> 対象: macOS 13 (Ventura) 以降

## インストール（Xcode 不要）

1. 上の [![Build](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml/badge.svg)](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml) バッジか、GitHub の **Actions** タブから最新の「Build」を開く
2. ページ下部 **Artifacts** の `CursorRing-app` をダウンロードして展開
3. `CursorRing.app` を「アプリケーション」フォルダなどに移動
4. **初回だけ Gatekeeper に止められる**ので、どちらかで回避:
   - `CursorRing.app` を右クリック →「開く」→ ダイアログで「開く」
   - またはターミナルで `xattr -dr com.apple.quarantine /アプリのパス/CursorRing.app`

> 配布用に署名・公証（Notarization）はしていない個人利用向けビルドです。そのため初回だけ上の操作が要ります。

## 使い方

起動するとメニューバーにアイコンが出ます（Dock には出ません）。

1. **既定のショートカット ⌃⌥R**（設定で変更可）を押す
   - タップ → リングが出たまま。もう一度タップで消える
   - 長押し → 押している間だけ表示
2. **キーを押しながら2本指スクロール**でリングの大きさを調整（上下＝縦、左右＝横）
   - この操作中だけはスクロールが下のアプリ（ブラウザ等）に流れません
3. メニューバーアイコン →「設定…」で形・色・サイズ・ショートカットを変更
4. メニューの「サークルを表示（テスト）」で固定表示して見た目を確認できます

---

## 開発者向け

<details>
<summary>仕組み・ビルド・構成（クリックで展開）</summary>

### 技術概要

- Swift + SwiftUI（`MenuBarExtra` / 設定画面）+ AppKit（オーバーレイ描画・イベント監視）
- メニューバー常駐は `MenuBarExtra` + `LSUIElement=YES`（Dock 非表示）
- オーバーレイは透明・クリック透過・最前面の `NSWindow`
  - `.borderless` / `backgroundColor = .clear` / `isOpaque = false` / `ignoresMouseEvents = true` / `level = .screenSaver`
  - 全ディスプレイを覆う矩形でマルチディスプレイ追従
- 描画は `CAShapeLayer`（`CursorShapeView`）。形は `enum CursorShape { ring, square }`（縦横別指定で楕円・長方形）
- ショートカット検知は **Carbon `RegisterEventHotKey`**（`ShortcutMonitor`）→ **アクセシビリティ権限不要**
  - 「離した」検知は Carbon の released イベントではなく `CGEventSource.keyState` をポーリング
    （修飾キーを先に離すと released が届かない場合があるため）
- 伸縮はキー押下中だけ `ignoresMouseEvents` を解除し、オーバーレイ自身が `scrollWheel` を消費（下のアプリに漏れない）
- マウス追従（`MouseTracker`）は `NSEvent` グローバル監視（マウス系は権限不要）
- 設定は `UserDefaults` に永続化（`AppSettings`）

> 当初はショートカット検知に `NSEvent` のグローバルキー監視（要・アクセシビリティ権限）を使っていたが、
> 未署名アプリだと TCC の署名不一致で権限が効かない問題があり、権限不要な Carbon 方式へ切り替えた。
> 設定 UI のショートカット記録も外部ライブラリ（`KeyboardShortcuts`）を使わず `NSEvent` で自前実装している
> （`.xcodeproj` を手書き管理しているため、未検証の SPM 依存を入れない方針）。

### ビルド・実行

```sh
open CursorRing.xcodeproj
```

Xcode で Run（⌘R）。ローカル実行のみなら署名は「Sign to Run Locally」で動く。

push のたびに `.github/workflows/build.yml` が macOS ランナー（Xcode 15.4、`arm64`＋`x86_64`、
deployment target macOS 13.0）で `xcodebuild` し、`.app` を Artifacts として添付する。

### ファイル構成

```
CursorRing/
  CursorRingApp.swift            @main / MenuBarExtra（メニュー）
  AppDelegate.swift              ショートカット監視と表示の配線（タップ/長押し/伸縮の状態管理）
  OverlayController.swift        オーバーレイ生成・表示・マウス追従・スクロール捕捉切替・設定反映
  OverlayWindow.swift            透明・クリック透過・最前面の NSWindow
  CursorShapeView.swift          CAShapeLayer でサークルを描く NSView（スクロール消費もここ）
  CursorShape.swift              形の enum（パス差し替え）
  MouseTracker.swift             NSEvent によるマウス追従
  ShortcutMonitor.swift          Carbon RegisterEventHotKey によるホットキー検知（権限不要）
  AppSettings.swift              設定の保持・永続化（UserDefaults）
  SettingsView.swift             設定画面（SwiftUI）
  SettingsWindowController.swift 設定ウィンドウ管理（AppKit）
  NSColor+Hex.swift              色の保存用 hex 変換
```

### 今後（未着手）

- 配布する場合の署名・Notarization（Apple Developer 登録が必要）
- アプリアイコン（AppIcon）の追加

</details>
