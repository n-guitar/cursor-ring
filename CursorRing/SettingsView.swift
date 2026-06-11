import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    @State private var recording = false
    @State private var recorderMonitor: Any?

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
                Text("⌃ ⌥ ⇧ ⌘ のいずれかと組み合わせて記録してください。特別な権限は不要です。")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 480)
        .onDisappear { stopRecording() }
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
