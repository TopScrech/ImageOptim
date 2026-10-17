import SwiftUI

@main
struct ImageOptimApp: App {
    @NSApplicationDelegateAdaptor(ImageOptimController.self) private var delegate
    @State private var model = OptimizationViewModel()

    var body: some Scene {
        Window("ImageOptim", id: "optimization") {
            OptimizationView()
                .environment(model)
                .focusedSceneValue(\.optimizationModel, model)
                .task {
                    await model.connect(to: delegate)
                }
        }
        .defaultSize(width: 800, height: 480)
        .commands {
            OptimizationCommands()
        }

        Settings {
            SettingsView()
        }
    }
}
