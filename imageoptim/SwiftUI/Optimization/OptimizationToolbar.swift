import ScrechKit

struct OptimizationToolbar: ToolbarContent {
    @Environment(OptimizationViewModel.self) private var model

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button("Add images", systemImage: "plus") {
                model.isImporting = true
            }
            .help("Add images or folders to optimize")

            Button("Stop", systemImage: "stop", action: model.stop)
                .help("Stop optimization")
                .disabled(!model.canStop)

            Button("Optimize again", systemImage: "arrow.clockwise") {
                model.optimizeAgain()
            }
            .help("Optimize images again")
            .disabled(!model.canOptimizeAgain)

            Button("Clear completed", systemImage: "trash", action: model.clearCompleted)
                .help("Remove completed images from the list")
                .disabled(!model.canClearCompleted)

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .help("Open settings")
        }
    }
}
