import SwiftUI

/// Teleprompter settings, persisted in UserDefaults and restored on launch.
final class SettingsStorage: ObservableObject {
    @Published var settings: TeleprompterSettings {
        didSet { save() }
    }

    private static let key = "teleprompterSettings.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           var decoded = try? JSONDecoder().decode(TeleprompterSettings.self, from: data) {
            decoded.clampValues()
            settings = decoded
        } else {
            settings = TeleprompterSettings()
        }
    }

    func binding<T>(_ keyPath: WritableKeyPath<TeleprompterSettings, T>) -> Binding<T> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { self.settings[keyPath: keyPath] = $0 }
        )
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
