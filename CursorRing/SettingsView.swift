import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    @State private var recording = false
    @State private var recorderMonitor: Any?

    var body: some View {
        let l = settings.l10n
        Form {
            Section(l.sectionAppearance) {
                Picker(l.shape, selection: $settings.shape) {
                    ForEach(CursorShape.allCases) { shape in
                        Text(l.shapeName(shape)).tag(shape)
                    }
                }

                ColorPicker(l.color, selection: $settings.color, supportsOpacity: true)

                sliderRow(title: l.width, value: $settings.width, range: 20...600)
                sliderRow(title: l.height, value: $settings.height, range: 20...600)
                sliderRow(title: l.lineWidth, value: $settings.lineWidth, range: 1...40)

                HStack {
                    Spacer()
                    Button(l.resetSize) { settings.resetSize() }
                }
            }

            Section(l.sectionShortcut) {
                HStack {
                    Text("\(l.current) \(settings.shortcut.displayString)").font(.body.monospaced())
                    Spacer()
                    Button(recording ? l.pressKeys : l.change) {
                        recording ? stopRecording() : startRecording()
                    }
                }
                Text(l.shortcutHintCombo)
                    .font(.caption).foregroundColor(.secondary)
                Text(l.shortcutHintBehavior)
                    .font(.caption).foregroundColor(.secondary)
                Text(l.shortcutHintFnKey)
                    .font(.caption).foregroundColor(.secondary)
            }

            Section(l.sectionLanguage) {
                Picker(l.sectionLanguage, selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.label).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 600)
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
            let isFunctionKey = KeyNames.isFunctionKey(event.keyCode)
            // 修飾キー無しの単独キーはファンクションキーのときだけ許可（誤爆防止）。
            guard !mods.isEmpty || isFunctionKey else { return nil }
            let label = KeyNames.label(for: event.keyCode)
                ?? (event.charactersIgnoringModifiers ?? "").uppercased()
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
