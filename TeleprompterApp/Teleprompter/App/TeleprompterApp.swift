import SwiftUI

@main
struct TeleprompterApp: App {
    @StateObject private var scriptStorage = ScriptStorage()
    @StateObject private var settingsStorage = SettingsStorage()

    var body: some Scene {
        WindowGroup {
            ScriptLibraryView()
                .environmentObject(scriptStorage)
                .environmentObject(settingsStorage)
        }
    }
}
