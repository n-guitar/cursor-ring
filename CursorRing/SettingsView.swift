import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    @State private var recording = false
    @State private var recorderMonitor: Any?
    @State private var accessibilityTrusted = Accessibility.isTrusted

    // 権限状態を 1 秒ごとに見直して表示を自動更新する。
    private let pollTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section("見た目") {
                Picker("形", selection: $settings.shape) {
                    ForEach(CursorShape.allCases) { shape in
                        Text(shape.label).tag(shape)
                    }
                }

                ColorPicker("色", selection: $settings.color, supportsOpacity: true)

                sliderRow(title: "横幅", value: $settings.width, range: 20...600)
                sliderRow(title: "縦幅", value: $settings.height, range: 20...600)
                sliderRow(title: "線の太さ", value: $settings.lineWidth, range: 1...40)
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
                Text(accessibilityTrusted
                     ? "ショートカット監視が有効です。"
                     : "グローバルショートカットの検知に必要です。許可するとここが自動で「許可済み」に変わります。")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 560)
        .onAppear { accessibilityTrusted = Accessibility.isTrusted }
        .onDisappear { stopRecording() }
        .onReceive(pollTimer) { _ in
            accessibilityTrusted = Accessibility.isTrusted
        }
    }

    @ViewBuilder
    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue)) px")
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
        }
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
