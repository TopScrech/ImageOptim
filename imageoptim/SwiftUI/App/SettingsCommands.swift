import SwiftUI

struct SettingsCommands: Commands {
    @Environment(\.openSettings) private var openSettings
    @FocusedValue(\.closeSettings) private var closeSettings

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…", systemImage: "gearshape") {
                if let closeSettings {
                    closeSettings()
                } else {
                    openSettings()
                }
            }
            .keyboardShortcut(",")
        }
    }
}
