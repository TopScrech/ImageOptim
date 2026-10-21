import ScrechKit

struct OptimizationToolbar: ToolbarContent {
    @Environment(OptimizationVM.self) private var vm

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button("Add images", systemImage: "plus") {
                vm.isImporting = true
            }
            .help("Add images or folders to optimize")

            if !vm.results.isEmpty || vm.isBusy {
                Button("Stop", systemImage: "stop", action: vm.stop)
                    .help("Stop optimization")
                    .disabled(!vm.canStop)

                Button("Optimize again", systemImage: "arrow.clockwise") {
                    vm.optimizeAgain()
                }
                .help("Optimize images again")
                .disabled(!vm.canOptimizeAgain)

                Button("Clear completed", systemImage: "trash", action: vm.clearCompleted)
                    .help("Remove completed images from the list")
                    .disabled(!vm.canClearCompleted)
            }

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .help("Open settings")
        }
    }
}
