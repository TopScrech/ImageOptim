import SwiftUI

@main
struct PicPressApp: App {
    @NSApplicationDelegateAdaptor(PicPressController.self) private var delegate
    @State private var vm = OptimizationVM()
    @AppStorage("AlwaysOnTop") private var alwaysOnTop = false

    var body: some Scene {
        Window("PicPress", id: "optimization") {
            OptimizationView()
                .background {
                    WindowLevelView(alwaysOnTop: alwaysOnTop)
                }
                .environment(vm)
                .focusedSceneValue(\.optimizationModel, vm)
                .onAppear {
                    vm.connect(to: delegate)
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
