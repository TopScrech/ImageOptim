import SwiftUI

@main
struct ImageOptimApp: App {
    @NSApplicationDelegateAdaptor(ImageOptimController.self) private var delegate
    @State private var model = OptimizationViewModel()
    @AppStorage("AlwaysOnTop") private var alwaysOnTop = false

    var body: some Scene {
        Window("ImageOptim", id: "optimization") {
            OptimizationView()
                .background {
                    WindowLevelView(alwaysOnTop: alwaysOnTop)
                }
                .environment(model)
                .focusedSceneValue(\.optimizationModel, model)
                .onAppear {
                    model.connect(to: delegate)
                }
        }
        .defaultSize(width: 800, height: 480)
        .commands {
            OptimizationCommands()
            SettingsCommands()
        }

        Settings {
            SettingsView()
                .background {
                    WindowLevelView(alwaysOnTop: alwaysOnTop)
                }
        }
    }
}
