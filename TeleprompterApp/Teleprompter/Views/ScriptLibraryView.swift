import SwiftUI

private struct EditorTarget: Identifiable {
    let id = UUID()
    let script: Script?
}

struct ScriptLibraryView: View {
    @EnvironmentObject private var storage: ScriptStorage

    @State private var editorTarget: EditorTarget?
    @State private var recordingScript: Script?
    @State private var renamingScript: Script?
    @State private var renameText = ""
    @State private var deletingScript: Script?

    var body: some View {
        NavigationStack {
            Group {
                if storage.scripts.isEmpty {
                    emptyState
                } else {
                    scriptList
                }
            }
            .navigationTitle("我的稿件")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editorTarget = EditorTarget(script: nil)
                    } label: {
                        Label("新增稿件", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(item: $editorTarget) { target in
            ScriptEditorView(existing: target.script)
        }
        .fullScreenCover(item: $recordingScript) { script in
            CameraTeleprompterView(script: script)
        }
        .alert("重新命名", isPresented: Binding(
            get: { renamingScript != nil },
            set: { if !$0 { renamingScript = nil } }
        )) {
            TextField("稿件標題", text: $renameText)
            Button("取消", role: .cancel) {}
            Button("儲存") {
                if let script = renamingScript {
                    let title = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !title.isEmpty {
                        storage.rename(id: script.id, title: title)
                    }
                }
            }
        }
        .alert("刪除稿件", isPresented: Binding(
            get: { deletingScript != nil },
            set: { if !$0 { deletingScript = nil } }
        )) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                if let script = deletingScript {
                    storage.delete(id: script.id)
                }
            }
        } message: {
            Text("確定要刪除「\(deletingScript?.title ?? "")」嗎？此動作無法復原。")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("還沒有稿件")
                .font(.headline)
            Text("按右上角「＋」新增你的第一份稿件。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("新增稿件") {
                editorTarget = EditorTarget(script: nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var scriptList: some View {
        List {
            ForEach(storage.scripts) { script in
                Button {
                    recordingScript = script
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(script.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(previewText(script))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Label("開始拍攝", systemImage: "video.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deletingScript = script
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                    Button {
                        editorTarget = EditorTarget(script: script)
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .contextMenu {
                    Button {
                        recordingScript = script
                    } label: {
                        Label("開始拍攝", systemImage: "video.fill")
                    }
                    Button {
                        editorTarget = EditorTarget(script: script)
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }
                    Button {
                        renameText = script.title
                        renamingScript = script
                    } label: {
                        Label("重新命名", systemImage: "character.cursor.ibeam")
                    }
                    Button(role: .destructive) {
                        deletingScript = script
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func previewText(_ script: Script) -> String {
        let flat = script.body.replacingOccurrences(of: "\n", with: " ")
        return flat.isEmpty ? "（空白稿件）" : flat
    }
}
