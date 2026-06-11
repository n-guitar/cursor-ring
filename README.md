# cursor-ring

[![Build](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml/badge.svg)](https://github.com/n-guitar/cursor-ring/actions/workflows/build.yml)

<p align="center">
  <img src="design/icon.png" width="160" alt="cursor-ring icon">
</p>

**Show your audience exactly where to look.**
cursor-ring draws a ring around your mouse pointer with a single keypress, so you can call out the
spot you're talking about — during screen shares, demos, presentations, live coding, and recordings.
It lives in the menu bar and stays out of the Dock.

> 🇯🇵 日本語の説明は [**README.ja.md**](README.ja.md) にあります。

Free and open source under the [MIT License](LICENSE) — use it however you like.

## Features

- 🔵 **A ring that follows your cursor**, shown with one key — point at what matters
- ⏱ **Two ways to show it**
  - **Tap** → stays on; tap again to hide
  - **Hold** → visible only while the key is held
- 🖱 **Resize on the fly** — hold the key and two-finger scroll (up/down = height, left/right = width). Turn the ring into an ellipse, or the square into a rectangle
- 🎨 **Make it yours** — shape (ring / square), color, width, height, line thickness
- ⌨️ **Re-bindable shortcut** — any key combo, or a single key like F1
- 🪟 Multi-display aware / never blocks clicks to the app underneath
- 🔒 **No special permissions required** (no Accessibility prompt)

> Requires macOS 13 (Ventura) or later.

## Install (no Xcode needed)

1. Open [**Releases**](https://github.com/n-guitar/cursor-ring/releases/latest), download the latest `CursorRing.zip`, and unzip it
2. Move `CursorRing.app` to your Applications folder
3. The first launch is blocked by Gatekeeper (the build is unsigned). Work around it with either:
   - Right-click `CursorRing.app` → **Open** → **Open** in the dialog
   - or run `xattr -dr com.apple.quarantine /path/to/CursorRing.app` in Terminal

> This is an unsigned, non-notarized build for personal use, so the one-time step above is needed.

## Usage

After launching, an icon appears in the menu bar (nothing in the Dock).

1. Press the shortcut (**⌃⌥R** by default; change it in Settings)
   - **Tap** → the ring stays on. Tap again to hide it
   - **Hold** → the ring shows only while held
2. **Hold the key and two-finger scroll** to resize the ring (up/down = height, left/right = width).
   Scrolling only affects the ring during this — it won't scroll the app underneath
3. Menu bar icon → **Settings** to change shape, color, size, and the shortcut

---

## For developers

<details>
<summary>How it works / build / structure (click to expand)</summary>

### Overview

- Swift + SwiftUI (`MenuBarExtra`, settings window) + AppKit (overlay drawing, event monitoring)
- Menu-bar resident via `MenuBarExtra` + `LSUIElement=YES` (hidden from Dock)
- Overlay is a transparent, click-through, top-most `NSWindow`
  - `.borderless` / `backgroundColor = .clear` / `isOpaque = false` / `ignoresMouseEvents = true` / `level = .screenSaver`
  - **One overlay window per display** (`NSScreen`), so it renders correctly across mixed resolutions/scales; rebuilt on display changes
- Drawing via `CAShapeLayer` (`CursorShapeView`). Shape is `enum CursorShape { ring, square }` (independent width/height → ellipse/rectangle)
- Shortcut detection uses **Carbon `RegisterEventHotKey`** (`ShortcutMonitor`) → **no Accessibility permission**
  - "released" is detected by polling `CGEventSource.keyState` (Carbon's released event can be missed if a modifier is released first)
- Resize: while the key is held, click-through is disabled so the overlay itself consumes `scrollWheel` (doesn't leak to the app below)
- Mouse following (`MouseTracker`) uses an `NSEvent` global monitor (mouse events need no permission)
- Settings persist in `UserDefaults` (`AppSettings`)

### Build

```sh
open CursorRing.xcodeproj
```

Run with ⌘R (signing can be "Sign to Run Locally" for local use).

CI builds on every push (`.github/workflows/build.yml`, macOS / Xcode 15.4, universal). Tagged
releases (`.github/workflows/release.yml`, on `v*` tag push or manual run) attach `CursorRing.zip`
to a GitHub Release.

### Icon

`design/icon.svg` is the source. The PNGs in `CursorRing/Assets.xcassets/AppIcon.appiconset` are
generated from it — edit the SVG and regenerate the sizes to change the icon.

### Structure

```
CursorRing/
  CursorRingApp.swift            @main / MenuBarExtra (menu)
  AppDelegate.swift              wires shortcut → show/hide (tap/hold/resize state machine)
  OverlayController.swift        per-display overlays, cursor following, scroll capture, settings
  OverlayWindow.swift            transparent click-through top-most NSWindow
  CursorShapeView.swift          draws the ring with CAShapeLayer (and consumes scroll)
  CursorShape.swift              shape enum (swap the path)
  MouseTracker.swift             cursor following via NSEvent
  ShortcutMonitor.swift          Carbon RegisterEventHotKey (no permission)
  AppSettings.swift              settings storage / persistence (UserDefaults)
  SettingsView.swift             settings screen (SwiftUI)
  SettingsWindowController.swift settings window management (AppKit)
  NSColor+Hex.swift              color hex conversion for persistence
```

### Not done yet

- Code signing / notarization for distribution (needs an Apple Developer account)

</details>

## License

[MIT License](LICENSE) © n-guitar. Completely free — use, modify, and redistribute freely.
