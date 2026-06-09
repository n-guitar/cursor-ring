import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    @State private var recording = false
    @State private var recorderMonitor: Any?
    @State private var accessibilityTrusted = Accessibility.isTrusted

    var body: some View {
        Form {
            Section("見た目") {
                Picker("形", selection: $settings.shape) {
                    ForEach(CursorShape.allCases) { shape in
                        Text(shape.label).tag(shape)
                    }
                }

                ColorPicker("色", selection: $settings.color, supportsOpacity: true)

                HStack {
                    Text("サイズ")
                    Slider(value: $settings.diameter, in: 20...400)
                    Text("\(Int(settings.diameter)) px").monospacedDigit().frame(width: 56, alignment: .trailing)
                }

                if settings.shape != .circle {
                    HStack {
                        Text("線の太さ")
                        Slider(value: $settings.lineWidth, in: 1...40)
                        Text("\(Int(settings.lineWidth)) px").monospacedDigit().frame(width: 56, alignment: .trailing)
                    }
                }
            }

            Section("ショートカット（押している間だけ表示）") {
                HStack {
                    Text("現在: \(settings.shortcut.displayString)").font(.body.monospaced())
                    Spacer()
                    Button(recording ? "修飾キー + キーを押す…" : "変更") {
                        recording ? stopRecording() : startRecording()
                    }
                }
                Text("⌃ ⌥ ⇧ ⌘ のいずれかと組み合わせて記録してください。")
                    .font(.caption).foregroundColor(.secondary)
            }

            Section("権限") {
                HStack {
                    Image(systemName: accessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(accessibilityTrusted ? .green : .orange)
                    Text(accessibilityTrusted ? "アクセシビリティ権限: 許可済み" : "アクセシビリティ権限が必要です")
                    Spacer()
                    if !accessibilityTrusted {
                        Button("システム設定を開く") { Accessibility.openSettings() }
                    }
                }
                Text("グローバルショートカットの検知にアクセシビリティ権限が必要です。許可後、しばらく待つか再起動すると有効になります。")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .onAppear { accessibilityTrusted = Accessibility.isTrusted }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        recording = true
        recorderMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection(KeyCombo.trackedModifiers)
            // 修飾キーなしの単独キーは誤爆防止のため無効にする。
            guard !mods.isEmpty else { return nil }
            let label = (event.charactersIgnoringModifiers ?? "").uppercased()
            settings.shortcut = KeyCombo(keyCode: event.keyCode, modifiers: mods, keyLabel: label)
            stopRecording()
            return nil   // 記録中のキーは他へ流さない
        }
    }

    private func stopRecording() {
        recording = false
        if let monitor = recorderMonitor {
            NSEvent.removeMonitor(monitor)
            recorderMonitor = nil
        }
    }
}
