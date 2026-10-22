import ScrechKit

struct OptimizationTableView: View {
    @Environment(OptimizationVM.self) private var vm
    
    @State private var sortOrder = [KeyPathComparator(\OptimizationResult.name)]

    var body: some View {
        @Bindable var vm = vm

        Table(vm.results.sorted(using: sortOrder), selection: $vm.selection, sortOrder: $sortOrder) {
            TableColumn("File", value: \.name) {
                OptimizationFileView(result: $0)
            }

            TableColumn("Original", value: \.originalSize) {
                Text($0.originalSize, format: .byteCount(style: .file))
                    .monospacedDigit()
            }

            TableColumn("Optimized", value: \.optimizedSize) {
                Text($0.optimizedSize, format: .byteCount(style: .file))
                    .monospacedDigit()
            }

            TableColumn("Savings", value: \.savings) {
                Text($0.savings, format: .percent.precision(.fractionLength(1)))
                    .monospacedDigit()
            }

            TableColumn("Tool", value: \.tool)
        }
        .contextMenu {
            Button("Quick Look", systemImage: "eye", action: vm.preview)
                .disabled(vm.selection.isEmpty)

            Button("Reveal in Finder", systemImage: "folder", action: vm.reveal)
                .disabled(vm.selection.isEmpty)

            Button("Restore original", systemImage: "arrow.uturn.backward", action: vm.revert)
                .disabled(!vm.canRevert)

            Button("Remove", systemImage: "trash", action: vm.removeSelected)
                .disabled(vm.selection.isEmpty)
        }
        .onDeleteCommand(perform: vm.removeSelected)
    }
}
