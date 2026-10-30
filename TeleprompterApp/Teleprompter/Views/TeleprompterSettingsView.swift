import SwiftUI

struct TeleprompterSettingsView: View {
    @EnvironmentObject private var store: SettingsStorage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                SliderRow(
                    title: "組件闊度",
                    value: store.binding(\.panelWidth),
                    range: TeleprompterSettings.widthRange,
                    step: 0.01,
                    format: percent
                )
                SliderRow(
                    title: "組件高度",
                    value: store.binding(\.panelHeight),
                    range: TeleprompterSettings.heightRange,
                    step: 0.01,
                    format: percent
                )
                SliderRow(
                    title: "文字大小",
                    value: store.binding(\.fontSize),
                    range: TeleprompterSettings.fontSizeRange,
                    step: 1,
                    format: { "\(Int($0.rounded())) pt" }
                )
                SliderRow(
                    title: "提詞速度",
                    value: store.binding(\.speed),
                    range: TeleprompterSettings.speedRange,
                    step: 1,
                    format: { "\(Int($0.rounded())) pt/秒" }
                )
                SliderRow(
                    title: "文字透明度",
                    value: store.binding(\.textOpacity),
                    range: TeleprompterSettings.opacityRange,
                    step: 0.01,
                    format: percent
                )
                SliderRow(
                    title: "背景透明度",
                    value: store.binding(\.backgroundOpacity),
                    range: TeleprompterSettings.opacityRange,
                    step: 0.01,
                    format: percent
                )
                VStack(alignment: .leading, spacing: 8) {
                    Text("文字對齊")
                    Picker("文字對齊", selection: store.binding(\.textAlignment)) {
                        Text("靠左").tag(TeleprompterSettings.TextAlignment.left)
                        Text("置中").tag(TeleprompterSettings.TextAlignment.center)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                SliderRow(
                    title: "行距",
                    value: store.binding(\.lineSpacing),
                    range: TeleprompterSettings.lineSpacingRange,
                    step: 1,
                    format: { "\(Int($0.rounded())) pt" }
                )
            }
            .navigationTitle("提詞設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(format(value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
        .padding(.vertical, 2)
    }
}
