# cursor-ring

グローバルショートカット押下中、マウスカーソル周りにサークルを表示する macOS メニューバー常駐アプリ。

- 設計・調査ログ: [n-guitar/second-brain #287](https://github.com/n-guitar/second-brain/issues/287)
- 言語/UI: Swift + SwiftUI（`MenuBarExtra`）+ AppKit（オーバーレイ描画）
- 対象: macOS 13 (Ventura) 以降

## 進め方（#287 のステップ）

1. Xcode で macOS App（SwiftUI / `MenuBarExtra`）を新規作成。`LSUIElement=YES`
2. **透明・クリック透過の `NSWindow` に固定の円を描く（追従なし）** ← 現在ここまで実装済み
3. `NSEvent.mouseLocation` でマウス追従
4. `KeyboardShortcuts` を SPM で追加し、設定画面 + `onKeyDown` で表示トグル
5. 色・形・サイズの設定 UI（`@AppStorage`）
6. （配布するなら）署名・Notarization・権限誘導

配布（署名/Notarization）は後回し。まずは個人利用版。

## 実装状況（ステップ2まで）

- メニューバー常駐（`MenuBarExtra`、`LSUIElement=YES` で Dock に出さない）
- 透明・クリック透過・最前面のオーバーレイウィンドウ（`OverlayWindow`）
  - `.borderless` / `backgroundColor = .clear` / `isOpaque = false`
  - `ignoresMouseEvents = true`（クリック透過）/ `level = .screenSaver`
- `CAShapeLayer` で**画面中央に固定の円**を描画（`CursorShapeView`）
- 形は `enum CursorShape { circle, ring, square, cross }` で抽象化（パス差し替え式）
- メニューからサークルの表示/非表示トグル・終了

まだ実装していない: マウス追従（3）、グローバルショートカット（4）、設定 UI（5）。

## ビルド・実行

```sh
open CursorRing.xcodeproj
```

Xcode で Run（⌘R）。起動すると Dock には出ず、メニューバーに破線円アイコンが出て、
画面中央に赤い円が表示される。メニューから「サークルを隠す」「CursorRing を終了」。

> ローカル実行のみなら署名は「Sign to Run Locally」で動く。配布時に Apple Developer 署名 + Notarization が必要（ステップ6）。

## 構成

```
CursorRing/
  CursorRingApp.swift     @main / MenuBarExtra（メニュー）
  AppDelegate.swift       起動時にオーバーレイを表示
  OverlayController.swift オーバーレイの生成・表示・破棄
  OverlayWindow.swift     透明・クリック透過・最前面の NSWindow
  CursorShapeView.swift   CAShapeLayer でサークルを描く NSView
  CursorShape.swift       形の enum（パス差し替え）
```
