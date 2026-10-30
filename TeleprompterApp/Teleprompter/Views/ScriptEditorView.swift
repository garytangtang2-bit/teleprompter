import SwiftUI
import UIKit

struct ScriptEditorView: View {
    @EnvironmentObject private var storage: ScriptStorage
    @Environment(\.dismiss) private var dismiss

    let existing: Script?

    @State private var title: String
    @State private var bodyText: String

    init(existing: Script?) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _bodyText = State(initialValue: existing?.body ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("稿件標題", text: $title)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                Divider()
                TextEditor(text: $bodyText)
                    .font(.body)
                    .padding(.horizontal, 12)
                Divider()
                HStack(spacing: 12) {
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("貼上", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        bodyText = bodyText.splitIntoSentenceLines()
                    } label: {
                        Label("每句分行", systemImage: "text.line.first.and.arrowtriangle.forward")
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                    Text("\(bodyText.count) 字")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "新增稿件" : "編輯稿件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    private func pasteFromClipboard() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        if bodyText.isEmpty {
            bodyText = text
        } else {
            bodyText += (bodyText.hasSuffix("\n") ? "" : "\n") + text
        }
    }

    private func save() {
        var finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalTitle.isEmpty {
            let firstLine = bodyText
                .split(separator: "\n", omittingEmptySubsequences: true)
                .first
                .map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
            finalTitle = firstLine.isEmpty ? "未命名稿件" : String(firstLine.prefix(20))
        }

        if var script = existing {
            script.title = finalTitle
            script.body = bodyText
            storage.update(script)
        } else {
            storage.add(title: finalTitle, body: bodyText)
        }
        dismiss()
    }
}
