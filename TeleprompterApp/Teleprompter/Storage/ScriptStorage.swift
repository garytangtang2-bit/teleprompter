import Foundation

/// Stores scripts as a JSON file in the app's Documents folder (local only, no network).
final class ScriptStorage: ObservableObject {
    @Published private(set) var scripts: [Script] = []

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("scripts.json")
        load()
    }

    @discardableResult
    func add(title: String, body: String) -> Script {
        let script = Script(title: title, body: body)
        scripts.append(script)
        saveAndSort()
        return script
    }

    func update(_ script: Script) {
        guard let index = scripts.firstIndex(where: { $0.id == script.id }) else { return }
        var updated = script
        updated.updatedAt = Date()
        scripts[index] = updated
        saveAndSort()
    }

    func rename(id: UUID, title: String) {
        guard let index = scripts.firstIndex(where: { $0.id == id }) else { return }
        scripts[index].title = title
        scripts[index].updatedAt = Date()
        saveAndSort()
    }

    func delete(id: UUID) {
        scripts.removeAll { $0.id == id }
        saveAndSort()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Script].self, from: data) else { return }
        scripts = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func saveAndSort() {
        scripts.sort { $0.updatedAt > $1.updatedAt }
        do {
            let data = try JSONEncoder().encode(scripts)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save scripts: \(error)")
        }
    }
}
